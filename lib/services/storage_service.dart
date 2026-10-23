import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../constants/app_config.dart';
import 'api_client.dart';

// stream request with chunk progress
class _ProgressUploadRequest extends http.BaseRequest {
  final Stream<List<int>> _stream;

  _ProgressUploadRequest(super.method, super.url, this._stream);

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(_stream);
  }
}

// upload error with status code
class MediaUploadHttpException implements Exception {
  final String message;
  final int? statusCode;
  final bool isRetryable;

  const MediaUploadHttpException(this.message,
      {this.statusCode, this.isRetryable = true});

  @override
  String toString() => message;
}

class PickedAttachment {
  final XFile file;
  final Uint8List bytes;

  const PickedAttachment({
    required this.file,
    required this.bytes,
  });

  String get name => file.name.isNotEmpty
      ? file.name.split(RegExp(r'[\\/]')).last
      : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
  int get sizeBytes => bytes.length;
}

class JobMediaUploadResult {
  final String url;
  final String key;
  const JobMediaUploadResult({required this.url, required this.key});
}

// worker for compute()
Uint8List _compressImageWorker(Map<String, dynamic> params) {
  final rawBytes = params['bytes'] as Uint8List;
  final maxDimension = params['maxDimension'] as int;
  final quality = params['quality'] as int;

  final decoded = img.decodeImage(rawBytes);
  if (decoded == null) {
    throw Exception('Failed to decode image');
  }
  final oriented = img.bakeOrientation(decoded);
  img.Image resized = oriented;
  if (oriented.width > maxDimension || oriented.height > maxDimension) {
    if (oriented.width >= oriented.height) {
      resized = img.copyResize(oriented, width: maxDimension);
    } else {
      resized = img.copyResize(oriented, height: maxDimension);
    }
  }
  resized.exif = img.ExifData();
  final compressedBytes = img.encodeJpg(resized, quality: quality);
  return Uint8List.fromList(compressedBytes);
}

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();
  factory StorageService() => instance;

  static String _resolveMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'image/jpeg';
  }

  static String _ensureFilenameExtension(String filename, String mimeType) {
    if (filename.contains('.')) return filename;
    switch (mimeType) {
      case 'image/png':
        return '$filename.png';
      case 'image/webp':
        return '$filename.webp';
      case 'application/pdf':
        return '$filename.pdf';
      case 'video/mp4':
        return '$filename.mp4';
      case 'image/jpeg':
      default:
        return '$filename.jpg';
    }
  }

  // strip exif and compress
  Future<Uint8List> stripExifAndCompressImage(
    Uint8List rawBytes, {
    int maxDimension = 1280,
    int quality = 75,
  }) {
    return compute(_compressImageWorker, {
      'bytes': rawBytes,
      'maxDimension': maxDimension,
      'quality': quality,
    });
  }

  // sync version
  Uint8List stripExifAndCompressImageSync(
    Uint8List rawBytes, {
    int maxDimension = 1280,
    int quality = 75,
  }) {
    return _compressImageWorker({
      'bytes': rawBytes,
      'maxDimension': maxDimension,
      'quality': quality,
    });
  }

  // upload job media to b2
  Future<JobMediaUploadResult> uploadJobMedia({
    required Uint8List bytes,
    required String filename,
    required String contentType,
    void Function(int sentBytes, int totalBytes)? onProgress,
    Future<void>? cancelTrigger,
  }) async {
    final cleanBase = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleanBase/upload');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to upload media');
    }

    // presign with 1 retry
    http.Response? presignRes;
    for (int presignAttempt = 0; presignAttempt < 2; presignAttempt++) {
      try {
        presignRes = await ApiClient.instance.post(
          uri: uri,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'mode': 'presign',
            'purpose': 'job_media',
            'filename': filename,
            'contentType': contentType,
            'sizeBytes': bytes.length,
          }),
          timeout: const Duration(seconds: 20),
        );
      } catch (e) {
        // retry network errors once
        if (presignAttempt == 0) {
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
        throw MediaUploadHttpException('Presign connection failed: $e',
            isRetryable: true);
      }

      if (presignRes.statusCode == 200) {
        break;
      }

      // do not retry 4xx
      final code = presignRes.statusCode;
      if (code == 400 ||
          code == 401 ||
          code == 403 ||
          code == 413 ||
          code == 415 ||
          code == 429) {
        debugPrint(
            '[StorageService] Non-retryable presign error: $code - ${presignRes.body}');
        throw MediaUploadHttpException(
          'Failed to get upload authorization ($code)',
          statusCode: code,
          isRetryable: false,
        );
      }

      // retry 5xx once
      if (presignAttempt == 0) {
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }

      debugPrint(
          '[StorageService] Presign error: $code - ${presignRes.body}');
      throw MediaUploadHttpException(
        'Failed to get upload authorization ($code)',
        statusCode: code,
        isRetryable: code >= 500,
      );
    }

    final presignData = jsonDecode(presignRes!.body) as Map<String, dynamic>;
    final uploadUrl = presignData['uploadUrl'] as String;
    final publicUrl = presignData['publicUrl'] as String;
    final key = presignData['key'] as String;
    final headersMap = (presignData['headers'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v.toString()),
        ) ??
        {};

    final isVideo = contentType.toLowerCase().contains('video');
    final client = http.Client();
    Timer? inactivityTimer;
    Timer? safetyCapTimer;
    bool aborted = false;
    String? abortReason;

    // abort if stalled 30s
    void resetInactivityTimer() {
      inactivityTimer?.cancel();
      inactivityTimer = Timer(const Duration(seconds: 30), () {
        aborted = true;
        abortReason = 'Upload stalled: no data sent for 30 seconds';
        client.close();
      });
    }

    // safety cap: 3m image, 10m video
    final safetyDuration =
        isVideo ? const Duration(minutes: 10) : const Duration(minutes: 3);
    safetyCapTimer = Timer(safetyDuration, () {
      aborted = true;
      abortReason = 'Upload exceeded maximum safety duration';
      client.close();
    });

    // cancel listener
    cancelTrigger?.then((_) {
      if (!aborted) {
        aborted = true;
        abortReason = 'Upload cancelled';
        client.close();
      }
    });

    // pipe chunks with progress
    Stream<List<int>> createChunkStream() async* {
      const chunkSize = 64 * 1024;
      int sent = 0;
      for (int i = 0; i < bytes.length; i += chunkSize) {
        if (aborted) break;
        final end =
            (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);
        yield chunk;
        sent += chunk.length;
        resetInactivityTimer();
        onProgress?.call(sent, bytes.length);
      }
    }

    resetInactivityTimer();

    try {
      final uploadReq = _ProgressUploadRequest(
        'PUT',
        Uri.parse(uploadUrl),
        createChunkStream(),
      );
      uploadReq.headers.addAll({
        'Content-Type': contentType,
        ...headersMap,
      });
      uploadReq.contentLength = bytes.length;

      final streamedRes = await client.send(uploadReq);
      final putRes = await http.Response.fromStream(streamedRes);

      if (putRes.statusCode < 200 || putRes.statusCode >= 300) {
        debugPrint(
            '[StorageService] B2 direct upload error: ${putRes.statusCode} - ${putRes.body}');
        final code = putRes.statusCode;
        final isRetryable = code >= 500;
        throw MediaUploadHttpException(
          'B2 upload failed ($code)',
          statusCode: code,
          isRetryable: isRetryable,
        );
      }

      return JobMediaUploadResult(url: publicUrl, key: key);
    } catch (e) {
      if (aborted) {
        throw TimeoutException(abortReason ?? 'Upload timed out');
      }
      if (e is MediaUploadHttpException) rethrow;
      throw MediaUploadHttpException('B2 upload failed: $e', isRetryable: true);
    } finally {
      inactivityTimer?.cancel();
      safetyCapTimer.cancel();
      client.close();
    }
  }

  // upload picked image
  Future<String> uploadPickedImage(
    XFile file, {
    String purpose = 'job_photo',
    Uint8List? preloadedBytes,
  }) async {
    final bytes = preloadedBytes ?? await file.readAsBytes();
    final filename = file.name.isNotEmpty
        ? file.name
        : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadBytes(bytes, filename: filename, purpose: purpose);
  }

  Future<String> uploadPickedAttachment(
    PickedAttachment attachment, {
    String purpose = 'job_photo',
  }) {
    return uploadPickedImage(
      attachment.file,
      purpose: purpose,
      preloadedBytes: attachment.bytes,
    );
  }

  Future<String> uploadJobPhoto({
    dynamic file,
    String? filename,
    String? userId,
    dynamic imageFile,
  }) {
    final target = file ?? imageFile;
    if (target == null) throw ArgumentError('Image file cannot be null');
    if (target is PickedAttachment) {
      return uploadPickedAttachment(target, purpose: 'job_photo');
    }
    if (target is XFile) {
      return uploadPickedImage(target, purpose: 'job_photo');
    }
    return uploadFile(target, filename: filename, purpose: 'job_photo');
  }

  // legacy multipart upload
  Future<String> uploadFile(dynamic file,
      {String? filename, String? purpose}) async {
    try {
      if (file is PickedAttachment) {
        return await uploadPickedAttachment(file,
            purpose: purpose ?? 'job_photo');
      }
      if (file is XFile) {
        return await uploadPickedImage(file, purpose: purpose ?? 'job_photo');
      }
      final bytes = await file.readAsBytes() as Uint8List;
      final rawName = filename ??
          (file is XFile
              ? file.name
              : file.path?.toString().split(RegExp(r'[\\/]')).last ??
                  'file.jpg');
      return await uploadBytes(bytes, filename: rawName, purpose: purpose);
    } catch (e) {
      debugPrint('[StorageService] Local read error: $e');
      rethrow;
    }
  }

  // legacy byte upload
  Future<String> uploadBytes(Uint8List bytes,
      {required String filename, String? purpose}) async {
    final cleanBase = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
    final isPrivate = purpose == 'nic' || purpose == 'cert';
    final baseUploadUri = Uri.parse('$cleanBase/upload');
    final uri = isPrivate
        ? baseUploadUri.replace(queryParameters: {'purpose': purpose!})
        : baseUploadUri;

    final mimeType = _resolveMimeType(filename);
    final finalFilename = _ensureFilenameExtension(filename, mimeType);

    Uint8List bytesToUpload = bytes;
    if (mimeType.startsWith('image/')) {
      try {
        bytesToUpload = await stripExifAndCompressImage(bytes);
      } catch (_) {}
    }

    try {
      final request = http.MultipartRequest('POST', uri);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        request.headers['Authorization'] = 'Bearer ${await user.getIdToken()}';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytesToUpload,
          filename: finalFilename,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (isPrivate) {
          final key = data['key'] as String?;
          if (key != null && key.isNotEmpty) {
            return key;
          }
        } else {
          final url = data['url'] as String?;
          if (url != null && url.isNotEmpty) {
            return url;
          }
        }
      }
      debugPrint(
          '[StorageService] Server returned ${response.statusCode}: ${response.body}');
      throw Exception('Upload failed (${response.statusCode})');
    } catch (e) {
      debugPrint('[StorageService] Remote upload exception: $e');
      if (e is Exception) rethrow;
      throw Exception('Upload failed');
    }
  }
}

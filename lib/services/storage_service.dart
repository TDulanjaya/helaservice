import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../constants/app_config.dart';

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

  // strip gps/exif and compress
  Uint8List stripExifAndCompressImage(
    Uint8List rawBytes, {
    int maxDimension = 1600,
    int quality = 80,
  }) {
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

  // upload job media directly to b2
  Future<JobMediaUploadResult> uploadJobMedia({
    required Uint8List bytes,
    required String filename,
    required String contentType,
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    final cleanBase = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleanBase/upload');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to upload media');
    }
    final token = await user.getIdToken();

    // get presigned url
    final presignRes = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'mode': 'presign',
        'purpose': 'job_media',
        'filename': filename,
        'contentType': contentType,
        'sizeBytes': bytes.length,
      }),
    ).timeout(const Duration(seconds: 20));

    if (presignRes.statusCode != 200) {
      debugPrint('[StorageService] Presign error: ${presignRes.statusCode} - ${presignRes.body}');
      throw Exception('Failed to get upload authorization: ${presignRes.body}');
    }

    final presignData = jsonDecode(presignRes.body) as Map<String, dynamic>;
    final uploadUrl = presignData['uploadUrl'] as String;
    final publicUrl = presignData['publicUrl'] as String;
    final key = presignData['key'] as String;
    final headersMap = (presignData['headers'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v.toString()),
        ) ??
        {};

    // stream upload to b2 with byte progress
    final streamedReq = http.StreamedRequest('PUT', Uri.parse(uploadUrl));
    streamedReq.headers.addAll({
      'Content-Type': contentType,
      ...headersMap,
    });
    streamedReq.contentLength = bytes.length;

    const chunkSize = 64 * 1024;
    () async {
      int sent = 0;
      for (int i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);
        streamedReq.sink.add(chunk);
        sent += chunk.length;
        onProgress?.call(sent, bytes.length);
      }
      streamedReq.sink.close();
    }();

    final streamedRes = await streamedReq.send().timeout(const Duration(seconds: 90));
    final putRes = await http.Response.fromStream(streamedRes);

    if (putRes.statusCode < 200 || putRes.statusCode >= 300) {
      debugPrint('[StorageService] B2 direct upload error: ${putRes.statusCode} - ${putRes.body}');
      throw Exception('B2 upload failed (${putRes.statusCode})');
    }

    return JobMediaUploadResult(url: publicUrl, key: key);
  }

  // upload image picked from image picker
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

  // upload file to storage api (legacy multipart)
  Future<String> uploadFile(dynamic file, {String? filename, String? purpose}) async {
    try {
      if (file is PickedAttachment) {
        return await uploadPickedAttachment(file, purpose: purpose ?? 'job_photo');
      }
      if (file is XFile) {
        return await uploadPickedImage(file, purpose: purpose ?? 'job_photo');
      }
      final bytes = await file.readAsBytes() as Uint8List;
      final rawName = filename ??
          (file is XFile
              ? file.name
              : file.path?.toString().split(RegExp(r'[\\/]')).last ?? 'file.jpg');
      return await uploadBytes(bytes, filename: rawName, purpose: purpose);
    } catch (e) {
      debugPrint('[StorageService] Local read error: $e');
      rethrow;
    }
  }

  // upload file bytes (legacy multipart)
  Future<String> uploadBytes(Uint8List bytes, {required String filename, String? purpose}) async {
    final cleanBase = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
    final isNic = purpose == 'nic';
    final baseUploadUri = Uri.parse('$cleanBase/upload');
    final uri = isNic
        ? baseUploadUri.replace(queryParameters: {'purpose': 'nic'})
        : baseUploadUri;

    final mimeType = _resolveMimeType(filename);
    final finalFilename = _ensureFilenameExtension(filename, mimeType);

    Uint8List bytesToUpload = bytes;
    if (mimeType.startsWith('image/')) {
      try {
        bytesToUpload = stripExifAndCompressImage(bytes);
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
        if (isNic) {
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
      throw Exception(
          'Upload failed (${response.statusCode}): ${response.body}');
    } catch (e) {
      debugPrint('[StorageService] Remote upload exception: $e');
      if (e is Exception) rethrow;
      throw Exception('Upload failed: $e');
    }
  }
}


import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/app_config.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static String _resolveMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
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
      case 'image/jpeg':
      default:
        return '$filename.jpg';
    }
  }

  // upload file to storage api
  Future<String> uploadFile(File file, {String? filename, String? purpose}) async {
    try {
      final bytes = await file.readAsBytes();
      final rawName = filename ?? file.path.split(Platform.pathSeparator).last;
      return await uploadBytes(bytes, filename: rawName, purpose: purpose);
    } catch (e) {
      debugPrint('[StorageService] Local read error: $e');
      rethrow;
    }
  }

  // upload file bytes
  Future<String> uploadBytes(Uint8List bytes, {required String filename, String? purpose}) async {
    final cleanBase = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
    final isNic = purpose == 'nic';
    final uri = Uri.parse(isNic ? '$cleanBase/upload?purpose=nic' : '$cleanBase/upload');

    final mimeType = _resolveMimeType(filename);
    final finalFilename = _ensureFilenameExtension(filename, mimeType);

    try {
      final request = http.MultipartRequest('POST', uri);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        request.headers['Authorization'] = 'Bearer ${await user.getIdToken()}';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
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

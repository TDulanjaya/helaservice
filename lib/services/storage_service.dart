import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  // upload file to b2 via vercel api
  Future<String> uploadFile(File file, {String? filename}) async {
    try {
      final bytes = await file.readAsBytes();
      final name = filename ?? file.path.split(Platform.pathSeparator).last;
      return await uploadBytes(bytes, filename: name);
    } catch (e) {
      debugPrint('[StorageService] Local read error: $e');
      rethrow;
    }
  }

  // upload raw bytes to /api/upload
  Future<String> uploadBytes(Uint8List bytes, {required String filename}) async {
    final cleanBase = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleanBase/upload');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers['x-helaservice-key'] = AppConfig.apiSecretKey;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final url = data['url'] as String?;
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }
      debugPrint('[StorageService] Server returned ${response.statusCode}: ${response.body}. Using fallback.');
    } catch (e) {
      debugPrint('[StorageService] Remote upload exception: $e. Falling back to data URI.');
    }

    // fallback to base64 if offline or dev mode
    final b64 = base64Encode(bytes);
    return 'data:image/jpeg;base64,$b64';
  }
}

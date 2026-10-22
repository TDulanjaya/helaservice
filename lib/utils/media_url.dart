import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// check if url is app media
bool isAppMediaUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final lower = url.toLowerCase();
  return lower.contains('/api/media?key=') || lower.contains('/api/media');
}

// auth headers with id token
Future<Map<String, String>> mediaHeaders() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const {};
  try {
    final token = await user.getIdToken();
    if (token != null && token.isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }
  } catch (e) {
    debugPrint('[media_url] error getting token: $e');
  }
  return const {};
}

// get signed url for video
Future<String?> resolveMediaUrlForVideo(String url) async {
  if (!isAppMediaUrl(url)) return url;
  try {
    final headers = await mediaHeaders();
    final separator = url.contains('?') ? '&' : '?';
    final jsonUri = Uri.parse('$url${separator}mode=json');
    final res = await http.get(jsonUri, headers: headers).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map && data['url'] is String) {
        return data['url'] as String;
      }
    }
    debugPrint('[media_url] resolve video status: ${res.statusCode}');
  } catch (e) {
    debugPrint('[media_url] failed to resolve video url: $e');
  }
  return null;
}

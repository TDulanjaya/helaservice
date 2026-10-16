import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';
import '../constants/firestore_paths.dart';
import '../models/app_notification.dart';

// push and in app notification service
class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _initialized = false;

  // initialize notifications and token registration
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (!kIsWeb) {
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          final token = await messaging.getToken();
          if (token != null) {
            await _saveToken(token);
          }

          messaging.onTokenRefresh.listen((newToken) {
            _saveToken(newToken);
          });
        }

        // handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('foreground push message received ${message.messageId}');
        });

        // handle message open
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('push message opened ${message.messageId}');
        });
      }
    } catch (e) {
      debugPrint('notification setup note $e');
    }
  }

  // save token to user record
  Future<void> _saveToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    try {
      final tokenHash =
          token.length > 32 ? token.substring(token.length - 32) : token;
      final docRef = _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection('fcmTokens')
          .doc(tokenHash);

      await docRef.set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('save fcm token note $e');
    }
  }

  // stream notifications list
  Stream<List<AppNotification>> streamUserNotifications(String uid) {
    if (uid.isEmpty) return Stream.value([]);

    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => AppNotification.fromDoc(doc)).toList());
  }

  // stream unread notification count
  Stream<int> streamUnreadCount(String uid) {
    if (uid.isEmpty) return Stream.value(0);

    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // mark single item as read
  Future<void> markAsRead(String uid, String notificationId) async {
    if (uid.isEmpty || notificationId.isEmpty) return;
    try {
      await _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('mark read note $e');
    }
  }

  // mark all user alerts read
  Future<void> markAllAsRead(String uid) async {
    if (uid.isEmpty) return;
    try {
      final snap = await _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (snap.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('mark all read note $e');
    }
  }

  // delete notification
  Future<void> deleteNotification(String uid, String notificationId) async {
    if (uid.isEmpty || notificationId.isEmpty) return;
    try {
      await _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('delete notification note $e');
    }
  }

  // trigger notification via backend api with authenticated session
  Future<bool> sendNotification({
    required String event,
    required String docId,
  }) async {
    if (event.isEmpty || docId.isEmpty) return false;

    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final token = await user.getIdToken();
      if (token == null || token.isEmpty) return false;

      final baseUrl = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$baseUrl/notify');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final payload = jsonEncode({
        'event': event,
        'docId': docId,
      });

      final response = await http
          .post(uri, headers: headers, body: payload)
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('send notification note $e');
      return false;
    }
  }
}

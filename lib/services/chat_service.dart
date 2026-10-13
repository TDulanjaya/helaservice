import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import 'notification_service.dart';
import 'storage_service.dart';

// chat message model with optional photo support
class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String? imageUrl;
  final String type;
  final DateTime? createdAt;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl,
    this.type = 'text',
    this.createdAt,
  });

  factory ChatMessageModel.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return ChatMessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl']?.toString(),
      type: map['type']?.toString() ?? (map['imageUrl'] != null ? 'image' : 'text'),
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
        'type': type,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}

// chat room summary with unread badge tracking
class ChatRoomSummary {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantRoles;
  final Map<String, String> participantPhones;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final String? jobRequestId;
  final Map<String, int> unreadCounts;
  final Map<String, DateTime> lastReadAt;

  const ChatRoomSummary({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.participantRoles = const {},
    this.participantPhones = const {},
    required this.lastMessage,
    this.lastMessageAt,
    this.lastSenderId,
    this.jobRequestId,
    this.unreadCounts = const {},
    this.lastReadAt = const {},
  });

  factory ChatRoomSummary.fromMap(String id, Map<String, dynamic> map) {
    final participantsRaw = map['participants'];
    final participants = (participantsRaw is List)
        ? participantsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final namesRaw = map['participantNames'];
    final names = <String, String>{};
    if (namesRaw is Map) {
      namesRaw.forEach((k, v) => names[k.toString()] = v.toString());
    }

    final rolesRaw = map['participantRoles'];
    final roles = <String, String>{};
    if (rolesRaw is Map) {
      rolesRaw.forEach((k, v) => roles[k.toString()] = v.toString());
    }

    final phonesRaw = map['participantPhones'];
    final phones = <String, String>{};
    if (phonesRaw is Map) {
      phonesRaw.forEach((k, v) => phones[k.toString()] = v.toString());
    }

    // parse unread counts map
    final unreadRaw = map['unreadCounts'];
    final unreads = <String, int>{};
    if (unreadRaw is Map) {
      unreadRaw.forEach((k, v) {
        if (v is num) {
          unreads[k.toString()] = v.toInt();
        }
      });
    }

    // parse last read timestamps
    final lastReadRaw = map['lastReadAt'];
    final reads = <String, DateTime>{};
    if (lastReadRaw is Map) {
      lastReadRaw.forEach((k, v) {
        if (v is Timestamp) {
          reads[k.toString()] = v.toDate();
        }
      });
    }

    final ts = map['lastMessageAt'];
    final lastMessageAt = ts is Timestamp ? ts.toDate() : null;

    return ChatRoomSummary(
      id: id,
      participants: participants,
      participantNames: names,
      participantRoles: roles,
      participantPhones: phones,
      lastMessage: map['lastMessage']?.toString() ?? '',
      lastMessageAt: lastMessageAt,
      lastSenderId: map['lastSenderId']?.toString(),
      jobRequestId: map['jobRequestId']?.toString(),
      unreadCounts: unreads,
      lastReadAt: reads,
    );
  }

  // get other participant id
  String getOtherPartyId(String currentUserId) {
    return participants.firstWhere((p) => p != currentUserId, orElse: () => '');
  }

  // get other participant name
  String getOtherPartyName(String currentUserId) {
    final otherId = getOtherPartyId(currentUserId);
    final name = participantNames[otherId];
    return (name != null && name.isNotEmpty) ? name : '';
  }

  // get other participant role
  String? getOtherPartyRole(String currentUserId) {
    final otherId = getOtherPartyId(currentUserId);
    return participantRoles[otherId];
  }

  // get other participant phone
  String? getOtherPartyPhone(String currentUserId) {
    final otherId = getOtherPartyId(currentUserId);
    return participantPhones[otherId];
  }

  // get unread count for current user
  int getUnreadCount(String currentUserId) {
    return unreadCounts[currentUserId] ?? 0;
  }
}

// chat service for messaging and rooms
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final _db = FirebaseFirestore.instance;

  // get or create chat room with deterministic id
  Future<String> getOrCreateChatRoom({
    required String userId1,
    required String userId2,
    required String user1Name,
    required String user2Name,
    String? jobRequestId,
    String? user1Role,
    String? user2Role,
    String? user1Phone,
    String? user2Phone,
  }) async {
    final ids = [userId1, userId2]..sort();
    final chatId = '${ids[0]}_${ids[1]}';

    final docRef = _db.collection(FirestorePaths.chatRooms).doc(chatId);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'participants': ids,
        'participantNames': {userId1: user1Name, userId2: user2Name},
        'participantRoles': {
          if (user1Role != null && user1Role.isNotEmpty) userId1: user1Role,
          if (user2Role != null && user2Role.isNotEmpty) userId2: user2Role,
        },
        'participantPhones': {
          if (user1Phone != null && user1Phone.isNotEmpty) userId1: user1Phone,
          if (user2Phone != null && user2Phone.isNotEmpty) userId2: user2Phone,
        },
        'jobRequestId': jobRequestId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCounts': {userId1: 0, userId2: 0},
        'lastReadAt': {
          userId1: FieldValue.serverTimestamp(),
          userId2: FieldValue.serverTimestamp(),
        },
      });
    } else {
      final updates = <String, dynamic>{};
      if (user1Name.isNotEmpty) updates['participantNames.$userId1'] = user1Name;
      if (user2Name.isNotEmpty) updates['participantNames.$userId2'] = user2Name;
      if (user1Role != null && user1Role.isNotEmpty) updates['participantRoles.$userId1'] = user1Role;
      if (user2Role != null && user2Role.isNotEmpty) updates['participantRoles.$userId2'] = user2Role;
      if (user1Phone != null && user1Phone.isNotEmpty) updates['participantPhones.$userId1'] = user1Phone;
      if (user2Phone != null && user2Phone.isNotEmpty) updates['participantPhones.$userId2'] = user2Phone;
      if (updates.isNotEmpty) {
        await docRef.update(updates);
      }
    }

    return chatId;
  }

  // stream chat rooms for user
  Stream<List<ChatRoomSummary>> streamUserChatRooms(String userId, {int limit = 50}) {
    return _db
        .collection(FirestorePaths.chatRooms)
        .where('participants', arrayContains: userId)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ChatRoomSummary.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });
      return list;
    });
  }

  // stream all chat rooms for admin
  Stream<List<ChatRoomSummary>> streamAllChatRooms({int limit = 100}) {
    return _db
        .collection(FirestorePaths.chatRooms)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ChatRoomSummary.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });
      return list;
    });
  }

  // mark room as read for user
  Future<void> markRoomAsRead(String chatRoomId, String userId) async {
    if (chatRoomId.isEmpty || userId.isEmpty) return;
    try {
      await _db.collection(FirestorePaths.chatRooms).doc(chatRoomId).update({
        'unreadCounts.$userId': 0,
        'lastReadAt.$userId': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // send chat message with optional photo
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String text,
    String? imageUrl,
    String type = 'text',
  }) async {
    final batch = _db.batch();

    final msgRef = _db
        .collection(FirestorePaths.chatRooms)
        .doc(chatRoomId)
        .collection(FirestorePaths.messages)
        .doc();

    final previewText = text.trim().isNotEmpty
        ? text.trim()
        : (imageUrl != null ? 'photo' : '');

    batch.set(msgRef, {
      'senderId': senderId,
      'senderName': senderName,
      'text': text.trim(),
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final docSnap = await _db.collection(FirestorePaths.chatRooms).doc(chatRoomId).get();
    final participants = (docSnap.data()?['participants'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final recipientUid = participants.firstWhere((p) => p != senderId, orElse: () => '');

    final roomUpdates = <String, dynamic>{
      'lastMessage': previewText,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'unreadCounts.$senderId': 0,
      'lastReadAt.$senderId': FieldValue.serverTimestamp(),
    };

    if (recipientUid.isNotEmpty) {
      roomUpdates['unreadCounts.$recipientUid'] = FieldValue.increment(1);
    }

    batch.update(
      _db.collection(FirestorePaths.chatRooms).doc(chatRoomId),
      roomUpdates,
    );

    await batch.commit();

    // send push alert to recipient
    if (recipientUid.isNotEmpty) {
      NotificationService.instance.sendNotification(
        event: 'chat_message',
        docId: chatRoomId,
      );
    }
  }

  // send image message
  Future<void> sendImageMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required dynamic imageInput,
    String text = '',
  }) async {
    String? uploadedUrl;
    if (imageInput is PickedAttachment) {
      uploadedUrl = await StorageService.instance.uploadPickedAttachment(imageInput, purpose: 'chat');
    } else if (imageInput is XFile) {
      uploadedUrl = await StorageService.instance.uploadPickedImage(imageInput, purpose: 'chat');
    } else if (imageInput is Uint8List) {
      final chatFilename = 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
      uploadedUrl = await StorageService.instance.uploadBytes(
        imageInput,
        filename: chatFilename,
      );
    } else if (imageInput is String && imageInput.startsWith('http')) {
      uploadedUrl = imageInput;
    } else if (imageInput != null) {
      uploadedUrl = await StorageService.instance.uploadFile(imageInput, purpose: 'chat');
    }

    if (uploadedUrl == null || uploadedUrl.isEmpty) {
      throw Exception('Failed to obtain image URL');
    }

    await sendMessage(
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      imageUrl: uploadedUrl,
      type: 'image',
    );
  }

  // stream room messages
  Stream<List<ChatMessageModel>> streamMessages(String chatRoomId, {int limit = 100}) {
    return _db
        .collection(FirestorePaths.chatRooms)
        .doc(chatRoomId)
        .collection(FirestorePaths.messages)
        .orderBy('createdAt', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessageModel.fromMap(d.id, d.data()))
            .toList());
  }
}


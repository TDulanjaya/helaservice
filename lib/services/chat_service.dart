import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';

// chat message model
class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime? createdAt;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.createdAt,
  });

  factory ChatMessageModel.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return ChatMessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

// inbox item
class ChatRoomSummary {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantRoles;
  final Map<String, String> participantPhones;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String? jobRequestId;

  const ChatRoomSummary({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.participantRoles = const {},
    this.participantPhones = const {},
    required this.lastMessage,
    this.lastMessageAt,
    this.jobRequestId,
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
      jobRequestId: map['jobRequestId']?.toString(),
    );
  }

  String getOtherPartyId(String currentUserId) {
    return participants.firstWhere((p) => p != currentUserId, orElse: () => '');
  }

  String getOtherPartyName(String currentUserId) {
    final otherId = getOtherPartyId(currentUserId);
    final name = participantNames[otherId];
    return (name != null && name.isNotEmpty) ? name : 'User';
  }

  String? getOtherPartyRole(String currentUserId) {
    final otherId = getOtherPartyId(currentUserId);
    return participantRoles[otherId];
  }

  String? getOtherPartyPhone(String currentUserId) {
    final otherId = getOtherPartyId(currentUserId);
    return participantPhones[otherId];
  }
}

// chat service
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final _db = FirebaseFirestore.instance;

  // get or create room
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

  // stream user rooms
  Stream<List<ChatRoomSummary>> streamUserChatRooms(String userId) {
    return _db
        .collection(FirestorePaths.chatRooms)
        .where('participants', arrayContains: userId)
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

  // stream all rooms
  Stream<List<ChatRoomSummary>> streamAllChatRooms() {
    return _db
        .collection(FirestorePaths.chatRooms)
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

  // send message
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final batch = _db.batch();

    final msgRef = _db
        .collection(FirestorePaths.chatRooms)
        .doc(chatRoomId)
        .collection(FirestorePaths.messages)
        .doc();

    batch.set(msgRef, {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(
      _db.collection(FirestorePaths.chatRooms).doc(chatRoomId),
      {
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  // stream room messages
  Stream<List<ChatMessageModel>> streamMessages(String chatRoomId) {
    return _db
        .collection(FirestorePaths.chatRooms)
        .doc(chatRoomId)
        .collection(FirestorePaths.messages)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessageModel.fromMap(d.id, d.data()))
            .toList());
  }
}

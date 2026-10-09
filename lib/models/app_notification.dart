import 'package:cloud_firestore/cloud_firestore.dart';

// notification model for user alerts
class AppNotification {
  final String id;
  final String recipientUid;
  final String eventType;
  final String title;
  final String body;
  final String? bookingId;
  final String? quoteId;
  final String? chatRoomId;
  final String? jobRequestId;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic> data;

  const AppNotification({
    required this.id,
    required this.recipientUid,
    required this.eventType,
    required this.title,
    required this.body,
    this.bookingId,
    this.quoteId,
    this.chatRoomId,
    this.jobRequestId,
    this.isRead = false,
    this.createdAt,
    this.data = const {},
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return AppNotification.fromMap(map, documentId: doc.id);
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime? parsedCreatedAt;
    final rawCreated = map['createdAt'];
    if (rawCreated is Timestamp) {
      parsedCreatedAt = rawCreated.toDate();
    } else if (rawCreated is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreated);
    }

    return AppNotification(
      id: documentId ?? (map['id']?.toString() ?? ''),
      recipientUid: map['recipientUid']?.toString() ?? '',
      eventType: map['eventType']?.toString() ?? 'custom',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      bookingId: map['bookingId']?.toString(),
      quoteId: map['quoteId']?.toString(),
      chatRoomId: map['chatRoomId']?.toString(),
      jobRequestId: map['jobRequestId']?.toString(),
      isRead: map['isRead'] == true,
      createdAt: parsedCreatedAt,
      data: (map['data'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(map['data'])
          : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipientUid': recipientUid,
      'eventType': eventType,
      'title': title,
      'body': body,
      if (bookingId != null) 'bookingId': bookingId,
      if (quoteId != null) 'quoteId': quoteId,
      if (chatRoomId != null) 'chatRoomId': chatRoomId,
      if (jobRequestId != null) 'jobRequestId': jobRequestId,
      'isRead': isRead,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (data.isNotEmpty) 'data': data,
    };
  }

  AppNotification copyWith({
    String? id,
    String? recipientUid,
    String? eventType,
    String? title,
    String? body,
    String? bookingId,
    String? quoteId,
    String? chatRoomId,
    String? jobRequestId,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      recipientUid: recipientUid ?? this.recipientUid,
      eventType: eventType ?? this.eventType,
      title: title ?? this.title,
      body: body ?? this.body,
      bookingId: bookingId ?? this.bookingId,
      quoteId: quoteId ?? this.quoteId,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      jobRequestId: jobRequestId ?? this.jobRequestId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}

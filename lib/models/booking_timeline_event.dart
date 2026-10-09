import 'package:cloud_firestore/cloud_firestore.dart';

// booking timeline event model
class BookingTimelineEvent {
  final String id;
  final String action;
  final String title;
  final String description;
  final DateTime? timestamp;
  final String actorUid;
  final String actorRole;
  final Map<String, dynamic>? metadata;

  const BookingTimelineEvent({
    this.id = '',
    required this.action,
    required this.title,
    required this.description,
    this.timestamp,
    required this.actorUid,
    this.actorRole = 'system',
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
        'action': action,
        'title': title,
        'description': description,
        'timestamp': timestamp != null
            ? Timestamp.fromDate(timestamp!)
            : FieldValue.serverTimestamp(),
        'actorUid': actorUid,
        'actorRole': actorRole,
        if (metadata != null) 'metadata': metadata,
      };

  factory BookingTimelineEvent.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['timestamp'];
    return BookingTimelineEvent(
      id: id,
      action: map['action'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: ts is Timestamp ? ts.toDate() : null,
      actorUid: map['actorUid'] ?? '',
      actorRole: map['actorRole'] ?? 'system',
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

// admin audit log model
class AdminLog {
  final String id;
  final String adminUid;
  final String adminEmail;
  final String action;
  final String targetType;
  final String targetId;
  final String details;
  final DateTime? timestamp;
  final Map<String, dynamic>? metadata;

  const AdminLog({
    this.id = '',
    required this.adminUid,
    this.adminEmail = '',
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.details,
    this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
        'adminUid': adminUid,
        'adminEmail': adminEmail,
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'details': details,
        'timestamp': timestamp != null
            ? Timestamp.fromDate(timestamp!)
            : FieldValue.serverTimestamp(),
        if (metadata != null) 'metadata': metadata,
      };

  factory AdminLog.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['timestamp'];
    return AdminLog(
      id: id,
      adminUid: map['adminUid'] ?? '',
      adminEmail: map['adminEmail'] ?? '',
      action: map['action'] ?? '',
      targetType: map['targetType'] ?? '',
      targetId: map['targetId'] ?? '',
      details: map['details'] ?? '',
      timestamp: ts is Timestamp ? ts.toDate() : null,
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }
}

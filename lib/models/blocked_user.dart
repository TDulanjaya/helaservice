import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:hela_service/utils/l10n_extension.dart';

class BlockedUser {
  final String id;
  final String blockedUid;
  final String name;
  final String reason;
  final DateTime? createdAt;

  const BlockedUser({
    required this.id,
    required this.blockedUid,
    required this.name,
    this.reason = '',
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'blockedUid': blockedUid,
        'name': name,
        'reason': reason,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  String displayName(BuildContext context) {
    if (name.trim().isNotEmpty) return name;
    return context.l10n.roleCustomer;
  }

  factory BlockedUser.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return BlockedUser(
      id: id,
      blockedUid: map['blockedUid'] ?? id,
      name: map['name'] ?? '',
      reason: map['reason'] ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class SupportMessage {
  final String id;
  final String senderUid;
  final String senderRole; // 'user' | 'admin'
  final String? senderName;
  final String text;
  final List<String> photos;
  final DateTime? createdAt;

  const SupportMessage({
    this.id = '',
    required this.senderUid,
    required this.senderRole,
    required this.text,
    this.senderName,
    this.photos = const [],
    this.createdAt,
  });

  bool get isAdmin => senderRole == 'admin';
  String get body => text;
  String get formattedTime {
    if (createdAt == null) return '';
    final h = createdAt!.hour.toString().padLeft(2, '0');
    final m = createdAt!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, dynamic> toMap() => {
        'senderUid': senderUid,
        'senderRole': senderRole,
        if (senderName != null) 'senderName': senderName,
        'text': text,
        'photos': photos,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  factory SupportMessage.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    final rawPhotos = map['photos'];
    final photoList = (rawPhotos is List)
        ? rawPhotos.map((e) => e.toString()).toList()
        : <String>[];

    return SupportMessage(
      id: id,
      senderUid: map['senderUid']?.toString() ?? '',
      senderRole: map['senderRole']?.toString() ?? 'user',
      senderName: map['senderName']?.toString(),
      text: map['text']?.toString() ?? '',
      photos: photoList,
      createdAt: parseDate(map['createdAt']),
    );
  }
}

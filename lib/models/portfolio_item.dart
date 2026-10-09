import 'package:cloud_firestore/cloud_firestore.dart';

class PortfolioItem {
  final String id;
  final String providerId;
  final String title;
  final String description;
  final String photoUrl;
  final String category;
  final DateTime? createdAt;
  final bool isApproved;

  const PortfolioItem({
    this.id = '',
    required this.providerId,
    required this.title,
    this.description = '',
    required this.photoUrl,
    this.category = '',
    this.createdAt,
    this.isApproved = true,
  });

  Map<String, dynamic> toMap() => {
        'providerId': providerId,
        'title': title,
        'description': description,
        'photoUrl': photoUrl,
        'category': category,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'isApproved': isApproved,
      };

  factory PortfolioItem.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return PortfolioItem(
      id: id,
      providerId: map['providerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      category: map['category'] ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
      isApproved: map['isApproved'] ?? true,
    );
  }

  PortfolioItem copyWith({
    String? id,
    String? providerId,
    String? title,
    String? description,
    String? photoUrl,
    String? category,
    DateTime? createdAt,
    bool? isApproved,
  }) {
    return PortfolioItem(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}

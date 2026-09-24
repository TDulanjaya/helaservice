class Review {
  final String reviewerName;
  final String initials;
  final String location;
  final String timeAgo;
  final double rating;
  final String comment;

  const Review({
    required this.reviewerName,
    required this.initials,
    required this.location,
    required this.timeAgo,
    required this.rating,
    required this.comment,
  });

  Map<String, dynamic> toMap() => {
        'reviewerName': reviewerName,
        'initials': initials,
        'location': location,
        'timeAgo': timeAgo,
        'rating': rating,
        'comment': comment,
      };

  factory Review.fromMap(Map<String, dynamic> map) => Review(
        reviewerName: map['reviewerName'] ?? '',
        initials: map['initials'] ?? '',
        location: map['location'] ?? '',
        timeAgo: map['timeAgo'] ?? '',
        rating: (map['rating'] ?? 0).toDouble(),
        comment: map['comment'] ?? '',
      );
}

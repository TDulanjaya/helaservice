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
}

class PlaceReview {
  final String authorName;
  final String authorAvatar;
  final int rating;
  final String timeAgo;
  final String text;
  final int likesCount;
  final bool isLocalGuide;

  const PlaceReview({
    required this.authorName,
    required this.authorAvatar,
    required this.rating,
    required this.timeAgo,
    required this.text,
    this.likesCount = 0,
    this.isLocalGuide = true,
  });
}

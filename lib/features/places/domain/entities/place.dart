import 'package:latlong2/latlong.dart';
import 'place_review.dart';

class Place {
  final String id;
  final String name;
  final LatLng position;
  final String type;
  final String? address;
  final double rating;
  final int reviewsCount;
  final List<String> photos;
  final List<PlaceReview> reviews;
  final String? phone;
  final String? openingHours;

  const Place({
    required this.id,
    required this.name,
    required this.position,
    required this.type,
    this.address,
    this.rating = 4.7,
    this.reviewsCount = 42,
    this.photos = const [],
    this.reviews = const [],
    this.phone,
    this.openingHours,
  });
}

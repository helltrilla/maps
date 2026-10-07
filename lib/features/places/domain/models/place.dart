import 'package:flutter/material.dart';
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

  IconData get icon {
    switch (type.toLowerCase()) {
      case 'кафе':
        return Icons.local_cafe_rounded;
      case 'ресторан':
        return Icons.restaurant_rounded;
      case 'аптека':
        return Icons.local_pharmacy_rounded;
      case 'магазин':
      case 'супермаркет':
        return Icons.shopping_bag_rounded;
      case 'заправка':
      case 'азс':
        return Icons.local_gas_station_rounded;
      case 'отель':
      case 'гостиница':
        return Icons.hotel_rounded;
      case 'банк':
      case 'банкомат':
        return Icons.account_balance_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  Color get color {
    switch (type.toLowerCase()) {
      case 'кафе':
        return const Color(0xFFFF9800);
      case 'ресторан':
        return const Color(0xFFE91E63);
      case 'аптека':
        return const Color(0xFF4CAF50);
      case 'магазин':
      case 'супермаркет':
        return const Color(0xFF2196F3);
      case 'заправка':
      case 'азс':
        return const Color(0xFFFF5722);
      case 'отель':
      case 'гостиница':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF00BCD4);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class SearchResult {
  final String title;
  final String subtitle;
  final LatLng position;
  final String type;

  const SearchResult({
    required this.title,
    required this.subtitle,
    required this.position,
    required this.type,
  });

  IconData get icon {
    switch (type.toLowerCase()) {
      case 'cafe':
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'shop':
      case 'supermarket':
        return Icons.shopping_cart_rounded;
      case 'pharmacy':
      case 'hospital':
        return Icons.local_hospital_rounded;
      case 'fuel':
        return Icons.local_gas_station_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'street':
      case 'highway':
        return Icons.route_rounded;
      case 'city':
      case 'town':
      case 'village':
        return Icons.location_city_rounded;
      default:
        return Icons.place_rounded;
    }
  }
}

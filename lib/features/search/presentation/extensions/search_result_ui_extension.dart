import 'package:flutter/material.dart';
import '../../domain/entities/search_result.dart';

extension SearchResultUiExtension on SearchResult {
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

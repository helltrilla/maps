import 'package:latlong2/latlong.dart';

class SearchResult {
  final String title;
  final String subtitle;
  final LatLng position;
  final String type;
  final double? distanceMeters;

  const SearchResult({
    required this.title,
    required this.subtitle,
    required this.position,
    required this.type,
    this.distanceMeters,
  });

  String? get distanceFormatted {
    if (distanceMeters == null) return null;
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} м';
    }
    final km = distanceMeters! / 1000;
    return '${km.toStringAsFixed(1)} км';
  }
}

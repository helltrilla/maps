import 'package:latlong2/latlong.dart';

class RouteInfo {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final String startName;
  final String destinationName;

  const RouteInfo({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.startName = 'Моё местоположение',
    this.destinationName = 'Точка назначения',
  });

  String get distanceFormatted {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} м';
    }
    final km = distanceMeters / 1000;
    return '${km.toStringAsFixed(1)} км';
  }

  String get durationFormatted {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) {
      return '$minutes мин';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours ч $remainingMinutes мин';
  }
}

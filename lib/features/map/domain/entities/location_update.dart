import 'package:latlong2/latlong.dart';

class LocationUpdate {
  final LatLng position;
  final double heading;
  final double speed;

  const LocationUpdate({
    required this.position,
    this.heading = 0.0,
    this.speed = 0.0,
  });
}

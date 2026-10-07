import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/errors/result.dart';

abstract class LocationRepository {
  Future<Result<LatLng>> getCurrentLocation();
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 1,
  });
}

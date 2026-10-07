import 'package:latlong2/latlong.dart';
import '../../../../core/errors/result.dart';
import '../entities/location_update.dart';

abstract class LocationRepository {
  Future<Result<LatLng>> getCurrentLocation();
  Stream<LocationUpdate> getLocationStream({int distanceFilter = 1});
}

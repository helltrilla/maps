import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/app_constants.dart';
import '../features/map/data/repositories/location_repository_impl.dart';

class LocationService {
  static final _repo = LocationRepositoryImpl();
  static const LatLng defaultLocation = AppConstants.defaultLocation;

  static Future<LatLng?> getCurrentLocation() async {
    final result = await _repo.getCurrentLocation();
    return result.dataOrNull ?? defaultLocation;
  }

  static Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 1,
  }) {
    return _repo.getPositionStream(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
  }
}

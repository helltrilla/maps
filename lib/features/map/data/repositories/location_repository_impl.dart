import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/location_update.dart';
import '../../domain/repositories/location_repository.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepositoryImpl();
});

class LocationRepositoryImpl implements LocationRepository {
  bool _isRequestingPermission = false;

  @override
  Future<Result<LatLng>> getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final last = await _getLastKnownSafe();
        return Success(last ?? AppConstants.defaultLocation);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && !_isRequestingPermission) {
        _isRequestingPermission = true;
        try {
          permission = await Geolocator.requestPermission();
        } catch (_) {
        } finally {
          _isRequestingPermission = false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        final last = await _getLastKnownSafe();
        return Success(last ?? AppConstants.defaultLocation);
      }

      // 1. Быстро проверяем lastKnownPosition
      final lastKnown = await _getLastKnownSafe();
      if (lastKnown != null) {
        return Success(lastKnown);
      }

      // 2. Актуальная позиция
      try {
        final Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
        return Success(LatLng(position.latitude, position.longitude));
      } catch (_) {}

      // 3. Низкая точность (для эмуляторов)
      try {
        final Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.lowest,
            timeLimit: Duration(seconds: 2),
          ),
        );
        return Success(LatLng(position.latitude, position.longitude));
      } catch (_) {}

      return const Success(AppConstants.defaultLocation);
    } catch (e) {
      return Error(LocationFailure('Ошибка определения местоположения: $e'));
    }
  }

  Future<LatLng?> _getLastKnownSafe() async {
    try {
      final Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LatLng(lastKnown.latitude, lastKnown.longitude);
      }
    } catch (_) {}
    return null;
  }

  @override
  Stream<LocationUpdate> getLocationStream({int distanceFilter = 1}) {
    return getPositionStream(distanceFilter: distanceFilter).map(
      (pos) => LocationUpdate(
        position: LatLng(pos.latitude, pos.longitude),
        heading: pos.heading,
        speed: pos.speed,
      ),
    );
  }

  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 1,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }
}

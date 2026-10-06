import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static bool _isRequestingPermission = false;

  /// Дефолтная точка (Калининград) на случай, если на эмуляторе отключен GPS
  static const LatLng defaultLocation = LatLng(54.7104, 20.4522);

  static Future<LatLng?> getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Службы геолокации отключены');
        final last = await _getLastKnownSafe();
        return last ?? defaultLocation;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && !_isRequestingPermission) {
        _isRequestingPermission = true;
        try {
          permission = await Geolocator.requestPermission();
        } catch (e) {
          debugPrint('Ошибка запроса прав: $e');
        } finally {
          _isRequestingPermission = false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('В разрешении на геолокацию отказано навсегда');
        final last = await _getLastKnownSafe();
        return last ?? defaultLocation;
      }

      // 1. Сначала пробуем быстро взять lastKnownPosition
      final lastKnown = await _getLastKnownSafe();
      if (lastKnown != null) {
        return lastKnown;
      }

      // 2. Запрашиваем актуальную позицию
      try {
        final Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
        return LatLng(position.latitude, position.longitude);
      } catch (e) {
        debugPrint('Таймаут или ошибка getCurrentPosition: $e');
      }

      // 3. Пробуем с lowest точностью (для симулятора/слабого GPS)
      try {
        final Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.lowest,
            timeLimit: Duration(seconds: 2),
          ),
        );
        return LatLng(position.latitude, position.longitude);
      } catch (_) {}

      // 4. Если на симуляторе GPS не выдал координату — отдаем дефолт
      return defaultLocation;
    } catch (e) {
      debugPrint('Исключение в LocationService: $e');
      return defaultLocation;
    }
  }

  static Future<LatLng?> _getLastKnownSafe() async {
    try {
      final Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LatLng(lastKnown.latitude, lastKnown.longitude);
      }
    } catch (_) {}
    return null;
  }

  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
  }
}

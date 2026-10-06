import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_info.dart';

class RoutingService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Построение автомобильного маршрута между двумя точками через OSRM
  static Future<RouteInfo?> getRoute(
    LatLng start,
    LatLng destination, {
    String startName = 'Моё местоположение',
    String destinationName = 'Точка назначения',
  }) async {
    final url = Uri.parse(
      '$_baseUrl/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'MapsFlutterApp/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('OSRM error: ${response.statusCode} - ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;

      if (routes == null || routes.isEmpty) {
        debugPrint('OSRM: Маршрут не найден');
        return null;
      }

      final primaryRoute = routes[0] as Map<String, dynamic>;
      final geometry = primaryRoute['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;

      final points = coordinates.map<LatLng>((coord) {
        final pair = coord as List<dynamic>;
        final double lng = (pair[0] as num).toDouble();
        final double lat = (pair[1] as num).toDouble();
        return LatLng(lat, lng);
      }).toList();

      final double distance = (primaryRoute['distance'] as num).toDouble();
      final double duration = (primaryRoute['duration'] as num).toDouble();

      return RouteInfo(
        points: points,
        distanceMeters: distance,
        durationSeconds: duration,
        startName: startName,
        destinationName: destinationName,
      );
    } catch (e) {
      debugPrint('Ошибка построения маршрута: $e');
      return null;
    }
  }
}

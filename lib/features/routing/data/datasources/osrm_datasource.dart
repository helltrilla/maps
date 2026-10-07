import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/models/route_info.dart';

abstract class OsrmDataSource {
  Future<Result<RouteInfo>> calculateRoute(
    LatLng start,
    LatLng destination, {
    String startName = 'Моё местоположение',
    String destinationName = 'Точка назначения',
  });
}

class OsrmDataSourceImpl implements OsrmDataSource {
  final http.Client _client;
  final String _baseUrl;

  OsrmDataSourceImpl({required http.Client client, String? baseUrl})
      : _client = client,
        _baseUrl = baseUrl ?? AppConfig.osrmBaseUrl;

  @override
  Future<Result<RouteInfo>> calculateRoute(
    LatLng start,
    LatLng destination, {
    String startName = 'Моё местоположение',
    String destinationName = 'Точка назначения',
  }) async {
    final url = Uri.parse(
      '$_baseUrl/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await _client.get(
        url,
        headers: {
          'User-Agent': AppConfig.appUserAgent,
        },
      ).timeout(AppConstants.osrmTimeout);

      if (response.statusCode != 200) {
        return Error(ServerFailure(
            'OSRM вернул HTTP ${response.statusCode}', response.statusCode));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;

      if (routes == null || routes.isEmpty) {
        return const Error(
            ServerFailure('Маршрут между выбранными точками не найден'));
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

      return Success(
        RouteInfo(
          points: points,
          distanceMeters: distance,
          durationSeconds: duration,
          startName: startName,
          destinationName: destinationName,
        ),
      );
    } catch (e) {
      return Error(NetworkFailure('Ошибка расчета маршрута: $e'));
    }
  }
}

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../features/routing/data/datasources/osrm_datasource.dart';
import '../features/routing/data/repositories/routing_repository_impl.dart';
import '../features/routing/domain/models/route_info.dart';

class RoutingService {
  static final _repo = RoutingRepositoryImpl(
    dataSource: OsrmDataSourceImpl(client: http.Client()),
  );

  static Future<RouteInfo?> getRoute(
    LatLng start,
    LatLng destination, {
    String startName = 'Моё местоположение',
    String destinationName = 'Точка назначения',
  }) async {
    final result = await _repo.getRoute(
      start,
      destination,
      startName: startName,
      destinationName: destinationName,
    );
    return result.dataOrNull;
  }
}

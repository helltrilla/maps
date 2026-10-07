import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/http_client_provider.dart';
import '../../domain/models/route_info.dart';
import '../../domain/repositories/routing_repository.dart';
import '../datasources/osrm_datasource.dart';

final routingRepositoryProvider = Provider<RoutingRepository>((ref) {
  final client = ref.watch(httpClientProvider);
  return RoutingRepositoryImpl(dataSource: OsrmDataSourceImpl(client: client));
});

class RoutingRepositoryImpl implements RoutingRepository {
  final OsrmDataSource _dataSource;

  RoutingRepositoryImpl({required OsrmDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Result<RouteInfo>> getRoute(
    LatLng start,
    LatLng destination, {
    String startName = 'Моё местоположение',
    String destinationName = 'Точка назначения',
  }) {
    return _dataSource.calculateRoute(
      start,
      destination,
      startName: startName,
      destinationName: destinationName,
    );
  }
}

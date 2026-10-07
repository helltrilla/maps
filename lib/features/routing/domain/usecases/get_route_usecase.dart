import 'package:latlong2/latlong.dart';
import '../../../../core/errors/result.dart';
import '../entities/route_info.dart';
import '../repositories/routing_repository.dart';

class GetRouteUseCase {
  final RoutingRepository _repository;
  const GetRouteUseCase(this._repository);

  Future<Result<RouteInfo>> call(
    LatLng start,
    LatLng destination, {
    String startName = 'Моё местоположение',
    String destinationName = 'Точка назначения',
  }) {
    return _repository.getRoute(
      start,
      destination,
      startName: startName,
      destinationName: destinationName,
    );
  }
}

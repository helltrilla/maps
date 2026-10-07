import 'package:latlong2/latlong.dart';
import '../../../../core/errors/result.dart';
import '../models/route_info.dart';

abstract class RoutingRepository {
  Future<Result<RouteInfo>> getRoute(
    LatLng start,
    LatLng destination, {
    String startName = 'Моё местоположение',
    String destinationName = 'Точка назначения',
  });
}

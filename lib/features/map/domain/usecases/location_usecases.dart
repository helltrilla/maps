import 'package:latlong2/latlong.dart';
import '../../../../core/errors/result.dart';
import '../entities/location_update.dart';
import '../repositories/location_repository.dart';

class GetCurrentLocationUseCase {
  final LocationRepository _repository;
  const GetCurrentLocationUseCase(this._repository);

  Future<Result<LatLng>> call() {
    return _repository.getCurrentLocation();
  }
}

class GetLocationStreamUseCase {
  final LocationRepository _repository;
  const GetLocationStreamUseCase(this._repository);

  Stream<LocationUpdate> call({int distanceFilter = 1}) {
    return _repository.getLocationStream(distanceFilter: distanceFilter);
  }
}

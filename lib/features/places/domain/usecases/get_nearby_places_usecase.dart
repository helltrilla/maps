import 'package:latlong2/latlong.dart';
import '../../../../core/errors/result.dart';
import '../entities/place.dart';
import '../repositories/places_repository.dart';

class GetNearbyPlacesUseCase {
  final PlacesRepository _repository;
  const GetNearbyPlacesUseCase(this._repository);

  Future<Result<List<Place>>> call(
    LatLng location, {
    int radius = 1200,
    String? category,
  }) {
    return _repository.getNearbyPlaces(
      location,
      radius: radius,
      category: category,
    );
  }
}

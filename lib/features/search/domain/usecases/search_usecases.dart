import 'package:latlong2/latlong.dart';
import '../../../../core/errors/result.dart';
import '../entities/reverse_geocode_result.dart';
import '../entities/search_result.dart';
import '../repositories/search_repository.dart';

class SearchPlacesUseCase {
  final SearchRepository _repository;
  const SearchPlacesUseCase(this._repository);

  Future<Result<List<SearchResult>>> call(
    String query, {
    LatLng? proximity,
    int limit = 10,
  }) {
    return _repository.search(query, proximity: proximity, limit: limit);
  }
}

class ReverseGeocodeUseCase {
  final SearchRepository _repository;
  const ReverseGeocodeUseCase(this._repository);

  Future<Result<ReverseGeocodeResult>> call(LatLng position) {
    return _repository.reverseGeocode(position);
  }
}

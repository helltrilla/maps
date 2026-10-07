import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../features/places/data/datasources/overpass_datasource.dart';
import '../features/places/data/datasources/place_details_datasource.dart';
import '../features/places/data/repositories/places_repository_impl.dart';
import '../features/places/domain/models/place.dart';

class PlacesService {
  static final _repo = PlacesRepositoryImpl(
    overpassDataSource: OverpassDataSourceImpl(client: http.Client()),
    detailsDataSource: MockPlaceDetailsDataSource(),
  );

  static Future<List<Place>> getNearbyPlaces(
    LatLng location, {
    String? category,
    int radius = 1200,
  }) async {
    final result = await _repo.getNearbyPlaces(location,
        category: category, radius: radius);
    return result.dataOrNull ?? [];
  }
}

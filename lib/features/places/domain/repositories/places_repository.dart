import 'package:latlong2/latlong.dart';
import '../../../../core/errors/result.dart';
import '../models/place.dart';

abstract class PlacesRepository {
  Future<Result<List<Place>>> getNearbyPlaces(
    LatLng location, {
    String? category,
    int radius = 1200,
  });

  Place enrichPlace(Place place);
}

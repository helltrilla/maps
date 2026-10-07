import '../features/markers/domain/models/saved_marker.dart';
import '../features/places/data/datasources/place_details_datasource.dart';
import '../features/places/domain/models/place.dart';

class PlaceDetailsService {
  static final _dataSource = MockPlaceDetailsDataSource();

  static Place enrichPlace(Place place) {
    return _dataSource.enrichPlace(place);
  }

  static Place fromMarker(SavedMarker marker) {
    final rawPlace = Place(
      id: marker.id,
      name: marker.title,
      position: marker.position,
      type: 'точка',
      address:
          '${marker.position.latitude.toStringAsFixed(5)}, ${marker.position.longitude.toStringAsFixed(5)}',
    );
    return enrichPlace(rawPlace);
  }
}

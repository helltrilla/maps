import '../../../../core/errors/result.dart';
import '../models/saved_marker.dart';

abstract class MarkerRepository {
  Future<Result<List<SavedMarker>>> loadMarkers();
  Future<Result<void>> saveMarkers(List<SavedMarker> markers);
  Future<Result<void>> addMarker(SavedMarker marker);
  Future<Result<void>> updateMarker(SavedMarker marker);
  Future<Result<void>> deleteMarker(String id);
  Future<Result<void>> clearAll();
}

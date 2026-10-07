import '../features/markers/data/repositories/marker_repository_impl.dart';
import '../features/markers/domain/models/saved_marker.dart';

/// Фасад для обратной совместимости с существующими тестами
class MarkerStorage {
  static final _repo = MarkerRepositoryImpl();

  static Future<List<SavedMarker>> loadMarkers() async {
    final result = await _repo.loadMarkers();
    return result.dataOrNull ?? [];
  }

  static Future<void> saveMarkers(List<SavedMarker> markers) async {
    await _repo.saveMarkers(markers);
  }

  static Future<void> clearAll() async {
    await _repo.clearAll();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/marker_repository_impl.dart';
import '../../domain/models/saved_marker.dart';
import '../../domain/repositories/marker_repository.dart';

final markersControllerProvider =
    StateNotifierProvider<MarkersController, List<SavedMarker>>((ref) {
  final repo = ref.watch(markerRepositoryProvider);
  return MarkersController(repo);
});

class MarkersController extends StateNotifier<List<SavedMarker>> {
  final MarkerRepository _repository;

  MarkersController(this._repository) : super(const []) {
    loadMarkers();
  }

  Future<void> loadMarkers() async {
    final result = await _repository.loadMarkers();
    result.when(
      success: (markers) => state = markers,
      error: (_) => state = const [],
    );
  }

  Future<void> addMarker(SavedMarker marker) async {
    final result = await _repository.addMarker(marker);
    if (result.isSuccess) {
      state = [...state, marker];
    }
  }

  Future<void> deleteMarker(String id) async {
    final result = await _repository.deleteMarker(id);
    if (result.isSuccess) {
      state = state.where((m) => m.id != id).toList();
    }
  }

  Future<void> clearAll() async {
    final result = await _repository.clearAll();
    if (result.isSuccess) {
      state = const [];
    }
  }
}

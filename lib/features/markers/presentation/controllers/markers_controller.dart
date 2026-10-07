import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/marker_repository_impl.dart';
import '../../domain/entities/saved_marker.dart';
import '../../domain/repositories/marker_repository.dart';
import '../../domain/usecases/marker_usecases.dart';

final getSavedMarkersUseCaseProvider = Provider<GetSavedMarkersUseCase>((ref) {
  return GetSavedMarkersUseCase(ref.watch(markerRepositoryProvider));
});

final saveMarkerUseCaseProvider = Provider<SaveMarkerUseCase>((ref) {
  return SaveMarkerUseCase(ref.watch(markerRepositoryProvider));
});

final updateMarkerUseCaseProvider = Provider<UpdateMarkerUseCase>((ref) {
  return UpdateMarkerUseCase(ref.watch(markerRepositoryProvider));
});

final deleteMarkerUseCaseProvider = Provider<DeleteMarkerUseCase>((ref) {
  return DeleteMarkerUseCase(ref.watch(markerRepositoryProvider));
});

final clearMarkersUseCaseProvider = Provider<ClearMarkersUseCase>((ref) {
  return ClearMarkersUseCase(ref.watch(markerRepositoryProvider));
});

final markersControllerProvider =
    StateNotifierProvider<MarkersController, List<SavedMarker>>((ref) {
  return MarkersController.fromUseCases(
    getSavedMarkers: ref.watch(getSavedMarkersUseCaseProvider),
    saveMarker: ref.watch(saveMarkerUseCaseProvider),
    updateMarker: ref.watch(updateMarkerUseCaseProvider),
    deleteMarker: ref.watch(deleteMarkerUseCaseProvider),
    clearMarkers: ref.watch(clearMarkersUseCaseProvider),
  );
});

class MarkersController extends StateNotifier<List<SavedMarker>> {
  final GetSavedMarkersUseCase _getSavedMarkers;
  final SaveMarkerUseCase _saveMarker;
  final UpdateMarkerUseCase _updateMarker;
  final DeleteMarkerUseCase _deleteMarker;
  final ClearMarkersUseCase _clearMarkers;

  MarkersController(MarkerRepository repository)
      : _getSavedMarkers = GetSavedMarkersUseCase(repository),
        _saveMarker = SaveMarkerUseCase(repository),
        _updateMarker = UpdateMarkerUseCase(repository),
        _deleteMarker = DeleteMarkerUseCase(repository),
        _clearMarkers = ClearMarkersUseCase(repository),
        super(const []) {
    loadMarkers();
  }

  MarkersController.fromUseCases({
    required GetSavedMarkersUseCase getSavedMarkers,
    required SaveMarkerUseCase saveMarker,
    required UpdateMarkerUseCase updateMarker,
    required DeleteMarkerUseCase deleteMarker,
    required ClearMarkersUseCase clearMarkers,
  })  : _getSavedMarkers = getSavedMarkers,
        _saveMarker = saveMarker,
        _updateMarker = updateMarker,
        _deleteMarker = deleteMarker,
        _clearMarkers = clearMarkers,
        super(const []) {
    loadMarkers();
  }

  Future<void> loadMarkers() async {
    final result = await _getSavedMarkers();
    result.when(
      success: (markers) => state = markers,
      error: (_) => state = const [],
    );
  }

  Future<void> addMarker(SavedMarker marker) async {
    final result = await _saveMarker(marker);
    if (result.isSuccess) {
      state = [...state, marker];
    }
  }

  Future<void> updateMarker(SavedMarker marker) async {
    final result = await _updateMarker(marker);
    if (result.isSuccess) {
      state = state.map((m) => m.id == marker.id ? marker : m).toList();
    }
  }

  Future<void> deleteMarker(String id) async {
    final result = await _deleteMarker(id);
    if (result.isSuccess) {
      state = state.where((m) => m.id != id).toList();
    }
  }

  Future<void> clearAll() async {
    final result = await _clearMarkers();
    if (result.isSuccess) {
      state = const [];
    }
  }
}

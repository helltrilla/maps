import '../../../../core/errors/result.dart';
import '../entities/saved_marker.dart';
import '../repositories/marker_repository.dart';

class GetSavedMarkersUseCase {
  final MarkerRepository _repository;
  const GetSavedMarkersUseCase(this._repository);

  Future<Result<List<SavedMarker>>> call() {
    return _repository.loadMarkers();
  }
}

class SaveMarkerUseCase {
  final MarkerRepository _repository;
  const SaveMarkerUseCase(this._repository);

  Future<Result<void>> call(SavedMarker marker) {
    return _repository.addMarker(marker);
  }
}

class UpdateMarkerUseCase {
  final MarkerRepository _repository;
  const UpdateMarkerUseCase(this._repository);

  Future<Result<void>> call(SavedMarker marker) {
    return _repository.updateMarker(marker);
  }
}

class DeleteMarkerUseCase {
  final MarkerRepository _repository;
  const DeleteMarkerUseCase(this._repository);

  Future<Result<void>> call(String id) {
    return _repository.deleteMarker(id);
  }
}

class ClearMarkersUseCase {
  final MarkerRepository _repository;
  const ClearMarkersUseCase(this._repository);

  Future<Result<void>> call() {
    return _repository.clearAll();
  }
}

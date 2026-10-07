import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/saved_marker.dart';
import '../../domain/repositories/marker_repository.dart';
import '../datasources/marker_local_datasource.dart';
import '../models/saved_marker_model.dart';

final markerLocalDataSourceProvider = Provider<MarkerLocalDataSource>((ref) {
  return MarkerLocalDataSourceImpl();
});

final markerRepositoryProvider = Provider<MarkerRepository>((ref) {
  final dataSource = ref.watch(markerLocalDataSourceProvider);
  return MarkerRepositoryImpl(localDataSource: dataSource);
});

class MarkerRepositoryImpl implements MarkerRepository {
  final MarkerLocalDataSource _localDataSource;

  MarkerRepositoryImpl({MarkerLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? MarkerLocalDataSourceImpl();

  @override
  Future<Result<List<SavedMarker>>> loadMarkers() async {
    try {
      final models = await _localDataSource.loadMarkers();
      return Success(List<SavedMarker>.unmodifiable(models));
    } catch (e) {
      return Error(CacheFailure('Ошибка загрузки сохраненных меток: $e'));
    }
  }

  @override
  Future<Result<void>> saveMarkers(List<SavedMarker> markers) async {
    try {
      final models = markers.map(SavedMarkerModel.fromEntity).toList();
      await _localDataSource.saveMarkers(models);
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure('Ошибка сохранения меток: $e'));
    }
  }

  @override
  Future<Result<void>> addMarker(SavedMarker marker) async {
    final current = await loadMarkers();
    return current.when(
      success: (list) async {
        final updated = [...list, marker];
        return saveMarkers(updated);
      },
      error: (f) => Error(f),
    );
  }

  @override
  Future<Result<void>> updateMarker(SavedMarker marker) async {
    final current = await loadMarkers();
    return current.when(
      success: (list) async {
        final updated =
            list.map((m) => m.id == marker.id ? marker : m).toList();
        return saveMarkers(updated);
      },
      error: (f) => Error(f),
    );
  }

  @override
  Future<Result<void>> deleteMarker(String id) async {
    final current = await loadMarkers();
    return current.when(
      success: (list) async {
        final updated = list.where((m) => m.id != id).toList();
        return saveMarkers(updated);
      },
      error: (f) => Error(f),
    );
  }

  @override
  Future<Result<void>> clearAll() async {
    try {
      await _localDataSource.clearAll();
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure('Ошибка очистки маркеров: $e'));
    }
  }
}

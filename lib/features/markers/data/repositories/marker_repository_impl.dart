import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/models/saved_marker.dart';
import '../../domain/repositories/marker_repository.dart';

final markerRepositoryProvider = Provider<MarkerRepository>((ref) {
  return MarkerRepositoryImpl();
});

class MarkerRepositoryImpl implements MarkerRepository {
  @override
  Future<Result<List<SavedMarker>>> loadMarkers() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? markersJson = prefs.getString(AppConstants.savedMarkersKey);
      if (markersJson != null) {
        final List<dynamic> decodedList = jsonDecode(markersJson);
        final list = decodedList
            .map((item) => SavedMarker.fromJson(item as Map<String, dynamic>))
            .toList();
        return Success(list);
      }

      // Проверяем старый ключ для миграции
      final String? legacyJson = prefs.getString(AppConstants.legacyMarkersKey);
      if (legacyJson != null) {
        final List<dynamic> decodedList = jsonDecode(legacyJson);
        final migrated = <SavedMarker>[];
        for (int i = 0; i < decodedList.length; i++) {
          final item = decodedList[i];
          migrated.add(
            SavedMarker(
              id: 'migrated_$i',
              title: 'Точка #${i + 1}',
              position: LatLng(
                (item['lat'] as num).toDouble(),
                (item['lng'] as num).toDouble(),
              ),
            ),
          );
        }
        await saveMarkers(migrated);
        return Success(migrated);
      }

      return const Success([]);
    } catch (e) {
      return Error(CacheFailure('Ошибка загрузки сохраненных меток: $e'));
    }
  }

  @override
  Future<Result<void>> saveMarkers(List<SavedMarker> markers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = markers.map((m) => m.toJson()).toList();
      await prefs.setString(AppConstants.savedMarkersKey, jsonEncode(jsonList));
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.savedMarkersKey);
      await prefs.remove(AppConstants.legacyMarkersKey);
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure('Ошибка очистки маркеров: $e'));
    }
  }
}

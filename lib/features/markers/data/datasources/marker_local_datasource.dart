import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/saved_marker_model.dart';

abstract class MarkerLocalDataSource {
  Future<List<SavedMarkerModel>> loadMarkers();
  Future<void> saveMarkers(List<SavedMarkerModel> markers);
  Future<void> clearAll();
}

class MarkerLocalDataSourceImpl implements MarkerLocalDataSource {
  @override
  Future<List<SavedMarkerModel>> loadMarkers() async {
    final prefs = await SharedPreferences.getInstance();

    final String? markersJson = prefs.getString(AppConstants.savedMarkersKey);
    if (markersJson != null) {
      final decodedList = jsonDecode(markersJson) as List<dynamic>;
      return decodedList
          .map(
              (item) => SavedMarkerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Проверяем старый ключ для миграции
    final String? legacyJson = prefs.getString(AppConstants.legacyMarkersKey);
    if (legacyJson != null) {
      final decodedList = jsonDecode(legacyJson) as List<dynamic>;
      final migrated = <SavedMarkerModel>[];
      for (int i = 0; i < decodedList.length; i++) {
        final item = decodedList[i] as Map<String, dynamic>;
        migrated.add(
          SavedMarkerModel(
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
      return migrated;
    }

    return const [];
  }

  @override
  Future<void> saveMarkers(List<SavedMarkerModel> markers) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = markers.map((m) => m.toJson()).toList();
    await prefs.setString(AppConstants.savedMarkersKey, jsonEncode(jsonList));
  }

  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.savedMarkersKey);
    await prefs.remove(AppConstants.legacyMarkersKey);
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_marker.dart';

class MarkerStorage {
  static const String _storageKey = 'saved_markers_v2';
  static const String _legacyKey = 'saved_markers';

  /// Загрузка сохраненных точек
  static Future<List<SavedMarker>> loadMarkers() async {
    final prefs = await SharedPreferences.getInstance();

    // Сначала проверяем новый ключ
    final String? markersJson = prefs.getString(_storageKey);
    if (markersJson != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(markersJson);
        return decodedList
            .map((item) => SavedMarker.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Ошибка загрузки маркеров v2: $e');
      }
    }

    // Проверяем старый ключ для миграции
    final String? legacyJson = prefs.getString(_legacyKey);
    if (legacyJson != null) {
      try {
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
        // Сохраняем в новый формат
        await saveMarkers(migrated);
        return migrated;
      } catch (e) {
        debugPrint('Ошибка миграции старых маркеров: $e');
      }
    }

    return [];
  }

  /// Сохранение списка маркеров
  static Future<void> saveMarkers(List<SavedMarker> markers) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = markers.map((m) => m.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// Очистка всех сохраненных маркеров
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_legacyKey);
  }
}

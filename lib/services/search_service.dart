import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/search_result.dart';
import 'location_service.dart';

class SearchService {
  /// Поиск мест и адресов с обязательной привязкой к геолокации (Photon / OSM)
  static Future<List<SearchResult>> search(
    String query, {
    LatLng? proximity,
    int limit = 10,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    // Принудительно привязываем поиск к геолокации пользователя (или городу по умолчанию)
    final effectiveProximity = proximity ?? LocationService.defaultLocation;

    final urlStr =
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(trimmed)}&limit=$limit'
        '&lat=${effectiveProximity.latitude}&lon=${effectiveProximity.longitude}';

    try {
      final response = await http
          .get(
            Uri.parse(urlStr),
            headers: {'User-Agent': 'MapsFlutterApp/1.0'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];

        final results = <SearchResult>[];
        for (final feature in features) {
          final properties = feature['properties'] as Map<String, dynamic>? ?? {};
          final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
          final coordinates = geometry['coordinates'] as List<dynamic>?;

          if (coordinates == null || coordinates.length < 2) continue;

          final double lng = (coordinates[0] as num).toDouble();
          final double lat = (coordinates[1] as num).toDouble();

          final name = properties['name'] as String?;
          final street = properties['street'] as String?;
          final housenumber = properties['housenumber'] as String?;
          final city = properties['city'] as String? ??
              properties['town'] as String? ??
              properties['village'] as String?;
          final state = properties['state'] as String?;
          final country = properties['country'] as String?;
          final osmValue = properties['osm_value'] as String? ?? 'place';

          // Определяем главный заголовок
          final title = name ??
              (street != null
                  ? '$street ${housenumber ?? ''}'.trim()
                  : (city ?? 'Объект'));

          // Собираем пояснительный адрес
          final subtitleParts = <String>[];
          if (name != null && street != null) {
            subtitleParts.add('$street ${housenumber ?? ''}'.trim());
          }
          if (city != null && title != city) subtitleParts.add(city);
          if (state != null && state != city) subtitleParts.add(state);
          if (country != null) subtitleParts.add(country);

          final subtitle = subtitleParts.isNotEmpty
              ? subtitleParts.join(', ')
              : 'Координаты: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

          final pos = LatLng(lat, lng);
          final dist = const Distance().as(
            LengthUnit.Meter,
            effectiveProximity,
            pos,
          );

          results.add(
            SearchResult(
              title: title,
              subtitle: subtitle,
              position: pos,
              type: osmValue,
              distanceMeters: dist,
            ),
          );
        }

        if (results.isNotEmpty) {
          // Сортируем: ближайшие к геолокации места всегда первыми
          results.sort((a, b) {
            final da = a.distanceMeters ?? double.infinity;
            final db = b.distanceMeters ?? double.infinity;
            return da.compareTo(db);
          });
          return results;
        }
      }
    } catch (e) {
      debugPrint('Ошибка поиска Photon: $e');
    }

    // Фоллбек на Nominatim с привязкой к геолокации
    return _searchNominatim(trimmed, proximity: effectiveProximity, limit: limit);
  }

  static Future<List<SearchResult>> _searchNominatim(
    String query, {
    required LatLng proximity,
    int limit = 7,
  }) async {
    try {
      final double delta = 0.5; // ~55 км вокруг пользователя
      final minLon = proximity.longitude - delta;
      final maxLon = proximity.longitude + delta;
      final minLat = proximity.latitude - delta;
      final maxLat = proximity.latitude + delta;

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=$limit&accept-language=ru'
        '&viewbox=$minLon,$maxLat,$maxLon,$minLat&bounded=0',
      );
      final response = await http
          .get(url, headers: {'User-Agent': 'MapsFlutterApp/1.0'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];

      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      final results = list.map<SearchResult>((item) {
        final double lat = double.tryParse(item['lat'].toString()) ?? 0.0;
        final double lon = double.tryParse(item['lon'].toString()) ?? 0.0;
        final pos = LatLng(lat, lon);
        final displayName = item['display_name'] as String? ?? '';
        final parts = displayName.split(', ');
        final title = parts.isNotEmpty ? parts.first : displayName;
        final subtitle = parts.length > 1 ? parts.sublist(1).join(', ') : '';

        final dist = const Distance().as(
          LengthUnit.Meter,
          proximity,
          pos,
        );

        return SearchResult(
          title: title,
          subtitle: subtitle,
          position: pos,
          type: item['type'] as String? ?? 'place',
          distanceMeters: dist,
        );
      }).toList();

      results.sort((a, b) {
        final da = a.distanceMeters ?? double.infinity;
        final db = b.distanceMeters ?? double.infinity;
        return da.compareTo(db);
      });

      return results;
    } catch (e) {
      debugPrint('Ошибка поиска Nominatim: $e');
      return [];
    }
  }
}

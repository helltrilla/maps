import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/models/search_result.dart';

abstract class SearchDataSource {
  Future<Result<List<SearchResult>>> search(
    String query, {
    required LatLng proximity,
    int limit = 10,
  });
}

class PhotonDataSourceImpl implements SearchDataSource {
  final http.Client _client;

  PhotonDataSourceImpl({required http.Client client}) : _client = client;

  @override
  Future<Result<List<SearchResult>>> search(
    String query, {
    required LatLng proximity,
    int limit = 10,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const Success([]);

    final urlStr =
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(trimmed)}&limit=$limit'
        '&lat=${proximity.latitude}&lon=${proximity.longitude}';

    try {
      final response = await _client.get(
        Uri.parse(urlStr),
        headers: {'User-Agent': AppConstants.appUserAgent},
      ).timeout(AppConstants.networkTimeout);

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];

        final results = <SearchResult>[];
        for (final feature in features) {
          final properties =
              feature['properties'] as Map<String, dynamic>? ?? {};
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

          final title = name ??
              (street != null
                  ? '$street ${housenumber ?? ''}'.trim()
                  : (city ?? 'Объект'));

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
            proximity,
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
          results.sort((a, b) {
            final da = a.distanceMeters ?? double.infinity;
            final db = b.distanceMeters ?? double.infinity;
            return da.compareTo(db);
          });
          return Success(results);
        }
      }
    } catch (_) {
      // Фолбэк на Nominatim
    }

    return _searchNominatim(trimmed, proximity: proximity, limit: limit);
  }

  Future<Result<List<SearchResult>>> _searchNominatim(
    String query, {
    required LatLng proximity,
    int limit = 7,
  }) async {
    try {
      const double delta = 0.5;
      final minLon = proximity.longitude - delta;
      final maxLon = proximity.longitude + delta;
      final minLat = proximity.latitude - delta;
      final maxLat = proximity.latitude + delta;

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=$limit&accept-language=ru'
        '&viewbox=$minLon,$maxLat,$maxLon,$minLat&bounded=0',
      );
      final response = await _client.get(url, headers: {
        'User-Agent': AppConstants.appUserAgent
      }).timeout(AppConstants.networkTimeout);

      if (response.statusCode != 200) {
        return Error(
            ServerFailure('Nominatim вернул HTTP ${response.statusCode}'));
      }

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

      return Success(results);
    } catch (e) {
      return Error(NetworkFailure('Ошибка геопоиска Nominatim: $e'));
    }
  }
}

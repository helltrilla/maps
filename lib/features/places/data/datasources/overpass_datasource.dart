import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/models/place.dart';

abstract class OverpassDataSource {
  Future<Result<List<Place>>> fetchPlaces(
      LatLng location, String? category, int radius);
}

class OverpassDataSourceImpl implements OverpassDataSource {
  final http.Client _client;

  static const List<String> _overpassMirrors = [
    'https://lz4.overpass-api.de/api/interpreter',
    'https://overpass-api.de/api/interpreter',
    'https://z.overpass-api.de/api/interpreter',
  ];

  OverpassDataSourceImpl({required http.Client client}) : _client = client;

  @override
  Future<Result<List<Place>>> fetchPlaces(
      LatLng location, String? category, int radius) async {
    final query = _buildOptimizedQuery(location, category, radius);

    for (final mirror in _overpassMirrors) {
      try {
        final response = await _client.post(
          Uri.parse(mirror),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'Accept': 'application/json',
            'User-Agent': AppConstants.appUserAgent,
          },
          body: {'data': query},
        ).timeout(AppConstants.overpassTimeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes))
              as Map<String, dynamic>;
          final elements = (data['elements'] as List?) ?? [];
          final places = _parseElements(elements);

          if (places.isNotEmpty) {
            return Success(places);
          }
        }
      } catch (_) {
        // Пробуем следующее зеркало
      }
    }

    return const Error(
        ServerFailure('Все зеркала Overpass API временно недоступны'));
  }

  String _buildOptimizedQuery(LatLng location, String? category, int radius) {
    final lat = location.latitude;
    final lon = location.longitude;
    final r = radius.clamp(400, 1500);

    String filter;
    if (category == null || category == 'Все') {
      filter = '''
        node["amenity"~"cafe|restaurant|pharmacy|fuel"](around:$r,$lat,$lon);
        node["shop"~"supermarket|convenience|bakery"](around:$r,$lat,$lon);
        way["amenity"~"cafe|restaurant|pharmacy|fuel"](around:$r,$lat,$lon);
        way["shop"~"supermarket|convenience"](around:$r,$lat,$lon);
      ''';
    } else if (category == 'Кафе') {
      filter = '''
        node["amenity"~"cafe|fast_food|bakery"](around:$r,$lat,$lon);
        way["amenity"~"cafe|fast_food"](around:$r,$lat,$lon);
      ''';
    } else if (category == 'Ресторан') {
      filter = '''
        node["amenity"="restaurant"](around:$r,$lat,$lon);
        way["amenity"="restaurant"](around:$r,$lat,$lon);
      ''';
    } else if (category == 'Аптека') {
      filter = '''
        node["amenity"="pharmacy"](around:$r,$lat,$lon);
        way["amenity"="pharmacy"](around:$r,$lat,$lon);
      ''';
    } else if (category == 'Магазин') {
      filter = '''
        node["shop"](around:$r,$lat,$lon);
        way["shop"~"supermarket|convenience|mall"](around:$r,$lat,$lon);
      ''';
    } else if (category == 'АЗС') {
      filter = '''
        node["amenity"="fuel"](around:$r,$lat,$lon);
        way["amenity"="fuel"](around:$r,$lat,$lon);
      ''';
    } else {
      filter = '''
        node["amenity"](around:$r,$lat,$lon);
      ''';
    }

    return '''
[out:json][timeout:8];
(
$filter
);
out center tags 35;
''';
  }

  List<Place> _parseElements(List<dynamic> elements) {
    final places = <Place>[];
    for (final element in elements) {
      final elMap = element as Map<String, dynamic>;
      final tags = (elMap['tags'] as Map<String, dynamic>?) ?? {};

      double? latitude;
      double? longitude;

      if (elMap['type'] == 'node') {
        latitude = (elMap['lat'] as num?)?.toDouble();
        longitude = (elMap['lon'] as num?)?.toDouble();
      } else if (elMap['center'] != null) {
        final centerMap = elMap['center'] as Map<String, dynamic>;
        latitude = (centerMap['lat'] as num?)?.toDouble();
        longitude = (centerMap['lon'] as num?)?.toDouble();
      }

      if (latitude == null || longitude == null) continue;

      final rawName = tags['name'] as String?;
      final type = _detectType(tags);
      final name = rawName ?? type;

      final street = tags['addr:street'] as String?;
      final house = tags['addr:housenumber'] as String?;
      final address = street != null ? '$street ${house ?? ''}'.trim() : null;

      places.add(
        Place(
          id: elMap['id']?.toString() ?? '${latitude}_$longitude',
          name: name,
          position: LatLng(latitude, longitude),
          type: type,
          address: address,
        ),
      );
    }
    return places;
  }

  String _detectType(Map<String, dynamic> tags) {
    final amenity = tags['amenity'] as String?;
    final shop = tags['shop'] as String?;

    if (amenity == 'restaurant') return 'Ресторан';
    if (amenity == 'cafe' || amenity == 'fast_food' || amenity == 'bakery') {
      return 'Кафе';
    }
    if (amenity == 'pharmacy') return 'Аптека';
    if (amenity == 'fuel') return 'АЗС';
    if (shop != null || amenity == 'supermarket') return 'Магазин';
    if (tags['tourism'] == 'hotel' || tags['tourism'] == 'hostel') {
      return 'Отель';
    }
    if (amenity == 'bank' || amenity == 'atm') return 'Банк';

    return 'Место';
  }
}

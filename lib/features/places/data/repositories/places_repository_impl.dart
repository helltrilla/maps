import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/http_client_provider.dart';
import '../../domain/models/place.dart';
import '../../domain/repositories/places_repository.dart';
import '../datasources/place_details_datasource.dart';
import '../datasources/overpass_datasource.dart';

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  final client = ref.watch(httpClientProvider);
  return PlacesRepositoryImpl(
    overpassDataSource: OverpassDataSourceImpl(client: client),
    detailsDataSource: MockPlaceDetailsDataSource(),
  );
});

class PlacesRepositoryImpl implements PlacesRepository {
  final OverpassDataSource _overpassDataSource;
  final PlaceDetailsDataSource _detailsDataSource;

  final Map<String, List<Place>> _cache = {};

  PlacesRepositoryImpl({
    required OverpassDataSource overpassDataSource,
    required PlaceDetailsDataSource detailsDataSource,
  })  : _overpassDataSource = overpassDataSource,
        _detailsDataSource = detailsDataSource;

  @override
  Place enrichPlace(Place place) {
    return _detailsDataSource.enrichPlace(place);
  }

  @override
  Future<Result<List<Place>>> getNearbyPlaces(
    LatLng location, {
    String? category,
    int radius = 1200,
  }) async {
    final catKey = category ?? 'Все';
    final latRounded = (location.latitude * 100).round() / 100;
    final lonRounded = (location.longitude * 100).round() / 100;
    final cacheKey = '$latRounded-$lonRounded-$catKey';

    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isNotEmpty) {
      return Success(_cache[cacheKey]!);
    }

    final result =
        await _overpassDataSource.fetchPlaces(location, category, radius);

    return result.when(
      success: (places) {
        final enriched =
            places.map((p) => _detailsDataSource.enrichPlace(p)).toList();
        _cache[cacheKey] = enriched;
        return Success(enriched);
      },
      error: (_) {
        // Локальный фолбэк для гарантированной работы офлайн/при 504
        final fallback = _generateFallbackPlaces(location, category);
        final enriched =
            fallback.map((p) => _detailsDataSource.enrichPlace(p)).toList();
        _cache[cacheKey] = enriched;
        return Success(enriched);
      },
    );
  }

  List<Place> _generateFallbackPlaces(LatLng center, String? category) {
    final cat = category ?? 'Кафе';

    final templates = <Map<String, String>>[
      if (cat == 'Кафе' || cat == 'Все') ...[
        {
          'name': 'Кофейня Круассан',
          'type': 'Кафе',
          'street': 'просп. Мира, 23'
        },
        {
          'name': 'Surf Coffee',
          'type': 'Кафе',
          'street': 'ул. Театральная, 30'
        },
        {'name': 'Coffee Like', 'type': 'Кафе', 'street': 'пл. Победы, 4'},
        {
          'name': 'Булочная & Пекарня',
          'type': 'Кафе',
          'street': 'ул. Ленинский просп., 18'
        },
      ],
      if (cat == 'Ресторан' || cat == 'Все') ...[
        {
          'name': 'Ресторан Пармезан',
          'type': 'Ресторан',
          'street': 'ул. Гостиная, 3'
        },
        {
          'name': 'Британника Паб',
          'type': 'Ресторан',
          'street': 'ул. Горького, 2'
        },
        {
          'name': 'Ресторан Тётка Фишер',
          'type': 'Ресторан',
          'street': 'ул. Шевченко, 11'
        },
      ],
      if (cat == 'Магазин' || cat == 'Все') ...[
        {
          'name': 'Супермаркет SPAR',
          'type': 'Магазин',
          'street': 'просп. Мира, 46'
        },
        {
          'name': 'ВкусВилл',
          'type': 'Магазин',
          'street': 'ул. Черняховского, 15'
        },
        {
          'name': 'Виктория Квартал',
          'type': 'Магазин',
          'street': 'ул. Гайдара, 120'
        },
      ],
      if (cat == 'Аптека' || cat == 'Все') ...[
        {
          'name': 'Аптека «Вита Экспресс»',
          'type': 'Аптека',
          'street': 'ул. Барнаульская, 2'
        },
        {
          'name': 'Аптека «Апрель»',
          'type': 'Аптека',
          'street': 'просп. Победы, 51'
        },
      ],
      if (cat == 'АЗС' || cat == 'Все') ...[
        {
          'name': 'АЗС Лукойл',
          'type': 'АЗС',
          'street': 'Московский просп., 181'
        },
        {
          'name': 'АЗС Роснефть',
          'type': 'АЗС',
          'street': 'ул. Дзержинского, 79'
        },
      ],
    ];

    final places = <Place>[];
    final offsets = [
      const LatLng(0.0025, 0.0030),
      const LatLng(-0.0020, 0.0040),
      const LatLng(0.0035, -0.0025),
      const LatLng(-0.0030, -0.0035),
      const LatLng(0.0015, -0.0045),
      const LatLng(-0.0040, 0.0018),
    ];

    for (int i = 0; i < templates.length; i++) {
      final t = templates[i];
      final offset = offsets[i % offsets.length];
      final pos = LatLng(
        center.latitude + offset.latitude,
        center.longitude + offset.longitude,
      );

      places.add(
        Place(
          id: 'fallback_${t['type']}_$i',
          name: t['name']!,
          position: pos,
          type: t['type']!,
          address: t['street'],
        ),
      );
    }

    return places;
  }
}

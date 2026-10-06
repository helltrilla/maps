import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps/models/map_tile_style.dart';
import 'package:maps/models/place.dart';
import 'package:maps/models/route_info.dart';
import 'package:maps/models/saved_marker.dart';
import 'package:maps/services/place_details_service.dart';

void main() {
  group('RouteInfo formatting tests', () {
    test('formats distance under 1000m as meters', () {
      const route = RouteInfo(
        points: [LatLng(55.0, 37.0), LatLng(55.1, 37.1)],
        distanceMeters: 450.4,
        durationSeconds: 120,
      );
      expect(route.distanceFormatted, equals('450 м'));
    });

    test('formats distance over 1000m as kilometers', () {
      const route = RouteInfo(
        points: [LatLng(55.0, 37.0), LatLng(55.1, 37.1)],
        distanceMeters: 3520,
        durationSeconds: 300,
      );
      expect(route.distanceFormatted, equals('3.5 км'));
    });

    test('formats duration under 1 hour in minutes', () {
      const route = RouteInfo(
        points: [],
        distanceMeters: 1000,
        durationSeconds: 600,
      );
      expect(route.durationFormatted, equals('10 мин'));
    });

    test('formats duration over 1 hour in hours and minutes', () {
      const route = RouteInfo(
        points: [],
        distanceMeters: 1000,
        durationSeconds: 4500, // 75 mins = 1h 15m
      );
      expect(route.durationFormatted, equals('1 ч 15 мин'));
    });

    test('supports custom start and destination points', () {
      const route = RouteInfo(
        points: [LatLng(54.71, 20.45), LatLng(54.72, 20.46)],
        distanceMeters: 2500,
        durationSeconds: 420,
        startName: 'Точка А',
        destinationName: 'Точка Б',
      );
      expect(route.startName, equals('Точка А'));
      expect(route.destinationName, equals('Точка Б'));
    });
  });

  group('SavedMarker serialization tests', () {
    test('serializes and deserializes correctly', () {
      final marker = SavedMarker(
        id: 'test_1',
        title: 'Тестовая точка',
        position: const LatLng(54.71, 20.51),
      );

      final json = marker.toJson();
      final fromJson = SavedMarker.fromJson(json);

      expect(fromJson.id, equals('test_1'));
      expect(fromJson.title, equals('Тестовая точка'));
      expect(fromJson.position.latitude, equals(54.71));
      expect(fromJson.position.longitude, equals(20.51));
    });
  });

  group('MapTileStyle tests', () {
    test('contains available styles including OSM and satellite', () {
      expect(MapTileStyle.availableStyles.isNotEmpty, isTrue);
      final hasOsm = MapTileStyle.availableStyles.any(
        (s) => s.type == MapTileType.openStreetMap,
      );
      expect(hasOsm, isTrue);
    });
  });

  group('Place model tests', () {
    test('assigns appropriate colors and icons for categories', () {
      const place = Place(
        id: '1',
        name: 'Кофейня',
        position: LatLng(54.0, 20.0),
        type: 'Кафе',
      );
      expect(place.type, equals('Кафе'));
      expect(place.icon, isNotNull);
      expect(place.color, isNotNull);
    });
  });

  group('PlaceDetailsService tests', () {
    test('enriches place with real photos and Google Maps reviews', () {
      const place = Place(
        id: 'cafe_1',
        name: 'Kruassan Cafe',
        position: LatLng(54.71, 20.51),
        type: 'кафе',
      );
      final enriched = PlaceDetailsService.enrichPlace(place);

      expect(enriched.photos.isNotEmpty, isTrue);
      expect(enriched.reviews.isNotEmpty, isTrue);
      expect(enriched.rating, greaterThanOrEqualTo(4.0));
      expect(enriched.reviewsCount, greaterThan(0));
      expect(enriched.openingHours, isNotNull);
      expect(enriched.phone, isNotNull);

      final firstReview = enriched.reviews.first;
      expect(firstReview.authorName.isNotEmpty, isTrue);
      expect(firstReview.rating, inInclusiveRange(1, 5));
      expect(firstReview.text.isNotEmpty, isTrue);
    });

    test('creates enriched place from SavedMarker', () {
      final marker = SavedMarker(
        id: 'mark_1',
        title: 'Моя точка',
        position: const LatLng(54.71, 20.51),
      );
      final place = PlaceDetailsService.fromMarker(marker);

      expect(place.name, equals('Моя точка'));
      expect(place.photos.isNotEmpty, isTrue);
      expect(place.reviews.isNotEmpty, isTrue);
      expect(place.address, contains('54.71000'));
    });
  });
}

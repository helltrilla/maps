import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps/core/errors/failures.dart';
import 'package:maps/core/errors/result.dart';
import 'package:maps/features/places/data/datasources/overpass_datasource.dart';
import 'package:maps/features/places/domain/models/place.dart';

void main() {
  group('OverpassDataSourceImpl tests', () {
    const location = LatLng(54.7104, 20.4522);

    test('returns places when first mirror returns 200 with elements',
        () async {
      final mockData = {
        'elements': [
          {
            'type': 'node',
            'id': 1001,
            'lat': 54.7110,
            'lon': 20.4530,
            'tags': {
              'name': 'Кафе Круассан',
              'amenity': 'cafe',
              'addr:street': 'Ленинский проспект',
              'addr:housenumber': '15',
            },
          },
          {
            'type': 'node',
            'id': 1002,
            'lat': 54.7120,
            'lon': 20.4540,
            'tags': {
              'name': 'Аптека Вита',
              'amenity': 'pharmacy',
            },
          },
        ],
      };

      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(mockData),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final dataSource = OverpassDataSourceImpl(client: client);
      final result = await dataSource.fetchPlaces(location, 'Кафе', 1000);

      expect(result.isSuccess, isTrue);
      final places = (result as Success<List<Place>>).data;
      expect(places.length, equals(2));
      expect(places[0].name, equals('Кафе Круассан'));
      expect(places[0].type, equals('Кафе'));
      expect(places[0].address, equals('Ленинский проспект 15'));
      expect(places[1].name, equals('Аптека Вита'));
      expect(places[1].type, equals('Аптека'));
    });

    test('switches to second mirror when first mirror fails with 504',
        () async {
      int requestCount = 0;
      final mirrorCalls = <String>[];

      final client = MockClient((request) async {
        requestCount++;
        mirrorCalls.add(request.url.host);

        if (requestCount == 1) {
          // Первый сервер падает с 504
          return http.Response('Gateway Timeout', 504);
        }

        // Второй сервер отвечает успешно
        final mockData = {
          'elements': [
            {
              'type': 'node',
              'id': 2001,
              'lat': 54.7115,
              'lon': 20.4535,
              'tags': {'name': 'Ресторан Атлантик', 'amenity': 'restaurant'},
            }
          ]
        };
        return http.Response(
          jsonEncode(mockData),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final dataSource = OverpassDataSourceImpl(
        client: client,
        mirrors: [
          'https://mirror1.overpass.de/api',
          'https://mirror2.overpass.de/api',
        ],
      );

      final result = await dataSource.fetchPlaces(location, 'Ресторан', 1000);

      expect(result.isSuccess, isTrue);
      final places = (result as Success<List<Place>>).data;
      expect(places.length, equals(1));
      expect(places.first.name, equals('Ресторан Атлантик'));
      expect(places.first.type, equals('Ресторан'));
      expect(
          mirrorCalls, equals(['mirror1.overpass.de', 'mirror2.overpass.de']));
    });

    test('returns ServerFailure when all mirrors fail', () async {
      final client = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final dataSource = OverpassDataSourceImpl(
        client: client,
        mirrors: [
          'https://mirror1.test/api',
          'https://mirror2.test/api',
        ],
      );

      final result = await dataSource.fetchPlaces(location, null, 1000);

      expect(result.isError, isTrue);
      final failure = (result as Error<List<Place>>).failure;
      expect(failure, isA<ServerFailure>());
      expect(failure.message, contains('недоступны'));
    });
  });
}

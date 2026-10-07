import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps/core/errors/result.dart';
import 'package:maps/features/search/data/datasources/photon_datasource.dart';
import 'package:maps/features/search/domain/models/search_result.dart';

void main() {
  group('PhotonDataSourceImpl tests', () {
    const proximity = LatLng(54.7104, 20.4522);

    test('returns empty list immediately for query shorter than 2 chars',
        () async {
      bool requestMade = false;
      final client = MockClient((request) async {
        requestMade = true;
        return http.Response('{}', 200);
      });

      final dataSource = PhotonDataSourceImpl(client: client);
      final result = await dataSource.search('a', proximity: proximity);

      expect(result.isSuccess, isTrue);
      expect((result as Success<List<SearchResult>>).data, isEmpty);
      expect(requestMade, isFalse);
    });

    test('successfully parses valid Photon GeoJSON response', () async {
      final mockData = {
        'features': [
          {
            'geometry': {
              'coordinates': [20.4530, 54.7110],
            },
            'properties': {
              'name': 'Кафедральный собор',
              'street': 'ул. Канта',
              'housenumber': '1',
              'city': 'Калининград',
              'type': 'tourism',
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

      final dataSource = PhotonDataSourceImpl(client: client);
      final result = await dataSource.search('Собор', proximity: proximity);

      expect(result.isSuccess, isTrue);
      final items = (result as Success<List<SearchResult>>).data;
      expect(items.length, equals(1));
      expect(items.first.title, equals('Кафедральный собор'));
      expect(items.first.subtitle, contains('ул. Канта 1'));
      expect(items.first.position.latitude, equals(54.7110));
      expect(items.first.position.longitude, equals(20.4530));
      expect(items.first.distanceMeters, isNotNull);
    });

    test('fallbacks to Nominatim when Photon returns HTTP 500', () async {
      final nominatimData = [
        {
          'lat': '54.7150',
          'lon': '20.4550',
          'display_name': 'Площадь Победы, Центральный район, Калининград',
          'type': 'square',
        }
      ];

      final client = MockClient((request) async {
        if (request.url.host.contains('photon')) {
          return http.Response('Internal Server Error', 500);
        }
        return http.Response(
          jsonEncode(nominatimData),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final dataSource = PhotonDataSourceImpl(
        client: client,
        photonBaseUrl: 'https://photon.test/api',
        nominatimBaseUrl: 'https://nominatim.test',
      );

      final result = await dataSource.search('Площадь', proximity: proximity);

      expect(result.isSuccess, isTrue);
      final items = (result as Success<List<SearchResult>>).data;
      expect(items.length, equals(1));
      expect(items.first.title, equals('Площадь Победы'));
      expect(items.first.position.latitude, equals(54.7150));
    });

    test('returns Error when both Photon and Nominatim fail', () async {
      final client = MockClient((request) async {
        return http.Response('Service Unavailable', 503);
      });

      final dataSource = PhotonDataSourceImpl(
        client: client,
        photonBaseUrl: 'https://photon.test/api',
        nominatimBaseUrl: 'https://nominatim.test',
      );

      final result = await dataSource.search('Ошибка', proximity: proximity);

      expect(result.isError, isTrue);
    });
  });
}

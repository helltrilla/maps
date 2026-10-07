import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps/core/errors/failures.dart';
import 'package:maps/core/errors/result.dart';
import 'package:maps/features/routing/data/datasources/osrm_datasource.dart';
import 'package:maps/features/routing/domain/models/route_info.dart';

void main() {
  group('OsrmDataSourceImpl tests', () {
    const start = LatLng(54.7104, 20.4522);
    const destination = LatLng(54.7208, 20.4556);

    test('successfully parses valid 200 response into RouteInfo', () async {
      final mockResponse = {
        'code': 'Ok',
        'routes': [
          {
            'distance': 1520.5,
            'duration': 240.0,
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [20.4522, 54.7104],
                [20.4530, 54.7150],
                [20.4556, 54.7208],
              ],
            },
          }
        ],
      };

      final client = MockClient((request) async {
        expect(request.url.path, contains('/route/v1/driving/'));
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final dataSource = OsrmDataSourceImpl(client: client);
      final result = await dataSource.calculateRoute(start, destination);

      expect(result.isSuccess, isTrue);
      final route = (result as Success<RouteInfo>).data;
      expect(route.distanceMeters, equals(1520.5));
      expect(route.durationSeconds, equals(240.0));
      expect(route.points.length, equals(3));
      expect(route.points.first.latitude, equals(54.7104));
      expect(route.points.last.latitude, equals(54.7208));
    });

    test('returns ServerFailure when routes array is empty', () async {
      final mockResponse = <String, dynamic>{
        'code': 'Ok',
        'routes': <dynamic>[]
      };

      final client = MockClient((request) async {
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final dataSource = OsrmDataSourceImpl(client: client);
      final result = await dataSource.calculateRoute(start, destination);

      expect(result.isError, isTrue);
      final failure = (result as Error<RouteInfo>).failure;
      expect(failure, isA<ServerFailure>());
      expect(failure.message, contains('не найден'));
    });

    test('returns ServerFailure when HTTP status is 504 Gateway Timeout',
        () async {
      final client = MockClient((request) async {
        return http.Response('Gateway Timeout', 504);
      });

      final dataSource = OsrmDataSourceImpl(client: client);
      final result = await dataSource.calculateRoute(start, destination);

      expect(result.isError, isTrue);
      final failure = (result as Error<RouteInfo>).failure;
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, equals(504));
    });

    test('returns NetworkFailure when network exception occurs', () async {
      final client = MockClient((request) async {
        throw http.ClientException('Connection failed');
      });

      final dataSource = OsrmDataSourceImpl(client: client);
      final result = await dataSource.calculateRoute(start, destination);

      expect(result.isError, isTrue);
      final failure = (result as Error<RouteInfo>).failure;
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, contains('Connection failed'));
    });
  });
}

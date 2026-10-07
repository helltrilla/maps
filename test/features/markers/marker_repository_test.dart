import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps/core/constants/app_constants.dart';
import 'package:maps/core/errors/result.dart';
import 'package:maps/features/markers/data/repositories/marker_repository_impl.dart';
import 'package:maps/features/markers/domain/models/saved_marker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MarkerRepositoryImpl tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loadMarkers returns empty list initially', () async {
      final repo = MarkerRepositoryImpl();
      final result = await repo.loadMarkers();

      expect(result.isSuccess, isTrue);
      expect((result as Success<List<SavedMarker>>).data, isEmpty);
    });

    test('adds, updates, and deletes marker successfully', () async {
      final repo = MarkerRepositoryImpl();

      const marker = SavedMarker(
        id: 'm1',
        title: 'Моя точка',
        position: LatLng(54.71, 20.45),
      );

      // Add
      final addRes = await repo.addMarker(marker);
      expect(addRes.isSuccess, isTrue);

      final loadRes1 = await repo.loadMarkers();
      expect((loadRes1 as Success<List<SavedMarker>>).data.length, equals(1));
      expect(loadRes1.data.first.title, equals('Моя точка'));

      // Update m1
      final updatedM1 =
          marker.copyWith(title: 'Обновленная точка', address: 'ул. Мира, 1');
      final updateRes = await repo.updateMarker(updatedM1);
      expect(updateRes.isSuccess, isTrue);

      final loadAfterUpdate = await repo.loadMarkers();
      expect((loadAfterUpdate as Success<List<SavedMarker>>).data.first.title,
          equals('Обновленная точка'));
      expect(loadAfterUpdate.data.first.address, equals('ул. Мира, 1'));

      // Add second marker
      const marker2 = SavedMarker(
        id: 'm2',
        title: 'Вторая точка',
        position: LatLng(54.72, 20.46),
      );
      final addRes2 = await repo.addMarker(marker2);
      expect(addRes2.isSuccess, isTrue);

      final loadRes2 = await repo.loadMarkers();
      expect((loadRes2 as Success<List<SavedMarker>>).data.length, equals(2));

      // Delete m1
      final delRes = await repo.deleteMarker('m1');
      expect(delRes.isSuccess, isTrue);

      final loadRes3 = await repo.loadMarkers();
      expect((loadRes3 as Success<List<SavedMarker>>).data.length, equals(1));
      expect(loadRes3.data.first.id, equals('m2'));

      // Clear all
      final clearRes = await repo.clearAll();
      expect(clearRes.isSuccess, isTrue);

      final loadRes4 = await repo.loadMarkers();
      expect((loadRes4 as Success<List<SavedMarker>>).data, isEmpty);
    });

    test('migrates legacy saved_markers format to new format', () async {
      final legacyList = [
        {'lat': 54.71, 'lng': 20.45},
        {'lat': 54.72, 'lng': 20.46},
      ];
      SharedPreferences.setMockInitialValues({
        AppConstants.legacyMarkersKey: jsonEncode(legacyList),
      });

      final repo = MarkerRepositoryImpl();
      final result = await repo.loadMarkers();

      expect(result.isSuccess, isTrue);
      final markers = (result as Success<List<SavedMarker>>).data;
      expect(markers.length, equals(2));
      expect(markers[0].position.latitude, equals(54.71));
      expect(markers[1].position.latitude, equals(54.72));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps/core/errors/result.dart';
import 'package:maps/features/markers/domain/models/saved_marker.dart';
import 'package:maps/features/markers/presentation/widgets/add_marker_sheet.dart';
import 'package:maps/features/search/data/repositories/search_repository_impl.dart';
import 'package:maps/features/search/domain/models/reverse_geocode_result.dart';
import 'package:maps/features/search/domain/models/search_result.dart';
import 'package:maps/features/search/domain/repositories/search_repository.dart';

class MockSearchRepoForAddMarker implements SearchRepository {
  @override
  Future<Result<List<SearchResult>>> search(
    String query, {
    LatLng? proximity,
    int limit = 10,
  }) async {
    return const Success([]);
  }

  @override
  Future<Result<ReverseGeocodeResult>> reverseGeocode(LatLng position) async {
    return Success(
      ReverseGeocodeResult(
        street: 'ул. Театральная, 30',
        fullAddress: 'ул. Театральная, 30, Калининград',
        position: position,
      ),
    );
  }
}

void main() {
  testWidgets(
      'AddMarkerSheet resolves street as default title, shows coordinates in additional info, and saves',
      (tester) async {
    SavedMarker? savedMarker;
    const testPos = LatLng(54.7104, 20.4522);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchRepositoryProvider
              .overrideWithValue(MockSearchRepoForAddMarker()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AddMarkerSheet(
              position: testPos,
              onSave: (marker) => savedMarker = marker,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header
    expect(find.text('Новая метка'), findsOneWidget);

    // Verify prefilled title matches the street
    expect(find.text('ул. Театральная, 30'), findsWidgets);

    // Verify address card
    expect(find.text('ул. Театральная, 30, Калининград'), findsOneWidget);

    // Verify coordinates in additional information
    expect(find.text('Координаты (дополнительная информация)'), findsOneWidget);
    expect(find.text('54.710400, 20.452200'), findsOneWidget);

    // Tap save button
    await tester.tap(find.text('Сохранить метку'));
    await tester.pumpAndSettle();

    expect(savedMarker, isNotNull);
    expect(savedMarker!.title, equals('ул. Театральная, 30'));
    expect(savedMarker!.address, equals('ул. Театральная, 30, Калининград'));
  });

  testWidgets('AddMarkerSheet allows immediately renaming title before saving',
      (tester) async {
    SavedMarker? savedMarker;
    const testPos = LatLng(54.7104, 20.4522);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchRepositoryProvider
              .overrideWithValue(MockSearchRepoForAddMarker()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AddMarkerSheet(
              position: testPos,
              onSave: (marker) => savedMarker = marker,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Change title immediately
    final textField = find.byType(TextField);
    await tester.enterText(textField, 'Мой любимый ресторан');
    await tester.pump();

    // Tap save button
    await tester.tap(find.text('Сохранить метку'));
    await tester.pumpAndSettle();

    expect(savedMarker, isNotNull);
    expect(savedMarker!.title, equals('Мой любимый ресторан'));
    expect(savedMarker!.address, equals('ул. Театральная, 30, Калининград'));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps/core/constants/app_strings.dart';
import 'package:maps/core/errors/result.dart';
import 'package:maps/features/places/domain/models/place.dart';
import 'package:maps/features/search/domain/models/search_result.dart';
import 'package:maps/features/search/domain/repositories/search_repository.dart';
import 'package:maps/features/search/presentation/widgets/search_bar_widget.dart';
import 'package:maps/services/search_service.dart';

class FakeSearchRepository implements SearchRepository {
  final Future<Result<List<SearchResult>>> Function(String query, int limit)?
      onSearch;

  FakeSearchRepository({this.onSearch});

  @override
  Future<Result<List<SearchResult>>> search(
    String query, {
    LatLng? proximity,
    int limit = 10,
  }) async {
    if (onSearch != null) {
      return onSearch!(query, limit);
    }
    return const Success([]);
  }
}

void main() {
  testWidgets(
      'FloatingSearchBar renders placeholder and opens categories on focus',
      (tester) async {
    String? selectedCategory;
    bool? openState;

    const nearby = [
      Place(
        id: 'p1',
        name: 'Кафе Уют',
        position: LatLng(54.71, 20.45),
        type: 'Кафе',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatingSearchBar(
            userLocation: const LatLng(54.71, 20.45),
            nearbyPlaces: nearby,
            onResultSelected: (_) {},
            onClear: () {},
            onCategorySelected: (cat) => selectedCategory = cat,
            onOpenStateChanged: (isOpen) => openState = isOpen,
          ),
        ),
      ),
    );

    // Initial state
    expect(find.text(AppStrings.searchPlaceholder), findsOneWidget);

    // Tap text field to focus
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(openState, isTrue);
    expect(find.text('Рядом с вашей геолокацией'), findsOneWidget);
    expect(find.text('Кафе Уют'), findsOneWidget);

    // Tap quick category
    await tester.tap(find.text('Кафе').first);
    await tester.pumpAndSettle();

    expect(selectedCategory, equals('Кафе'));
  });

  testWidgets(
      'FloatingSearchBar displays far results indicator and loads broader results on button tap',
      (tester) async {
    int requestedLimit = 0;
    final fakeRepo = FakeSearchRepository(
      onSearch: (query, limit) async {
        requestedLimit = limit;
        if (limit == 10) {
          return const Success([
            SearchResult(
              title: 'Далекое Место 1',
              subtitle: '60 км отсюда',
              position: LatLng(55.20, 21.10),
              type: 'place',
              distanceMeters: 60000,
            ),
          ]);
        } else {
          return const Success([
            SearchResult(
              title: 'Далекое Место 1',
              subtitle: '60 км отсюда',
              position: LatLng(55.20, 21.10),
              type: 'place',
              distanceMeters: 60000,
            ),
            SearchResult(
              title: 'Далекое Место 2',
              subtitle: '75 км отсюда',
              position: LatLng(55.40, 21.30),
              type: 'place',
              distanceMeters: 75000,
            ),
          ]);
        }
      },
    );

    SearchService.setRepositoryForTesting(fakeRepo);
    addTearDown(SearchService.resetRepositoryForTesting);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatingSearchBar(
            userLocation: const LatLng(54.71, 20.45),
            onResultSelected: (_) {},
            onClear: () {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Далекое');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('> 50 км'), findsOneWidget);
    expect(find.text('Далекое Место 1'), findsOneWidget);
    expect(find.text('Показать другие результаты'), findsOneWidget);
    expect(requestedLimit, equals(10));

    // Tap "Показать другие результаты"
    await tester.tap(find.text('Показать другие результаты'));
    await tester.pumpAndSettle();

    expect(requestedLimit, equals(25));
    expect(find.text('Далекое Место 2'), findsOneWidget);
  });
}

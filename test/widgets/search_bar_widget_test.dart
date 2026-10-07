import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps/core/constants/app_strings.dart';
import 'package:maps/core/errors/result.dart';
import 'package:maps/features/places/domain/models/place.dart';
import 'package:maps/features/search/domain/models/search_result.dart';
import 'package:maps/features/search/domain/repositories/search_repository.dart';
import 'package:maps/features/search/presentation/widgets/search_bar_widget.dart';
import 'package:maps/features/search/domain/models/reverse_geocode_result.dart';
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

  @override
  Future<Result<ReverseGeocodeResult>> reverseGeocode(LatLng position) async {
    return Success(
      ReverseGeocodeResult(
        street: 'ул. Тестовая',
        fullAddress: 'ул. Тестовая, 10, Калининград',
        position: position,
      ),
    );
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
      'FloatingSearchBar shows only near results in city (<=50km) initially, and far results strictly after button tap',
      (tester) async {
    int requestedLimit = 0;
    final fakeRepo = FakeSearchRepository(
      onSearch: (query, limit) async {
        requestedLimit = limit;
        if (limit == 10) {
          return const Success([
            SearchResult(
              title: 'Городское Кафе',
              subtitle: 'Ленинский проспект 5',
              position: LatLng(54.72, 20.46),
              type: 'cafe',
              distanceMeters: 2500, // 2.5 km -> in city <= 50km
            ),
            SearchResult(
              title: 'Загородная Усадьба',
              subtitle: 'Трасса А-229',
              position: LatLng(54.95, 21.80),
              type: 'place',
              distanceMeters: 78000, // 78 km -> outside city > 50km
            ),
          ]);
        } else {
          return const Success([
            SearchResult(
              title: 'Городское Кафе',
              subtitle: 'Ленинский проспект 5',
              position: LatLng(54.72, 20.46),
              type: 'cafe',
              distanceMeters: 2500,
            ),
            SearchResult(
              title: 'Загородная Усадьба',
              subtitle: 'Трасса А-229',
              position: LatLng(54.95, 21.80),
              type: 'place',
              distanceMeters: 78000,
            ),
            SearchResult(
              title: 'Дальний Отель',
              subtitle: 'Курортный проспект',
              position: LatLng(55.20, 21.60),
              type: 'hotel',
              distanceMeters: 92000,
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

    await tester.enterText(find.byType(TextField), 'Кафе');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(requestedLimit, equals(10));

    // Initially: main display is ONLY near place in city (<= 50km)
    expect(find.text('Городское Кафе'), findsOneWidget);
    expect(find.text('В районе города: 1'), findsOneWidget);
    expect(find.text('+1 дальше 50 км'), findsOneWidget);

    // Far place (>50km) MUST NOT be visible before clicking button
    expect(find.text('Загородная Усадьба'), findsNothing);

    // Button to show others is visible
    expect(find.text('Показать другие результаты'), findsOneWidget);

    // Tap "Показать другие результаты"
    await tester.tap(find.text('Показать другие результаты'));
    await tester.pumpAndSettle();

    expect(requestedLimit, equals(25));

    // Now all results are shown strictly after clicking the button
    expect(find.text('Городское Кафе'), findsOneWidget);
    expect(find.text('Загородная Усадьба'), findsOneWidget);
    expect(find.text('Дальний Отель'), findsOneWidget);
    expect(find.text('Все результаты: 3'), findsOneWidget);
  });

  testWidgets(
      'FloatingSearchBar informs when no city results exist and reveals far results after button tap',
      (tester) async {
    final fakeRepo = FakeSearchRepository(
      onSearch: (query, limit) async {
        return const Success([
          SearchResult(
            title: 'Парижский Музей',
            subtitle: 'Франция',
            position: LatLng(48.85, 2.35),
            type: 'tourism',
            distanceMeters: 1400000, // 1400 km
          ),
        ]);
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

    await tester.enterText(find.byType(TextField), 'Париж');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Informs that nothing is found in city up to 50km
    expect(find.text('В районе города (до 50 км) ничего не найдено'),
        findsOneWidget);
    expect(find.text('Найдено дальше 50 км: 1'), findsOneWidget);

    // Far place NOT yet in list
    expect(find.text('Парижский Музей'), findsNothing);

    // Tap button to reveal far results
    await tester.tap(find.text('Показать другие результаты'));
    await tester.pumpAndSettle();

    expect(find.text('Парижский Музей'), findsOneWidget);
  });
}

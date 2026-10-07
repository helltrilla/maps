import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps/core/constants/app_strings.dart';
import 'package:maps/features/places/domain/models/place.dart';
import 'package:maps/features/search/presentation/widgets/search_bar_widget.dart';

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
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps/core/constants/app_strings.dart';
import 'package:maps/features/places/domain/models/place.dart';
import 'package:maps/features/places/domain/models/place_review.dart';
import 'package:maps/features/places/presentation/widgets/place_details_sheet.dart';

void main() {
  testWidgets('PlaceDetailsSheet renders details and triggers onBuildRoute',
      (tester) async {
    bool routeBuilt = false;

    const testPlace = Place(
      id: 'place_1',
      name: 'Кофейня Мечта',
      position: LatLng(54.7104, 20.4522),
      type: 'Кафе',
      address: 'Ленинский проспект 15',
      rating: 4.8,
      reviewsCount: 12,
      reviews: [
        PlaceReview(
          authorName: 'Алексей',
          authorAvatar: '',
          rating: 5,
          timeAgo: 'вчера',
          text: 'Отличный кофе и выпечка!',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaceDetailsSheet(
            place: testPlace,
            onBuildRoute: () => routeBuilt = true,
          ),
        ),
      ),
    );

    // Verify name and category
    expect(find.text('Кофейня Мечта'), findsOneWidget);
    expect(find.text('Кафе'), findsOneWidget);
    expect(find.text('Ленинский проспект 15'), findsOneWidget);

    // Verify honest demo label
    expect(find.text('(12 отзывов • Демо)'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Отзывы пользователей (Демо)'), findsOneWidget);

    // Tap build route button
    await tester.tap(find.text(AppStrings.buildRoute));
    await tester.pump();

    expect(routeBuilt, isTrue);
  });
}

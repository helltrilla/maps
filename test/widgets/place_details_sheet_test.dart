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

  testWidgets(
      'PlaceDetailsSheet does not overflow on narrow screens (320px width)',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const testPlace = Place(
      id: 'place_narrow',
      name: 'Очень длинное название заведения или кофейни с пекарней',
      position: LatLng(54.7104, 20.4522),
      type: 'Ресторан высокой кухни и кулинария',
      address: 'Улица Космонавта Леонова, дом 42, корпус 3, подъезд 2',
      rating: 4.9,
      reviewsCount: 384,
      photos: [
        'https://example.com/photo1.jpg',
        'https://example.com/photo2.jpg'
      ],
      reviews: [
        PlaceReview(
          authorName: 'Константин Константинопольский',
          authorAvatar: '',
          rating: 5,
          timeAgo: '2 дня назад',
          text: 'Превосходное обслуживание и вкусный кофе!',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaceDetailsSheet(
            place: testPlace,
            onBuildRoute: () {},
          ),
        ),
      ),
    );

    expect(find.text('Очень длинное название заведения или кофейни с пекарней'),
        findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(
        find.text('Очень длинное название заведения или кофейни с пекарней'),
        const Offset(0, -500));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Отзывы пользователей (Демо)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'PlaceDetailsSheet supports renaming and shows coordinates in additional info',
      (tester) async {
    String? updatedName;

    const testPlace = Place(
      id: 'marker_test',
      name: 'Улица Мира',
      position: LatLng(54.7104, 20.4522),
      type: 'точка',
      address: 'Улица Мира, 5, Калининград',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaceDetailsSheet(
            place: testPlace,
            onBuildRoute: () {},
            onRename: (newName) => updatedName = newName,
          ),
        ),
      ),
    );

    expect(find.text('Улица Мира'), findsOneWidget);
    expect(find.text('Улица Мира, 5, Калининград'), findsOneWidget);
    expect(find.text('Координаты (дополнительная информация)'), findsOneWidget);

    // Tap rename button
    await tester.tap(find.byTooltip('Переименовать'));
    await tester.pumpAndSettle();

    expect(find.text('Переименовать точку'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Мой дом');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(updatedName, equals('Мой дом'));
    expect(find.text('Мой дом'), findsOneWidget);
  });
}

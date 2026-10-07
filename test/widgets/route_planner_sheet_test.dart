import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps/core/constants/app_strings.dart';
import 'package:maps/features/routing/presentation/widgets/route_planner_sheet.dart';

void main() {
  testWidgets('RoutePlannerSheet renders start/end points and builds route',
      (tester) async {
    LatLng? builtStart;
    LatLng? builtEnd;

    const startItem = RoutePointItem(
      id: 'pt_a',
      title: 'Точка А (Старт)',
      position: LatLng(54.71, 20.45),
      icon: Icons.play_arrow_rounded,
      iconColor: Colors.green,
    );

    const endItem = RoutePointItem(
      id: 'pt_b',
      title: 'Точка Б (Финиш)',
      position: LatLng(54.72, 20.46),
      icon: Icons.flag_rounded,
      iconColor: Colors.red,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutePlannerSheet(
            savedMarkers: const [],
            nearbyPlaces: const [],
            initialStart: startItem,
            initialDestination: endItem,
            onBuildRoute: (sPos, sName, ePos, eName) {
              builtStart = sPos;
              builtEnd = ePos;
            },
          ),
        ),
      ),
    );

    expect(find.text('Точка А (Старт)'), findsOneWidget);
    expect(find.text('Точка Б (Финиш)'), findsOneWidget);

    // Swap points
    await tester.tap(find.byIcon(Icons.swap_vert_rounded));
    await tester.pumpAndSettle();

    // Now start is B and destination is A
    await tester.tap(find.text(AppStrings.buildRouteAction));
    await tester.pump();

    expect(builtStart?.latitude, equals(54.72));
    expect(builtEnd?.latitude, equals(54.71));
  });
}

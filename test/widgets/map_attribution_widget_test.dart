import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/features/map/domain/models/map_tile_style.dart';
import 'package:maps/features/map/presentation/widgets/map_attribution_widget.dart';

void main() {
  testWidgets(
      'MapAttributionWidget displays attribution and opens dialog on tap',
      (tester) async {
    final style = MapTileStyle.availableStyles.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapAttributionWidget(tileStyle: style),
        ),
      ),
    );

    // Attribution is rendered
    expect(find.text(style.attribution), findsOneWidget);
    expect(find.byIcon(Icons.copyright_rounded), findsOneWidget);

    // Tap opens dialog
    await tester.tap(find.byType(MapAttributionWidget));
    await tester.pumpAndSettle();

    expect(find.text('Правообладатели и лицензии данных:'), findsOneWidget);
    expect(find.text('Понятно'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Понятно'));
    await tester.pumpAndSettle();

    expect(find.text('Правообладатели и лицензии данных:'), findsNothing);
  });
}

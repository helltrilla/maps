import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/core/constants/app_strings.dart';
import 'package:maps/features/map/domain/models/map_tile_style.dart';
import 'package:maps/features/map/presentation/widgets/layer_switcher_dialog.dart';

void main() {
  testWidgets(
      'LayerSwitcherModal scrolls and renders without overflow on small screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 380);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    MapTileStyle? selectedStyle;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LayerSwitcherModal(
            currentType: MapTileType.openStreetMap,
            onStyleSelected: (style) => selectedStyle = style,
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.mapLayers), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Scroll down to find satellite style
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(find.text('Спутник (Esri World)'), findsOneWidget);
    await tester.tap(find.text('Спутник (Esri World)'));
    await tester.pumpAndSettle();

    expect(selectedStyle?.type, equals(MapTileType.satellite));
    expect(tester.takeException(), isNull);
  });
}

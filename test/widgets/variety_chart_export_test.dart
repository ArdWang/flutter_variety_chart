import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('the chart wraps itself in a repaint boundary',
      (WidgetTester tester) async {
    final GlobalKey<VarietyCartesianChartState> key =
        GlobalKey<VarietyCartesianChartState>();
    await tester.pumpWidget(
      host(
        VarietyCartesianChart(
          key: key,
          series: <VarietySeries>[
            VarietyLineSeries(name: 'Revenue', data: monthly()),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    // `toImage` captures the chart through this boundary, so it has to be the
    // first render object the state owns.
    expect(
      find.descendant(
        of: find.byType(VarietyCartesianChart),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );
    expect(key.currentState, isNotNull);
  });

  testWidgets('toImage renders the chart at the requested ratio',
      (WidgetTester tester) async {
    final GlobalKey<VarietyCartesianChartState> key =
        GlobalKey<VarietyCartesianChartState>();
    await tester.pumpWidget(
      host(
        VarietyCartesianChart(
          key: key,
          series: <VarietySeries>[
            VarietyLineSeries(name: 'Revenue', data: monthly()),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Rasterizing is real engine work, so it runs outside the fake async zone
    // the test binding installs; awaiting it inside would wait for a frame
    // that never comes.
    final ui.Image? image = await tester.runAsync(
      () => key.currentState!.toImage(pixelRatio: 2),
    );
    expect(image!.width, 800);
    expect(image.height, 600);
    image.dispose();
  });
}

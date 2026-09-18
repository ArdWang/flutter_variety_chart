import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../test_helpers.dart';

Finder chartCanvas() => find
    .descendant(
      of: find.byType(VarietyCartesianChart),
      matching: find.byType(CustomPaint),
    )
    .first;

/// The geometry the chart currently paints.
dynamic currentGeometry(WidgetTester tester) =>
    (tester.widget<CustomPaint>(chartCanvas()).painter as dynamic).geometry;

List<VarietySeries> series() => <VarietySeries>[
      VarietyLineSeries(
        name: 'Revenue',
        showMarkers: true,
        data: List<VarietyChartData>.generate(
          12,
          (int i) => VarietyChartData(i, (i * 3 % 11).toDouble()),
        ),
      ),
    ];

/// Puts two fingers down at [centre] [spread] apart and leaves them there.
Future<(TestGesture, TestGesture)> beginPinch(
  WidgetTester tester,
  Offset centre,
  double spread,
) async {
  final TestGesture a =
      await tester.startGesture(centre - Offset(spread / 2, 0));
  final TestGesture b =
      await tester.startGesture(centre + Offset(spread / 2, 0));
  await tester.pump(const Duration(milliseconds: 50));
  // Small alternating steps so the arena resolves while the fingers still rest
  // at their original distance.
  for (int i = 0; i < 5; i++) {
    await a.moveBy(const Offset(10, 0));
    await b.moveBy(const Offset(10, 0));
    await tester.pump();
  }
  return (a, b);
}

void main() {
  testWidgets('a tooltip waits out showDuration before it appears',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyCartesianChart(
          series: series(),
          tooltipBehavior: const VarietyTooltipBehavior(
            showDuration: Duration(milliseconds: 600),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final Rect canvasRect = tester.getRect(find.byType(VarietyCartesianChart));
    final TestGesture gesture =
        await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: canvasRect.topLeft);
    addTearDown(gesture.removePointer);
    await tester.pump();
    // Straight onto the first point, read off the layout rather than guessed.
    final List<Offset> points =
        (currentGeometry(tester).pointPositions as List<List<Offset>>).first;
    final Offset hover = canvasRect.topLeft + points.first;
    await gesture.moveTo(hover);
    // Nothing yet: the pointer has to rest first.
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(VarietyTooltipCard), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(VarietyTooltipCard), findsOneWidget);
  });

  testWidgets('deferred zooming holds the repaint back until the fingers leave',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyCartesianChart(
          series: series(),
          zoomPanBehavior: const VarietyZoomPanBehavior(
            enableDeferredZooming: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final double before = currentGeometry(tester).xMinimum as double;
    final Rect canvasRect = tester.getRect(find.byType(VarietyCartesianChart));
    final (TestGesture a, TestGesture b) =
        await beginPinch(tester, canvasRect.center, 80);
    await a.moveBy(const Offset(-40, 0));
    await b.moveBy(const Offset(40, 0));
    await tester.pump();
    // Still pinching, so the painted window is untouched.
    expect(currentGeometry(tester).xMinimum, before);
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    // The fingers are off and the deferred window is finally on screen.
    expect(currentGeometry(tester).xMinimum, greaterThan(before));
  });

  testWidgets('a pinch repaints as it goes when zooming is not deferred',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyCartesianChart(
          series: series(),
          zoomPanBehavior: const VarietyZoomPanBehavior(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final double before = currentGeometry(tester).xMinimum as double;
    final Rect canvasRect = tester.getRect(find.byType(VarietyCartesianChart));
    final (TestGesture a, TestGesture b) =
        await beginPinch(tester, canvasRect.center, 80);
    await a.moveBy(const Offset(-40, 0));
    await b.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(currentGeometry(tester).xMinimum, greaterThan(before));
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
  });
}

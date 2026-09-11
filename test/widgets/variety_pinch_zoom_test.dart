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

/// Performs a two-finger pinch-out at [centre], doubling the finger spread.
Future<void> pinchOut(WidgetTester tester, Offset centre, double spread) async {
  final TestGesture a = await tester.startGesture(centre - Offset(spread / 2, 0));
  final TestGesture b = await tester.startGesture(centre + Offset(spread / 2, 0));
  await tester.pump(const Duration(milliseconds: 50));
  // Slide both fingers together in small alternating steps so the spread
  // never changes by more than the gesture slop: the arena resolves while
  // the fingers still rest at the original distance, which the pinch below
  // is then measured against.
  for (int i = 0; i < 5; i++) {
    await a.moveBy(const Offset(10, 0));
    await b.moveBy(const Offset(10, 0));
    await tester.pump();
  }
  // Now spread the fingers to double the distance.
  await a.moveBy(-Offset(spread / 2, 0));
  await b.moveBy(Offset(spread / 2, 0));
  await tester.pump();
  await a.up();
  await b.up();
  await tester.pumpAndSettle();
}

Future<void> pumpChart(
  WidgetTester tester, {
  VarietyZoomAxisMode axisMode = VarietyZoomAxisMode.xy,
  List<VarietySeries> series = const <VarietySeries>[],
}) async {
  await tester.pumpWidget(
    host(
      VarietyCartesianChart(
        zoomPanBehavior: VarietyZoomPanBehavior(
          mode: VarietyZoomMode.pinch,
          axisMode: axisMode,
        ),
        series: series.isEmpty
            ? <VarietySeries>[
                VarietyLineSeries(name: 'A', showMarkers: true, data: monthly()),
              ]
            : series,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pinch zooms the X and Y axes together on a category chart',
      (WidgetTester tester) async {
    await pumpChart(tester);
    final dynamic before = currentGeometry(tester);
    final double xSpanBefore = before.xMaximum - before.xMinimum;
    final double ySpanBefore = before.yMaximum - before.yMinimum;
    final double slotWidthBefore = before.slotWidth;

    await pinchOut(tester, tester.getCenter(chartCanvas()), 80);

    final dynamic after = currentGeometry(tester);
    // Both windows shrink to roughly half of the full range.
    expect(after.xMaximum - after.xMinimum, lessThan(xSpanBefore * 0.6));
    expect(after.yMaximum - after.yMinimum, lessThan(ySpanBefore * 0.6));
    // Fewer visible categories share the plot, so each slot grows wider.
    expect(after.slotWidth, greaterThan(slotWidthBefore * 1.5));
  });

  testWidgets('pinch leaves the Y axis alone when only the X axis is zoomed',
      (WidgetTester tester) async {
    await pumpChart(tester, axisMode: VarietyZoomAxisMode.x);
    final dynamic before = currentGeometry(tester);
    final double ySpanBefore = before.yMaximum - before.yMinimum;

    await pinchOut(tester, tester.getCenter(chartCanvas()), 80);

    final dynamic after = currentGeometry(tester);
    expect(after.xMaximum - after.xMinimum, lessThan(before.xMaximum - before.xMinimum));
    expect(after.yMaximum - after.yMinimum, moreOrLessEquals(ySpanBefore, epsilon: 0.5));
  });

  testWidgets('pinch zooms a chart that mixes column and line series',
      (WidgetTester tester) async {
    await pumpChart(
      tester,
      series: <VarietySeries>[
        VarietyColumnSeries(name: 'Revenue', data: monthly()),
        VarietyLineSeries(name: 'Target', data: monthly()),
      ],
    );
    final dynamic before = currentGeometry(tester);
    final double xSpanBefore = before.xMaximum - before.xMinimum;
    final double ySpanBefore = before.yMaximum - before.yMinimum;

    await pinchOut(tester, tester.getCenter(chartCanvas()), 80);

    final dynamic after = currentGeometry(tester);
    expect(after.xMaximum - after.xMinimum, lessThan(xSpanBefore * 0.6));
    expect(after.yMaximum - after.yMinimum, lessThan(ySpanBefore * 0.6));
  });

  testWidgets('a drag pans both axes after a pinch zoom',
      (WidgetTester tester) async {
    await pumpChart(tester);
    final Offset centre = tester.getCenter(chartCanvas());
    await pinchOut(tester, centre, 80);
    // Let the double-tap recogniser give up before the next touch.
    await tester.pump(const Duration(milliseconds: 400));
    final dynamic zoomed = currentGeometry(tester);
    final double xMinBefore = zoomed.xMinimum;
    final double yMinBefore = zoomed.yMinimum;

    // Drag left and down: the content follows the finger, so the visible
    // window slides towards later categories and smaller values. The first
    // move resolves the gesture arena, so the pan itself starts from the
    // second move on.
    final TestGesture finger = await tester.startGesture(centre);
    await tester.pump(const Duration(milliseconds: 120));
    await finger.moveBy(const Offset(40, 40));
    await tester.pump();
    await finger.moveBy(const Offset(-60, 40));
    await tester.pump();
    await finger.up();
    await tester.pumpAndSettle();

    final dynamic panned = currentGeometry(tester);
    expect(panned.xMinimum, greaterThan(xMinBefore));
    expect(panned.yMinimum, lessThan(yMinBefore));
  });
}

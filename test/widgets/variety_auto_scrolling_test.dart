import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_variety_chart/src/painters/variety_cartesian_painter.dart';

import '../test_helpers.dart';

/// Enough categories that a small delta leaves several of them scrolled out.
int pointCount = 10;

List<VarietyChartData> points() => <VarietyChartData>[
      for (int i = 0; i < pointCount; i++)
        VarietyChartData('P$i', (i + 1) * 10.0),
    ];

/// The geometry the chart is drawing, which carries the x window.
VarietyCartesianGeometry chartGeometry(WidgetTester tester) {
  final CustomPaint paint = tester.widget<CustomPaint>(
    find
        .descendant(
          of: find.byType(VarietyCartesianChart),
          matching: find.byType(CustomPaint),
        )
        .first,
  );
  return (paint.painter! as VarietyCartesianPainter).geometry;
}

VarietyAxis scrollingAxis({
  double? delta,
  VarietyAutoScrollingMode mode = VarietyAutoScrollingMode.end,
}) {
  return VarietyAxis(
    type: VarietyAxisType.category,
    autoScrollingDelta: delta,
    autoScrollingMode: mode,
  );
}

Widget chart(VarietyAxis xAxis) => host(
      VarietyCartesianChart(
        primaryXAxis: xAxis,
        series: <VarietySeries>[
          VarietyColumnSeries(name: 'A', data: points()),
        ],
      ),
    );

Future<void> doubleTap(WidgetTester tester) async {
  final Offset centre = tester.getCenter(
    find
        .descendant(
          of: find.byType(VarietyCartesianChart),
          matching: find.byType(CustomPaint),
        )
        .first,
  );
  await tester.tapAt(centre);
  // The gap has to clear Flutter's `kDoubleTapMinTime` (40 ms) or the two taps
  // are treated as independent and no double tap is recognised at all.
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tapAt(centre);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => pointCount = 10);

  group('autoScrollingDelta', () {
    testWidgets('without a delta the whole category range is shown',
        (WidgetTester tester) async {
      await tester.pumpWidget(chart(scrollingAxis()));
      await tester.pumpAndSettle();
      final VarietyCartesianGeometry geometry = chartGeometry(tester);
      expect(geometry.xMinimum, 0);
      expect(geometry.xMaximum, 10);
    });

    testWidgets('a delta keeps the last categories in view',
        (WidgetTester tester) async {
      await tester.pumpWidget(chart(scrollingAxis(delta: 4)));
      await tester.pumpAndSettle();
      final VarietyCartesianGeometry geometry = chartGeometry(tester);
      expect(geometry.xMinimum, 6);
      expect(geometry.xMaximum, 10);
    });

    testWidgets('AutoScrollingMode.start keeps the first ones instead',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        chart(
          scrollingAxis(delta: 4, mode: VarietyAutoScrollingMode.start),
        ),
      );
      await tester.pumpAndSettle();
      final VarietyCartesianGeometry geometry = chartGeometry(tester);
      expect(geometry.xMinimum, 0);
      expect(geometry.xMaximum, 4);
    });

    testWidgets('a delta wider than the data shows all of it',
        (WidgetTester tester) async {
      await tester.pumpWidget(chart(scrollingAxis(delta: 25)));
      await tester.pumpAndSettle();
      final VarietyCartesianGeometry geometry = chartGeometry(tester);
      expect(geometry.xMinimum, 0);
      expect(geometry.xMaximum, 10);
    });

    testWidgets('a delta of zero is not a window', (WidgetTester tester) async {
      await tester.pumpWidget(chart(scrollingAxis(delta: 0)));
      await tester.pumpAndSettle();
      final VarietyCartesianGeometry geometry = chartGeometry(tester);
      expect(geometry.xMinimum, 0);
      expect(geometry.xMaximum, 10);
    });

    testWidgets('an appended point slides the window along',
        (WidgetTester tester) async {
      await tester.pumpWidget(chart(scrollingAxis(delta: 4)));
      await tester.pumpAndSettle();
      expect(chartGeometry(tester).xMinimum, 6);

      pointCount = 11;
      await tester.pumpWidget(chart(scrollingAxis(delta: 4)));
      await tester.pumpAndSettle();
      final VarietyCartesianGeometry geometry = chartGeometry(tester);
      expect(geometry.xMinimum, 7);
      expect(geometry.xMaximum, 11);
    });

    testWidgets('the window does not count as a zoom',
        (WidgetTester tester) async {
      // A double tap zooms in on an untouched chart and resets a zoomed one.
      // Auto scrolling is where the chart starts, not a zoom, so the first tap
      // has to zoom further in rather than reset back to the same window.
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            primaryXAxis: scrollingAxis(delta: 4),
            zoomPanBehavior: const VarietyZoomPanBehavior(
              enableDoubleTapZooming: true,
            ),
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'A', data: points()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final double before = chartGeometry(tester).xMinimum;
      await doubleTap(tester);
      expect(chartGeometry(tester).xMinimum, isNot(before));
    });

    testWidgets('a double tap zooms the plain chart in',
        (WidgetTester tester) async {
      // The same gesture without auto scrolling, so the test above is known to
      // be reading the difference and not a gesture that never arrived.
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            primaryXAxis: scrollingAxis(),
            zoomPanBehavior: const VarietyZoomPanBehavior(
              enableDoubleTapZooming: true,
            ),
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'A', data: points()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(chartGeometry(tester).xMinimum, 0);
      await doubleTap(tester);
      expect(chartGeometry(tester).xMinimum, greaterThan(0));
    });
  });
}

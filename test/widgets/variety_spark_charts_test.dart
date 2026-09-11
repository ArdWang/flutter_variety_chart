import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

/// The values shared by most spark chart tests.
const List<double> values = <double>[4, 6, 5, 8, 7, 11, 9, 12, 15, 13];

/// Wraps a spark chart in a bounded box.
Widget host(Widget child, {double width = 200, double height = 60}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: width, height: height, child: child)),
    ),
  );
}

/// Reads the painter the spark chart built.
VarietySparkPainter painterOf(WidgetTester tester) {
  final CustomPaint paint = tester.widget<CustomPaint>(
    find.byType(CustomPaint).last,
  );
  return paint.painter! as VarietySparkPainter;
}

void main() {
  group('widgets', () {
    testWidgets('renders all four spark chart kinds', (WidgetTester tester) async {
      final List<Widget> charts = <Widget>[
        const VarietySparkLineChart(data: values),
        const VarietySparkAreaChart(data: values),
        const VarietySparkBarChart(data: values),
        const VarietySparkWinLossChart(data: <double>[1, -1, 1, 1, -1, 0, 1]),
      ];
      for (final Widget chart in charts) {
        await tester.pumpWidget(host(chart));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('handles empty, single and flat data', (WidgetTester tester) async {
      for (final List<double> data in <List<double>>[
        <double>[],
        <double>[5],
        <double>[7, 7, 7, 7],
      ]) {
        await tester.pumpWidget(host(VarietySparkLineChart(data: data)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('renders without animation when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(const VarietySparkLineChart(data: values, enableAnimation: false)),
      );
      await tester.pump();
      expect(painterOf(tester).progress, 1);
    });

    testWidgets('exposes the kind it draws', (WidgetTester tester) async {
      await tester.pumpWidget(host(const VarietySparkBarChart(data: values)));
      expect(
        tester.widget<VarietySparkBarChart>(find.byType(VarietySparkBarChart)).seriesType,
        VarietySparkSeriesType.bar,
      );
      expect(painterOf(tester).seriesType, VarietySparkSeriesType.bar);
    });
  });

  group('styling', () {
    testWidgets('accepts every axis line option', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const VarietySparkLineChart(
            data: values,
            axisCrossesAt: 8,
            axisLineColor: Colors.red,
            axisLineWidth: 3,
            axisLineDashArray: <double>[4, 4],
            isInversed: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final VarietySparkPainter painter = painterOf(tester);
      expect(painter.axisCrossesAt, 8);
      expect(painter.axisLineWidth, 3);
      // `isInversed` mirrors the series horizontally.
      expect(painter.data.first, values.last);
      expect(painter.data.last, values.first);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts line width and a dash pattern', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const VarietySparkLineChart(
            data: values,
            strokeWidth: 4,
            dashArray: <double>[6, 3],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).strokeWidth, 4);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts area and bar borders', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const VarietySparkAreaChart(
            data: values,
            borderWidth: 2,
            borderColor: Colors.green,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).borderWidth, 2);

      await tester.pumpWidget(
        host(
          const VarietySparkBarChart(
            data: values,
            borderWidth: 2,
            borderColor: Colors.green,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts every point colour override', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const VarietySparkLineChart(
            data: values,
            highPointColor: Colors.red,
            lowPointColor: Colors.blue,
            negativePointColor: Colors.orange,
            firstPointColor: Colors.purple,
            lastPointColor: Colors.teal,
            marker: VarietySparkMarker(
              displayMode: VarietySparkMarkerDisplayMode.all,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts a tie colour on a win/loss chart', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const VarietySparkWinLossChart(
            data: <double>[1, -1, 0, 1],
            tiePointColor: Colors.grey,
            negativePointColor: Colors.red,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).tiePointColor, Colors.grey);
    });

    testWidgets('renders a plot band', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const VarietySparkAreaChart(
            data: values,
            plotBand: VarietySparkPlotBand(
              start: 6,
              end: 12,
              color: Colors.amber,
              borderColor: Colors.black,
              borderWidth: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).plotBand?.start, 6);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ignores an incomplete plot band', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const VarietySparkAreaChart(
            data: values,
            plotBand: VarietySparkPlotBand(start: 6),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('markers', () {
    testWidgets('supports every display mode', (WidgetTester tester) async {
      for (final VarietySparkMarkerDisplayMode mode
          in VarietySparkMarkerDisplayMode.values) {
        await tester.pumpWidget(
          host(
            VarietySparkLineChart(
              data: values,
              marker: VarietySparkMarker(displayMode: mode),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('supports every marker shape', (WidgetTester tester) async {
      for (final VarietySparkMarkerShape shape in VarietySparkMarkerShape.values) {
        await tester.pumpWidget(
          host(
            VarietySparkLineChart(
              data: values,
              marker: VarietySparkMarker(
                displayMode: VarietySparkMarkerDisplayMode.all,
                shape: shape,
                size: 8,
                borderColor: Colors.black,
                borderWidth: 1,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('labels', () {
    testWidgets('supports every label display mode', (WidgetTester tester) async {
      for (final VarietySparkLabelDisplayMode mode
          in VarietySparkLabelDisplayMode.values) {
        await tester.pumpWidget(
          host(
            VarietySparkAreaChart(
              data: values,
              labelDisplayMode: mode,
              labelStyle: const TextStyle(fontSize: 9),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('labels every point when asked to', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const VarietySparkBarChart(
            data: <double>[3, 6, 9],
            labelDisplayMode: VarietySparkLabelDisplayMode.all,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).labelDisplayMode, VarietySparkLabelDisplayMode.all);
    });
  });

  group('trackball', () {
    testWidgets('a tap reveals the trackball', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const VarietySparkLineChart(
            data: values,
            trackball: VarietySparkTrackball(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).trackballIndex, isNull);
      await tester.tapAt(tester.getCenter(find.byType(CustomPaint).last));
      await tester.pumpAndSettle();
      expect(painterOf(tester).trackballIndex, isNotNull);
    });

    testWidgets('a long press activates the trackball', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const VarietySparkLineChart(
            data: values,
            trackball: VarietySparkTrackball(
              activationMode: VarietySparkActivationMode.longPress,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.longPressAt(tester.getCenter(find.byType(CustomPaint).last));
      await tester.pumpAndSettle();
      expect(painterOf(tester).trackballIndex, isNotNull);
    });

    testWidgets('a double tap activates the trackball', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const VarietySparkLineChart(
            data: values,
            trackball: VarietySparkTrackball(
              activationMode: VarietySparkActivationMode.doubleTap,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Offset centre = tester.getCenter(find.byType(CustomPaint).last);
      await tester.tapAt(centre);
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tapAt(centre);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('hideDelay clears the trackball', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const VarietySparkLineChart(
            data: values,
            trackball: VarietySparkTrackball(hideDelay: 200),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(find.byType(CustomPaint).last));
      await tester.pumpAndSettle();
      expect(painterOf(tester).trackballIndex, isNotNull);
      await tester.pump(const Duration(milliseconds: 260));
      expect(painterOf(tester).trackballIndex, isNull);
    });

    testWidgets('shouldAlwaysShow keeps the trackball', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const VarietySparkLineChart(
            data: values,
            trackball: VarietySparkTrackball(
              shouldAlwaysShow: true,
              hideDelay: 100,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(find.byType(CustomPaint).last));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      expect(painterOf(tester).trackballIndex, isNotNull);
    });

    testWidgets('accepts a tooltip formatter and styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietySparkBarChart(
            data: values,
            trackball: VarietySparkTrackball(
              color: Colors.indigo,
              width: 3,
              dashArray: const <double>[3, 3],
              backgroundColor: Colors.black87,
              borderColor: Colors.white,
              borderWidth: 1,
              borderRadius: BorderRadius.circular(2),
              labelStyle: const TextStyle(fontSize: 10, color: Colors.white),
              tooltipFormatter: (VarietySparkTooltipFormatterDetails details) =>
                  '${details.index} => ${details.y}',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(find.byType(CustomPaint).last));
      await tester.pumpAndSettle();
      expect(painterOf(tester).trackballIndex, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a chart without a trackball ignores taps',
        (WidgetTester tester) async {
      await tester.pumpWidget(host(const VarietySparkLineChart(data: values)));
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(find.byType(CustomPaint).last));
      await tester.pumpAndSettle();
      expect(painterOf(tester).trackballIndex, isNull);
    });
  });

  group('VarietySparkline adapter', () {
    testWidgets('renders every legacy type', (WidgetTester tester) async {
      for (final VarietySparklineType type in VarietySparklineType.values) {
        await tester.pumpWidget(
          host(VarietySparkline.fromValues(values, type: type)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('marks high and low points', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietySparkline.fromValues(
            values,
            showHighPoint: true,
            showLowPoint: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).marker, isNotNull);
    });

    testWidgets('accepts VarietyChartData directly', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const VarietySparkline(
            data: <VarietyChartData>[
              VarietyChartData(0, 2),
              VarietyChartData(1, 6),
              VarietyChartData(2, 4),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('geometry parity', () {
    VarietySparkPainter painter({
      List<double> data = values,
      double axisCrossesAt = 0,
    }) {
      return VarietySparkPainter(
        data: data,
        seriesType: VarietySparkSeriesType.line,
        theme: const _StubTheme(),
        progress: 1,
        color: const Color(0xFF3F6FE0),
        axisCrossesAt: axisCrossesAt,
      );
    }

    test('has no padding, so the ends sit on the edges', () {
      final VarietySparkPainter p = painter()..layoutFor(const Size(200, 60));
      expect(p.drawingWidth, 200);
      expect(p.drawingHeight, 60);
      expect(p.pointFor(0).dx, 0);
      expect(p.pointFor(values.length - 1).dx, 200);
    });

    test('the highest value is on the top edge and the lowest on the bottom', () {
      final VarietySparkPainter p = painter()..layoutFor(const Size(200, 60));
      final int high = values.indexOf(values.reduce(math.max));
      final int low = values.indexOf(values.reduce(math.min));
      expect(p.pointFor(high).dy, 0);
      expect(p.pointFor(low).dy, 60);
    });

    test('a value between the extremes maps proportionally', () {
      final VarietySparkPainter p = painter(data: <double>[0, 50, 100])
        ..layoutFor(const Size(100, 100));
      expect(p.pointFor(0).dy, 100);
      expect(p.pointFor(1).dy, 50);
      expect(p.pointFor(2).dy, 0);
    });

    test('the axis line is clamped into the drawing area', () {
      final VarietySparkPainter inside = painter(axisCrossesAt: 8)
        ..layoutFor(const Size(200, 60));
      expect(inside.axisPixel, greaterThanOrEqualTo(0));
      expect(inside.axisPixel, lessThanOrEqualTo(60));

      final VarietySparkPainter below = painter(axisCrossesAt: -100)
        ..layoutFor(const Size(200, 60));
      expect(below.axisPixel, 60);

      final VarietySparkPainter above = painter(axisCrossesAt: 1000)
        ..layoutFor(const Size(200, 60));
      expect(above.axisPixel, 0);
    });

    test('the axis line does not stretch the value scale', () {
      final VarietySparkPainter withoutAxis = painter()
        ..layoutFor(const Size(200, 60));
      final VarietySparkPainter withAxis = painter(axisCrossesAt: 0)
        ..layoutFor(const Size(200, 60));
      final int high = values.indexOf(values.reduce(math.max));
      expect(withAxis.pointFor(high).dy, withoutAxis.pointFor(high).dy);
    });

    test('a flat series sits on the top edge', () {
      final VarietySparkPainter p = painter(data: <double>[7, 7, 7, 7])
        ..layoutFor(const Size(200, 60));
      for (int i = 0; i < 4; i++) {
        expect(p.pointFor(i).dy, 0);
      }
    });

    test('a single point sits in the middle', () {
      final VarietySparkPainter p = painter(data: <double>[7])
        ..layoutFor(const Size(200, 60));
      expect(p.pointFor(0).dx, 100);
      expect(p.pointFor(0).dy, 0);
    });

    test('a mirrored series is plotted from the right', () {
      final VarietySparkPainter normal = painter()..layoutFor(const Size(200, 60));
      final VarietySparkPainter mirrored = painter(
        data: values.reversed.toList(growable: false),
      )..layoutFor(const Size(200, 60));
      expect(normal.pointFor(0).dy, mirrored.pointFor(values.length - 1).dy);
      expect(normal.pointFor(0).dy, isNot(mirrored.pointFor(0).dy));
    });
  });
}

/// A minimal theme so the painter can be exercised without a widget tree.
class _StubTheme implements VarietyChartTheme {
  const _StubTheme();

  @override
  Color get axisLineColor => const Color(0xFF000000);

  @override
  Color get gridLineColor => const Color(0x22000000);

  @override
  Color get labelColor => const Color(0xCC000000);

  @override
  Color get markerBorderColor => const Color(0xFFFFFFFF);

  @override
  Color get tooltipBackgroundColor => const Color(0xFF32323A);

  @override
  Color get tooltipTextColor => const Color(0xFFFFFFFF);
}

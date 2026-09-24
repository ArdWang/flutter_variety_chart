import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
// The painter is not part of the public surface, but these tests drive it
// directly to check what actually reaches the canvas.
import 'package:flutter_variety_chart/src/painters/variety_cartesian_painter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

const VarietyChartTheme _theme = VarietyChartTheme(
  gridLineColor: Color(0x1F000000),
  axisLineColor: Color(0x59000000),
  labelColor: Color(0xBF000000),
  tooltipBackgroundColor: Color(0xFF32323A),
  tooltipTextColor: Colors.white,
  markerBorderColor: Colors.white,
);

const VarietyAxis rateAxis = VarietyAxis(
  type: VarietyAxisType.numeric,
  name: 'rate',
  minimum: 0,
  maximum: 100,
  title: 'Rate (%)',
);

VarietyCartesianGeometry build({
  required List<VarietySeries> series,
  List<VarietyAxis> secondary = const <VarietyAxis>[rateAxis],
}) {
  return VarietyCartesianGeometry(
    series: series,
    xAxis: const VarietyAxis(type: VarietyAxisType.category),
    yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
    plotRect: defaultPlotRect,
    progress: 1,
    secondaryYAxes: secondary,
  );
}

void main() {
  group('axis resolution', () {
    test('a series without an axis name uses the primary axis', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[VarietyColumnSeries(data: monthly())],
      );
      expect(geometry.yAxes.length, 2);
      expect(geometry.axisIndexOf(0), 0);
    });

    test('a series bound by name uses the matching axis', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyColumnSeries(data: monthly()),
          VarietyLineSeries(
            data: const <VarietyChartData>[
              VarietyChartData('Jan', 10),
              VarietyChartData('Feb', 20),
            ],
            yAxisName: 'rate',
          ),
        ],
      );
      expect(geometry.axisIndexOf(0), 0);
      expect(geometry.axisIndexOf(1), 1);
    });

    test('an unknown axis name falls back to the primary axis', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(data: monthly(), yAxisName: 'missing'),
        ],
      );
      expect(geometry.axisIndexOf(0), 0);
    });

    test('each axis resolves its own range', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyColumnSeries(data: monthly()),
          VarietyLineSeries(
            data: const <VarietyChartData>[
              VarietyChartData('Jan', 10),
              VarietyChartData('Feb', 20),
            ],
            yAxisName: 'rate',
          ),
        ],
      );
      // The secondary axis is pinned by the axis settings.
      expect(geometry.axisMinimums[1], 0);
      expect(geometry.axisMaximums[1], 100);
      // The primary axis keeps its own, much smaller range.
      expect(geometry.axisMaximums[0], lessThan(100));
    });

    test('a derived range is used when the axis leaves it open', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyColumnSeries(data: monthly()),
          VarietyLineSeries(
            data: const <VarietyChartData>[
              VarietyChartData('Jan', 200),
              VarietyChartData('Feb', 400),
            ],
            yAxisName: 'rate',
          ),
        ],
        secondary: const <VarietyAxis>[
          VarietyAxis(type: VarietyAxisType.numeric, name: 'rate'),
        ],
      );
      expect(geometry.axisMaximums[1], greaterThanOrEqualTo(400));
      expect(geometry.axisMaximums[0], lessThan(200));
    });
  });

  group('pixel mapping', () {
    test('the same value maps to different pixels on different axes', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyColumnSeries(data: monthly()),
          VarietyLineSeries(
            data: const <VarietyChartData>[VarietyChartData('Jan', 50)],
            yAxisName: 'rate',
          ),
        ],
      );
      final double onPrimary = geometry.pixelYOn(0, 50);
      final double onSecondary = geometry.pixelYOn(1, 50);
      expect(onPrimary, isNot(closeTo(onSecondary, 0.5)));
    });

    test('the secondary tick values follow its own interval', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(
            data: const <VarietyChartData>[VarietyChartData('Jan', 50)],
            yAxisName: 'rate',
          ),
        ],
      );
      final List<double> ticks = geometry.yTicksOn(1);
      expect(ticks.first, 0);
      expect(ticks.last, 100);
      expect(ticks.length, greaterThan(2));
    });

    test('the secondary caption uses the axis formatter', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(
            data: const <VarietyChartData>[VarietyChartData('Jan', 50)],
            yAxisName: 'rate',
          ),
        ],
        secondary: const <VarietyAxis>[
          VarietyAxis(
            type: VarietyAxisType.numeric,
            name: 'rate',
            minimum: 0,
            maximum: 100,
            numberFormat: '0.0',
          ),
        ],
      );
      expect(geometry.secondaryTickLabelOn(1, 25), '25.0');
    });

    test('the secondary axis has its own baseline', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyColumnSeries(data: monthly()),
          VarietyLineSeries(
            data: const <VarietyChartData>[VarietyChartData('Jan', 50)],
            yAxisName: 'rate',
          ),
        ],
        secondary: const <VarietyAxis>[
          VarietyAxis(
            type: VarietyAxisType.numeric,
            name: 'rate',
            minimum: 40,
            maximum: 60,
          ),
        ],
      );
      expect(geometry.baselineYOn(1), closeTo(geometry.pixelYOn(1, 40), 0.5));
    });
  });

  group('chart widget', () {
    testWidgets('renders a dual axis chart', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            secondaryYAxes: const <VarietyAxis>[rateAxis],
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'Revenue', data: monthly()),
              VarietyLineSeries(
                name: 'Rate',
                yAxisName: 'rate',
                data: const <VarietyChartData>[
                  VarietyChartData('Jan', 10),
                  VarietyChartData('Feb', 60),
                  VarietyChartData('Mar', 30),
                  VarietyChartData('Apr', 80),
                ],
              ),
            ],
          ),
          height: 360,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(VarietyCartesianChart), findsOneWidget);
    });

    testWidgets('a chart without extra axes still renders',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'Revenue', data: monthly()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  // Two series measured in different units is the reason a second value axis
  // exists, and it is only working if both scales really reach the canvas. A
  // chart that merely renders without throwing has not shown that.
  group('two value axes on screen', () {
    const VarietyAxis temperature = VarietyAxis(
      type: VarietyAxisType.numeric,
      name: 'temperature',
      title: 'Temperature (C)',
      minimum: 18,
      maximum: 30,
      interval: 3,
    );
    const VarietyAxis humidity = VarietyAxis(
      type: VarietyAxisType.numeric,
      name: 'humidity',
      title: 'Humidity (%)',
      minimum: 30,
      maximum: 70,
      interval: 10,
    );

    /// Paints the chart and collects both what the horizontal axis reported and
    /// where every paragraph went, since `labelHits` covers the horizontal axis
    /// alone and the value axes can only be seen through the canvas calls.
    (VarietyCartesianGeometry, List<Offset>) paint() {
      final VarietyCartesianGeometry geometry = VarietyCartesianGeometry(
        series: <VarietySeries>[
          VarietyLineSeries(data: monthly(), yAxisName: 'temperature'),
          VarietyLineSeries(data: monthly(), yAxisName: 'humidity'),
        ],
        xAxis: const VarietyAxis(type: VarietyAxisType.category),
        yAxis: temperature,
        plotRect: defaultPlotRect,
        progress: 1,
        secondaryYAxes: const <VarietyAxis>[humidity],
      );
      expect(geometry.axisIndexOf(0), 0);
      expect(geometry.axisIndexOf(1), 1);
      final _RecordingCanvas canvas = _RecordingCanvas();
      VarietyCartesianPainter(
        geometry: geometry,
        theme: _theme,
      ).paint(canvas, const Size(400, 300));
      return (geometry, canvas.paragraphs);
    }

    test('each value axis carries the scale it was configured with', () {
      final (VarietyCartesianGeometry geometry, List<Offset> _) = paint();
      // The two ranges share no tick value, so a tick can only have come from
      // the axis it was configured on.
      expect(geometry.yTicksOn(0).first, 18);
      expect(geometry.yTicksOn(0).last, 30);
      expect(geometry.yTicksOn(1).first, 30);
      expect(geometry.yTicksOn(1).last, 70);
      // The same number therefore means two different heights, which is the
      // whole point of a second value axis.
      expect(
        geometry.pixelYOn(0, 30),
        isNot(closeTo(geometry.pixelYOn(1, 30), 0.5)),
      );
    });

    test('both scales reach the canvas, one on each side of the plot', () {
      final (VarietyCartesianGeometry _, List<Offset> paragraphs) = paint();
      expect(paragraphs, isNotEmpty);
      // The primary scale hugs the left edge of the plot...
      expect(
        paragraphs.any((Offset at) => at.dx < defaultPlotRect.left),
        isTrue,
        reason: 'the primary value axis prints nothing left of the plot',
      );
      // ...and the extra one sits past its right edge, which is what makes the
      // two scales readable at once.
      expect(
        paragraphs.any((Offset at) => at.dx >= defaultPlotRect.right),
        isTrue,
        reason: 'the secondary value axis prints nothing right of the plot',
      );
    });
  });
}

/// A canvas that records where paragraphs were painted instead of rasterising
/// them.
///
/// The painter never reads a value back out of the canvas it is handed, so
/// answering every other call with `null` is enough to let a paint run through
/// and still say where the text landed.
class _RecordingCanvas implements ui.Canvas {
  /// The top-left corner of every paragraph the painter drew.
  final List<Offset> paragraphs = <Offset>[];

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    paragraphs.add(offset);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Everything the painter calls returns void, but answering the few calls
    // that want a value keeps a future one from tripping over a null.
    if (invocation.memberName == #getSaveCount) {
      return 1;
    }
    if (invocation.memberName == #getDestinationClipBounds ||
        invocation.memberName == #getLocalClipBounds) {
      return Rect.zero;
    }
    return null;
  }
}

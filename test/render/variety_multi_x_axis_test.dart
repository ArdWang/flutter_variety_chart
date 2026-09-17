import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
// The painter is not part of the public surface, but this test has to drive it
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

String _withUnit(dynamic value) => '${(value as num).round()}u';

/// A horizontal axis pinned to a range two orders of magnitude wider than the
/// primary one, so the two are easy to tell apart.
const VarietyAxis wideAxis = VarietyAxis(
  type: VarietyAxisType.numeric,
  name: 'wide',
  minimum: 0,
  maximum: 1000,
  labelFormatter: _withUnit,
);

const VarietyAxis quartersAxis = VarietyAxis(
  type: VarietyAxisType.category,
  name: 'quarters',
);

List<VarietyChartData> primaryPoints() => <VarietyChartData>[
      for (int i = 0; i <= 10; i++) VarietyChartData(i, i.toDouble() + 1),
    ];

List<VarietyChartData> widePoints() => const <VarietyChartData>[
      VarietyChartData(0, 12),
      VarietyChartData(200, 18),
      VarietyChartData(900, 9),
    ];

List<VarietyChartData> quarters() => const <VarietyChartData>[
      VarietyChartData('Q1', 5),
      VarietyChartData('Q2', 7),
      VarietyChartData('Q3', 9),
    ];

VarietyCartesianGeometry build({
  required List<VarietySeries> series,
  VarietyAxis xAxis = const VarietyAxis(type: VarietyAxisType.numeric),
  List<VarietyAxis> secondary = const <VarietyAxis>[wideAxis],
  (double, double)? visibleXRange,
}) {
  return VarietyCartesianGeometry(
    series: series,
    xAxis: xAxis,
    yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
    plotRect: defaultPlotRect,
    progress: 1,
    visibleXRange: visibleXRange,
    secondaryXAxes: secondary,
  );
}

void main() {
  group('axis resolution', () {
    test('a series without an axis name uses the primary horizontal axis', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[VarietyLineSeries(data: primaryPoints())],
      );
      expect(geometry.xAxes.length, 2);
      expect(geometry.xAxisIndexOf(0), 0);
      expect(identical(geometry.xAxisFor(0), geometry.xAxis), isTrue);
    });

    test('a series bound by name uses the matching axis', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(data: primaryPoints()),
          VarietyLineSeries(data: widePoints(), xAxisName: 'wide'),
        ],
      );
      expect(geometry.xAxisIndexOf(0), 0);
      expect(geometry.xAxisIndexOf(1), 1);
      expect(identical(geometry.xAxisFor(1), wideAxis), isTrue);
    });

    test('an unknown axis name falls back to the primary axis', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(data: primaryPoints(), xAxisName: 'missing'),
        ],
      );
      expect(geometry.xAxisIndexOf(0), 0);
    });
  });

  group('independent scales', () {
    test('each axis resolves its range from its own series', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(data: primaryPoints()),
          VarietyLineSeries(data: widePoints(), xAxisName: 'wide'),
        ],
      );
      expect(geometry.axisXMinimums[1], 0);
      expect(geometry.axisXMaximums[1], 1000);
      // The primary axis never sees the wide series' readings.
      expect(geometry.axisXMinimums[0], greaterThanOrEqualTo(0));
      expect(geometry.axisXMaximums[0], lessThan(100));
    });

    test('moving a series onto a second axis leaves the primary range alone',
        () {
      final VarietyCartesianGeometry together = build(
        series: <VarietySeries>[VarietyLineSeries(data: primaryPoints())],
        secondary: const <VarietyAxis>[],
      );
      final VarietyCartesianGeometry split = build(
        series: <VarietySeries>[
          VarietyLineSeries(data: primaryPoints()),
          VarietyLineSeries(data: widePoints(), xAxisName: 'wide'),
        ],
      );
      expect(split.axisXMinimums[0], together.axisXMinimums[0]);
      expect(split.axisXMaximums[0], together.axisXMaximums[0]);
    });

    test('the same value lands on a different pixel on each axis', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(data: primaryPoints()),
          VarietyLineSeries(data: widePoints(), xAxisName: 'wide'),
        ],
      );
      // 5 is halfway along a 0..10 axis and a two-hundredth along a 0..1000 one.
      expect(geometry.pixelXOn(1, 5), lessThan(geometry.pixelXOn(0, 5)));
      // And every point is drawn on its own axis, not the primary one.
      expect(
        geometry.pointPositions[0][5].dx,
        closeTo(geometry.pixelXOn(0, 5), 1e-6),
      );
      expect(
        geometry.pointPositions[1][2].dx,
        closeTo(geometry.pixelXOn(1, 900), 1e-6),
      );
    });

    test('each axis captions its own ticks', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(data: primaryPoints()),
          VarietyLineSeries(data: widePoints(), xAxisName: 'wide'),
        ],
      );
      expect(geometry.xTickLabelOn(0, 5), isNot(endsWith('u')));
      final List<double> wideTicks = geometry.xNumericTicksOn(1);
      expect(wideTicks, isNotEmpty);
      for (final double tick in wideTicks) {
        expect(geometry.xTickLabelOn(1, tick), endsWith('u'));
      }
      expect(
        geometry.xNumericTicksOn(1),
        isNot(equals(geometry.xNumericTicksOn(0))),
      );
    });

    test('the zoom window addresses the primary axis only', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(data: primaryPoints()),
          VarietyLineSeries(data: widePoints(), xAxisName: 'wide'),
        ],
        visibleXRange: (0, 4),
      );
      expect(geometry.axisXMinimums[0], 0);
      expect(geometry.axisXMaximums[0], 4);
      // A window in the primary axis' units means nothing on another scale, so
      // the second axis keeps its whole range.
      expect(geometry.axisXMaximums[1], 1000);
    });
  });

  group('category axes', () {
    VarietyCartesianGeometry category() => build(
          series: <VarietySeries>[
            VarietyColumnSeries(data: monthly()),
            VarietyColumnSeries(data: quarters(), xAxisName: 'quarters'),
          ],
          xAxis: const VarietyAxis(type: VarietyAxisType.category),
          secondary: const <VarietyAxis>[quartersAxis],
        );

    test('a second category axis keeps its own slots and captions', () {
      final VarietyCartesianGeometry geometry = category();
      expect(geometry.categories, <String>['Jan', 'Feb', 'Mar', 'Apr']);
      expect(geometry.axisCategories[1], <String>['Q1', 'Q2', 'Q3']);
      expect(geometry.slotCenters, hasLength(4));
      expect(geometry.axisSlotCenters[1], hasLength(3));
      expect(geometry.categoryIndexOf(const VarietyChartData('Q2', 7), 1), 1);
      // A quarter is not a month, so the point has no slot on the primary axis.
      expect(geometry.categoryIndexOf(const VarietyChartData('Q2', 7), 0), -1);
      expect(
        geometry.pointPositions[1][1].dx,
        closeTo(geometry.axisSlotCenters[1][1], 1e-6),
      );
    });

    test('columns on each axis carve their own slot width', () {
      final VarietyCartesianGeometry geometry = category();
      expect(
          geometry.axisSlotWidths[0], closeTo(defaultPlotRect.width / 4, 1e-6));
      expect(
          geometry.axisSlotWidths[1], closeTo(defaultPlotRect.width / 3, 1e-6));
      // Both series carry the default width factor, so the ratio of their
      // columns is the ratio of their slot widths.
      final double primary = geometry.bandRects[0][0]!.width;
      final double second = geometry.bandRects[1][0]!.width;
      expect(second / primary, closeTo(4 / 3, 1e-6));
    });
  });

  group('transposed layout', () {
    test('a bar reads its own value axis', () {
      final VarietyCartesianGeometry geometry = VarietyCartesianGeometry(
        series: <VarietySeries>[
          VarietyBarSeries(
            data: const <VarietyChartData>[VarietyChartData('Jan', 10)],
          ),
          VarietyBarSeries(
            data: const <VarietyChartData>[VarietyChartData('Jan', 10)],
            xAxisName: 'wide',
          ),
        ],
        xAxis: const VarietyAxis(type: VarietyAxisType.category),
        yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
        secondaryXAxes: const <VarietyAxis>[wideAxis],
        plotRect: defaultPlotRect,
        progress: 1,
      );
      // In a bar chart the horizontal family carries the values, so the second
      // horizontal axis is a second value axis.
      expect(geometry.transposed, isTrue);
      expect(geometry.xAxisIndexOf(1), 1);
      expect(geometry.axisXMaximums[1], 1000);
      // The same reading is a whole bar on its own scale and a sliver on a
      // scale a hundred times wider.
      final double narrow = geometry.bandRects[0][0]!.width;
      final double wide = geometry.bandRects[1][0]!.width;
      expect(wide, lessThan(narrow));
    });
  });

  group('painter', () {
    test('the extra axis prints a row of its own', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(data: primaryPoints()),
          VarietyLineSeries(data: widePoints(), xAxisName: 'wide'),
        ],
      );
      final List<VarietyAxisLabelHit> hits = <VarietyAxisLabelHit>[];
      VarietyCartesianPainter(
        geometry: geometry,
        theme: _theme,
        labelHits: hits,
      ).paint(Canvas(ui.PictureRecorder()), const Size(400, 300));
      List<VarietyAxisLabelHit> on(VarietyAxis axis) => hits
          .where((VarietyAxisLabelHit hit) => identical(hit.axis, axis))
          .toList();
      final List<VarietyAxisLabelHit> extra = on(geometry.xAxes[1]);
      final List<VarietyAxisLabelHit> primary = on(geometry.xAxis);
      expect(primary, isNotEmpty);
      expect(extra, isNotEmpty);
      // Each row is captioned by its own axis...
      expect(primary.first.text, isNot(endsWith('u')));
      expect(extra.first.text, endsWith('u'));
      // ...and the stacked row sits below the primary one.
      expect(extra.first.rect.top, greaterThan(primary.first.rect.top));
      expect(extra.first.rect.top, greaterThan(geometry.plotRect.bottom));
    });

    test('a title on the primary axis pushes the stacked row clear of it', () {
      // The title is painted under the primary captions, so the stacked axis has
      // to clear it. The room it takes is measured, not assumed, which is what
      // makes this hold for a title larger than the default.
      double extraRowTop({double? titleSize}) {
        final VarietyCartesianGeometry geometry = build(
          series: <VarietySeries>[
            VarietyLineSeries(data: primaryPoints()),
            VarietyLineSeries(data: widePoints(), xAxisName: 'wide'),
          ],
          xAxis: VarietyAxis(
            type: VarietyAxisType.numeric,
            title: titleSize == null ? null : 'Engine speed (rpm)',
          ),
        );
        final List<VarietyAxisLabelHit> hits = <VarietyAxisLabelHit>[];
        VarietyCartesianPainter(
          geometry: geometry,
          theme: titleSize == null
              ? _theme
              : _theme.copyWith(
                  axisTitleTextStyle: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          labelHits: hits,
        ).paint(Canvas(ui.PictureRecorder()), const Size(400, 500));
        return hits
            .where((VarietyAxisLabelHit hit) =>
                identical(hit.axis, geometry.xAxes[1]))
            .first
            .rect
            .top;
      }

      const double titleSize = 40;
      final double withoutTitle = extraRowTop();
      final double withTitle = extraRowTop(titleSize: titleSize);
      expect(withTitle - withoutTitle, greaterThan(titleSize));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../test_helpers.dart';

VarietyCartesianGeometry build({
  required List<VarietySeries> series,
  VarietyAxis xAxis = const VarietyAxis(type: VarietyAxisType.category),
  VarietyAxis yAxis = const VarietyAxis(type: VarietyAxisType.numeric),
  Rect plotRect = defaultPlotRect,
  double progress = 1,
}) {
  return VarietyCartesianGeometry(
    series: series,
    xAxis: xAxis,
    yAxis: yAxis,
    plotRect: plotRect,
    progress: progress,
  );
}

void main() {
  group('empty point modes', () {
    List<VarietyChartData> withHole() => const <VarietyChartData>[
          VarietyChartData('A', 10),
          VarietyChartData('B', 20),
          VarietyChartData('C', null, isEmpty: true),
          VarietyChartData('D', 40),
        ];

    test('gap keeps the point empty so the line breaks', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[VarietyLineSeries(data: withHole())],
      );
      expect(geometry.resolvedData.first[2].isEmpty, isTrue);
    });

    test('zero substitutes a zero reading', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(
            data: withHole(),
            emptyPointSettings: const VarietyEmptyPointSettings(
              mode: VarietyEmptyPointMode.zero,
            ),
          ),
        ],
      );
      expect(geometry.resolvedData.first[2].y, 0);
      expect(geometry.resolvedData.first[2].isEmpty, isFalse);
    });

    test('average interpolates between the closest valid neighbours', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(
            data: withHole(),
            emptyPointSettings: const VarietyEmptyPointSettings(
              mode: VarietyEmptyPointMode.average,
            ),
          ),
        ],
      );
      expect(geometry.resolvedData.first[2].y, closeTo(30, 0.001));
    });

    test('drop removes the point and its neighbours', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(
            data: withHole(),
            emptyPointSettings: const VarietyEmptyPointSettings(
              mode: VarietyEmptyPointMode.drop,
            ),
          ),
        ],
      );
      expect(geometry.resolvedData.first[1].isEmpty, isTrue);
      expect(geometry.resolvedData.first[2].isEmpty, isTrue);
      expect(geometry.resolvedData.first[3].isEmpty, isTrue);
      expect(geometry.resolvedData.first[0].isEmpty, isFalse);
    });

    test('a series without empty points is left untouched', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(
            data: monthly(),
            emptyPointSettings: const VarietyEmptyPointSettings(
              mode: VarietyEmptyPointMode.average,
            ),
          ),
        ],
      );
      expect(geometry.resolvedData.first[1].y, 48);
    });
  });

  group('sorting order', () {
    List<VarietyChartData> shuffled() => const <VarietyChartData>[
          VarietyChartData(3, 30),
          VarietyChartData(1, 10),
          VarietyChartData(2, 20),
        ];

    test('none keeps the author order', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[VarietyLineSeries(data: shuffled())],
        xAxis: const VarietyAxis(type: VarietyAxisType.numeric),
      );
      expect(geometry.resolvedData.first.first.x, 3);
    });

    test('ascending sorts by the primary value', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(
              data: shuffled(), sortingOrder: VarietySortingOrder.ascending),
        ],
        xAxis: const VarietyAxis(type: VarietyAxisType.numeric),
      );
      expect(
        geometry.resolvedData.first
            .map((VarietyChartData point) => point.x)
            .toList(),
        <int>[1, 2, 3],
      );
    });

    test('descending sorts by the primary value in reverse', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(
              data: shuffled(), sortingOrder: VarietySortingOrder.descending),
        ],
        xAxis: const VarietyAxis(type: VarietyAxisType.numeric),
      );
      expect(geometry.resolvedData.first.first.x, 3);
      expect(geometry.resolvedData.first.last.x, 1);
    });
  });

  group('box and whisker', () {
    List<VarietyChartData> distribution() => const <VarietyChartData>[
          VarietyChartData('Q1', 10, label: 'Q1'),
          VarietyChartData('Q1', 20, label: 'Q1'),
          VarietyChartData('Q1', 30, label: 'Q1'),
          VarietyChartData('Q1', 40, label: 'Q1'),
          VarietyChartData('Q1', 90, label: 'Q1'),
          VarietyChartData('Q2', 12, label: 'Q2'),
          VarietyChartData('Q2', 18, label: 'Q2'),
          VarietyChartData('Q2', 26, label: 'Q2'),
          VarietyChartData('Q2', 34, label: 'Q2'),
        ];

    test('groups points that share a category into one box', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyBoxAndWhiskerSeries(data: distribution()),
        ],
      );
      final Iterable<Rect?> boxes =
          geometry.bandRects.first.where((Rect? rect) => rect != null);
      expect(boxes.length, distribution().length);
      // Both groups share one box, so every point of a group maps to it.
      expect(geometry.bandRects.first[0], geometry.bandRects.first[3]);
      expect(geometry.bandRects.first[5], geometry.bandRects.first[8]);
      expect(geometry.bandRects.first[0], isNot(geometry.bandRects.first[5]));
    });

    test('marks the far value as an outlier', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyBoxAndWhiskerSeries(data: distribution()),
        ],
      );
      // The box spans the two quartiles, so its height stays below the range.
      final Rect box = geometry.bandRects.first.first!;
      final double fullRange =
          (geometry.pixelY(90) - geometry.pixelY(10)).abs();
      expect(box.height, lessThan(fullRange));
    });

    test('reports itself as a box plot and honours the width factor', () {
      final VarietyCartesianGeometry narrow = build(
        series: <VarietySeries>[
          VarietyBoxAndWhiskerSeries(data: distribution(), widthFactor: 0.2),
        ],
      );
      final VarietyCartesianGeometry wide = build(
        series: <VarietySeries>[
          VarietyBoxAndWhiskerSeries(data: distribution(), widthFactor: 0.8),
        ],
      );
      expect(narrow.series.first.isBoxPlot, isTrue);
      expect(
        wide.bandRects.first.first!.width,
        greaterThan(narrow.bandRects.first.first!.width),
      );
    });
  });

  group('error bars', () {
    test('draws a whisker above and below every point', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(
            data: monthly(),
            errorBar: const VarietyErrorBarSeries(
              data: <VarietyChartData>[],
              errorValue: 5,
            ),
          ),
        ],
      );
      final Iterable<VarietySegmentsElement> segments =
          geometry.elements.whereType<VarietySegmentsElement>();
      expect(segments, isNotEmpty);
    });

    test('supports a standalone error bar series', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyErrorBarSeries(data: monthly(), errorValue: 3),
        ],
      );
      expect(geometry.elements.whereType<VarietySegmentsElement>(), isNotEmpty);
    });

    test('a percentage error scales with the value', () {
      final VarietyCartesianGeometry small = build(
        series: <VarietySeries>[
          VarietyErrorBarSeries(
            data: const <VarietyChartData>[VarietyChartData('A', 10)],
            type: VarietyErrorBarType.percentage,
            errorValue: 10,
          ),
        ],
      );
      final VarietyCartesianGeometry large = build(
        series: <VarietySeries>[
          VarietyErrorBarSeries(
            data: const <VarietyChartData>[VarietyChartData('A', 100)],
            type: VarietyErrorBarType.percentage,
            errorValue: 10,
          ),
        ],
      );
      double firstLength(VarietyCartesianGeometry geometry) {
        final VarietySegmentsElement element =
            geometry.elements.whereType<VarietySegmentsElement>().first;
        final VarietySegment segment = element.segments.first;
        return (segment.to - segment.from).distance;
      }

      expect(firstLength(large), greaterThan(firstLength(small)));
    });
  });

  group('new cartesian series kinds', () {
    test('spline area fills the region under a curve', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[VarietySplineAreaSeries(data: monthly())],
      );
      final Iterable<VarietyPathElement> paths =
          geometry.elements.whereType<VarietyPathElement>();
      expect(paths.where((VarietyPathElement path) => path.fillColor != null),
          isNotEmpty);
    });

    test('step area fills a staircase', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[VarietyStepAreaSeries(data: monthly())],
      );
      expect(geometry.elements, isNotEmpty);
    });

    test('spline range area reports itself as a range series', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietySplineRangeAreaSeries(
            data: const <VarietyChartData>[
              VarietyChartData('A', 10, secondaryY: 20),
              VarietyChartData('B', 15, secondaryY: 28),
              VarietyChartData('C', 12, secondaryY: 24),
            ],
          ),
        ],
      );
      expect(geometry.series.first.isRange, isTrue);
      expect(geometry.elements, isNotEmpty);
    });

    test('fast line taps the points it is asked to keep', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyFastLineSeries(
            data: List<VarietyChartData>.generate(
              40,
              (int i) => VarietyChartData(i, (i % 7).toDouble()),
            ),
            decimationFactor: 4,
          ),
        ],
        xAxis: const VarietyAxis(type: VarietyAxisType.numeric),
      );
      final VarietyPathElement path =
          geometry.elements.whereType<VarietyPathElement>().first;
      expect(path.antiAlias, isFalse);
    });
  });

  group('axis options', () {
    test('rangePadding none spans exactly the data range', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[VarietyLineSeries(data: monthly())],
        xAxis: const VarietyAxis(type: VarietyAxisType.numeric),
        yAxis: const VarietyAxis(
          type: VarietyAxisType.numeric,
          rangePadding: VarietyRangePadding.none,
        ),
      );
      expect(geometry.yMinimum, 32);
      expect(geometry.yMaximum, 55);
    });

    test('rangePadding extra adds a margin around the range', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[VarietyLineSeries(data: monthly())],
        xAxis: const VarietyAxis(type: VarietyAxisType.numeric),
        yAxis: const VarietyAxis(
          type: VarietyAxisType.numeric,
          rangePadding: VarietyRangePadding.extra,
        ),
      );
      expect(geometry.yMinimum, lessThan(32));
      expect(geometry.yMaximum, greaterThan(55));
    });

    test('an inverted secondary axis mirrors the pixel mapping', () {
      final VarietyCartesianGeometry normal = build(
        series: <VarietySeries>[VarietyLineSeries(data: monthly())],
      );
      final VarietyCartesianGeometry inverted = build(
        series: <VarietySeries>[VarietyLineSeries(data: monthly())],
        yAxis:
            const VarietyAxis(type: VarietyAxisType.numeric, isInversed: true),
      );
      final double normalTop = normal.pixelY(normal.yMaximum);
      final double invertedTop = inverted.pixelY(inverted.yMaximum);
      expect(normalTop, closeTo(defaultPlotRect.top, 0.5));
      expect(invertedTop, closeTo(defaultPlotRect.bottom, 0.5));
    });

    test('minor ticks subdivide each major interval', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[VarietyLineSeries(data: monthly())],
        yAxis: const VarietyAxis(
          type: VarietyAxisType.numeric,
          minorTicksPerInterval: 1,
        ),
      );
      final List<double> minor = geometry.yMinorTicks;
      expect(minor, isNotEmpty);
      expect(minor.length, greaterThanOrEqualTo(geometry.yTicks.length - 1));
      final List<double> merged = <double>[...geometry.yTicks, ...minor]
        ..sort();
      for (int i = 1; i < merged.length; i++) {
        expect(merged[i], greaterThan(merged[i - 1]));
      }
    });

    test('plotOffset shrinks the plotting rectangle', () {
      final VarietyCartesianGeometry plain = build(
        series: <VarietySeries>[VarietyLineSeries(data: monthly())],
      );
      final VarietyCartesianGeometry offset = build(
        series: <VarietySeries>[VarietyLineSeries(data: monthly())],
        xAxis: const VarietyAxis(
          type: VarietyAxisType.category,
          plotOffsetStart: 20,
        ),
      );
      expect(offset.plotRect.left, greaterThan(plain.plotRect.left));
    });

    test('a number format is applied to tick captions', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[VarietyLineSeries(data: monthly())],
        yAxis: const VarietyAxis(
          type: VarietyAxisType.numeric,
          numberFormat: '#,##0.00',
        ),
      );
      expect(geometry.secondaryTickLabel(1234.5), '1,234.50');
    });
  });

  group('spacing', () {
    double columnWidth(VarietySeries series) {
      final VarietyCartesianGeometry geometry =
          build(series: <VarietySeries>[series]);
      return geometry.bandRects[0].first!.width;
    }

    /// A chart of bars alone transposes, so the slot the group is carved out of
    /// runs vertically and the band a bar occupies is its height. Reading
    /// `width` there would return the bar's length instead.
    double barBand(VarietySeries series) {
      final VarietyCartesianGeometry geometry =
          build(series: <VarietySeries>[series]);
      return geometry.bandRects[0].first!.height;
    }

    test('a column leaves the declared share of its width empty', () {
      final double packed = columnWidth(VarietyColumnSeries(data: monthly()));
      final double spaced = columnWidth(
        VarietyColumnSeries(data: monthly(), spacing: 0.5),
      );
      expect(packed, greaterThan(0));
      // The gap is taken off the width, not added beside it, so the group
      // still fits in the slot it was given.
      expect(spaced, closeTo(packed / 2, 0.001));
    });

    test('bars read the same setting', () {
      final double packed = barBand(VarietyBarSeries(data: monthly()));
      final double spaced = barBand(
        VarietyBarSeries(data: monthly(), spacing: 0.25),
      );
      expect(packed, greaterThan(0));
      expect(spaced, closeTo(packed * 0.75, 0.001));
    });

    test('the default leaves every rectangle at its old width', () {
      // Bands are shared between the column-like series, so a series that
      // never mentions spacing has to keep widthFactor as its only input.
      final double declared = columnWidth(
        VarietyColumnSeries(data: monthly(), spacing: 0),
      );
      final double omitted = columnWidth(VarietyColumnSeries(data: monthly()));
      expect(omitted, closeTo(declared, 0.0001));
    });

    test('a spacing above one collapses rather than mirrors', () {
      final double width = columnWidth(
        VarietyColumnSeries(data: monthly(), spacing: 4),
      );
      expect(width, 0);
    });
  });

  group('candles', () {
    List<VarietyChartData> risingThenFalling() => const <VarietyChartData>[
          // Close above open: rising.
          VarietyChartData(1, 0, open: 100, high: 112, low: 98, close: 110),
          // Close below open: falling.
          VarietyChartData(2, 0, open: 110, high: 114, low: 96, close: 99),
        ];

    List<VarietyRectsElement> bodies(VarietyCandleSeries series) => build(
          series: <VarietySeries>[series],
        ).elements.whereType<VarietyRectsElement>().toList();

    test('a rising candle is filled unless the series says otherwise', () {
      final List<VarietyRectsElement> solid = bodies(
        VarietyCandleSeries(data: risingThenFalling()),
      );
      final List<VarietyRectsElement> hollow = bodies(
        VarietyCandleSeries(
          data: risingThenFalling(),
          enableSolidCandles: false,
        ),
      );
      expect(solid, hasLength(2));
      expect(hollow, hasLength(2));
      expect(solid[0].color, isNot(const Color(0x00000000)));
      expect(hollow[0].color, const Color(0x00000000));
      // The outline still carries the colour, so a hollow candle is visible.
      expect(hollow[0].border, isNotNull);
      expect(hollow[0].borderWidth, greaterThan(0));
      // Falling candles stay filled both ways, which is what keeps a dense
      // chart readable.
      expect(hollow[1].color, isNot(const Color(0x00000000)));
      expect(hollow[1].color, solid[1].color);
    });

    test('a flat session is drawn when the indication is on', () {
      const List<VarietyChartData> flat = <VarietyChartData>[
        // All four prices equal: no body to draw.
        VarietyChartData(1, 0, open: 100, high: 100, low: 100, close: 100),
      ];
      List<VarietyElement> elements({required bool indication}) => build(
            series: <VarietySeries>[
              VarietyCandleSeries(
                data: flat,
                showIndicationForSameValues: indication,
              ),
            ],
          ).elements;

      final List<VarietyElement> without = elements(indication: false);
      final List<VarietyElement> with_ = elements(indication: true);
      expect(
          without.whereType<VarietyRectsElement>().first.rects.single, isEmpty);
      expect(
        with_.whereType<VarietySegmentsElement>(),
        isNotEmpty,
        reason: 'a flat candle needs a mark or it disappears from the chart',
      );
      // The mark stands for the candle, so no zero-height rectangle joins it.
      expect(with_.whereType<VarietyRectsElement>(), isEmpty);
    });
  });
}

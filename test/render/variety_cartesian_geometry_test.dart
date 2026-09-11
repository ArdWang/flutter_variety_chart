import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../test_helpers.dart';

VarietyCartesianGeometry buildGeometry({
  required List<VarietySeries> series,
  VarietyAxis xAxis = const VarietyAxis(type: VarietyAxisType.category),
  VarietyAxis yAxis = const VarietyAxis(type: VarietyAxisType.numeric),
  double progress = 1,
  (double, double)? visibleXRange,
}) {
  return VarietyCartesianGeometry(
    series: series,
    xAxis: xAxis,
    yAxis: yAxis,
    plotRect: defaultPlotRect,
    progress: progress,
    visibleXRange: visibleXRange,
  );
}

void main() {
  group('category axis', () {
    test('collects categories in first-seen order', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[VarietyColumnSeries(name: 'A', data: monthly())],
      );
      expect(geometry.categories, <String>['Jan', 'Feb', 'Mar', 'Apr']);
      expect(geometry.xAxisType, VarietyAxisType.category);
    });

    test('pads the value range to include zero for banded series', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[VarietyColumnSeries(name: 'A', data: monthly())],
      );
      expect(geometry.yMinimum, lessThanOrEqualTo(0));
      expect(geometry.yMaximum, greaterThanOrEqualTo(55));
    });

    test('spaces category slots evenly', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[VarietyColumnSeries(name: 'A', data: monthly())],
      );
      expect(geometry.slotCenters.length, 4);
      final double firstGap = geometry.slotCenters[1] - geometry.slotCenters[0];
      final double secondGap = geometry.slotCenters[2] - geometry.slotCenters[1];
      expect(firstGap, closeTo(secondGap, 0.001));
    });

    test('emits one banded rectangle per point', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[VarietyColumnSeries(name: 'A', data: monthly())],
      );
      expect(geometry.bandRects.first.length, 4);
      expect(geometry.bandRects.first.every((Rect? rect) => rect != null), isTrue);
    });

    test('hit tests inside a column rectangle', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[VarietyColumnSeries(name: 'A', data: monthly())],
      );
      final Rect rect = geometry.bandRects.first.first!;
      final VarietyHitResult? hit = geometry.hitTest(rect.center);
      expect(hit, isNotNull);
      expect(hit!.pointIndex, 0);
      expect(hit.point.y, 32);
    });

    test('collapses geometry at progress zero', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[VarietyColumnSeries(name: 'A', data: monthly())],
        progress: 0,
      );
      expect(geometry.bandRects.first.first!.height, lessThan(0.01));
    });

    test('reports every series at the active slot', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[
          VarietyLineSeries(name: 'A', data: monthly()),
          VarietyLineSeries(name: 'B', data: monthly()),
        ],
      );
      final List<VarietyHitResult> hits =
          geometry.hitsAtSlot(Offset(geometry.slotCenters[2], 100));
      expect(hits.length, 2);
      expect(hits.first.pointIndex, 2);
    });
  });

  group('numeric axis', () {
    test('infers the axis type from numeric values', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[
          VarietyLineSeries(
            data: const <VarietyChartData>[
              VarietyChartData(0, 10),
              VarietyChartData(5, 30),
              VarietyChartData(10, 20),
            ],
          ),
        ],
        xAxis: const VarietyAxis(),
      );
      expect(geometry.xAxisType, VarietyAxisType.numeric);
      expect(geometry.xMaximum, greaterThanOrEqualTo(10));
    });

    test('honours an explicit zoom window', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[
          VarietyLineSeries(
            data: const <VarietyChartData>[
              VarietyChartData(0, 10),
              VarietyChartData(100, 30),
            ],
          ),
        ],
        xAxis: const VarietyAxis(type: VarietyAxisType.numeric, minimum: 0, maximum: 100),
        visibleXRange: (25, 75),
      );
      expect(geometry.xMinimum, 25);
      expect(geometry.xMaximum, 75);
    });
  });

  group('date time axis', () {
    test('builds ticks and formats them', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[
          VarietyLineSeries(
            data: <VarietyChartData>[
              VarietyChartData(DateTime(2026, 1, 1), 10),
              VarietyChartData(DateTime(2026, 1, 20), 30),
              VarietyChartData(DateTime(2026, 2, 15), 22),
            ],
          ),
        ],
        xAxis: const VarietyAxis(type: VarietyAxisType.dateTime, dateFormat: 'dd MMM'),
      );
      expect(geometry.xAxisType, VarietyAxisType.dateTime);
      expect(geometry.dateTimeTicks, isNotEmpty);
      expect(geometry.dateTimeTickLabel(DateTime(2026, 1, 5)), '05 Jan');
    });
  });

  group('logarithmic axis', () {
    test('produces power-of-base ticks', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[
          VarietyColumnSeries(
            data: const <VarietyChartData>[
              VarietyChartData(1, 2),
              VarietyChartData(2, 2000),
            ],
          ),
        ],
        yAxis: const VarietyAxis(type: VarietyAxisType.logarithmic),
      );
      final List<double> ticks = geometry.yTicks;
      expect(ticks, isNotEmpty);
      expect(ticks.first, 1);
      expect(ticks.any((double tick) => tick == 100 || tick == 1000), isTrue);
    });
  });

  group('stacking', () {
    test('stacks normal series cumulatively', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[
          VarietyColumnSeries(
            stackMode: VarietyStackingMode.normal,
            data: const <VarietyChartData>[
              VarietyChartData('A', 10),
              VarietyChartData('B', 20),
            ],
          ),
          VarietyColumnSeries(
            stackMode: VarietyStackingMode.normal,
            data: const <VarietyChartData>[
              VarietyChartData('A', 15),
              VarietyChartData('B', 5),
            ],
          ),
        ],
      );
      expect(geometry.topValue(1, 0), closeTo(25, 0.001));
      expect(geometry.baseValue(1, 0), closeTo(10, 0.001));
    });

    test('normalises percent stacked series to a 0-100 range', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[
          VarietyColumnSeries(
            stackMode: VarietyStackingMode.percent100,
            data: const <VarietyChartData>[
              VarietyChartData('A', 30),
              VarietyChartData('B', 10),
            ],
          ),
          VarietyColumnSeries(
            stackMode: VarietyStackingMode.percent100,
            data: const <VarietyChartData>[
              VarietyChartData('A', 70),
              VarietyChartData('B', 90),
            ],
          ),
        ],
      );
      expect(geometry.yMinimum, 0);
      expect(geometry.yMaximum, 100);
      expect(geometry.topValue(0, 0), closeTo(30, 0.001));
      expect(geometry.topValue(1, 0), closeTo(100, 0.001));
    });
  });

  group('derived series data', () {
    test('bins raw samples for a histogram series', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[
          VarietyHistogramSeries(
            binCount: 4,
            data: const <VarietyChartData>[
              VarietyChartData(0, 1),
              VarietyChartData(1, 2),
              VarietyChartData(2, 2),
              VarietyChartData(3, 3),
              VarietyChartData(4, 4),
              VarietyChartData(5, 5),
            ],
          ),
        ],
        xAxis: const VarietyAxis(type: VarietyAxisType.numeric),
      );
      expect(geometry.resolvedData.first.length, 4);
    });

    test('accumulates deltas into a running waterfall total', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[
          VarietyWaterfallSeries(
            data: const <VarietyChartData>[
              VarietyChartData('Start', 100),
              VarietyChartData('Gain', 40),
              VarietyChartData('Loss', -25),
            ],
          ),
        ],
      );
      final List<VarietyChartData> resolved = geometry.resolvedData.first;
      expect(resolved.length, 4);
      expect(resolved.last.closeValue, closeTo(115, 0.001));
    });
  });

  group('transposed bar layout', () {
    VarietyCartesianGeometry barGeometry() => buildGeometry(
          series: <VarietySeries>[VarietyBarSeries(name: 'A', data: monthly())],
        );

    test('transposes when every series is a bar series', () {
      expect(barGeometry().transposed, isTrue);
    });

    test('does not transpose when another series kind is present', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[
          VarietyBarSeries(name: 'A', data: monthly()),
          VarietyLineSeries(name: 'B', data: monthly()),
        ],
      );
      expect(geometry.transposed, isFalse);
    });

    test('puts values on the horizontal axis and categories on the vertical one', () {
      final VarietyCartesianGeometry geometry = barGeometry();
      expect(geometry.xAxisType, VarietyAxisType.numeric);
      expect(geometry.yAxisType, VarietyAxisType.category);
      expect(geometry.categories, <String>['Jan', 'Feb', 'Mar', 'Apr']);
      expect(geometry.secondaryTickLabel(0), 'Jan');
      expect(geometry.secondaryTickLabel(3), 'Apr');
    });

    test('keeps every bar inside the plot rectangle', () {
      final VarietyCartesianGeometry geometry = barGeometry();
      for (final Rect? rect in geometry.bandRects.first) {
        expect(rect, isNotNull);
        expect(rect!.top, greaterThanOrEqualTo(defaultPlotRect.top - 0.01));
        expect(rect.bottom, lessThanOrEqualTo(defaultPlotRect.bottom + 0.01));
        expect(rect.left, greaterThanOrEqualTo(defaultPlotRect.left - 0.01));
        expect(rect.right, lessThanOrEqualTo(defaultPlotRect.right + 0.01));
      }
    });

    test('bar length tracks the value', () {
      final VarietyCartesianGeometry geometry = barGeometry();
      final Rect first = geometry.bandRects.first[0]!;
      final Rect second = geometry.bandRects.first[1]!;
      // April (55) is the largest value and January (32) the smallest here.
      expect(geometry.bandRects.first[3]!.width, greaterThan(first.width));
      expect(second.width, greaterThan(first.width));
    });

    test('keeps the original data point in hit results', () {
      final VarietyCartesianGeometry geometry = barGeometry();
      final Rect rect = geometry.bandRects.first[1]!;
      final VarietyHitResult? hit = geometry.hitTest(rect.center);
      expect(hit, isNotNull);
      expect(hit!.point.x, 'Feb');
      expect(hit.point.y, 48);
    });

    test('stacks transposed bars from the shared baseline', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[
          VarietyBarSeries(
            stackMode: VarietyStackingMode.normal,
            data: const <VarietyChartData>[
              VarietyChartData('A', 10),
              VarietyChartData('B', 20),
            ],
          ),
          VarietyBarSeries(
            stackMode: VarietyStackingMode.normal,
            data: const <VarietyChartData>[
              VarietyChartData('A', 15),
              VarietyChartData('B', 5),
            ],
          ),
        ],
      );
      expect(geometry.topValue(1, 0), closeTo(25, 0.001));
    });
  });

  group('elements', () {
    test('produces at least one element per visible series', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        series: <VarietySeries>[
          VarietyColumnSeries(name: 'A', data: monthly()),
          VarietyLineSeries(name: 'B', data: monthly()),
        ],
      );
      expect(geometry.elements, isNotEmpty);
    });

    test('adds a trendline element when one is requested', () {
      final VarietyCartesianGeometry withoutTrend = buildGeometry(
        series: <VarietySeries>[VarietyScatterSeries(name: 'A', data: monthly())],
        xAxis: const VarietyAxis(type: VarietyAxisType.numeric),
      );
      final VarietyCartesianGeometry withTrend = buildGeometry(
        series: <VarietySeries>[
          VarietyScatterSeries(
            name: 'A',
            data: monthly(),
            trendlines: const <VarietyTrendline>[VarietyTrendline()],
          ),
        ],
        xAxis: const VarietyAxis(type: VarietyAxisType.numeric),
      );
      expect(withTrend.elements.length, greaterThan(withoutTrend.elements.length));
    });
  });
}

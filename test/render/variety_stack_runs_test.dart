import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

/// A stacked column series carrying [data].
VarietyColumnSeries stacked(
  List<VarietyChartData> data, {
  VarietyStackingMode mode = VarietyStackingMode.normal,
  String? yAxisName,
}) =>
    VarietyColumnSeries(
      stackMode: mode,
      yAxisName: yAxisName,
      data: data,
    );

/// An unstacked column series carrying [data].
VarietyColumnSeries plain(List<VarietyChartData> data, {String? yAxisName}) =>
    VarietyColumnSeries(yAxisName: yAxisName, data: data);

VarietyCartesianGeometry build(
  List<VarietySeries> series, {
  List<VarietyAxis> secondaryYAxes = const <VarietyAxis>[],
}) =>
    VarietyCartesianGeometry(
      series: series,
      xAxis: const VarietyAxis(type: VarietyAxisType.category),
      yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
      secondaryYAxes: secondaryYAxes,
      plotRect: defaultPlotRect,
      progress: 1,
    );

/// A pair of readings both series share.
List<VarietyChartData> two(double first, double second) => <VarietyChartData>[
      VarietyChartData('A', first),
      VarietyChartData('B', second),
    ];

void main() {
  // The running totals a stack reads are summed once per axis now instead of
  // being walked again for every point. These pin the numbers either way.
  group('stacked running totals', () {
    test('three series add up row by row', () {
      final VarietyCartesianGeometry geometry = build(<VarietySeries>[
        stacked(two(10, 20)),
        stacked(two(5, 1)),
        stacked(two(2, 4)),
      ]);
      expect(geometry.baseValue(0, 0), closeTo(0, 1e-9));
      expect(geometry.topValue(0, 0), closeTo(10, 1e-9));
      expect(geometry.baseValue(1, 0), closeTo(10, 1e-9));
      expect(geometry.topValue(1, 0), closeTo(15, 1e-9));
      expect(geometry.baseValue(2, 0), closeTo(15, 1e-9));
      expect(geometry.topValue(2, 0), closeTo(17, 1e-9));
      expect(geometry.baseValue(2, 1), closeTo(21, 1e-9));
      expect(geometry.topValue(2, 1), closeTo(25, 1e-9));
    });

    test('the stack reaches the drawn points', () {
      final VarietyCartesianGeometry geometry = build(<VarietySeries>[
        stacked(two(10, 20)),
        stacked(two(5, 1)),
      ]);
      // A larger value sits higher on the canvas, so the second series of the
      // stack is drawn above the first one at both slots.
      for (int p = 0; p < 2; p++) {
        expect(
          geometry.pointPositions[1][p].dy,
          lessThan(geometry.pointPositions[0][p].dy),
          reason: 'slot $p did not stack',
        );
      }
    });

    test('a short series only adds where it has a reading', () {
      final VarietyCartesianGeometry geometry = build(<VarietySeries>[
        stacked(const <VarietyChartData>[
          VarietyChartData('A', 10),
          VarietyChartData('B', 20),
          VarietyChartData('C', 30),
        ]),
        stacked(const <VarietyChartData>[
          VarietyChartData('A', 1),
          VarietyChartData('B', 2),
        ]),
        stacked(const <VarietyChartData>[
          VarietyChartData('A', 100),
        ]),
      ]);
      // Only the first series reaches the third slot, so the stack there is as
      // tall as that one reading and every row above it carries the same total.
      expect(geometry.baseValue(0, 2), closeTo(0, 1e-9));
      expect(geometry.topValue(0, 2), closeTo(30, 1e-9));
      expect(geometry.baseValue(1, 2), closeTo(30, 1e-9));
      expect(geometry.baseValue(2, 2), closeTo(30, 1e-9));
      // A series with no reading in a slot has no top of its own there.
      expect(geometry.topValue(1, 2), closeTo(0, 1e-9));
      expect(geometry.topValue(2, 2), closeTo(0, 1e-9));
      // The earlier slots carry every series that gets there.
      expect(geometry.baseValue(2, 0), closeTo(11, 1e-9));
      expect(geometry.topValue(2, 0), closeTo(111, 1e-9));
      expect(geometry.baseValue(2, 1), closeTo(22, 1e-9));
      expect(geometry.topValue(2, 1), closeTo(22, 1e-9));
    });

    test('a series that is not stacked sits out of the stack', () {
      final VarietyCartesianGeometry geometry = build(<VarietySeries>[
        stacked(two(10, 20)),
        plain(two(1000, 2)),
        stacked(two(5, 3)),
      ]);
      expect(geometry.baseValue(1, 0), closeTo(0, 1e-9));
      expect(geometry.topValue(1, 0), closeTo(1000, 1e-9));
      expect(geometry.baseValue(2, 0), closeTo(10, 1e-9));
      expect(geometry.topValue(2, 0), closeTo(15, 1e-9));
    });

    test('each value axis accumulates its own stack', () {
      final VarietyCartesianGeometry geometry = build(
        <VarietySeries>[
          stacked(two(10, 20)),
          stacked(two(100, 200), yAxisName: 'rate'),
          stacked(two(5, 3)),
        ],
        secondaryYAxes: const <VarietyAxis>[
          VarietyAxis(type: VarietyAxisType.numeric, name: 'rate'),
        ],
      );
      expect(geometry.axisIndexOf(1), 1);
      // The series on the extra axis contributes to neither of the others.
      expect(geometry.topValue(1, 0), closeTo(100, 1e-9));
      expect(geometry.baseValue(1, 0), closeTo(0, 1e-9));
      expect(geometry.baseValue(2, 0), closeTo(10, 1e-9));
      expect(geometry.topValue(2, 0), closeTo(15, 1e-9));
    });

    test('negative readings subtract from a plain stack', () {
      final VarietyCartesianGeometry geometry = build(<VarietySeries>[
        stacked(two(10, 20)),
        stacked(two(-5, -10)),
      ]);
      expect(geometry.baseValue(1, 0), closeTo(10, 1e-9));
      expect(geometry.topValue(1, 0), closeTo(5, 1e-9));
      expect(geometry.topValue(1, 1), closeTo(10, 1e-9));
    });
  });

  group('percentage stacks', () {
    test('a row divides by the total of its own axis', () {
      final VarietyCartesianGeometry geometry = build(<VarietySeries>[
        stacked(two(30, 10), mode: VarietyStackingMode.percent100),
        stacked(two(70, 90), mode: VarietyStackingMode.percent100),
      ]);
      expect(geometry.baseValue(0, 0), closeTo(0, 1e-9));
      expect(geometry.topValue(0, 0), closeTo(30, 1e-9));
      expect(geometry.baseValue(1, 0), closeTo(30, 1e-9));
      expect(geometry.topValue(1, 0), closeTo(100, 1e-9));
      expect(geometry.baseValue(1, 1), closeTo(10, 1e-9));
      expect(geometry.topValue(1, 1), closeTo(100, 1e-9));
    });

    test('every percentage series on an axis shares one total', () {
      final VarietyCartesianGeometry geometry = build(<VarietySeries>[
        stacked(two(30, 10), mode: VarietyStackingMode.percent100),
        stacked(two(70, 30), mode: VarietyStackingMode.percent100),
        stacked(two(20, 20), mode: VarietyStackingMode.percent100),
        stacked(two(80, 40), mode: VarietyStackingMode.percent100),
      ]);
      // The four readings add up to 200, so a fifth of the row is 10%.
      expect(geometry.baseValue(2, 0), closeTo(50, 1e-9));
      expect(geometry.topValue(2, 0), closeTo(60, 1e-9));
      expect(geometry.baseValue(3, 0), closeTo(60, 1e-9));
      expect(geometry.topValue(3, 0), closeTo(100, 1e-9));
    });

    test('a row with nothing to divide by reads as zero', () {
      final VarietyCartesianGeometry geometry = build(<VarietySeries>[
        stacked(const <VarietyChartData>[
          VarietyChartData('A', 0),
          VarietyChartData('B', 30),
        ], mode: VarietyStackingMode.percent100),
        stacked(const <VarietyChartData>[
          VarietyChartData('A', 0),
          VarietyChartData('B', 70),
        ], mode: VarietyStackingMode.percent100),
      ]);
      expect(geometry.baseValue(1, 0), closeTo(0, 1e-9));
      expect(geometry.topValue(1, 0), closeTo(0, 1e-9));
      expect(geometry.baseValue(1, 1), closeTo(30, 1e-9));
      expect(geometry.topValue(1, 1), closeTo(100, 1e-9));
    });

    test('a negative reading contributes nothing to the total', () {
      final VarietyCartesianGeometry geometry = build(<VarietySeries>[
        stacked(two(-50, 0), mode: VarietyStackingMode.percent100),
        stacked(two(50, 0), mode: VarietyStackingMode.percent100),
      ]);
      // The total is 50 rather than 0, so the positive row takes all of it.
      expect(geometry.baseValue(1, 0), closeTo(0, 1e-9));
      expect(geometry.topValue(1, 0), closeTo(100, 1e-9));
    });
  });
}

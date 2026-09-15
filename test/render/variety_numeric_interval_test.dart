import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../test_helpers.dart';

/// Guards [VarietyCartesianGeometry.xNumericTicks].
///
/// The numeric x axis used to split `[minimum, maximum]` into `desiredIntervals`
/// equal parts and ignore `VarietyAxis.interval` completely, so a caller with
/// whole-number x values got ticks between the points — and the zoom window,
/// whose bounds are never whole, moved every tick off the value it belonged to.
VarietyCartesianGeometry buildGeometry({
  required VarietyAxis xAxis,
  (double, double)? visibleXRange,
}) {
  return VarietyCartesianGeometry(
    series: <VarietySeries>[
      VarietyLineSeries(
        data: <VarietyChartData>[
          for (int i = 0; i < 58; i++) VarietyChartData(i.toDouble(), 20.0),
        ],
      ),
    ],
    xAxis: xAxis,
    yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
    plotRect: defaultPlotRect,
    progress: 1,
    visibleXRange: visibleXRange,
  );
}

/// 58 readings on indices 0..57, axes splitting them into three steps.
VarietyAxis indexedAxis({double? interval = 19}) => VarietyAxis(
      type: VarietyAxisType.numeric,
      minimum: 0,
      maximum: 57,
      interval: interval,
      desiredIntervals: 3,
    );

void main() {
  group('without an interval', () {
    test('splits the visible span into equal parts', () {
      final VarietyCartesianGeometry geometry =
          buildGeometry(xAxis: indexedAxis(interval: null));

      expect(geometry.xNumericTicks, <double>[0, 19, 38, 57]);
    });

    test('still splits the zoom window when one is given', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        xAxis: indexedAxis(interval: null),
        visibleXRange: (0, 30),
      );

      expect(geometry.xNumericTicks, <double>[0, 10, 20, 30]);
    });
  });

  group('with an interval', () {
    test('lays the ticks on the interval grid', () {
      final VarietyCartesianGeometry geometry =
          buildGeometry(xAxis: indexedAxis());

      expect(geometry.xNumericTicks, <double>[0, 19, 38, 57]);
    });

    test('anchors the grid on the pre-zoom minimum', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        xAxis: indexedAxis(),
        visibleXRange: (18.37, 29.82),
      );

      expect(geometry.xMinimum, closeTo(18.37, 1e-9));
      expect(geometry.xMaximum, closeTo(29.82, 1e-9));
      expect(geometry.xTickOrigin, 0);
    });

    test('keeps the grid values through a fractional zoom window', () {
      // A pinch produces a window like this: neither bound is whole. The ticks
      // must stay on the caller's grid — whole numbers — instead of being
      // recomputed from the window, which is what used to move them off the
      // data points.
      final VarietyCartesianGeometry geometry = buildGeometry(
        xAxis: indexedAxis(),
        visibleXRange: (18.37, 29.82),
      );

      // The window is narrower than a step and a half, so the grid refines to 1;
      // every tick is still a whole index.
      expect(geometry.xNumericTicks.first, 19);
      expect(geometry.xNumericTicks.last, 29);
      expect(
        geometry.xNumericTicks.every((double t) => t == t.roundToDouble()),
        isTrue,
      );
    });

    test('keeps the exact grid while it still fits twice into the window', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        xAxis: indexedAxis(),
        visibleXRange: (10.37, 40.82),
      );

      // Span 30.45 holds 19 twice, so the caller's step is kept as it is.
      expect(geometry.xNumericTicks, <double>[19, 38]);
    });

    test('shows only the grid values inside the window', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        xAxis: indexedAxis(),
        visibleXRange: (0, 40),
      );

      expect(geometry.xNumericTicks, <double>[0, 19, 38]);
    });

    test('refines the step when a window is narrower than one step', () {
      // 19 does not fit twice into a span of 8, and an axis with no ticks at all
      // is worse than a denser grid, so the step drops to 1.
      final VarietyCartesianGeometry geometry = buildGeometry(
        xAxis: indexedAxis(),
        visibleXRange: (20, 28),
      );

      expect(geometry.xNumericTicks.first, 20);
      expect(geometry.xNumericTicks.last, 28);
      expect(geometry.xNumericTicks, hasLength(9));
    });

    test('halves an even step before dropping to one', () {
      final VarietyCartesianGeometry geometry = buildGeometry(
        xAxis: indexedAxis(interval: 20),
        visibleXRange: (20, 28),
      );

      // 20 -> 10 -> 5; 5 is the first step that fits twice into a span of 8.
      expect(geometry.xNumericTicks, <double>[20, 25]);
    });

    test('every tick stays on a whole index at every zoom level', () {
      // This is what the app depends on: x is the point index, so a tick is only
      // on a reading when its value is whole.
      const List<(double, double)> windows = <(double, double)>[
        (0, 57),
        (18.37, 29.82),
        (20, 28),
        (5.5, 33.25),
        (41.2, 57),
        (0, 6),
      ];

      for (final (double, double) window in windows) {
        final VarietyCartesianGeometry geometry = buildGeometry(
          xAxis: indexedAxis(),
          visibleXRange: window,
        );
        expect(geometry.xNumericTicks, isNotEmpty, reason: 'window $window');
        for (final double tick in geometry.xNumericTicks) {
          expect(
            tick,
            tick.roundToDouble(),
            reason: 'window $window produced a tick at $tick',
          );
        }
      }
    });
  });
}

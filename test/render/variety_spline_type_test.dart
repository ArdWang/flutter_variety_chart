import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_test/flutter_test.dart';

const Rect plotRect = Rect.fromLTWH(40, 10, 320, 220);

/// A step-shaped series, which is where the interpolation kinds visibly differ.
const List<VarietyChartData> steps = <VarietyChartData>[
  VarietyChartData(0, 0),
  VarietyChartData(1, 0),
  VarietyChartData(2, 100),
  VarietyChartData(3, 100),
];

VarietyCartesianGeometry build(VarietySplineType type) {
  return VarietyCartesianGeometry(
    series: <VarietySeries>[
      VarietyLineSeries(
        data: steps,
        lineStyle: VarietyLineStyle.curved,
        splineType: type,
      ),
    ],
    xAxis: VarietyAxis(type: VarietyAxisType.numeric),
    yAxis: VarietyAxis(type: VarietyAxisType.numeric),
    plotRect: plotRect,
    progress: 1,
  );
}

/// The stroke the line series produced.
Rect curveBounds(VarietyCartesianGeometry geometry) {
  final List<VarietyPathElement> paths =
      geometry.elements.whereType<VarietyPathElement>().toList();
  expect(paths, isNotEmpty, reason: 'no path was built');
  return paths.first.path.getBounds();
}

/// The box the data points themselves occupy.
Rect pointBounds(VarietyCartesianGeometry geometry) {
  double top = double.infinity;
  double bottom = double.negativeInfinity;
  for (final Offset p in geometry.pointPositions[0]) {
    top = top < p.dy ? top : p.dy;
    bottom = bottom > p.dy ? bottom : p.dy;
  }
  return Rect.fromLTRB(0, top, 0, bottom);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('spline interpolation', () {
    test('every kind reaches the same points', () {
      // All four are interpolation, not approximation, so they pass through
      // every data point and share its box.
      for (final VarietySplineType type in VarietySplineType.values) {
        final VarietyCartesianGeometry geometry = build(type);
        final Rect curve = curveBounds(geometry);
        final Rect points = pointBounds(geometry);
        expect(curve.top, lessThanOrEqualTo(points.top + 0.01),
            reason: '$type');
        expect(curve.bottom, greaterThanOrEqualTo(points.bottom - 0.01),
            reason: '$type');
      }
    });

    test('monotonic never overshoots the points it runs through', () {
      final VarietyCartesianGeometry geometry =
          build(VarietySplineType.monotonic);
      final Rect curve = curveBounds(geometry);
      final Rect points = pointBounds(geometry);
      expect(curve.top, greaterThanOrEqualTo(points.top - 0.01));
      expect(curve.bottom, lessThanOrEqualTo(points.bottom + 0.01));
    });

    test('cardinal does overshoot a step, which is the point of the choice',
        () {
      final VarietyCartesianGeometry geometry =
          build(VarietySplineType.cardinal);
      final Rect curve = curveBounds(geometry);
      final Rect points = pointBounds(geometry);
      expect(curve.top, lessThan(points.top - 1));
    });

    test('the four kinds are not all the same curve', () {
      final Set<String> shapes = <String>{};
      for (final VarietySplineType type in VarietySplineType.values) {
        shapes.add(curveBounds(build(type)).toString());
      }
      expect(shapes.length, greaterThan(1),
          reason: 'splineType is being ignored again');
    });

    test('a straight line ignores the spline kind', () {
      final VarietyCartesianGeometry a = VarietyCartesianGeometry(
        series: <VarietySeries>[
          VarietyLineSeries(
            data: steps,
            lineStyle: VarietyLineStyle.straight,
            splineType: VarietySplineType.cardinal,
          ),
        ],
        xAxis: VarietyAxis(type: VarietyAxisType.numeric),
        yAxis: VarietyAxis(type: VarietyAxisType.numeric),
        plotRect: plotRect,
        progress: 1,
      );
      final VarietyCartesianGeometry b = VarietyCartesianGeometry(
        series: <VarietySeries>[
          VarietyLineSeries(
            data: steps,
            lineStyle: VarietyLineStyle.straight,
            splineType: VarietySplineType.monotonic,
          ),
        ],
        xAxis: VarietyAxis(type: VarietyAxisType.numeric),
        yAxis: VarietyAxis(type: VarietyAxisType.numeric),
        plotRect: plotRect,
        progress: 1,
      );
      expect(curveBounds(a), curveBounds(b));
    });

    test('a series without its own splineType defaults to cardinal', () {
      // The getter on the base class is what lets the renderer ask every
      // series for one; a column has no spline of its own.
      const VarietyColumnSeries column = VarietyColumnSeries(
        data: <VarietyChartData>[VarietyChartData('Jan', 1)],
      );
      expect(column.splineType, VarietySplineType.cardinal);
    });
  });
}

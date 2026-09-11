import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

const List<VarietyChartData> stages = <VarietyChartData>[
  VarietyChartData('Visited', 100),
  VarietyChartData('Cart', 60),
  VarietyChartData('Buy', 20),
];

VarietyFunnelGeometry build({
  required VarietySeries series,
  bool isPyramid = false,
  double progress = 1,
}) {
  return VarietyFunnelGeometry(
    series: series,
    plotRect: const Rect.fromLTWH(0, 0, 200, 300),
    progress: progress,
    isPyramid: isPyramid,
  );
}

void main() {
  group('funnel', () {
    test('produces one segment per point', () {
      final VarietyFunnelGeometry geometry =
          build(series: const VarietyFunnelSeries(data: stages));
      expect(geometry.segments.length, 3);
    });

    test('widens towards the widest value', () {
      final VarietyFunnelGeometry geometry =
          build(series: const VarietyFunnelSeries(data: stages));
      final double first =
          geometry.segments.first.topRight.dx - geometry.segments.first.topLeft.dx;
      final double last =
          geometry.segments.last.bottomRight.dx - geometry.segments.last.bottomLeft.dx;
      expect(first, greaterThan(last));
    });

    test('collapses widths at progress zero', () {
      final VarietyFunnelGeometry geometry =
          build(series: const VarietyFunnelSeries(data: stages), progress: 0);
      final VarietyFunnelSegment first = geometry.segments.first;
      expect((first.topRight.dx - first.topLeft.dx).abs(), lessThan(0.01));
    });

    test('offsets an exploded segment', () {
      final VarietyFunnelGeometry geometry = build(
        series: const VarietyFunnelSeries(
          explodeIndexes: <int>[1],
          explodeOffset: 20,
          data: stages,
        ),
      );
      expect(geometry.segments[1].center.dx, greaterThan(100));
      expect(geometry.segments[0].center.dx, closeTo(100, 0.001));
    });

    test('hit tests inside a segment', () {
      final VarietyFunnelGeometry geometry =
          build(series: const VarietyFunnelSeries(data: stages));
      final VarietyHitResult? hit = geometry.hitTest(geometry.segments[1].center);
      expect(hit, isNotNull);
      expect(hit!.pointIndex, 1);
    });

    test('produces drawable elements', () {
      final VarietyFunnelGeometry geometry =
          build(series: const VarietyFunnelSeries(data: stages));
      expect(geometry.elements.length, greaterThanOrEqualTo(3));
    });
  });

  group('pyramid', () {
    test('orders segments from wide to narrow', () {
      final VarietyFunnelGeometry geometry = build(
        series: const VarietyPyramidSeries(data: stages),
        isPyramid: true,
      );
      final double first =
          geometry.segments.first.topRight.dx - geometry.segments.first.topLeft.dx;
      final double last =
          geometry.segments.last.bottomRight.dx - geometry.segments.last.bottomLeft.dx;
      expect(first, greaterThan(last));
    });

    test('supports a surface area width mode', () {
      final VarietyFunnelGeometry linear = build(
        series: const VarietyPyramidSeries(data: stages),
        isPyramid: true,
      );
      final VarietyFunnelGeometry surface = build(
        series: const VarietyPyramidSeries(
          mode: VarietyPyramidMode.surface,
          data: stages,
        ),
        isPyramid: true,
      );
      final double linearWidth =
          linear.segments.last.bottomRight.dx - linear.segments.last.bottomLeft.dx;
      final double surfaceWidth =
          surface.segments.last.bottomRight.dx - surface.segments.last.bottomLeft.dx;
      expect(surfaceWidth, greaterThan(linearWidth));
    });
  });
}

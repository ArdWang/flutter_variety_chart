import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_test/flutter_test.dart';

const Rect plotRect = Rect.fromLTWH(40, 10, 320, 220);

/// Two series that carry their own x values, as time stamped data usually
/// does. Series 0 sits at the ends, series 1 in the middle.
List<VarietySeries> staggered() => <VarietySeries>[
      VarietyLineSeries(name: 'A', data: <VarietyChartData>[
        VarietyChartData(DateTime(2026, 9, 15, 11, 30, 0), 10),
        VarietyChartData(DateTime(2026, 9, 15, 11, 30, 50), 20),
      ]),
      VarietyLineSeries(name: 'B', data: <VarietyChartData>[
        VarietyChartData(DateTime(2026, 9, 15, 11, 30, 28), 12),
        VarietyChartData(DateTime(2026, 9, 15, 11, 31, 0), 22),
      ]),
    ];

VarietyCartesianGeometry build(
  List<VarietySeries> series, {
  VarietyAxis xAxis = const VarietyAxis(type: VarietyAxisType.dateTime),
}) {
  return VarietyCartesianGeometry(
    series: series,
    xAxis: xAxis,
    yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
    plotRect: plotRect,
    progress: 1,
  );
}

void main() {
  group('trackball slot', () {
    test('follows the point the user aimed at, not the first series', () {
      final VarietyCartesianGeometry geometry = build(staggered());
      final double aimed = geometry.pointPositions[1][0].dx;
      final List<VarietyHitResult> hits =
          geometry.hitsAtSlot(Offset(aimed, plotRect.center.dy));

      expect(hits, isNotEmpty);
      // Series 0's nearest point lives far away; anchoring there is what made
      // the guide appear beside the touch.
      expect(
        geometry.pointPositions[0][1].dx,
        isNot(closeTo(aimed, 1)),
        reason: 'the fixture must keep the two series apart',
      );
      expect(hits.first.position.dx, closeTo(aimed, 0.01));
    });

    test('groups every series onto the guide by default', () {
      final VarietyCartesianGeometry geometry = build(staggered());
      final double aimed = geometry.pointPositions[1][0].dx;
      final List<VarietyHitResult> hits =
          geometry.hitsAtSlot(Offset(aimed, plotRect.center.dy));

      expect(hits.length, 2);
      for (final VarietyHitResult hit in hits) {
        expect(hit.position.dx, closeTo(aimed, 0.01));
      }
      // Each series still reports its own point.
      expect(hits[1].pointIndex, 0);
      expect(hits[0].pointIndex, 1);
    });

    test('floatAllPoints leaves every point on its own x', () {
      final VarietyCartesianGeometry geometry = build(staggered());
      final double aimed = geometry.pointPositions[1][0].dx;
      final List<VarietyHitResult> hits = geometry.hitsAtSlot(
        Offset(aimed, plotRect.center.dy),
        displayMode: VarietyTrackballDisplayMode.floatAllPoints,
      );

      expect(hits.length, 2);
      expect(
          hits[0].position.dx, closeTo(geometry.pointPositions[0][1].dx, 0.01));
      expect(hits[1].position.dx, closeTo(aimed, 0.01));
    });

    test('nearestPoint reports a single hit', () {
      final VarietyCartesianGeometry geometry = build(staggered());
      final double aimed = geometry.pointPositions[1][0].dx;
      final List<VarietyHitResult> hits = geometry.hitsAtSlot(
        Offset(aimed, plotRect.center.dy),
        displayMode: VarietyTrackballDisplayMode.nearestPoint,
      );

      expect(hits.length, 1);
      expect(hits.single.position.dx, closeTo(aimed, 0.01));
    });

    test('none reports nothing', () {
      final VarietyCartesianGeometry geometry = build(staggered());
      final List<VarietyHitResult> hits = geometry.hitsAtSlot(
        Offset(geometry.pointPositions[1][0].dx, plotRect.center.dy),
        displayMode: VarietyTrackballDisplayMode.none,
      );

      expect(hits, isEmpty);
    });

    test('a single series still lands on its own point', () {
      final VarietyCartesianGeometry geometry = build(<VarietySeries>[
        VarietyLineSeries(data: <VarietyChartData>[
          VarietyChartData(DateTime(2026, 9, 15, 11, 30, 0), 10),
          VarietyChartData(DateTime(2026, 9, 15, 11, 30, 28), 20),
          VarietyChartData(DateTime(2026, 9, 15, 11, 31, 0), 15),
        ]),
      ]);
      final double aimed = geometry.pointPositions[0][1].dx;
      final List<VarietyHitResult> hits =
          geometry.hitsAtSlot(Offset(aimed, plotRect.center.dy));

      expect(hits.length, 1);
      expect(hits.single.pointIndex, 1);
      expect(hits.single.position.dx, closeTo(aimed, 0.01));
    });
  });
}

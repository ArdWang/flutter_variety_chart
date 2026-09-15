import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_test/flutter_test.dart';

const Rect plotRect = Rect.fromLTWH(40, 10, 320, 220);

VarietyCartesianGeometry build(
  List<VarietyChartData> data, {
  VarietyAxis xAxis = const VarietyAxis(type: VarietyAxisType.dateTimeCategory),
}) {
  return VarietyCartesianGeometry(
    series: <VarietySeries>[VarietyLineSeries(data: data)],
    xAxis: xAxis,
    yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
    plotRect: plotRect,
    progress: 1,
  );
}

/// Three readings inside one minute, well inside one day.
List<VarietyChartData> sameDay() => <VarietyChartData>[
      VarietyChartData(DateTime(2026, 9, 15, 11, 30, 1), 10),
      VarietyChartData(DateTime(2026, 9, 15, 11, 30, 11), 20),
      VarietyChartData(DateTime(2026, 9, 15, 11, 30, 31), 15),
    ];

void main() {
  group('category axis slots', () {
    test('gives every distinct instant its own slot', () {
      // Keying categories on the caption folded all three onto one slot, so
      // the line had nothing to spread across.
      final VarietyCartesianGeometry geometry = build(sameDay());
      expect(geometry.categories.length, 3);
      final Set<double> drawn =
          geometry.pointPositions[0].map((Offset p) => p.dx).toSet();
      expect(drawn.length, 3, reason: 'points share a slot: $drawn');
    });

    test('captions each slot with the time it stands for', () {
      final VarietyCartesianGeometry geometry = build(sameDay());
      expect(geometry.categories, <String>[
        '11:30:01',
        '11:30:11',
        '11:30:31',
      ]);
    });

    test('slots keep up when the data spans days', () {
      final VarietyCartesianGeometry geometry = build(<VarietyChartData>[
        VarietyChartData(DateTime(2026, 9, 14, 8), 10),
        VarietyChartData(DateTime(2026, 9, 15, 8), 20),
        VarietyChartData(DateTime(2026, 9, 16, 8), 15),
      ]);
      expect(geometry.categories.length, 3);
      expect(geometry.categories.first, contains('14'));
    });

    test('a coarse dateFormat cannot merge two slots', () {
      // The caption is allowed to repeat when the caller pins it, but the
      // categories behind it must not.
      final VarietyCartesianGeometry geometry = build(
        sameDay(),
        xAxis: const VarietyAxis(
          type: VarietyAxisType.dateTimeCategory,
          dateFormat: 'dd MMM',
        ),
      );
      expect(geometry.categories, <String>['15 Sep', '15 Sep', '15 Sep']);
      final Set<double> drawn =
          geometry.pointPositions[0].map((Offset p) => p.dx).toSet();
      expect(drawn.length, 3, reason: 'points share a slot: $drawn');
    });

    test('a plain category axis buckets date times the same way', () {
      final VarietyCartesianGeometry geometry = build(
        sameDay(),
        xAxis: const VarietyAxis(type: VarietyAxisType.category),
      );
      expect(geometry.categories.length, 3);
      final Set<double> drawn =
          geometry.pointPositions[0].map((Offset p) => p.dx).toSet();
      expect(drawn.length, 3);
    });

    test('string categories are untouched', () {
      final VarietyCartesianGeometry geometry = build(
        const <VarietyChartData>[
          VarietyChartData('Jan', 10),
          VarietyChartData('Feb', 20),
          VarietyChartData('Mar', 15),
        ],
        xAxis: const VarietyAxis(type: VarietyAxisType.category),
      );
      expect(geometry.categories, <String>['Jan', 'Feb', 'Mar']);
    });

    test('a repeated label still shares one slot', () {
      final VarietyCartesianGeometry geometry = build(
        const <VarietyChartData>[
          VarietyChartData('Jan', 10),
          VarietyChartData('Jan', 20),
          VarietyChartData('Feb', 15),
        ],
        xAxis: const VarietyAxis(type: VarietyAxisType.category),
      );
      expect(geometry.categories, <String>['Jan', 'Feb']);
    });

    test('the trackball lands on the tapped slot', () {
      final VarietyCartesianGeometry geometry = build(sameDay());
      final double aimed = geometry.pointPositions[0][1].dx;
      final List<VarietyHitResult> hits =
          geometry.hitsAtSlot(Offset(aimed, plotRect.center.dy));
      expect(hits, isNotEmpty);
      expect(hits.first.pointIndex, 1);
      expect(hits.first.position.dx, closeTo(aimed, 0.01));
    });
  });
}

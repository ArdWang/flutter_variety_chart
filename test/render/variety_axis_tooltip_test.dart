import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_variety_chart/src/painters/variety_cartesian_painter.dart';
import 'package:flutter_test/flutter_test.dart';

const Rect plotRect = Rect.fromLTWH(60, 10, 300, 200);
const Size surface = Size(400, 300);

const VarietyChartTheme theme = VarietyChartTheme(
  gridLineColor: Color(0x22000000),
  axisLineColor: Color(0xFF888888),
  labelColor: Color(0xFF333333),
  tooltipBackgroundColor: Color(0xFF32323A),
  tooltipTextColor: Color(0xFFFFFFFF),
  markerBorderColor: Color(0xFFFFFFFF),
);

VarietyCartesianGeometry build(
  List<VarietyChartData> data, {
  VarietyAxis? xAxis,
}) {
  // Built without `const`: two identical const axes would be canonicalised
  // into one instance and could not be told apart afterwards.
  return VarietyCartesianGeometry(
    series: <VarietySeries>[VarietyLineSeries(data: data)],
    xAxis: xAxis ?? VarietyAxis(type: VarietyAxisType.numeric),
    yAxis: VarietyAxis(type: VarietyAxisType.numeric),
    plotRect: plotRect,
    progress: 1,
  );
}

/// Paints [geometry] with one highlighted point and returns the axis boxes
/// that were drawn.
List<VarietyAxisLabelHit> paintWithGuide(
  VarietyCartesianGeometry geometry, {
  VarietyAxisTooltipSettings settings = const VarietyAxisTooltipSettings(),
  bool withHighlight = true,
}) {
  final int index = geometry.pointPositions[0].length ~/ 2;
  final VarietyHitResult hit = VarietyHitResult(
    series: geometry.series[0],
    seriesIndex: 0,
    point: geometry.sourceData[0][index],
    pointIndex: index,
    position: geometry.pointPositions[0][index],
  );
  final List<VarietyAxisLabelHit> boxes = <VarietyAxisLabelHit>[];
  VarietyCartesianPainter(
    geometry: geometry,
    theme: theme,
    highlights:
        withHighlight ? <VarietyHitResult>[hit] : const <VarietyHitResult>[],
    trackballSlot: hit.position.dx,
    trackball: const VarietyTrackballBehavior(),
    axisTooltip: settings,
    axisLabelHits: boxes,
  ).paint(Canvas(ui.PictureRecorder()), surface);
  return boxes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('axis value boxes', () {
    const List<VarietyChartData> data = <VarietyChartData>[
      VarietyChartData(10, 100),
      VarietyChartData(20, 200),
      VarietyChartData(30, 150),
    ];

    test('pin one box to each axis', () {
      final VarietyCartesianGeometry geometry = build(data);
      final List<VarietyAxisLabelHit> boxes = paintWithGuide(geometry);
      expect(boxes, hasLength(2));

      final VarietyAxisLabelHit xBox = boxes.firstWhere(
          (VarietyAxisLabelHit b) => identical(b.axis, geometry.xAxis));
      final VarietyAxisLabelHit yBox = boxes.firstWhere(
          (VarietyAxisLabelHit b) => identical(b.axis, geometry.yAxis));

      // The x box sits on the x axis line, centred on the guide column.
      final int index = geometry.pointPositions[0].length ~/ 2;
      expect(xBox.rect.center.dx,
          closeTo(geometry.pointPositions[0][index].dx, 1));
      expect(xBox.rect.center.dy, closeTo(plotRect.bottom, 12));
      // The y box sits on the y axis line, level with the point.
      expect(yBox.rect.center.dy,
          closeTo(geometry.pointPositions[0][index].dy, 1));
      expect(yBox.rect.center.dx, closeTo(plotRect.left, 2));
    });

    test('caption the value the guide is on', () {
      final VarietyCartesianGeometry geometry = build(data);
      final List<VarietyAxisLabelHit> boxes = paintWithGuide(geometry);
      final VarietyAxisLabelHit xBox = boxes.firstWhere(
          (VarietyAxisLabelHit b) => identical(b.axis, geometry.xAxis));
      final VarietyAxisLabelHit yBox = boxes.firstWhere(
          (VarietyAxisLabelHit b) => identical(b.axis, geometry.yAxis));
      expect(xBox.text, '20');
      expect(yBox.text, '200');
    });

    test('use the axis date format for a date time axis', () {
      final VarietyCartesianGeometry geometry = build(
        <VarietyChartData>[
          VarietyChartData(DateTime(2026, 9, 16, 10, 0), 1),
          VarietyChartData(DateTime(2026, 9, 16, 10, 5), 2),
          VarietyChartData(DateTime(2026, 9, 16, 10, 10), 3),
        ],
        xAxis: const VarietyAxis(
            type: VarietyAxisType.dateTime, dateFormat: 'HH:mm'),
      );
      final List<VarietyAxisLabelHit> boxes = paintWithGuide(geometry);
      final VarietyAxisLabelHit xBox = boxes.firstWhere(
          (VarietyAxisLabelHit b) => identical(b.axis, geometry.xAxis));
      expect(xBox.text, '10:05');
    });

    test('hidden settings draw nothing', () {
      final VarietyCartesianGeometry geometry = build(data);
      final List<VarietyAxisLabelHit> boxes = paintWithGuide(
        geometry,
        settings: VarietyAxisTooltipSettings.hidden,
      );
      expect(boxes, isEmpty);
    });

    test('nothing is drawn without an active guide', () {
      final VarietyCartesianGeometry geometry = build(data);
      final List<VarietyAxisLabelHit> boxes =
          paintWithGuide(geometry, withHighlight: false);
      expect(boxes, isEmpty);
    });

    test('honour the padding and border radius', () {
      final VarietyCartesianGeometry geometry = build(data);
      final List<VarietyAxisLabelHit> plain = paintWithGuide(geometry);
      final List<VarietyAxisLabelHit> padded = paintWithGuide(
        geometry,
        settings: const VarietyAxisTooltipSettings(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      );
      expect(padded.first.rect.width, greaterThan(plain.first.rect.width));
      expect(padded.first.rect.height, greaterThan(plain.first.rect.height));
    });
  });
}

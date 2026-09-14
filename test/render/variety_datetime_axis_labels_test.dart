import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
// The painter is not part of the public surface, but this test has to drive it
// directly to check what actually reaches the canvas.
import 'package:flutter_variety_chart/src/painters/variety_cartesian_painter.dart';
import 'package:flutter_test/flutter_test.dart';

const Rect plotRect = Rect.fromLTWH(40, 10, 320, 220);

const VarietyChartTheme _theme = VarietyChartTheme(
  gridLineColor: Color(0x1F000000),
  axisLineColor: Color(0x59000000),
  labelColor: Color(0xBF000000),
  tooltipBackgroundColor: Color(0xFF32323A),
  tooltipTextColor: Colors.white,
  markerBorderColor: Colors.white,
);

VarietyCartesianGeometry build(
  List<VarietyChartData> data, {
  VarietyAxis xAxis = const VarietyAxis(type: VarietyAxisType.dateTime),
}) {
  return VarietyCartesianGeometry(
    series: <VarietySeries>[VarietyLineSeries(data: data)],
    xAxis: xAxis,
    yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
    plotRect: plotRect,
    progress: 1,
  );
}

List<String> captionsOf(VarietyCartesianGeometry geometry) =>
    geometry.dateTimeTicks.map(geometry.dateTimeTickLabel).toList();

/// Paints [geometry] and returns the captions the primary axis drew.
List<String> paintedCaptions(VarietyCartesianGeometry geometry) {
  final List<VarietyAxisLabelHit> hits = <VarietyAxisLabelHit>[];
  VarietyCartesianPainter(
    geometry: geometry,
    theme: _theme,
    labelHits: hits,
  ).paint(
    Canvas(ui.PictureRecorder()),
    const Size(400, 300),
  );
  return hits
      .where((VarietyAxisLabelHit hit) => identical(hit.axis, geometry.xAxis))
      .map((VarietyAxisLabelHit hit) => hit.text)
      .toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('date time axis captions', () {
    test('stay unique however little data drives the range', () {
      final Map<String, List<VarietyChartData>> cases =
          <String, List<VarietyChartData>>{
        // A lone point, which the axis pads out to a whole day.
        'single point': <VarietyChartData>[
          VarietyChartData(DateTime(2026, 9, 11, 10, 28, 1), 10),
        ],
        // The case from the report: a handful of points a few seconds apart.
        'three points, thirty seconds': <VarietyChartData>[
          VarietyChartData(DateTime(2026, 9, 11, 10, 28, 1), 10),
          VarietyChartData(DateTime(2026, 9, 11, 10, 28, 11), 20),
          VarietyChartData(DateTime(2026, 9, 11, 10, 28, 31), 15),
        ],
        // An hours interval has to wrap past midnight here.
        'two days': <VarietyChartData>[
          VarietyChartData(DateTime(2026, 9, 10, 10, 28, 1), 10),
          VarietyChartData(DateTime(2026, 9, 11, 10, 28, 1), 20),
        ],
        // Ten days used to be carved into hours.
        'ten days': <VarietyChartData>[
          VarietyChartData(DateTime(2026, 9, 1, 8), 10),
          VarietyChartData(DateTime(2026, 9, 11, 8), 20),
        ],
        'sub second': <VarietyChartData>[
          VarietyChartData(DateTime(2026, 9, 11, 10, 28, 1, 100), 10),
          VarietyChartData(DateTime(2026, 9, 11, 10, 28, 1, 900), 20),
        ],
        'half a year': <VarietyChartData>[
          VarietyChartData(DateTime(2026, 1, 1), 10),
          VarietyChartData(DateTime(2026, 7, 1), 20),
        ],
      };

      cases.forEach((String name, List<VarietyChartData> data) {
        final List<String> captions = captionsOf(build(data));
        expect(captions, isNotEmpty, reason: name);
        expect(
          captions.toSet().length,
          captions.length,
          reason: '$name repeated a caption: $captions',
        );
      });
    });

    test('follow the tick interval as well as the span', () {
      // A hundred milliseconds across half a minute. A pattern derived from the
      // span alone would caption all three hundred ticks "10:28:01".
      final VarietyCartesianGeometry geometry = build(
        <VarietyChartData>[
          VarietyChartData(DateTime(2026, 9, 11, 10, 28, 1), 10),
          VarietyChartData(DateTime(2026, 9, 11, 10, 28, 31), 20),
        ],
        xAxis: const VarietyAxis(
          type: VarietyAxisType.dateTime,
          dateTimeIntervalType: VarietyDateTimeIntervalType.milliseconds,
          dateTimeInterval: 100,
        ),
      );
      final List<String> captions = captionsOf(geometry);
      expect(captions.length, greaterThan(1));
      expect(captions.toSet().length, captions.length);
      expect(captions.first, '10:28:01.000');
    });

    test('keep the tick count near a readable number', () {
      final VarietyCartesianGeometry geometry = build(
        <VarietyChartData>[
          VarietyChartData(DateTime(2026, 9, 1, 8), 10),
          VarietyChartData(DateTime(2026, 9, 11, 8), 20),
        ],
      );
      expect(geometry.dateTimeTicks.length, lessThanOrEqualTo(12));
      expect(geometry.dateTimeTicks.length, greaterThanOrEqualTo(2));
    });

    test('leave an explicit format alone', () {
      final VarietyCartesianGeometry geometry = build(
        <VarietyChartData>[
          VarietyChartData(DateTime(2026, 1, 1), 10),
          VarietyChartData(DateTime(2026, 2, 15), 20),
        ],
        xAxis: const VarietyAxis(
          type: VarietyAxisType.dateTime,
          dateFormat: 'dd MMM',
        ),
      );
      expect(geometry.dateTimeTickLabel(DateTime(2026, 1, 5)), '05 Jan');
    });
  });

  group('date time axis painting', () {
    test('never draws the same caption twice', () {
      // The caller pinned a pattern that cannot tell a hundred milliseconds
      // apart, so the axis itself cannot fix this. The painter still must not
      // repeat a caption.
      final VarietyCartesianGeometry geometry = build(
        <VarietyChartData>[
          VarietyChartData(DateTime(2026, 9, 11, 10, 28, 1), 10),
          VarietyChartData(DateTime(2026, 9, 11, 10, 28, 31), 20),
        ],
        xAxis: const VarietyAxis(
          type: VarietyAxisType.dateTime,
          dateFormat: 'HH:mm:ss',
          dateTimeIntervalType: VarietyDateTimeIntervalType.milliseconds,
          dateTimeInterval: 100,
        ),
      );
      final List<String> painted = paintedCaptions(geometry);
      expect(painted, isNotEmpty);
      expect(
        painted.toSet().length,
        painted.length,
        reason: 'painted the same caption twice: $painted',
      );
    });

    test('drops repeats the caller introduced with a coarser formatter', () {
      // Second-level ticks captioned to the minute collapse into one caption.
      final VarietyCartesianGeometry geometry = build(
        <VarietyChartData>[
          VarietyChartData(DateTime(2026, 9, 11, 10, 28, 1), 10),
          VarietyChartData(DateTime(2026, 9, 11, 10, 28, 31), 20),
        ],
        xAxis: VarietyAxis(
          type: VarietyAxisType.dateTime,
          labelFormatter: (dynamic value) =>
              varietyFormatDateTime(value as DateTime, 'HH:mm'),
        ),
      );
      final List<String> painted = paintedCaptions(geometry);
      expect(painted, isNotEmpty);
      expect(painted.toSet().length, painted.length,
          reason: 'painted the same caption twice: $painted');
    });
  });
}

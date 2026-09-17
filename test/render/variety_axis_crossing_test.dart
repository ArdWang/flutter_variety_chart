import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_variety_chart/src/painters/variety_cartesian_painter.dart';
import 'package:flutter_test/flutter_test.dart';

const Rect plotRect = Rect.fromLTWH(60, 10, 300, 200);
const Size surface = Size(400, 300);

const VarietyChartTheme theme = VarietyChartTheme(
  gridLineColor: Color(0xFFCCCCCC),
  axisLineColor: Color(0xFF000000),
  labelColor: Color(0xFF333333),
  tooltipBackgroundColor: Color(0xFF32323A),
  tooltipTextColor: Color(0xFFFFFFFF),
  markerBorderColor: Color(0xFFFFFFFF),
);

/// A straight climb from -50 to 50, so the middle of the plot is the value 0
/// and the series is nowhere near it at either end.
const List<VarietyChartData> signed = <VarietyChartData>[
  VarietyChartData(-1, -50),
  VarietyChartData(0, 0),
  VarietyChartData(1, 50),
];

VarietyCartesianGeometry build(VarietyAxis yAxis, {bool xLabels = false}) {
  return VarietyCartesianGeometry(
    series: <VarietySeries>[VarietyLineSeries(data: signed)],
    xAxis: VarietyAxis(
      type: VarietyAxisType.numeric,
      showGridLines: false,
      showLabels: xLabels,
      showTicks: false,
    ),
    yAxis: yAxis,
    plotRect: plotRect,
    progress: 1,
  );
}

/// A y axis that draws nothing of its own, so only the x axis can colour a
/// probed pixel.
VarietyAxis silentY({double? crossesAt}) => VarietyAxis(
      type: VarietyAxisType.numeric,
      showGridLines: false,
      showLabels: false,
      showTicks: false,
      crossesAt: crossesAt,
    );

Future<ByteData> raster(
  VarietyAxis yAxis, {
  bool xLabels = false,
  List<VarietyAxisLabelHit>? labelHits,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  VarietyCartesianPainter(
    geometry: build(yAxis, xLabels: xLabels),
    theme: theme,
    labelHits: labelHits,
  ).paint(Canvas(recorder), surface);
  final ui.Image image = await recorder
      .endRecording()
      .toImage(surface.width.toInt(), surface.height.toInt());
  final ByteData bytes =
      (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  image.dispose();
  return bytes;
}

/// The pixel at ([x], [y]) as `(r, g, b, a)`.
(int, int, int, int) pixel(ByteData bytes, int x, int y) {
  final int offset = (y * surface.width.toInt() + x) * 4;
  return (
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
    bytes.getUint8(offset + 3),
  );
}

bool inked(ByteData bytes, int x, int y) => pixel(bytes, x, y).$4 > 40;

/// A column the series is far from, whichever row is being read: the series
/// runs from the bottom left to the top right, so neither end touches the row
/// the crossing line lands on.
const int away = 100;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('crossesAt', () {
    test('moves the x axis line to that value', () async {
      final VarietyCartesianGeometry geometry = build(silentY());
      final ByteData plain = await raster(silentY());
      // Without a crossing the line is the bottom edge of the plot.
      expect(inked(plain, away, plotRect.bottom.round()), isTrue);
      expect(inked(plain, away, geometry.pixelY(0).round()), isFalse);

      final VarietyCartesianGeometry crossed = build(silentY(crossesAt: 0));
      final ByteData bytes = await raster(silentY(crossesAt: 0));
      expect(inked(bytes, away, crossed.pixelY(0).round()), isTrue);
      expect(inked(bytes, away, plotRect.bottom.round()), isFalse);
    });

    test('a crossing outside the range is clamped to the edge', () async {
      // The axis runs -50..50, so -100 is below everything there is.
      final VarietyCartesianGeometry geometry = build(silentY(crossesAt: -100));
      final ByteData bytes = await raster(silentY(crossesAt: -100));
      expect(inked(bytes, away, plotRect.bottom.round()), isTrue);
      expect(inked(bytes, away, geometry.pixelY(0).round()), isFalse);
    });

    test('the captions follow the line', () async {
      final List<VarietyAxisLabelHit> plain = <VarietyAxisLabelHit>[];
      await raster(silentY(), xLabels: true, labelHits: plain);
      expect(plain, isNotEmpty);
      for (final VarietyAxisLabelHit hit in plain) {
        expect(hit.rect.top, greaterThanOrEqualTo(plotRect.bottom));
      }

      final List<VarietyAxisLabelHit> crossed = <VarietyAxisLabelHit>[];
      await raster(silentY(crossesAt: 0), xLabels: true, labelHits: crossed);
      expect(crossed, hasLength(plain.length));
      final double lineY = build(silentY(crossesAt: 0)).pixelY(0);
      for (final VarietyAxisLabelHit hit in crossed) {
        // Below the moved line, and still inside the bottom margin.
        expect(hit.rect.top, greaterThanOrEqualTo(lineY));
        expect(hit.rect.bottom, lessThanOrEqualTo(plotRect.bottom - 4));
      }
    });
  });
}

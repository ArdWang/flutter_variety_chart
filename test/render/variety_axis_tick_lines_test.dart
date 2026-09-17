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

const List<VarietyChartData> data = <VarietyChartData>[
  VarietyChartData(10, 100),
  VarietyChartData(20, 200),
  VarietyChartData(30, 150),
];

/// A y axis that draws nothing of its own, for tests about the x axis.
VarietyAxis bareY() => VarietyAxis(
      type: VarietyAxisType.numeric,
      showGridLines: false,
      showLabels: false,
      showTicks: false,
    );

VarietyCartesianGeometry build(VarietyAxis yAxis, {VarietyAxis? xAxis}) {
  return VarietyCartesianGeometry(
    series: <VarietySeries>[VarietyLineSeries(data: data)],
    xAxis: xAxis ??
        VarietyAxis(
          type: VarietyAxisType.numeric,
          showGridLines: false,
          showLabels: false,
          showTicks: false,
        ),
    yAxis: yAxis,
    plotRect: plotRect,
    progress: 1,
  );
}

Future<ByteData> raster(VarietyAxis yAxis, {VarietyAxis? xAxis}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  VarietyCartesianPainter(
    geometry: build(yAxis, xAxis: xAxis),
    theme: theme,
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

/// The most opaque pixel in the three rows centred on [y].
///
/// A one pixel line rarely lands on a whole pixel row, so its colour is bled
/// across two rows and neither of them is saturated on its own.
(int, int, int, int) strongest(ByteData bytes, int x, int y) {
  (int, int, int, int) best = pixel(bytes, x, y);
  for (final int dy in <int>[-1, 1]) {
    final (int, int, int, int) other = pixel(bytes, x, y + dy);
    if (other.$4 > best.$4) {
      best = other;
    }
  }
  return best;
}

/// A tick's y, so the probes land on a tick rather than between two of them.
///
/// Rows near the series stroke are skipped: the stroke crosses the grid and
/// would colour the pixel we are trying to read.
int tickRow(VarietyAxis yAxis) {
  final VarietyCartesianGeometry geometry = build(yAxis);
  final List<int> busy = geometry.pointPositions[0]
      .map((Offset p) => p.dy.round())
      .toList(growable: false);
  for (final double tick in geometry.yTicks) {
    final int row = geometry.pixelY(tick).round();
    if (row <= plotRect.top + 3 || row >= plotRect.bottom - 3) {
      continue;
    }
    if (busy.any((int b) => (b - row).abs() <= 5)) {
      continue;
    }
    return row;
  }
  return geometry.pixelY(geometry.yTicks.last).round();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The y axis line sits on plotRect.left, so x below it is outside the plot
  // and x above it is inside.
  const int outside = 54;
  const int inside = 66;

  group('tick marks', () {
    test('point away from the plot area by default', () async {
      final VarietyAxis yAxis = VarietyAxis(
        type: VarietyAxisType.numeric,
        showGridLines: false,
        showLabels: false,
        tickLength: 8,
      );
      final ByteData bytes = await raster(yAxis);
      final int row = tickRow(yAxis);
      expect(inked(bytes, outside, row), isTrue);
      expect(inked(bytes, inside, row), isFalse);
    });

    test('tickPosition inside turns them round', () async {
      final VarietyAxis yAxis = VarietyAxis(
        type: VarietyAxisType.numeric,
        showGridLines: false,
        showLabels: false,
        tickLength: 8,
        tickPosition: VarietyTickPosition.inside,
      );
      final ByteData bytes = await raster(yAxis);
      final int row = tickRow(yAxis);
      expect(inked(bytes, inside, row), isTrue);
      expect(inked(bytes, outside, row), isFalse);
    });

    test('majorTickLines sets the length', () async {
      final VarietyAxis plain = VarietyAxis(
        type: VarietyAxisType.numeric,
        showGridLines: false,
        showLabels: false,
        tickLength: 8,
      );
      final VarietyAxis long = VarietyAxis(
        type: VarietyAxisType.numeric,
        showGridLines: false,
        showLabels: false,
        tickLength: 8,
        majorTickLines: VarietyMajorTickLines(size: 20),
      );
      final int row = tickRow(plain);
      expect(inked(await raster(plain), outside, row), isTrue);
      // 20 long reaches past the probe at 6 px out; 8 does not reach 14 px out.
      expect(inked(await raster(long), outside - 8, row), isTrue);
      expect(inked(await raster(plain), outside - 8, row), isFalse);
    });

    test('majorTickLines sets the colour', () async {
      // `size` is spelled out because `VarietyMajorTickLines.size` carries its
      // own default of 4 rather than falling back to `tickLength`.
      final VarietyAxis plain = VarietyAxis(
        type: VarietyAxisType.numeric,
        showGridLines: false,
        showLabels: false,
        tickLength: 12,
      );
      final VarietyAxis red = VarietyAxis(
        type: VarietyAxisType.numeric,
        showGridLines: false,
        showLabels: false,
        tickLength: 12,
        majorTickLines:
            VarietyMajorTickLines(color: Color(0xFFFF0000), size: 12),
      );
      final int row = tickRow(plain);
      final (int, int, int, int) before =
          strongest(await raster(plain), outside, row);
      final (int r, int g, int b, int a) =
          strongest(await raster(red), outside, row);
      // Both renders paint the same 12 px mark at the same y, so the same
      // fraction of the probed pixel is covered and the channels compare
      // directly. `rawRgba` is premultiplied, so absolute values are not
      // meaningful but the hue still is.
      expect(before.$4, greaterThan(40));
      expect(a, greaterThan(40));
      expect(r, greaterThan(before.$1));
      // The default tick is black, so its other two channels are already zero;
      // the hue of the new one is what tells the two apart.
      expect(r, greaterThan(g));
      expect(r, greaterThan(b));
    });

    test('majorTickLines sets the thickness', () async {
      final VarietyAxis thin = VarietyAxis(
        type: VarietyAxisType.numeric,
        showGridLines: false,
        showLabels: false,
        tickLength: 12,
      );
      final VarietyAxis thick = VarietyAxis(
        type: VarietyAxisType.numeric,
        showGridLines: false,
        showLabels: false,
        tickLength: 12,
        majorTickLines: VarietyMajorTickLines(width: 5, size: 12),
      );
      final int row = tickRow(thin);
      int span(ByteData bytes) {
        int count = 0;
        for (int y = row - 4; y <= row + 4; y++) {
          if (inked(bytes, outside, y)) {
            count++;
          }
        }
        return count;
      }

      expect(span(await raster(thick)), greaterThan(span(await raster(thin))));
    });

    test('showTicks false draws none', () async {
      final VarietyAxis yAxis = VarietyAxis(
        type: VarietyAxisType.numeric,
        showGridLines: false,
        showLabels: false,
        tickLength: 12,
        showTicks: false,
      );
      final ByteData bytes = await raster(yAxis);
      final int row = tickRow(yAxis);
      expect(inked(bytes, outside, row), isFalse);
      expect(inked(bytes, outside - 6, row), isFalse);
    });
  });

  group('major grid lines', () {
    test('majorGridLines sets the colour', () async {
      final VarietyAxis plain =
          VarietyAxis(type: VarietyAxisType.numeric, showTicks: false);
      final VarietyAxis green = VarietyAxis(
        type: VarietyAxisType.numeric,
        showTicks: false,
        majorGridLines: VarietyMajorGridLines(color: Color(0xFF00FF00)),
      );
      final int row = tickRow(plain);
      final (int, int, int, int) before =
          strongest(await raster(plain), 200, row);
      final (int r, int g, int b, int a) =
          strongest(await raster(green), 200, row);
      // A 1 px line straddling two rows is drawn at half coverage, so both
      // renders are compared rather than an absolute 255.
      expect(before.$4, greaterThan(40));
      expect(a, greaterThan(40));
      expect(g, greaterThan(before.$2));
      expect(r, lessThan(before.$1));
      expect(b, lessThan(before.$3));
    });

    test('majorGridLines sets the thickness', () async {
      final VarietyAxis plain =
          VarietyAxis(type: VarietyAxisType.numeric, showTicks: false);
      final VarietyAxis thick = VarietyAxis(
        type: VarietyAxisType.numeric,
        showTicks: false,
        majorGridLines: VarietyMajorGridLines(width: 5),
      );
      final int row = tickRow(plain);
      int span(ByteData bytes) {
        int count = 0;
        for (int y = row - 4; y <= row + 4; y++) {
          if (inked(bytes, 200, y)) {
            count++;
          }
        }
        return count;
      }

      expect(span(await raster(thick)), greaterThan(span(await raster(plain))));
    });
  });

  group('x axis tick marks', () {
    // The x axis line sits on plotRect.bottom, so y below it is outside the
    // plot and y above it is inside.
    const int below = 214;
    const int above = 206;

    /// A tick's x, so the probes land on a mark rather than between two.
    double tickColumn(VarietyAxis xAxis) {
      final VarietyCartesianGeometry geometry = build(bareY(), xAxis: xAxis);
      final List<double> ticks = geometry.xNumericTicks;
      return geometry.toPixel(ticks[1], geometry.yMinimum).dx;
    }

    VarietyAxis xAxis({
      double tickLength = 8,
      VarietyTickPosition? tickPosition,
      VarietyMajorTickLines? majorTickLines,
      bool showTicks = true,
    }) {
      return VarietyAxis(
        type: VarietyAxisType.numeric,
        showGridLines: false,
        showLabels: false,
        showTicks: showTicks,
        tickLength: tickLength,
        tickPosition: tickPosition ?? VarietyTickPosition.outside,
        majorTickLines: majorTickLines,
      );
    }

    test('point down from the plot area by default', () async {
      final VarietyAxis axis = xAxis();
      final ByteData bytes = await raster(bareY(), xAxis: axis);
      final int column = tickColumn(axis).round();
      expect(inked(bytes, column, below), isTrue);
      expect(inked(bytes, column, above), isFalse);
    });

    test('tickPosition inside turns them round', () async {
      final VarietyAxis axis = xAxis(tickPosition: VarietyTickPosition.inside);
      final ByteData bytes = await raster(bareY(), xAxis: axis);
      final int column = tickColumn(axis).round();
      expect(inked(bytes, column, above), isTrue);
      expect(inked(bytes, column, below), isFalse);
    });

    test('majorTickLines sets the length', () async {
      final VarietyAxis plain = xAxis();
      // `VarietyMajorTickLines.size` carries its own default of 4 rather than
      // falling back to `tickLength`, so it makes a shorter mark than the
      // plain axis does and stops short of the probe.
      final VarietyAxis short = xAxis(majorTickLines: VarietyMajorTickLines());
      final VarietyAxis longest =
          xAxis(majorTickLines: VarietyMajorTickLines(size: 20));
      final int column = tickColumn(plain).round();
      expect(inked(await raster(bareY(), xAxis: plain), column, below), isTrue);
      expect(
          inked(await raster(bareY(), xAxis: short), column, below), isFalse);
      expect(
        inked(await raster(bareY(), xAxis: longest), column, below + 8),
        isTrue,
      );
    });

    test('showTicks false draws none', () async {
      final VarietyAxis axis = xAxis(showTicks: false);
      final ByteData bytes = await raster(bareY(), xAxis: axis);
      final int column = tickColumn(axis).round();
      expect(inked(bytes, column, below), isFalse);
    });
  });
}

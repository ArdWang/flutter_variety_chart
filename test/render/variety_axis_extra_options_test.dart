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

/// Twelve categories, so a chart of them has more captions than the default
/// label cap allows on a narrow plot.
List<VarietyChartData> months() => List<VarietyChartData>.generate(
      12,
      (int i) => VarietyChartData('M$i', (i + 1).toDouble()),
    );

VarietyCartesianGeometry build({
  VarietyAxis? xAxis,
  VarietyAxis? yAxis,
  List<VarietyChartData>? data,
}) {
  return VarietyCartesianGeometry(
    series: <VarietySeries>[
      VarietyLineSeries(data: data ?? months()),
    ],
    xAxis: xAxis ?? const VarietyAxis(type: VarietyAxisType.category),
    yAxis: yAxis ?? const VarietyAxis(type: VarietyAxisType.numeric),
    plotRect: plotRect,
    progress: 1,
  );
}

/// Rasterizes the axis furniture of [geometry] and hands back the pixels.
Future<ByteData> raster(VarietyCartesianGeometry geometry) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  VarietyCartesianPainter(geometry: geometry, theme: theme)
      .paint(Canvas(recorder), surface);
  final ui.Image image = await recorder
      .endRecording()
      .toImage(surface.width.toInt(), surface.height.toInt());
  final ByteData bytes =
      (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  image.dispose();
  return bytes;
}

(int, int, int, int) pixel(ByteData bytes, int x, int y) {
  final int offset = (y * surface.width.toInt() + x) * 4;
  return (
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
    bytes.getUint8(offset + 3),
  );
}

/// Whether anything was drawn at ([x], [y]).
///
/// A one pixel line rarely lands on a whole pixel row, so a two row window is
/// checked rather than the single row asked for.
bool inked(ByteData bytes, int x, double y) {
  for (final int row in <int>[y.floor() - 1, y.floor(), y.floor() + 1]) {
    if (row < 0 || row >= surface.height.toInt()) {
      continue;
    }
    if (pixel(bytes, x, row).$4 > 40) {
      return true;
    }
  }
  return false;
}

Future<List<VarietyAxisLabelHit>> captureLabels(
  VarietyCartesianGeometry geometry,
) async {
  final List<VarietyAxisLabelHit> hits = <VarietyAxisLabelHit>[];
  VarietyCartesianPainter(
    geometry: geometry,
    theme: theme,
    labelHits: hits,
  ).paint(Canvas(ui.PictureRecorder()), surface);
  return hits;
}

void main() {
  group('minor tick lines', () {
    test('a minor tick is drawn at the length the style asks for', () async {
      final VarietyCartesianGeometry geometry = build(
        yAxis: VarietyAxis(
          type: VarietyAxisType.numeric,
          minorTicksPerInterval: 1,
          showLabels: false,
          majorTickLines: const VarietyMajorTickLines(size: 4),
        ),
      );
      expect(geometry.yMinorTicks, isNotEmpty);
      final double y = geometry.pixelY(geometry.yMinorTicks.first);
      final ByteData bytes = await raster(geometry);
      // Eleven pixels out from the axis line: well past the four pixel major
      // ticks, well inside a fourteen pixel minor one.
      expect(inked(bytes, 49, y), isFalse);
    });

    test('growing the minor tick style makes the mark reach further', () async {
      final VarietyCartesianGeometry geometry = build(
        yAxis: VarietyAxis(
          type: VarietyAxisType.numeric,
          minorTicksPerInterval: 1,
          showLabels: false,
          majorTickLines: const VarietyMajorTickLines(size: 4),
          minorTickLines: const VarietyMinorTickLines(size: 14),
        ),
      );
      final double y = geometry.pixelY(geometry.yMinorTicks.first);
      final ByteData bytes = await raster(geometry);
      expect(inked(bytes, 49, y), isTrue);
    });

    test('a secondary value axis subdivides its own scale', () {
      final VarietyCartesianGeometry geometry = VarietyCartesianGeometry(
        series: <VarietySeries>[
          VarietyLineSeries(data: months()),
          VarietyLineSeries(name: 'b', data: months(), yAxisName: 'b'),
        ],
        xAxis: const VarietyAxis(type: VarietyAxisType.category),
        yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
        secondaryYAxes: const <VarietyAxis>[
          VarietyAxis(
            type: VarietyAxisType.numeric,
            name: 'b',
            minorTicksPerInterval: 2,
          ),
        ],
        plotRect: plotRect,
        progress: 1,
      );
      expect(geometry.yMinorTicksOn(1), isNotEmpty);
    });
  });

  group('maximum labels', () {
    test('caps the captions at three per hundred pixels', () async {
      final VarietyCartesianGeometry geometry = build(
        xAxis: const VarietyAxis(
          type: VarietyAxisType.category,
          maximumLabels: 1,
        ),
        yAxis: const VarietyAxis(
          type: VarietyAxisType.numeric,
          showLabels: false,
        ),
      );
      final List<VarietyAxisLabelHit> hits = await captureLabels(geometry);
      // Three hundred pixels at one label per hundred is a cap of three.
      expect(hits.length, 3);
    });

    test('a bigger cap lets more captions through', () async {
      final VarietyCartesianGeometry geometry = build(
        xAxis: const VarietyAxis(
          type: VarietyAxisType.category,
          maximumLabels: 4,
        ),
        yAxis: const VarietyAxis(
          type: VarietyAxisType.numeric,
          showLabels: false,
        ),
      );
      final List<VarietyAxisLabelHit> hits = await captureLabels(geometry);
      expect(hits.length, greaterThan(3));
      expect(hits.length, lessThanOrEqualTo(12));
    });
  });

  group('label alignment', () {
    test('start puts the leading edge on the grid line', () async {
      final VarietyCartesianGeometry centred = build(
        xAxis: const VarietyAxis(
          type: VarietyAxisType.category,
          maximumLabels: 100,
          labelIntersectAction: VarietyLabelIntersectAction.none,
        ),
        yAxis: const VarietyAxis(
          type: VarietyAxisType.numeric,
          showLabels: false,
        ),
      );
      final VarietyCartesianGeometry leading = build(
        xAxis: const VarietyAxis(
          type: VarietyAxisType.category,
          maximumLabels: 100,
          labelAlignment: VarietyLabelAlignment.start,
          labelIntersectAction: VarietyLabelIntersectAction.none,
        ),
        yAxis: const VarietyAxis(
          type: VarietyAxisType.numeric,
          showLabels: false,
        ),
      );
      final List<VarietyAxisLabelHit> a = await captureLabels(centred);
      final List<VarietyAxisLabelHit> b = await captureLabels(leading);
      expect(a.length, b.length);
      expect(b.first.rect.left, greaterThan(a.first.rect.left));
    });

    test('end moves the label the other way', () async {
      final VarietyCartesianGeometry centred = build(
        xAxis: const VarietyAxis(
          type: VarietyAxisType.category,
          maximumLabels: 100,
          labelIntersectAction: VarietyLabelIntersectAction.none,
        ),
        yAxis: const VarietyAxis(
          type: VarietyAxisType.numeric,
          showLabels: false,
        ),
      );
      final VarietyCartesianGeometry trailing = build(
        xAxis: const VarietyAxis(
          type: VarietyAxisType.category,
          maximumLabels: 100,
          labelAlignment: VarietyLabelAlignment.end,
          labelIntersectAction: VarietyLabelIntersectAction.none,
        ),
        yAxis: const VarietyAxis(
          type: VarietyAxisType.numeric,
          showLabels: false,
        ),
      );
      final List<VarietyAxisLabelHit> a = await captureLabels(centred);
      final List<VarietyAxisLabelHit> b = await captureLabels(trailing);
      expect(b.first.rect.right, lessThan(a.first.rect.right));
    });
  });

  group('label intersect action trim', () {
    test('a caption too wide for its slot keeps a shortened head', () async {
      final List<VarietyChartData> wide = <VarietyChartData>[
        const VarietyChartData('January sales for the north', 10),
        const VarietyChartData('February sales for the south', 20),
        const VarietyChartData('March sales for the east', 30),
      ];
      Future<List<VarietyAxisLabelHit>> labelsFor(
        VarietyLabelIntersectAction action,
      ) =>
          captureLabels(
            build(
              data: wide,
              xAxis: VarietyAxis(
                type: VarietyAxisType.category,
                maximumLabels: 100,
                labelIntersectAction: action,
              ),
              yAxis: const VarietyAxis(
                type: VarietyAxisType.numeric,
                showLabels: false,
              ),
            ),
          );

      final List<VarietyAxisLabelHit> plain =
          await labelsFor(VarietyLabelIntersectAction.none);
      final List<VarietyAxisLabelHit> trimmed =
          await labelsFor(VarietyLabelIntersectAction.trim);

      // Trimming keeps every caption rather than dropping the ones that
      // collide, which is what makes it different from `hide`.
      expect(trimmed.length, plain.length);
      expect(
        trimmed.first.rect.width,
        lessThan(plain.first.rect.width),
      );
      expect(trimmed.first.text, 'January sales for the north');
    });
  });

  group('axis border type', () {
    test('withoutTopAndBottom leaves the top edge out', () async {
      // Grid lines are switched off so the only thing that can ink the top
      // edge of the plot area is the frame itself.
      const VarietyAxis xAxis = VarietyAxis(
        type: VarietyAxisType.numeric,
        showGridLines: false,
      );
      Future<ByteData> borderOf(VarietyAxisBorderType type) => raster(
            VarietyCartesianGeometry(
              series: <VarietySeries>[
                VarietyLineSeries(data: months()),
              ],
              xAxis: xAxis.copyWith(borderType: type),
              yAxis: const VarietyAxis(
                type: VarietyAxisType.numeric,
                showGridLines: false,
              ),
              plotRect: plotRect,
              progress: 1,
            ),
          );

      final ByteData rectangle =
          await borderOf(VarietyAxisBorderType.rectangle);
      final ByteData upright =
          await borderOf(VarietyAxisBorderType.withoutTopAndBottom);

      // Two pixels inside the plot area, on a column away from the value axis
      // so the tick marks cannot be mistaken for the frame.
      const int column = 340;
      expect(inked(rectangle, column, plotRect.top), isTrue);
      expect(inked(upright, column, plotRect.top), isFalse);
      // The uprights themselves are still there.
      expect(inked(upright, plotRect.left.round(), 100), isTrue);
      expect(inked(upright, plotRect.right.round() - 1, 100), isTrue);
    });
  });

  group('multi level labels', () {
    Future<ByteData> paint(VarietyMultiLevelLabels config) => raster(
          build(
            xAxis: VarietyAxis(
              type: VarietyAxisType.category,
              multiLevelLabels: config,
            ),
            yAxis: const VarietyAxis(
              type: VarietyAxisType.numeric,
              showLabels: false,
            ),
          ),
        );

    /// The first inked row of [column], at or below [from].
    ///
    /// The bracket is an outline, so its interior is empty and the first rule
    /// a column crosses is the top edge of the band covering it.
    int firstInk(ByteData bytes, int column, int from) {
      for (int y = from; y < surface.height.toInt(); y++) {
        if (pixel(bytes, column, y).$4 > 40) {
          return y;
        }
      }
      return -1;
    }

    /// How many pixels are inked across the surface between [from] and [to].
    ///
    /// Counting the whole band rather than one column keeps the assertion
    /// independent of exactly where the slot boundaries land.
    int bandInk(ByteData bytes, int from, int to) {
      int count = 0;
      for (int y = from; y <= to; y++) {
        for (int x = 0; x < surface.width.toInt(); x++) {
          if (pixel(bytes, x, y).$4 > 40) {
            count++;
          }
        }
      }
      return count;
    }

    test('rowHeight sets how far a nested row sits below the axis', () async {
      Future<int> topFor(double rowHeight) async {
        final ByteData bytes = await paint(
          VarietyMultiLevelLabels(
            groups: const <VarietyLabelGroup>[
              VarietyLabelGroup(start: 0, end: 1, text: 'H1', level: 1),
            ],
            // No margin, so the band is exactly `rowHeight` tall and its top
            // edge is exactly one row below the level zero line.
            margin: EdgeInsets.zero,
            rowHeight: rowHeight,
          ),
        );
        // The middle of the group, clear of the caption at its centre only if
        // the caption is short; the top edge is what is being measured.
        return firstInk(bytes, 80, 230);
      }

      final int shallow = await topFor(16);
      final int deep = await topFor(44);
      expect(shallow, greaterThan(0));
      // A nested row moves down by exactly the extra row height.
      expect(deep - shallow, 28);
    });

    test('merge folds neighbouring groups that share a caption', () async {
      const List<VarietyLabelGroup> groups = <VarietyLabelGroup>[
        VarietyLabelGroup(start: 0, end: 1, text: 'H1'),
        VarietyLabelGroup(start: 2, end: 3, text: 'H1'),
        VarietyLabelGroup(start: 4, end: 5, text: 'H2'),
      ];
      final ByteData merged = await paint(
        const VarietyMultiLevelLabels(groups: groups, merge: true),
      );
      final ByteData separate = await paint(
        const VarietyMultiLevelLabels(groups: groups),
      );
      // Two brackets are drawn instead of three, and the boundary between
      // the two halves of H1 stops being outlined, so the merged picture
      // carries strictly less ink.
      final int mergedInk = bandInk(merged, 230, 299);
      final int separateInk = bandInk(separate, 230, 299);
      expect(mergedInk, greaterThan(0));
      expect(
        mergedInk,
        lessThan(separateInk),
        reason: 'merging should fold one bracket away',
      );
    });
  });
}

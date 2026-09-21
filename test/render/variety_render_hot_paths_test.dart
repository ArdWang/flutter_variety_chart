import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_variety_chart/src/painters/variety_cartesian_painter.dart';
import 'package:flutter_test/flutter_test.dart';

const VarietyChartTheme theme = VarietyChartTheme(
  gridLineColor: Color(0xFFCCCCCC),
  axisLineColor: Color(0xFF000000),
  labelColor: Color(0xFF333333),
  tooltipBackgroundColor: Color(0xFF32323A),
  tooltipTextColor: Color(0xFFFFFFFF),
  markerBorderColor: Color(0xFFFFFFFF),
);

const Rect defaultPlotRect = Rect.fromLTWH(40, 10, 320, 220);
const Size surface = Size(400, 300);

List<VarietyChartData> monthly() => const <VarietyChartData>[
      VarietyChartData('Jan', 32, label: 'Jan'),
      VarietyChartData('Feb', 48, label: 'Feb'),
      VarietyChartData('Mar', 41, label: 'Mar'),
      VarietyChartData('Apr', 55, label: 'Apr'),
    ];

VarietyCartesianGeometry build({bool buildElements = true}) {
  return VarietyCartesianGeometry(
    series: <VarietySeries>[
      VarietyColumnSeries(name: 'A', data: monthly()),
      VarietyLineSeries(name: 'B', data: monthly()),
    ],
    xAxis: const VarietyAxis(type: VarietyAxisType.category, title: 'Month'),
    yAxis: const VarietyAxis(type: VarietyAxisType.numeric, title: 'Value'),
    plotRect: defaultPlotRect,
    progress: 1,
    buildElements: buildElements,
  );
}

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

int alphaAt(ByteData bytes, int x, int y) =>
    bytes.getUint8((y * surface.width.toInt() + x) * 4 + 3);

void main() {
  group('the element pass can be skipped', () {
    test('ranges, ticks and slots are identical either way', () {
      final VarietyCartesianGeometry full = build();
      final VarietyCartesianGeometry light = build(buildElements: false);

      expect(light.elements, isEmpty);
      expect(full.elements, isNotEmpty);

      expect(light.xMinimum, full.xMinimum);
      expect(light.xMaximum, full.xMaximum);
      expect(light.yMinimum, full.yMinimum);
      expect(light.yMaximum, full.yMaximum);
      expect(light.xTickPositionsOn(0), full.xTickPositionsOn(0));
      expect(light.yTicks, full.yTicks);
      expect(light.categories, full.categories);
      expect(light.slotCenters, full.slotCenters);
      expect(light.slotWidth, full.slotWidth);
      expect(light.xNumericTicks, full.xNumericTicks);
      expect(light.seriesColors, full.seriesColors);
    });

    test('a light geometry still resolves categories by slot', () {
      final VarietyCartesianGeometry light = build(buildElements: false);
      expect(light.categoryIndexOf(monthly()[2]), 2);
    });
  });

  group('label hits describe one frame', () {
    test('painting twice does not double the list', () async {
      final VarietyCartesianGeometry geometry = build();
      final List<VarietyAxisLabelHit> hits = <VarietyAxisLabelHit>[];
      for (int i = 0; i < 3; i++) {
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        VarietyCartesianPainter(
          geometry: geometry,
          theme: theme,
          labelHits: hits,
        ).paint(Canvas(recorder), surface);
        recorder.endRecording().dispose();
      }
      expect(hits, isNotEmpty);
      // Four categories on a 320 pixel axis, so the first frame records a
      // handful of captions. Three frames must not record three times as many:
      // the list is the current frame's furniture, not a log.
      expect(hits.length, lessThan(8));
      expect(
        hits.map((VarietyAxisLabelHit hit) => hit.text).toSet().length,
        hits.length,
        reason: 'the same caption should appear once per frame',
      );
    });
  });

  group('categories are indexed once', () {
    test('a transposed chart resolves slots in first appearance order', () {
      final VarietyCartesianGeometry geometry = VarietyCartesianGeometry(
        series: <VarietySeries>[
          VarietyBarSeries(
            name: 'A',
            data: const <VarietyChartData>[
              VarietyChartData('b', 10),
              VarietyChartData('a', 20),
              VarietyChartData('b', 30),
            ],
          ),
        ],
        xAxis: const VarietyAxis(type: VarietyAxisType.category),
        yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
        plotRect: defaultPlotRect,
        progress: 1,
      );
      // `b` is met first, so it takes slot 0 and the repeated `b` joins it.
      expect(geometry.categories, <String>['b', 'a']);
      // A bar layout transposes the point, so the value travels along x and
      // the slot index along y.
      expect(
        geometry.resolvedData.first.map((VarietyChartData p) => p.x).toList(),
        <double>[10, 20, 30],
      );
      expect(
        geometry.resolvedData.first.map((VarietyChartData p) => p.y).toList(),
        <double>[0, 1, 0],
      );
      expect(geometry.categoryIndexOf(const VarietyChartData('a', 0)), 1);
      expect(geometry.categoryIndexOf(const VarietyChartData('zz', 0)), -1);
    });

    test('a label wins over the value as the category key', () {
      // A line series, so the axis takes the untransposed path this is about.
      final VarietyCartesianGeometry geometry = VarietyCartesianGeometry(
        series: <VarietySeries>[
          VarietyLineSeries(
            name: 'A',
            data: const <VarietyChartData>[
              VarietyChartData(7, 10, label: 'seven'),
              VarietyChartData(7, 20, label: 'other'),
            ],
          ),
        ],
        xAxis: const VarietyAxis(type: VarietyAxisType.category),
        yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
        plotRect: defaultPlotRect,
        progress: 1,
      );
      // Two slots, because the label is the identity...
      expect(
          geometry
              .categoryIndexOf(const VarietyChartData(7, 0, label: 'seven')),
          0);
      expect(
          geometry
              .categoryIndexOf(const VarietyChartData(7, 0, label: 'other')),
          1);
      // ...while both print the same caption, which is exactly why identity and
      // caption are kept apart.
      expect(geometry.categories, <String>['7', '7']);
      expect(geometry.categoryIndexOf(monthly().first), -1);
    });
  });

  group('dashes are batched into one path', () {
    test('a dashed rule still draws as a run of dashes', () async {
      Future<int> dashCount(List<double> pattern) async {
        final VarietyCartesianGeometry geometry = VarietyCartesianGeometry(
          series: <VarietySeries>[
            VarietyLineSeries(
              name: 'A',
              data: const <VarietyChartData>[
                VarietyChartData(0, 50),
                VarietyChartData(10, 50),
              ],
              dashPattern: pattern,
            ),
          ],
          xAxis: const VarietyAxis(type: VarietyAxisType.numeric),
          // An explicit range puts the rule on a row the test can name.
          yAxis: const VarietyAxis(
            type: VarietyAxisType.numeric,
            minimum: 0,
            maximum: 100,
          ),
          plotRect: defaultPlotRect,
          progress: 1,
        );
        final ByteData bytes = await raster(geometry);
        // Walk the row the rule sits on and count the runs of ink, which is
        // what "a dashed line" means on screen.
        int runs = 0;
        bool inked = false;
        for (int x = 0; x < surface.width.toInt(); x++) {
          bool rowInked = false;
          for (int dy = -1; dy <= 1; dy++) {
            if (alphaAt(bytes, x, 120 + dy) > 40) {
              rowInked = true;
            }
          }
          if (rowInked && !inked) {
            runs++;
          }
          inked = rowInked;
        }
        return runs;
      }

      expect(await dashCount(const <double>[6, 4]), greaterThan(5));
      // A longer period leaves fewer, longer dashes.
      expect(
        await dashCount(const <double>[20, 20]),
        lessThan(await dashCount(const <double>[6, 4])),
      );
      // No pattern at all is one continuous run.
      expect(await dashCount(const <double>[]), 1);
    });
  });
}

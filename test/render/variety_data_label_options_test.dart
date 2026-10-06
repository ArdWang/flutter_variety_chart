import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// The caption chain and the painter that reads it are not part of the public
// surface, but these tests drive them directly to check what reaches the
// canvas.
import 'package:flutter_variety_chart/src/painters/variety_circular_painter.dart';
import 'package:flutter_variety_chart/src/render/variety_data_labels.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

const List<VarietyChartData> stages = <VarietyChartData>[
  VarietyChartData('Visited', 100),
  VarietyChartData('Cart', 60),
  VarietyChartData('Buy', 20),
];

/// The theme the circular labels are painted under.
const VarietyChartTheme baseTheme = VarietyChartTheme(
  gridLineColor: Color(0x1F000000),
  axisLineColor: Color(0x59000000),
  labelColor: Color(0xBF000000),
  tooltipBackgroundColor: Color(0xFF32323A),
  tooltipTextColor: Colors.white,
  markerBorderColor: Colors.white,
);

/// The labels a funnel built, in segment order.
List<VarietyLabelItem> funnelLabels(VarietySeries series) {
  final VarietyFunnelGeometry geometry = VarietyFunnelGeometry(
    series: series,
    plotRect: const Rect.fromLTWH(0, 0, 200, 300),
    progress: 1,
    isPyramid: false,
  );
  return geometry.elements
      .whereType<VarietyLabelsElement>()
      .expand((VarietyLabelsElement element) => element.labels)
      .toList();
}

VarietyCircularGeometry circular(VarietySeries series) =>
    VarietyCircularGeometry(
      series: <VarietySeries>[series],
      center: const Offset(100, 100),
      maxRadius: 80,
      progress: 1,
    );

/// A canvas that keeps what a painter asked it to draw.
///
/// The painter never reads a value back out of the canvas it is handed, so
/// answering everything else with `null` still lets a paint run through.
class _Recorder implements ui.Canvas {
  final List<ui.Paragraph> paragraphs = <ui.Paragraph>[];

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) =>
      paragraphs.add(paragraph);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getSaveCount) {
      return 1;
    }
    if (invocation.memberName == #getDestinationClipBounds ||
        invocation.memberName == #getLocalClipBounds) {
      return Rect.zero;
    }
    return null;
  }
}

/// The paragraphs a circular painter draws for [series] under [theme].
List<ui.Paragraph> paintCircular(
  VarietySeries series, {
  VarietyChartTheme theme = baseTheme,
}) {
  final _Recorder recorder = _Recorder();
  VarietyCircularPainter(
    geometry: circular(series),
    theme: theme,
  ).paint(recorder, const Size(200, 200));
  return recorder.paragraphs;
}

void main() {
  group('the shared caption chain', () {
    VarietySeries series({
      VarietyDataLabelSettings settings =
          const VarietyDataLabelSettings(isVisible: true),
      String Function(VarietyChartData point, int index)? mapper,
    }) =>
        VarietyColumnSeries(
          data: stages,
          dataLabelSettings: settings,
          dataLabelMapper: mapper,
        );

    test('a mapper is asked before the settings builder', () {
      final VarietySeries item = series(
        settings: VarietyDataLabelSettings(
          isVisible: true,
          builder: (VarietyChartData point) => 'built ${point.x}',
        ),
        mapper: (VarietyChartData point, int index) => 'mapped $index',
      );
      expect(
        varietyDataLabelCaption(item, stages[0], 0, 100),
        'mapped 0',
      );
    });

    test('a builder is asked before the value is formatted', () {
      final VarietySeries item = series(
        settings: VarietyDataLabelSettings(
          isVisible: true,
          builder: (VarietyChartData point) => 'built ${point.x}',
        ),
      );
      expect(
        varietyDataLabelCaption(item, stages[0], 0, 100),
        'built Visited',
      );
    });

    test('the fallback is used before the value is formatted', () {
      final VarietySeries item = series();
      expect(
        varietyDataLabelCaption(item, stages[0], 0, 100, fallback: 'Visited'),
        'Visited',
      );
      expect(varietyDataLabelCaption(item, stages[0], 0, 100), '100');
    });

    test('a zero the settings hide has no caption at all', () {
      const VarietyChartData zero = VarietyChartData('Buy', 0);
      expect(
        varietyDataLabelCaption(
          series(settings: const VarietyDataLabelSettings(isVisible: true)),
          zero,
          2,
          0,
        ),
        '0',
      );
      expect(
        varietyDataLabelCaption(
          series(
            settings: const VarietyDataLabelSettings(
              isVisible: true,
              showZeroValue: false,
            ),
          ),
          zero,
          2,
          0,
        ),
        isNull,
      );
    });
  });

  group('funnel labels', () {
    test('honour a mapper and the zero switch', () {
      final List<VarietyLabelItem> mapped = funnelLabels(
        VarietyFunnelSeries(
          data: stages,
          dataLabelSettings: const VarietyDataLabelSettings(isVisible: true),
          dataLabelMapper: (VarietyChartData point, int index) => 'step $index',
        ),
      );
      expect(
        mapped.map((VarietyLabelItem item) => item.text),
        <String>['step 0', 'step 1', 'step 2'],
      );

      final List<VarietyLabelItem> withoutZero = funnelLabels(
        const VarietyFunnelSeries(
          data: <VarietyChartData>[
            VarietyChartData('Visited', 100),
            VarietyChartData('Cart', 0),
          ],
          dataLabelSettings: VarietyDataLabelSettings(
            isVisible: true,
            showZeroValue: false,
          ),
        ),
      );
      expect(withoutZero, hasLength(1));
    });

    test('take the series colour when asked to', () {
      final List<VarietyLabelItem> items = funnelLabels(
        const VarietyFunnelSeries(
          data: stages,
          color: Color(0xFF123456),
          dataLabelSettings: VarietyDataLabelSettings(
            isVisible: true,
            useSeriesColor: true,
          ),
        ),
      );
      expect(items, hasLength(3));
      for (final VarietyLabelItem item in items) {
        expect(item.color, const Color(0xFF123456));
      }
    });
  });

  group('circular labels', () {
    test('ask the mapper for every slice', () {
      final List<int> asked = <int>[];
      paintCircular(
        VarietyPieSeries(
          data: stages,
          dataLabelSettings: const VarietyDataLabelSettings(isVisible: true),
          dataLabelMapper: (VarietyChartData point, int index) {
            asked.add(index);
            return 'slice $index';
          },
        ),
      );
      expect(asked, <int>[0, 1, 2]);
    });

    test('prefer a slice label to the value under it', () {
      const List<VarietyChartData> bare = <VarietyChartData>[
        VarietyChartData('A', 30),
        VarietyChartData('B', 70),
      ];
      const List<VarietyChartData> named = <VarietyChartData>[
        VarietyChartData('A', 30, label: 'Visitors'),
        VarietyChartData('B', 70, label: 'Returning visitors'),
      ];
      final ui.Paragraph values = paintCircular(
        const VarietyPieSeries(
          data: bare,
          dataLabelSettings: VarietyDataLabelSettings(isVisible: true),
        ),
      ).first;
      final ui.Paragraph labels = paintCircular(
        const VarietyPieSeries(
          data: named,
          dataLabelSettings: VarietyDataLabelSettings(isVisible: true),
        ),
      ).first;
      // The first slice prints "30" of its own or "Visitors" when it has one,
      // and the longer caption is wider whichever font the test surface uses.
      expect(labels.width, greaterThan(values.width));
    });

    test('are drawn in the theme data label style', () {
      final ui.Paragraph plain = paintCircular(
        const VarietyPieSeries(
          data: stages,
          dataLabelSettings: VarietyDataLabelSettings(isVisible: true),
        ),
      ).first;
      final ui.Paragraph grown = paintCircular(
        const VarietyPieSeries(
          data: stages,
          dataLabelSettings: VarietyDataLabelSettings(isVisible: true),
        ),
        theme: const VarietyChartTheme(
          gridLineColor: Color(0x1F000000),
          axisLineColor: Color(0x59000000),
          labelColor: Color(0xBF000000),
          tooltipBackgroundColor: Color(0xFF32323A),
          tooltipTextColor: Colors.white,
          markerBorderColor: Colors.white,
          dataLabelTextStyle: TextStyle(fontSize: 22),
        ),
      ).first;
      // A theme that grows its data labels used to stop at the cartesian
      // charts and leave a slice at 11px.
      expect(grown.height, greaterThan(plain.height));
    });
  });
}

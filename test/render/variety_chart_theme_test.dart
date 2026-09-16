import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_test/flutter_test.dart';

const VarietyChartTheme base = VarietyChartTheme(
  gridLineColor: Color(0x22000000),
  axisLineColor: Color(0xFF888888),
  labelColor: Color(0xFF333333),
  tooltipBackgroundColor: Color(0xFF32323A),
  tooltipTextColor: Color(0xFFFFFFFF),
  markerBorderColor: Color(0xFFFFFFFF),
);

void main() {
  group('theme fallbacks', () {
    test('an unset field derives from the six base colours', () {
      // The minor grid keeps the major grid's hue at the alpha it has always
      // been drawn with.
      expect(base.minorGridLineColor.a, closeTo(0.6, 0.01));
      expect(base.minorGridLineColor.r, base.gridLineColor.r);
      expect(base.axisTitleColor, base.labelColor);
      expect(base.titleTextColor, base.labelColor);
      expect(base.legendTextColor, base.labelColor);
      expect(base.legendTitleColor, base.legendTextColor);
      expect(base.dataLabelColor, base.labelColor);
      expect(base.crosshairLineColor, base.axisLineColor);
      expect(base.majorTickLineColor, base.axisLineColor);
      expect(base.selectionRectBorderColor, base.axisLineColor);
    });

    test('nothing draws a card or fill unless asked', () {
      expect(base.titleBackgroundColor, isNull);
      expect(base.legendBackgroundColor, isNull);
      expect(base.plotAreaBackgroundColor, isNull);
      expect(base.plotAreaBorderColor, isNull);
      expect(base.palette, isNull);
    });

    test('an explicit value wins', () {
      final VarietyChartTheme themed = base.copyWith(
        minorGridLineColor: const Color(0xFF00FF00),
        legendTitleColor: const Color(0xFF0000FF),
      );
      expect(themed.minorGridLineColor, const Color(0xFF00FF00));
      expect(themed.legendTitleColor, const Color(0xFF0000FF));
      // The rest is untouched.
      expect(themed.gridLineColor, base.gridLineColor);
      expect(themed.legendTextColor, base.legendTextColor);
    });

    test('copyWith does not disturb equality of an identical theme', () {
      expect(base.copyWith(), base);
      expect(base.copyWith().hashCode, base.hashCode);
      expect(base.copyWith(labelColor: const Color(0xFF111111)), isNot(base));
    });
  });

  group('theme scope', () {
    testWidgets('reaches a chart through the widget tree', (
      WidgetTester tester,
    ) async {
      late VarietyChartTheme seen;
      final VarietyChartTheme themed =
          base.copyWith(labelColor: const Color(0xFFABCDEF));
      await tester.pumpWidget(
        MaterialApp(
          home: VarietyChartThemeScope(
            data: themed,
            child: Builder(
              builder: (BuildContext context) {
                seen = VarietyChartTheme.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(seen, themed);
    });

    testWidgets('falls back to the ambient ThemeData when absent', (
      WidgetTester tester,
    ) async {
      late VarietyChartTheme seen;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              seen = VarietyChartTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(seen.palette, isNull);
      expect(seen.labelColor, isNot(Colors.transparent));
    });
  });

  group('palette', () {
    test('a themed palette drives the series colours', () {
      const List<Color> palette = <Color>[
        Color(0xFF010203),
        Color(0xFF040506),
      ];
      VarietyCartesianGeometry build(List<Color>? colors) =>
          VarietyCartesianGeometry(
            series: <VarietySeries>[
              VarietyLineSeries(name: 'A', data: _points()),
              VarietyLineSeries(name: 'B', data: _points()),
            ],
            xAxis: const VarietyAxis(type: VarietyAxisType.category),
            yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
            plotRect: const Rect.fromLTWH(40, 10, 320, 220),
            progress: 1,
            palette: colors,
          );

      final VarietyCartesianGeometry plain = build(null);
      final VarietyCartesianGeometry themed = build(palette);
      expect(themed.colorFor(themed.series[0], 0, 0), palette[0]);
      expect(themed.colorFor(themed.series[1], 1, 0), palette[1]);
      // Without a palette the built-in one is used, which differs from ours.
      expect(plain.colorFor(plain.series[0], 0, 0), isNot(palette[0]));
    });

    test('an empty palette is ignored', () {
      final VarietyCartesianGeometry geometry = VarietyCartesianGeometry(
        series: <VarietySeries>[
          VarietyLineSeries(name: 'A', data: _points()),
        ],
        xAxis: const VarietyAxis(type: VarietyAxisType.category),
        yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
        plotRect: const Rect.fromLTWH(40, 10, 320, 220),
        progress: 1,
        palette: const <Color>[],
      );
      expect(geometry.seriesColors, isNotEmpty);
    });
  });
}

List<VarietyChartData> _points() => const <VarietyChartData>[
      VarietyChartData('Jan', 10),
      VarietyChartData('Feb', 20),
    ];

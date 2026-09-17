import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
// The painter is not part of the public surface, but the room reserved for the
// labels only ever reaches the outside world as the geometry it is handed, so
// this test has to reach for it.
import 'package:flutter_variety_chart/src/painters/variety_cartesian_painter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

/// The base theme the charts below are drawn with. Its label style is left
/// unset, so every case has to go through the fallback chain.
const VarietyChartTheme base = VarietyChartTheme(
  gridLineColor: Color(0x1F000000),
  axisLineColor: Color(0x59000000),
  labelColor: Color(0xBF000000),
  tooltipBackgroundColor: Color(0xFF32323A),
  tooltipTextColor: Colors.white,
  markerBorderColor: Colors.white,
);

/// Far larger than the built-in 11 px fallback, so a chart that honours the
/// theme needs visibly more room than one that quietly ignores it.
const TextStyle bigLabels = TextStyle(fontSize: 30);

/// The style the same chart, drawn small, should be reserving room for.
const TextStyle smallLabels = TextStyle(fontSize: 11);

const VarietyAxis numericX = VarietyAxis(
  type: VarietyAxisType.numeric,
  minimum: 0,
  maximum: 10,
);

const VarietyAxis numericY = VarietyAxis(type: VarietyAxisType.numeric);

const VarietyAxis secondaryX = VarietyAxis(
  type: VarietyAxisType.numeric,
  name: 'second',
  minimum: 0,
  maximum: 10,
);

List<VarietyChartData> points() => const <VarietyChartData>[
      VarietyChartData(0, 10),
      VarietyChartData(5, 32),
      VarietyChartData(10, 18),
    ];

/// The geometry the chart is drawing, which carries the plot rectangle the
/// widget reserved for it.
VarietyCartesianGeometry chartGeometry(WidgetTester tester) {
  final CustomPaint paint = tester.widget<CustomPaint>(
    find
        .descendant(
          of: find.byType(VarietyCartesianChart),
          matching: find.byType(CustomPaint),
        )
        .first,
  );
  return (paint.painter! as VarietyCartesianPainter).geometry;
}

Widget chart({
  VarietyChartTheme theme = base,
  VarietyAxis xAxis = numericX,
  VarietyAxis yAxis = numericY,
  List<VarietyAxis> secondary = const <VarietyAxis>[],
}) {
  return host(
    VarietyChartThemeScope(
      data: theme,
      child: VarietyCartesianChart(
        primaryXAxis: xAxis,
        primaryYAxis: yAxis,
        secondaryXAxes: secondary,
        showLegend: false,
        series: <VarietySeries>[
          VarietyLineSeries(name: 'A', data: points()),
        ],
      ),
    ),
  );
}

Future<VarietyCartesianGeometry> pump(
    WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
  return chartGeometry(tester);
}

void main() {
  group('themed axis label style', () {
    testWidgets('the value axis reserves room using the themed style',
        (WidgetTester tester) async {
      final double smallLeft = (await pump(tester, chart())).plotRect.left;
      final double bigLeft = (await pump(
        tester,
        chart(theme: base.copyWith(axisLabelTextStyle: bigLabels)),
      ))
          .plotRect
          .left;

      // A 30 px tick label is roughly three times as wide as an 11 px one, so
      // the left inset has to have grown. Before the theme reached this code
      // the two insets were byte-for-byte identical.
      expect(bigLeft, greaterThan(smallLeft));
    });

    testWidgets('a stacked horizontal axis measures its row with the theme',
        (WidgetTester tester) async {
      // The primary row is pinned with an explicit style so the theme can only
      // reach the secondary row; otherwise the primary row growing underneath
      // it would hide whether the extra row was measured at all.
      const VarietyAxis pinnedPrimary = VarietyAxis(
        type: VarietyAxisType.numeric,
        minimum: 0,
        maximum: 10,
        labelStyle: smallLabels,
      );
      Widget stacked(VarietyChartTheme theme) => chart(
            theme: theme,
            xAxis: pinnedPrimary,
            secondary: const <VarietyAxis>[secondaryX],
          );

      final double smallBottom =
          (await pump(tester, stacked(base))).plotRect.bottom;
      final double bigBottom = (await pump(
        tester,
        stacked(base.copyWith(axisLabelTextStyle: bigLabels)),
      ))
          .plotRect
          .bottom;

      expect(bigBottom, lessThan(smallBottom));
    });

    testWidgets('an explicit axis style still wins over the theme',
        (WidgetTester tester) async {
      final double plainLeft = (await pump(tester, chart())).plotRect.left;

      // The theme asks for the big style, but this axis names its own.
      final double pinnedLeft = (await pump(
        tester,
        chart(
          theme: base.copyWith(axisLabelTextStyle: bigLabels),
          yAxis: const VarietyAxis(
            type: VarietyAxisType.numeric,
            labelStyle: smallLabels,
          ),
        ),
      ))
          .plotRect
          .left;

      expect(pinnedLeft, plainLeft);
    });
  });
}

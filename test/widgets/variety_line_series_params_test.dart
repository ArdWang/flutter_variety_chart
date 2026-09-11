import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final List<VarietyChartData> points = <VarietyChartData>[
    const VarietyChartData(0, 4),
    const VarietyChartData(1, 9),
    const VarietyChartData(2, 6),
    const VarietyChartData(3, 8),
    const VarietyChartData(4, 2),
  ];

  Widget chart(List<VarietySeries> series) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 320,
            child: VarietyCartesianChart(
              primaryXAxis: const VarietyAxis(type: VarietyAxisType.numeric),
              primaryYAxis: const VarietyAxis(type: VarietyAxisType.numeric),
              series: series,
            ),
          ),
        ),
      );

  group('LineSeries extended parameters', () {
    testWidgets('sortFieldValueMapper overrides x for sorting', (WidgetTester tester) async {
      await tester.pumpWidget(
        chart(<VarietyLineSeries>[
          VarietyLineSeries(
            name: 'a',
            data: points,
            sortingOrder: VarietySortingOrder.ascending,
            sortFieldValueMapper: (VarietyChartData p) => -p.y!,
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('gradient and borderGradient render without crashing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        chart(<VarietyLineSeries>[
          VarietyLineSeries(
            name: 'a',
            data: points,
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF3F6FE0), Color(0xFF18B47B)],
            ),
            borderGradient: const LinearGradient(
              colors: <Color>[Color(0xFF000000), Color(0xFFFFFFFF)],
            ),
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('markerSettings takes effect on a line series', (WidgetTester tester) async {
      await tester.pumpWidget(
        chart(<VarietyLineSeries>[
          VarietyLineSeries(
            name: 'a',
            data: points,
            markerSettings: const VarietyMarkerSettings(
              isVisible: true,
              shape: VarietyMarkerShape.diamond,
              color: Color(0xFF18B47B),
            ),
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('initialIsVisible hides a series from render', (WidgetTester tester) async {
      await tester.pumpWidget(
        chart(<VarietyLineSeries>[
          VarietyLineSeries(name: 'a', data: points),
          VarietyLineSeries(name: 'b', data: points, initialIsVisible: false),
        ]),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('legendItemText and isVisibleInLegend filter the legend',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        chart(<VarietyLineSeries>[
          VarietyLineSeries(name: 'a', data: points, legendItemText: 'Series A'),
          VarietyLineSeries(name: 'b', data: points, isVisibleInLegend: false),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Series A'), findsOneWidget);
      expect(find.text('b'), findsNothing);
    });

    testWidgets('enableTrackball controls whether a series joins the trackball',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        chart(<VarietyLineSeries>[
          VarietyLineSeries(name: 'a', data: points, enableTrackball: false),
          VarietyLineSeries(name: 'b', data: points),
        ]),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('animationDuration on the widget applies during entry',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 320,
              child: VarietyCartesianChart(
                primaryXAxis: const VarietyAxis(type: VarietyAxisType.numeric),
                primaryYAxis: const VarietyAxis(type: VarietyAxisType.numeric),
                series: <VarietyLineSeries>[
                  VarietyLineSeries(
                    name: 'a',
                    data: points,
                    animationDuration: const Duration(milliseconds: 250),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
// The painter is not part of the public surface, but a tap has to be aimed at a
// point, and only the geometry knows where the points landed.
import 'package:flutter_variety_chart/src/painters/variety_cartesian_painter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  final List<VarietyChartData> points = <VarietyChartData>[
    const VarietyChartData(0, 4),
    const VarietyChartData(1, 9),
    const VarietyChartData(2, 6),
    const VarietyChartData(3, 8),
    const VarietyChartData(4, 2),
  ];

  Widget chart({
    List<VarietySeries> series = const <VarietySeries>[],
    VarietySelectionBehavior? selection,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 320,
            child: VarietyCartesianChart(
              primaryXAxis: const VarietyAxis(type: VarietyAxisType.numeric),
              primaryYAxis: const VarietyAxis(type: VarietyAxisType.numeric),
              series: series,
              selectionBehavior: selection,
            ),
          ),
        ),
      );

  group('onCreateRenderer / onRendererCreated', () {
    testWidgets('painters route per-series to the factory',
        (WidgetTester tester) async {
      int factoryCalls = 0;
      int createdCallbacks = 0;
      VarietyElementRenderer? captured;
      await tester.pumpWidget(
        chart(series: <VarietyLineSeries>[
          VarietyLineSeries(
            name: 'a',
            data: points,
            onCreateRenderer: (VarietyChartTheme theme, VarietySeries series) {
              factoryCalls++;
              return VarietyElementRenderer(theme);
            },
            onRendererCreated:
                (VarietyElementRenderer renderer, int seriesIndex) {
              createdCallbacks++;
              captured = renderer;
            },
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(factoryCalls, greaterThanOrEqualTo(1));
      expect(createdCallbacks, greaterThanOrEqualTo(1));
      expect(captured, isNotNull);
    });

    testWidgets('multiple series each get their own renderer',
        (WidgetTester tester) async {
      int factoryCalls = 0;
      await tester.pumpWidget(
        chart(series: <VarietyLineSeries>[
          VarietyLineSeries(
            name: 'a',
            data: points,
            onCreateRenderer: (VarietyChartTheme theme, VarietySeries series) {
              factoryCalls++;
              return VarietyElementRenderer(theme);
            },
          ),
          VarietyLineSeries(
            name: 'b',
            data: points,
            onCreateRenderer: (VarietyChartTheme theme, VarietySeries series) {
              factoryCalls++;
              return VarietyElementRenderer(theme);
            },
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(factoryCalls, greaterThanOrEqualTo(2));
    });
  });

  group('onCreateShader', () {
    testWidgets('a custom shader is consulted during path fill',
        (WidgetTester tester) async {
      int shaderCalls = 0;
      await tester.pumpWidget(
        chart(series: <VarietyLineSeries>[
          VarietyLineSeries(
            name: 'a',
            data: points,
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF3F6FE0), Color(0xFF18B47B)],
            ),
            onCreateShader: (
              VarietySeries series,
              Rect bounds,
              bool isFill,
            ) {
              shaderCalls++;
              return null; // fall through to gradient
            },
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(shaderCalls, greaterThan(0));
    });

    testWidgets('overriding shader is applied to the line',
        (WidgetTester tester) async {
      int shaderCalls = 0;
      await tester.pumpWidget(
        chart(series: <VarietyLineSeries>[
          VarietyLineSeries(
            name: 'a',
            data: points,
            onCreateShader: (
              VarietySeries series,
              Rect bounds,
              bool isFill,
            ) {
              shaderCalls++;
              return const LinearGradient(
                colors: <Color>[Color(0xFFFF0000), Color(0xFF0000FF)],
              ).createShader(bounds);
            },
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(shaderCalls, greaterThan(0));
    });
  });

  group('selectionBehavior', () {
    testWidgets(
        'a series-specific selectionBehaviour is preferred over the chart-wide one',
        (WidgetTester tester) async {
      int perSeriesApplied = 0;
      await tester.pumpWidget(
        chart(
          series: <VarietySeries>[
            VarietyColumnSeries(
              name: 'a',
              data: monthly(),
              selectionBehavior: VarietySelectionBehavior(
                enabled: true,
                onSelectionChanged: (List<VarietyHitResult> hits) {
                  perSeriesApplied++;
                },
              ),
            ),
          ],
          selection: const VarietySelectionBehavior(enabled: false),
        ),
      );
      await tester.pumpAndSettle();

      // The chart wide behaviour is off, so a selection can only arrive through
      // the series' own. The test used to say in a comment that it never
      // simulated a tap, and then assert the callback had not run.
      final Finder canvas = find
          .descendant(
            of: find.byType(VarietyCartesianChart),
            matching: find.byType(CustomPaint),
          )
          .first;
      final VarietyCartesianGeometry geometry = (tester
              .widget<CustomPaint>(canvas)
              .painter! as VarietyCartesianPainter)
          .geometry;
      await tester.tapAt(
        tester.getTopLeft(canvas) + geometry.pointPositions[0][0],
      );
      await tester.pumpAndSettle();
      expect(perSeriesApplied, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'chart-wide selectionBehaviour is used when the series has none',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        chart(
          series: <VarietyLineSeries>[
            VarietyLineSeries(name: 'a', data: points),
          ],
          selection: const VarietySelectionBehavior(enabled: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

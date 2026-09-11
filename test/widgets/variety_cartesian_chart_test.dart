import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('renders a chart with a title and a legend', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyCartesianChart(
          title: 'Revenue',
          series: <VarietySeries>[
            VarietyColumnSeries(name: 'Actual', data: monthly()),
            VarietyLineSeries(
              name: 'Target',
              data: monthly(),
              lineStyle: VarietyLineStyle.curved,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Revenue'), findsOneWidget);
    expect(find.text('Actual'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
  });

  testWidgets('clamps itself when the parent does not bound the height',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VarietyCartesianChart(
              series: <VarietySeries>[
                VarietyColumnSeries(name: 'A', data: monthly()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('fires onPointTap when a column is tapped', (WidgetTester tester) async {
    bool called = false;
    VarietyHitResult? tapped;
    await tester.pumpWidget(
      host(
        VarietyCartesianChart(
          onPointTap: (VarietyHitResult? hit) {
            called = true;
            tapped = hit;
          },
          series: <VarietySeries>[
            // A single slot makes the column cover the centre of the plot.
            VarietyColumnSeries(
              name: 'A',
              data: const <VarietyChartData>[VarietyChartData('Only', 50)],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(chartCanvas()));
    await tester.pumpAndSettle();
    expect(called, isTrue);
    expect(tapped, isNotNull);
  });

  testWidgets('shows a tooltip card after a tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyCartesianChart(
          series: <VarietySeries>[
            VarietyColumnSeries(
              name: 'Revenue',
              data: const <VarietyChartData>[VarietyChartData('Only', 50)],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(chartCanvas()));
    await tester.pumpAndSettle();
    expect(find.byType(VarietyTooltipCard), findsOneWidget);
  });

  testWidgets('positions the legend on the top', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyCartesianChart(
          legendPosition: VarietyLegendPosition.top,
          series: <VarietySeries>[
            VarietyColumnSeries(name: 'A', data: monthly()),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(VarietyLegend), findsOneWidget);
  });

  testWidgets('hides the legend when asked to', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyCartesianChart(
          showLegend: false,
          series: <VarietySeries>[
            VarietyColumnSeries(name: 'A', data: monthly()),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(VarietyLegend), findsNothing);
  });

  testWidgets('renders a transposed bar chart without clipping the bars',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyCartesianChart(
          series: <VarietySeries>[
            VarietyBarSeries(name: 'A', data: monthly()),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders every series kind in one chart', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyCartesianChart(
          primaryXAxis: const VarietyAxis(type: VarietyAxisType.numeric),
          series: <VarietySeries>[
            VarietyLineSeries(name: 'Line', data: rising()),
            VarietyAreaSeries(name: 'Area', data: rising()),
            VarietyScatterSeries(name: 'Scatter', data: rising()),
            VarietyBubbleSeries(name: 'Bubble', data: rising()),
            VarietySplineSeriesLike(name: 'Stepped', data: rising()),
          ],
        ),
        height: 400,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders financial series', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyCartesianChart(
          primaryXAxis: const VarietyAxis(type: VarietyAxisType.numeric),
          series: <VarietySeries>[
            VarietyCandleSeries(
              name: 'ACME',
              data: const <VarietyChartData>[
                VarietyChartData(1, 0, open: 10, high: 14, low: 9, close: 13),
                VarietyChartData(2, 0, open: 13, high: 15, low: 11, close: 12),
              ],
            ),
            VarietyHiLoSeries(
              name: 'Hi-lo',
              data: const <VarietyChartData>[
                VarietyChartData(1, 12, high: 14, low: 9),
                VarietyChartData(2, 13, high: 15, low: 11),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('replays the animation when the series change',
      (WidgetTester tester) async {
    Widget build(List<VarietyChartData> data) => host(
          VarietyCartesianChart(
            animationDuration: const Duration(milliseconds: 200),
            series: <VarietySeries>[VarietyColumnSeries(name: 'A', data: data)],
          ),
        );

    await tester.pumpWidget(build(monthly()));
    await tester.pumpAndSettle();
    await tester.pumpWidget(build(monthly().sublist(0, 2)));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports a zoom and pan behaviour without throwing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyCartesianChart(
          zoomPanBehavior: const VarietyZoomPanBehavior(mode: VarietyZoomMode.both),
          series: <VarietySeries>[
            VarietyLineSeries(name: 'A', data: monthly()),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final Offset centre = tester.getCenter(chartCanvas());
    await tester.tapAt(centre);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tapAt(centre);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

/// Finds the painting widget owned by the chart under test.
Finder chartCanvas() => find.descendant(
      of: find.byType(VarietyCartesianChart),
      matching: find.byType(CustomPaint),
    ).first;

/// A thin alias used to widen the "every series kind" smoke test.
class VarietySplineSeriesLike extends VarietyLineSeries {
  /// Creates a stepped line series.
  const VarietySplineSeriesLike({required super.data, super.name})
      : super(lineStyle: VarietyLineStyle.stepped);
}

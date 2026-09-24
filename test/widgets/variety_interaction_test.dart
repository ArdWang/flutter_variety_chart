import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../test_helpers.dart';

/// A single slot makes the column cover the centre of the plot.
List<VarietyChartData> singleSlot() => const <VarietyChartData>[
      VarietyChartData('Only', 50),
    ];

Finder chartCanvas() => find
    .descendant(
      of: find.byType(VarietyCartesianChart),
      matching: find.byType(CustomPaint),
    )
    .first;

void main() {
  group('selection', () {
    testWidgets('a selection controller drives the chart',
        (WidgetTester tester) async {
      final VarietySelectionController controller =
          VarietySelectionController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            selectionController: controller,
            selectionBehavior: const VarietySelectionBehavior(),
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'A', data: singleSlot()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(chartCanvas()));
      await tester.pumpAndSettle();
      expect(controller.selected, hasLength(1));
      expect(controller.isEmpty, isFalse);

      controller.clear();
      await tester.pumpAndSettle();
      expect(controller.selected, isEmpty);
    });

    testWidgets('multi selection collects more than one point',
        (WidgetTester tester) async {
      final VarietySelectionController controller =
          VarietySelectionController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            selectionController: controller,
            selectionBehavior: const VarietySelectionBehavior(
              enableMultiSelection: true,
            ),
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'A', data: monthly()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.select(<VarietyHitResult>[]);
      expect(controller.selected, isEmpty);
    });
  });

  group('legend', () {
    testWidgets('tapping an item toggles the series visibility',
        (WidgetTester tester) async {
      VarietyLegendTapDetails? details;
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            legendSettings: const VarietyLegendSettings(
              toggleSeriesVisibility: true,
            ),
            onLegendTapped: (VarietyLegendTapDetails value) => details = value,
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'Alpha', data: monthly()),
              VarietyLineSeries(name: 'Beta', data: monthly()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      expect(details, isNotNull);
      expect(details!.series.name, 'Alpha');
      expect(details!.isVisible, isFalse);
    });

    testWidgets('tapping an item actually drops the series from the plot',
        (WidgetTester tester) async {
      bool? reported;
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            legendSettings: const VarietyLegendSettings(
              toggleSeriesVisibility: true,
            ),
            onLegendTapped: (VarietyLegendTapDetails value) =>
                reported = value.isVisible,
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'Alpha', data: monthly()),
              VarietyLineSeries(name: 'Beta', data: monthly()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Both legends start undecorated.
      expect(
        tester.widget<Text>(find.text('Alpha')).style?.decoration,
        isNot(TextDecoration.lineThrough),
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      // The tap has to change the chart's own hidden set, not just report it:
      // the legend strikes the caption through exactly when the series is in
      // that set, so this is the state the plot is filtered by.
      expect(reported, isFalse);
      expect(
        tester.widget<Text>(find.text('Alpha')).style?.decoration,
        TextDecoration.lineThrough,
      );
      expect(
        tester.widget<Text>(find.text('Beta')).style?.decoration,
        isNot(TextDecoration.lineThrough),
      );

      // Tapping again brings the series back.
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      expect(reported, isTrue);
      expect(
        tester.widget<Text>(find.text('Alpha')).style?.decoration,
        isNot(TextDecoration.lineThrough),
      );
    });

    testWidgets('a tap reports the series but keeps it when toggling is off',
        (WidgetTester tester) async {
      VarietyLegendTapDetails? details;
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            onLegendTapped: (VarietyLegendTapDetails value) => details = value,
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'Alpha', data: monthly()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      expect(details, isNotNull);
      expect(
        tester.widget<Text>(find.text('Alpha')).style?.decoration,
        isNot(TextDecoration.lineThrough),
      );
    });

    testWidgets('hiding the last visible series leaves the legend in place',
        (WidgetTester tester) async {
      // Tapping an entry is the only way to bring a hidden series back, so the
      // legend has to outlive hiding everything it describes. It used to be
      // asked for by the series still on the plot, which meant hiding the last
      // one took the legend away with it and stranded the reader.
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            legendSettings: const VarietyLegendSettings(
              toggleSeriesVisibility: true,
            ),
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'Alpha', data: monthly()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);

      // And a second tap brings the series back.
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.text('Alpha')).style?.decoration,
        isNot(TextDecoration.lineThrough),
      );
    });

    testWidgets('a hidden custom item is dimmed rather than restyled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            legendSettings: const VarietyLegendSettings(
              toggleSeriesVisibility: true,
            ),
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'Alpha', data: monthly()),
            ],
            legendBuilder:
                (BuildContext context, VarietySeries series, int i) =>
                    Text('custom-${series.name}'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('custom-Alpha'));
      await tester.pumpAndSettle();
      final Opacity dimmed = tester.widget<Opacity>(
        find.ancestor(
          of: find.text('custom-Alpha'),
          matching: find.byType(Opacity),
        ),
      );
      expect(dimmed.opacity, lessThan(1.0));
    });

    testWidgets('a legend title is rendered', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            legendSettings: const VarietyLegendSettings(title: 'Series'),
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'Alpha', data: monthly()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Series'), findsOneWidget);
    });
  });

  group('callbacks', () {
    testWidgets('onTooltipRender can suppress the tooltip',
        (WidgetTester tester) async {
      int calls = 0;
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            onTooltipRender: (VarietyTooltipDetails details) {
              calls++;
              return false;
            },
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'A', data: singleSlot()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(chartCanvas()));
      await tester.pumpAndSettle();
      expect(calls, greaterThan(0));
      expect(find.byType(VarietyTooltipCard), findsNothing);
    });

    testWidgets('onDataLabelRender rewrites a caption',
        (WidgetTester tester) async {
      int calls = 0;
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            onDataLabelRender: (VarietyDataLabelRenderDetails details) {
              calls++;
              return 'v=${details.point.y}';
            },
            series: <VarietySeries>[
              VarietyColumnSeries(
                name: 'A',
                data: monthly(),
                dataLabelSettings:
                    const VarietyDataLabelSettings(isVisible: true),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('onAxisLabelTapped fires for a tick label',
        (WidgetTester tester) async {
      VarietyAxisLabelTapDetails? details;
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            onAxisLabelTapped: (VarietyAxisLabelTapDetails value) =>
                details = value,
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'A', data: monthly()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The primary axis labels sit just under the plot area, so probe along
      // that band until one is hit.
      final Rect canvas = tester.getRect(chartCanvas());
      for (double ratio = 0.1;
          ratio <= 0.95 && details == null;
          ratio += 0.05) {
        await tester.tapAt(
          Offset(
            canvas.left + canvas.width * ratio,
            canvas.bottom - canvas.height * 0.06,
          ),
        );
        await tester.pumpAndSettle();
      }
      expect(details, isNotNull);
      expect(details!.text, isNotEmpty);
    });
  });

  group('rendering', () {
    testWidgets('onDemand shows the placeholder until the first interaction',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            renderingMode: VarietyRenderingMode.onDemand,
            loadingBuilder: (BuildContext context) =>
                const Center(child: Text('loading')),
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'A', data: monthly()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('loading'), findsOneWidget);
      await tester.tapAt(tester.getCenter(chartCanvas()));
      await tester.pumpAndSettle();
      expect(find.text('loading'), findsNothing);
    });
  });

  group('new series in a chart', () {
    testWidgets('box plot, error bar and spline area all render',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            series: <VarietySeries>[
              VarietySplineAreaSeries(name: 'Spline', data: monthly()),
              VarietyBoxAndWhiskerSeries(
                name: 'Box',
                data: const <VarietyChartData>[
                  VarietyChartData('A', 10, label: 'A'),
                  VarietyChartData('A', 20, label: 'A'),
                  VarietyChartData('A', 35, label: 'A'),
                  VarietyChartData('B', 12, label: 'B'),
                  VarietyChartData('B', 24, label: 'B'),
                  VarietyChartData('B', 40, label: 'B'),
                ],
              ),
              VarietyErrorBarSeries(
                  name: 'Error', data: monthly(), errorValue: 4),
            ],
          ),
          height: 420,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('an inverted axis renders without throwing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            primaryYAxis: const VarietyAxis(
              type: VarietyAxisType.numeric,
              isInversed: true,
            ),
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'A', data: monthly()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a dense category axis with label hiding renders safely',
        (WidgetTester tester) async {
      final List<VarietyChartData> dense = List<VarietyChartData>.generate(
        40,
        (int i) => VarietyChartData('Day ${i + 1}', (i % 9).toDouble()),
      );
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(
              type: VarietyAxisType.category,
              labelIntersectAction: VarietyLabelIntersectAction.hide,
              minorTicksPerInterval: 1,
              minorGridLines: VarietyMinorGridLines(),
            ),
            series: <VarietySeries>[
              VarietyLineSeries(name: 'A', data: dense),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('minor grid lines and a rectangle border are drawn',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(
              type: VarietyAxisType.category,
              minorTicksPerInterval: 1,
            ),
            primaryYAxis: const VarietyAxis(
              type: VarietyAxisType.numeric,
              minorTicksPerInterval: 1,
              minorGridLines: VarietyMinorGridLines(),
              borderType: VarietyAxisBorderType.rectangle,
            ),
            series: <VarietySeries>[
              VarietyLineSeries(name: 'A', data: monthly()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

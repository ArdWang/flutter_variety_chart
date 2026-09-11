import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('renders one entry per named series',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyLegend(
          series: <VarietySeries>[
            VarietyLineSeries(name: 'Alpha', data: const <VarietyChartData>[]),
            VarietyLineSeries(name: 'Beta', data: const <VarietyChartData>[]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('skips unnamed series', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyLegend(
          series: <VarietySeries>[
            VarietyLineSeries(data: const <VarietyChartData>[]),
            VarietyLineSeries(name: 'Named', data: const <VarietyChartData>[]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Named'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('collapses when nothing can be labelled',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyLegend(
          series: <VarietySeries>[
            VarietyLineSeries(data: const <VarietyChartData>[]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('reports taps on an item', (WidgetTester tester) async {
    VarietySeries? tapped;
    await tester.pumpWidget(
      host(
        VarietyLegend(
          onItemTap: (VarietySeries series, int index) => tapped = series,
          series: <VarietySeries>[
            VarietyLineSeries(name: 'Alpha', data: const <VarietyChartData>[]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(tapped?.name, 'Alpha');
  });

  testWidgets('uses a vertical layout on the side',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyLegend(
          position: VarietyLegendPosition.right,
          series: <VarietySeries>[
            VarietyLineSeries(name: 'Alpha', data: const <VarietyChartData>[]),
            VarietyLineSeries(name: 'Beta', data: const <VarietyChartData>[]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Column), findsWidgets);
  });

  testWidgets('supports a custom item builder', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyLegend(
          itemBuilder:
              (BuildContext context, VarietySeries series, int index) =>
                  Text('custom-${series.name}'),
          series: <VarietySeries>[
            VarietyLineSeries(name: 'Alpha', data: const <VarietyChartData>[]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('custom-Alpha'), findsOneWidget);
  });
}

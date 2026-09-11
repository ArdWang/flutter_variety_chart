import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../test_helpers.dart';

const List<VarietyChartData> slices = <VarietyChartData>[
  VarietyChartData('Search', 52),
  VarietyChartData('Direct', 28),
  VarietyChartData('Social', 20),
];

void main() {
  testWidgets('renders a pie chart', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyCircularChart(
          title: 'Traffic',
          series: <VarietySeries>[
            VarietyPieSeries(name: 'Sessions', data: slices),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Traffic'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
  });

  testWidgets('renders a doughnut with a centre widget',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyCircularChart(
          series: <VarietySeries>[
            VarietyDoughnutSeries(name: 'Sessions', data: slices),
          ],
          center: const Text('100'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('renders radial bars', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyCircularChart(
          series: <VarietySeries>[
            VarietyRadialBarSeries(name: 'Traffic', data: slices),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a tooltip after tapping a slice',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyCircularChart(
          series: <VarietySeries>[
            VarietyPieSeries(name: 'Sessions', data: slices),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The first slice starts at -90 degrees, so tap above the centre.
    final Finder canvas = find
        .descendant(
          of: find.byType(VarietyCircularChart),
          matching: find.byType(CustomPaint),
        )
        .first;
    final Rect bounds = tester.getRect(canvas);
    await tester
        .tapAt(Offset(bounds.center.dx, bounds.center.dy - bounds.height / 5));
    await tester.pumpAndSettle();
    expect(find.byType(VarietyTooltipCard), findsOneWidget);
  });

  testWidgets('clamps itself when the parent does not bound the height',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VarietyCircularChart(
              series: <VarietySeries>[
                VarietyPieSeries(name: 'Sessions', data: slices),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

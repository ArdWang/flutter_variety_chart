import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../test_helpers.dart';

const List<VarietyChartData> stages = <VarietyChartData>[
  VarietyChartData('Visited', 100, label: 'Visited'),
  VarietyChartData('Cart', 60, label: 'Cart'),
  VarietyChartData('Buy', 20, label: 'Buy'),
];

void main() {
  testWidgets('renders a funnel chart', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(VarietyFunnelChart(series: const VarietyFunnelSeries(name: 'Funnel', data: stages))),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('renders a pyramid chart', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(VarietyFunnelChart(series: const VarietyPyramidSeries(name: 'Pyramid', data: stages))),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('draws data labels when enabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyFunnelChart(
          series: const VarietyFunnelSeries(
            name: 'Funnel',
            dataLabelSettings: VarietyDataLabelSettings(isVisible: true),
            data: stages,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('fires onPointTap for a tapped segment', (WidgetTester tester) async {
    bool called = false;
    VarietyHitResult? tapped;
    await tester.pumpWidget(
      host(
        VarietyFunnelChart(
          onPointTap: (VarietyHitResult? hit) {
            called = true;
            tapped = hit;
          },
          series: const VarietyFunnelSeries(name: 'Funnel', data: stages),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final Finder canvas = find
        .descendant(
          of: find.byType(VarietyFunnelChart),
          matching: find.byType(CustomPaint),
        )
        .first;
    final Rect bounds = tester.getRect(canvas);
    await tester.tapAt(Offset(bounds.center.dx, bounds.top + bounds.height * 0.15));
    await tester.pumpAndSettle();
    expect(called, isTrue);
    expect(tapped, isNotNull);
  });

  testWidgets('shows the legend when asked to', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyFunnelChart(
          showLegend: true,
          series: const VarietyFunnelSeries(name: 'Funnel', data: stages),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(VarietyLegend), findsOneWidget);
  });

  testWidgets('clamps itself when the parent does not bound the height',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VarietyFunnelChart(
              series: const VarietyFunnelSeries(name: 'Funnel', data: stages),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

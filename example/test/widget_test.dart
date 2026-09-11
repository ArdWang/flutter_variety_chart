import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:variety_chart_example/main.dart';

void main() {
  testWidgets('the demo catalogue lists every page', (WidgetTester tester) async {
    await tester.pumpWidget(const VarietyChartExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Flutter Variety Chart'), findsOneWidget);
    expect(find.text('Line and area'), findsOneWidget);
    expect(find.text('Column and bar'), findsOneWidget);
    expect(find.text('Circular'), findsOneWidget);

    // The catalogue scrolls, so the last entry has to be brought into view.
    await tester.scrollUntilVisible(
      find.text('Funnel, pyramid and sparkline'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Funnel, pyramid and sparkline'), findsOneWidget);
  });

  testWidgets('opening a demo renders its charts', (WidgetTester tester) async {
    await tester.pumpWidget(const VarietyChartExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Circular'));
    await tester.pumpAndSettle();

    expect(find.text('Pie with outside labels'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

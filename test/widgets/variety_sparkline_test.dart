import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('renders a line sparkline from raw values',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          height: 40,
          child: VarietySparkline.fromValues(<double>[1, 5, 3, 8, 4, 9]),
        ),
        height: 80,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('renders every sparkline variant', (WidgetTester tester) async {
    for (final VarietySparklineType type in VarietySparklineType.values) {
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 40,
            child: VarietySparkline.fromValues(<double>[1, -2, 3, 4, -1, 6],
                type: type),
          ),
          height: 80,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('renders high and low point markers',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          height: 40,
          child: VarietySparkline.fromValues(
            <double>[1, 5, 3, 8, 4, 9],
            showHighPoint: true,
            showLowPoint: true,
          ),
        ),
        height: 80,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles a flat series without dividing by zero',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          height: 40,
          child: VarietySparkline.fromValues(<double>[4, 4, 4, 4]),
        ),
        height: 80,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles an empty series', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          height: 40,
          child: VarietySparkline.fromValues(<double>[]),
        ),
        height: 80,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('accepts VarietyChartData directly', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          height: 40,
          child: VarietySparkline(
            data: <VarietyChartData>[
              VarietyChartData(0, 2),
              VarietyChartData(1, 6),
              VarietyChartData(2, 4),
            ],
          ),
        ),
        height: 80,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

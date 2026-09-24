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

  /// Taps a point inside the first slice, which starts at -90 degrees.
  Future<void> tapSlice(WidgetTester tester) async {
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
  }

  /// The fill the tooltip card was built with.
  Color? cardFill(WidgetTester tester) {
    final Material material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(VarietyTooltipCard),
            matching: find.byType(Material),
          )
          .first,
    );
    return material.color;
  }

  group('tooltip configuration', () {
    Widget circular({VarietyTooltipBehavior? behavior, bool? enabled}) => host(
          VarietyCircularChart(
            enableTooltip: enabled ?? true,
            tooltipBehavior: behavior ?? const VarietyTooltipBehavior(),
            series: <VarietySeries>[
              VarietyPieSeries(name: 'Sessions', data: slices),
            ],
          ),
        );

    testWidgets('the card takes its fill from the behaviour',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        circular(
          behavior: const VarietyTooltipBehavior(
            backgroundColor: Color(0xFF123456),
            elevation: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapSlice(tester);
      expect(find.byType(VarietyTooltipCard), findsOneWidget);
      expect(cardFill(tester), const Color(0xFF123456));
    });

    testWidgets('the behaviour can switch the card off',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        circular(behavior: const VarietyTooltipBehavior(enabled: false)),
      );
      await tester.pumpAndSettle();
      await tapSlice(tester);
      expect(find.byType(VarietyTooltipCard), findsNothing);
    });

    testWidgets('enableTooltip still switches the card off',
        (WidgetTester tester) async {
      await tester.pumpWidget(circular(enabled: false));
      await tester.pumpAndSettle();
      await tapSlice(tester);
      expect(find.byType(VarietyTooltipCard), findsNothing);
    });

    testWidgets('the value is formatted with decimalPlaces',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        circular(
          behavior: const VarietyTooltipBehavior(decimalPlaces: 2),
        ),
      );
      await tester.pumpAndSettle();
      await tapSlice(tester);
      // The first slice is 52, which reads as 52.00 once asked for two
      // decimals.
      expect(find.text('52.00'), findsOneWidget);
    });
  });

  testWidgets('the centre slot follows the doughnut hole',
      (WidgetTester tester) async {
    // A doughnut's hole is `innerRadiusFactor` of its outer edge, so turning the
    // factor down has to shrink the room the centre widget is given. Sizing the
    // slot off the outer radius instead hands back the same number either way,
    // which is how a centre widget ends up sitting on the ring.
    Future<double> slotFor(double innerRadiusFactor) async {
      const Key probe = Key('centre-probe');
      await tester.pumpWidget(
        host(
          VarietyCircularChart(
            series: <VarietySeries>[
              VarietyDoughnutSeries(
                name: 'Traffic',
                innerRadiusFactor: innerRadiusFactor,
                data: slices,
              ),
            ],
            center: const SizedBox(key: probe, width: 1000, height: 1000),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byKey(probe)).width;
    }

    final double wide = await slotFor(0.62);
    final double narrow = await slotFor(0.30);
    expect(wide, greaterThan(0));
    expect(narrow, lessThan(wide));
    // The slot is the hole less a sliver, so halving the hole halves it too.
    expect(narrow, lessThanOrEqualTo(wide * 0.5));
  });
}

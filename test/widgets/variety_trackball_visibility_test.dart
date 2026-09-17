import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../test_helpers.dart';

/// Three points on a 0..100 scale, so the middle one sits at the centre of the
/// plot and a tap there lands well inside the activation distance.
List<VarietyChartData> points() => const <VarietyChartData>[
      VarietyChartData(0, 0),
      VarietyChartData(1, 50),
      VarietyChartData(2, 100),
    ];

Finder chartCanvas() => find
    .descendant(
      of: find.byType(VarietyCartesianChart),
      matching: find.byType(CustomPaint),
    )
    .first;

/// A tap-activated trackball, which is the only gesture that starts the
/// auto-hide countdown.
Widget chart(VarietyTrackballBehavior ball) => host(
      VarietyCartesianChart(
        primaryXAxis: const VarietyAxis(type: VarietyAxisType.numeric),
        primaryYAxis: const VarietyAxis(type: VarietyAxisType.numeric),
        trackballBehavior: ball,
        series: <VarietySeries>[
          VarietyLineSeries(name: 'A', data: points()),
        ],
      ),
    );

/// The shared tooltip card is what the trackball puts on screen, so its
/// presence is the readable sign that the trackball is up.
Finder cardFinder = find.byType(VarietyTrackballTooltipCard);

/// Taps the middle point. `pumpAndSettle` advances the clock a hundred
/// milliseconds per frame, so the hide delay under test has to be longer than
/// the entry animation takes to settle.
Future<void> activate(WidgetTester tester) async {
  await tester.tapAt(tester.getCenter(chartCanvas()));
  await tester.pumpAndSettle();
}

void main() {
  group('trackball visibilityMode', () {
    testWidgets('auto shows the trackball and then clears it',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        chart(
          const VarietyTrackballBehavior(
            activationMode: VarietyActivationMode.tap,
            hideDelay: Duration(seconds: 2),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await activate(tester);
      expect(cardFinder, findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(cardFinder, findsNothing);
    });

    testWidgets('always keeps the trackball past the hide delay',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        chart(
          const VarietyTrackballBehavior(
            activationMode: VarietyActivationMode.tap,
            hideDelay: Duration(seconds: 2),
            visibilityMode: VarietyTrackballVisibilityMode.always,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await activate(tester);
      expect(cardFinder, findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(cardFinder, findsOneWidget);
    });

    testWidgets('hidden never shows the trackball',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        chart(
          const VarietyTrackballBehavior(
            activationMode: VarietyActivationMode.tap,
            visibilityMode: VarietyTrackballVisibilityMode.hidden,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await activate(tester);
      expect(cardFinder, findsNothing);
    });

    testWidgets('hidden never shows the trackball on a drag either',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        chart(
          const VarietyTrackballBehavior(
            visibilityMode: VarietyTrackballVisibilityMode.hidden,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Offset centre = tester.getCenter(chartCanvas());
      final TestGesture gesture = await tester.startGesture(centre);
      await gesture.moveBy(const Offset(20, 0));
      await tester.pumpAndSettle();
      expect(cardFinder, findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}

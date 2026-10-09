import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

/// Ten points at x = 0..9, so a range can be named in round numbers.
List<VarietyChartData> counts() => List<VarietyChartData>.generate(
      10,
      (int i) => VarietyChartData(i, i.toDouble() + 1),
    );

/// An axis whose low end is fixed and whose high end follows the data, with
/// nothing else drawn.
///
/// The padding is what makes a window assertable in round numbers; with `auto`
/// padding the ends land somewhere between the ticks. The high end is left to
/// the points so that appending one can be seen to stretch it.
VarietyAxis countingAxis({VarietyRangeController? controller}) => VarietyAxis(
      type: VarietyAxisType.numeric,
      minimum: 0,
      rangePadding: VarietyRangePadding.none,
      rangeController: controller,
      showGridLines: false,
      showLabels: false,
      showTicks: false,
      showAxisLine: false,
    );

VarietyCartesianChart countingChart({
  VarietyRangeController? controller,
  void Function(VarietyRangeChangedDetails)? onRange,
}) =>
    VarietyCartesianChart(
      primaryXAxis: countingAxis(controller: controller),
      primaryYAxis: const VarietyAxis(showAxisLine: false, showLabels: false),
      enableAnimation: false,
      onActualRangeChanged: onRange,
      series: <VarietySeries>[VarietyLineSeries(name: 'n', data: counts())],
    );

void main() {
  group('VarietyRangeController', () {
    test('answers its own ends', () {
      final VarietyRangeController controller = VarietyRangeController();
      expect(controller.isPinned, isFalse);
      expect(controller.start, isNull);
      expect(controller.end, isNull);

      controller.start = 4;
      expect(controller.start, 4);
      // Setting one end does not silently pin the other.
      expect(controller.end, isNull);
      expect(controller.isPinned, isTrue);

      controller.clear();
      expect(controller.isPinned, isFalse);
    });

    test('reads and writes a date as an instant', () {
      final VarietyRangeController controller = VarietyRangeController();
      final DateTime start = DateTime(2026, 3, 4, 5, 6);
      final DateTime end = start.add(const Duration(hours: 1));
      controller.setDateTimeRange(start, end);
      expect(controller.dateTimeStart, start);
      expect(controller.dateTimeEnd, end);
      expect(
        controller.end! - controller.start!,
        const Duration(hours: 1).inMicroseconds.toDouble(),
      );
    });

    test('a range that does not move is not announced twice', () {
      final VarietyRangeController controller = VarietyRangeController();
      int calls = 0;
      controller.addListener(() => calls++);
      controller.setRange(1, 2);
      controller.setRange(1, 2);
      controller.setRange(1, 2);
      expect(calls, 1);
    });

    test('one ends move in one notification', () {
      final VarietyRangeController controller = VarietyRangeController();
      int calls = 0;
      controller.addListener(() => calls++);
      controller.setRange(1, 2);
      expect(calls, 1);
      expect(controller.start, 1);
      expect(controller.end, 2);
    });
  });

  group('A chart bounds to one', () {
    testWidgets('answers with the window it is showing', (
      WidgetTester tester,
    ) async {
      final VarietyRangeController controller = VarietyRangeController();
      await tester.pumpWidget(host(countingChart(controller: controller)));
      expect(controller.start, 0);
      expect(controller.end, 9);
    });

    testWidgets('shows the range that was pinned on it', (
      WidgetTester tester,
    ) async {
      final VarietyRangeController controller = VarietyRangeController();
      VarietyRangeChangedDetails? latest;
      await tester.pumpWidget(
        host(countingChart(
            controller: controller,
            onRange: (
              VarietyRangeChangedDetails details,
            ) {
              latest = details;
            })),
      );
      expect(latest, isNull, reason: 'nothing has changed yet');

      controller.setRange(3, 7);
      await tester.pump();
      await tester.pump();
      expect(latest, isNotNull);
      expect(latest!.minimum, 3);
      expect(latest!.maximum, 7);
    });

    testWidgets('clamps a pinned end to what the data reaches', (
      WidgetTester tester,
    ) async {
      final VarietyRangeController controller = VarietyRangeController();
      VarietyRangeChangedDetails? latest;
      await tester.pumpWidget(
        host(countingChart(
            controller: controller,
            onRange: (
              VarietyRangeChangedDetails details,
            ) {
              latest = details;
            })),
      );
      // Nobody can look at -20 of nothing: the window is clamped back onto the
      // points there are rather than being refused outright.
      controller.setRange(-20, 4);
      await tester.pump();
      await tester.pump();
      expect(latest!.minimum, 0);
      expect(latest!.maximum, 4);
    });

    testWidgets('an end nobody pinned goes on following the data', (
      WidgetTester tester,
    ) async {
      final VarietyRangeController controller = VarietyRangeController();
      final VarietyCartesianChartController data =
          VarietyCartesianChartController();
      final List<VarietyChartData> source = counts();
      VarietyRangeChangedDetails? latest;
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            primaryXAxis: countingAxis(controller: controller),
            primaryYAxis:
                const VarietyAxis(showAxisLine: false, showLabels: false),
            controller: data,
            enableAnimation: false,
            onActualRangeChanged: (VarietyRangeChangedDetails details) {
              latest = details;
            },
            series: <VarietySeries>[
              VarietyLineSeries(name: 'n', data: source),
            ],
          ),
        ),
      );
      controller.setRange(4, null);
      await tester.pump();
      await tester.pump();
      expect(latest!.minimum, 4);
      final double highWater = latest!.maximum;

      source.add(const VarietyChartData(11, 12));
      data.updateDataSource();
      await tester.pump();
      await tester.pump();
      // The pinned low end held and the free end grew with the series, which
      // is what "not pinned" has to mean once data can arrive.
      expect(latest!.minimum, 4);
      expect(latest!.maximum, greaterThan(highWater));
    });
  });

  group('Two charts bound to one', () {
    testWidgets('stay on the same window', (WidgetTester tester) async {
      final VarietyRangeController shared = VarietyRangeController();
      final List<VarietyRangeChangedDetails> upper =
          <VarietyRangeChangedDetails>[];
      final List<VarietyRangeChangedDetails> lower =
          <VarietyRangeChangedDetails>[];
      await tester.pumpWidget(
        host(
          Column(
            children: <Widget>[
              Expanded(
                  child: countingChart(
                      controller: shared,
                      onRange: (
                        VarietyRangeChangedDetails details,
                      ) {
                        upper.add(details);
                      })),
              Expanded(
                  child: countingChart(
                      controller: shared,
                      onRange: (
                        VarietyRangeChangedDetails details,
                      ) {
                        lower.add(details);
                      })),
            ],
          ),
        ),
      );
      shared.setRange(2, 6);
      await tester.pump();
      await tester.pump();
      expect(upper.last.minimum, 2);
      expect(upper.last.maximum, 6);
      expect(lower.last.minimum, 2);
      expect(lower.last.maximum, 6);
    });

    testWidgets('one window is recorded for both to read', (
      WidgetTester tester,
    ) async {
      final VarietyRangeController shared = VarietyRangeController();
      await tester.pumpWidget(
        host(
          Column(
            children: <Widget>[
              Expanded(child: countingChart(controller: shared)),
              Expanded(child: countingChart(controller: shared)),
            ],
          ),
        ),
      );
      // Both answered 0..9 and neither has been told otherwise, so recording
      // one range twice has left one range, not drifted.
      expect(shared.start, 0);
      expect(shared.end, 9);
    });
  });
}

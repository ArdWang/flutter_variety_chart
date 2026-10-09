import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_variety_chart/src/painters/variety_cartesian_painter.dart';

import '../test_helpers.dart';

/// Ten readings, x = 0..9.
List<VarietyChartData> counts() => List<VarietyChartData>.generate(
      10,
      (int i) => VarietyChartData(i, i.toDouble() + 1),
    );

/// The painter that actually drew the plot, wherever it sits in the tree.
///
/// The chart is made of several canvases — the plot, its axis gutters and so
/// on — so picking the first `CustomPaint` would pick whichever happens to
/// come first. This picks the one that drew the series.
VarietyCartesianPainter painterOf(WidgetTester tester) {
  for (final Element element in find.byType(CustomPaint).evaluate()) {
    final CustomPaint paint = element.widget as CustomPaint;
    if (paint.painter is VarietyCartesianPainter) {
      return paint.painter! as VarietyCartesianPainter;
    }
  }
  throw StateError('The chart drew with no cartesian painter.');
}

VarietyCartesianChart chartOf({
  required VarietyCartesianChartController controller,
  required List<VarietyChartData> data,
  VarietyAnimationType animationType = VarietyAnimationType.load,
  bool enableAnimation = false,
}) =>
    VarietyCartesianChart(
      controller: controller,
      enableAnimation: enableAnimation,
      animationDuration: const Duration(milliseconds: 1200),
      animationType: animationType,
      series: <VarietySeries>[VarietyLineSeries(name: 'n', data: data)],
    );

void main() {
  testWidgets('appends to the list the application owns', (
    WidgetTester tester,
  ) async {
    final VarietyCartesianChartController chart =
        VarietyCartesianChartController();
    final List<VarietyChartData> source = counts();
    await tester.pumpWidget(host(chartOf(controller: chart, data: source)));

    chart.updateDataSource(points: <VarietyChartData>[
      const VarietyChartData(10, 11),
    ]);
    await tester.pump();

    // The point went into the caller's own list, not into a copy the chart
    // made: eleven points here means eleven points there.
    expect(source.length, 11);
    expect(source.last.y, 11);
    expect(painterOf(tester).geometry.pointPositions[0].length, 11);
  });

  testWidgets('keeps several of them in order', (WidgetTester tester) async {
    final VarietyCartesianChartController chart =
        VarietyCartesianChartController();
    final List<VarietyChartData> source = counts();
    await tester.pumpWidget(host(chartOf(controller: chart, data: source)));

    chart.updateDataSource(points: <VarietyChartData>[
      const VarietyChartData(10, 11),
      const VarietyChartData(11, 12),
    ]);
    await tester.pump();
    expect(source[10].y, 11);
    expect(source[11].y, 12);
  });

  testWidgets('inserts ahead of the point already there', (
    WidgetTester tester,
  ) async {
    final VarietyCartesianChartController chart =
        VarietyCartesianChartController();
    final List<VarietyChartData> source = counts();
    await tester.pumpWidget(host(chartOf(controller: chart, data: source)));

    chart.updateDataSource(
      type: VarietyDataChangeType.insert,
      index: 0,
      points: <VarietyChartData>[const VarietyChartData(-1, 0)],
    );
    await tester.pump();
    expect(source.length, 11);
    expect(source.first.x, -1);
    expect(source[1].x, 0);
  });

  testWidgets('replaces points in place', (WidgetTester tester) async {
    final VarietyCartesianChartController chart =
        VarietyCartesianChartController();
    final List<VarietyChartData> source = counts();
    await tester.pumpWidget(host(chartOf(controller: chart, data: source)));

    chart.updateDataSource(
      type: VarietyDataChangeType.replace,
      index: 3,
      points: <VarietyChartData>[const VarietyChartData(3, 99)],
    );
    await tester.pump();
    // Same number of points, one of them different: a reading revised in
    // place rather than appended.
    expect(source.length, 10);
    expect(source[3].y, 99);
    expect(painterOf(tester).geometry.pointPositions[0].length, 10);
  });

  testWidgets('removes the points it is told to, highest first', (
    WidgetTester tester,
  ) async {
    final VarietyCartesianChartController chart =
        VarietyCartesianChartController();
    final List<VarietyChartData> source = counts();
    await tester.pumpWidget(host(chartOf(controller: chart, data: source)));

    // Named out of order on purpose: taking the lower one first would move
    // the higher one, and the chart would drop the wrong point.
    chart.updateDataSource(
      type: VarietyDataChangeType.remove,
      indexes: <int>[7, 0],
    );
    await tester.pump();
    expect(source.length, 8);
    expect(source.first.x, 1);
    expect(source.last.x, 8);
  });

  testWidgets('an index nobody has is ignored rather than thrown', (
    WidgetTester tester,
  ) async {
    final VarietyCartesianChartController chart =
        VarietyCartesianChartController();
    final List<VarietyChartData> source = counts();
    await tester.pumpWidget(host(chartOf(controller: chart, data: source)));

    chart.updateDataSource(
      type: VarietyDataChangeType.remove,
      indexes: <int>[99],
    );
    chart.updateDataSource(points: <VarietyChartData>[], seriesIndex: 9);
    await tester.pump();
    expect(source.length, 10);
    expect(tester.takeException(), isNull);
  });

  testWidgets('counts what it has been asked to do', (
    WidgetTester tester,
  ) async {
    final VarietyCartesianChartController chart =
        VarietyCartesianChartController();
    expect(chart.changeCount, 0);
    expect(chart.pendingChange, isNull);
    chart.updateDataSource(type: VarietyDataChangeType.append);
    expect(chart.changeCount, 1);
    expect(chart.pendingChange, isNotNull);
    expect(chart.pendingChange!.seriesIndex, 0);
    expect(chart.pendingChange!.type, VarietyDataChangeType.append);
    chart.clear();
    expect(chart.pendingChange, isNull);
  });

  group('Replacing the series', () {
    testWidgets('replays the entrance by default', (
      WidgetTester tester,
    ) async {
      final VarietyCartesianChartController chart =
          VarietyCartesianChartController();
      await tester.pumpWidget(
        host(_Rebuilder(controller: chart, data: counts())),
      );
      await tester.pump(const Duration(milliseconds: 1200));
      final double settled =
          painterOf(tester).geometry.pointPositions[0].last.dy;

      await tester.pumpWidget(
        host(_Rebuilder(controller: chart, data: counts())),
      );
      // One frame in, the line has been thrown back to the bottom: this is the
      // redraw from nothing that a chart refreshed on a timer cannot live
      // with.
      final double restarted =
          painterOf(tester).geometry.pointPositions[0].last.dy;
      expect(restarted, greaterThan(settled + 20));
    });

    testWidgets('is held in place by realtime', (WidgetTester tester) async {
      final VarietyCartesianChartController chart =
          VarietyCartesianChartController();
      await tester.pumpWidget(
        host(_Rebuilder(
          controller: chart,
          data: counts(),
          animationType: VarietyAnimationType.realtime,
        )),
      );
      await tester.pump(const Duration(milliseconds: 1200));
      final double settled =
          painterOf(tester).geometry.pointPositions[0].last.dy;

      await tester.pumpWidget(
        host(_Rebuilder(
          controller: chart,
          data: counts(),
          animationType: VarietyAnimationType.realtime,
        )),
      );
      // Same series rebuilt, and this time nothing moved: the points are where
      // they were rather than back at the bottom.
      final double now = painterOf(tester).geometry.pointPositions[0].last.dy;
      expect(now, closeTo(settled, 1e-6));
    });
  });
}

/// Rebuilds its chart with whatever [data] it is given, so the test can make
/// the series a different list without changing anything else.
class _Rebuilder extends StatefulWidget {
  const _Rebuilder({
    required this.controller,
    required this.data,
    this.animationType = VarietyAnimationType.load,
  });

  final VarietyCartesianChartController controller;
  final List<VarietyChartData> data;
  final VarietyAnimationType animationType;

  @override
  State<_Rebuilder> createState() => _RebuilderState();
}

class _RebuilderState extends State<_Rebuilder> {
  @override
  Widget build(BuildContext context) {
    return VarietyCartesianChart(
      controller: widget.controller,
      enableAnimation: true,
      animationDuration: const Duration(milliseconds: 1200),
      animationType: widget.animationType,
      series: <VarietySeries>[
        VarietyLineSeries(name: 'n', data: widget.data),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
// The painter is not part of the public surface, but the entry animation only
// reaches the outside world as the progress the geometry is built with.
import 'package:flutter_variety_chart/src/painters/variety_cartesian_painter.dart';
import 'package:flutter_test/flutter_test.dart';

const Rect plotRect = Rect.fromLTWH(40, 10, 320, 220);

const List<VarietyChartData> points = <VarietyChartData>[
  VarietyChartData(0, 4),
  VarietyChartData(1, 9),
  VarietyChartData(2, 6),
  VarietyChartData(3, 8),
  VarietyChartData(4, 2),
];

/// The geometry a chart holds after it has been laid out.
VarietyCartesianGeometry chartGeometry(WidgetTester tester) {
  final CustomPaint paint = tester.widget<CustomPaint>(
    find
        .descendant(
          of: find.byType(VarietyCartesianChart),
          matching: find.byType(CustomPaint),
        )
        .first,
  );
  return (paint.painter! as VarietyCartesianPainter).geometry;
}

void main() {
  VarietyCartesianGeometry build(List<VarietySeries> series) {
    return VarietyCartesianGeometry(
      series: series,
      xAxis: const VarietyAxis(type: VarietyAxisType.numeric),
      yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
      plotRect: plotRect,
      progress: 1,
    );
  }

  Widget chart(List<VarietySeries> series) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 320,
            child: VarietyCartesianChart(
              primaryXAxis: const VarietyAxis(type: VarietyAxisType.numeric),
              primaryYAxis: const VarietyAxis(type: VarietyAxisType.numeric),
              series: series,
            ),
          ),
        ),
      );

  group('LineSeries extended parameters', () {
    test('sortFieldValueMapper overrides the key the points sort by', () {
      final VarietyCartesianGeometry mapped = build(<VarietySeries>[
        VarietyLineSeries(
          name: 'a',
          data: points,
          sortingOrder: VarietySortingOrder.ascending,
          sortFieldValueMapper: (VarietyChartData p) => -p.y!,
        ),
      ]);
      // Ascending on minus y is descending on y.
      expect(
        mapped.resolvedData.single.map((VarietyChartData p) => p.y),
        <double?>[9, 8, 6, 4, 2],
      );
      final VarietyCartesianGeometry plain = build(<VarietySeries>[
        VarietyLineSeries(
          name: 'a',
          data: points,
          sortingOrder: VarietySortingOrder.ascending,
        ),
      ]);
      expect(
        plain.resolvedData.single.map((VarietyChartData p) => p.y),
        <double?>[2, 4, 6, 8, 9],
      );
    });

    test('a gradient reaches the stroked path', () {
      final VarietyCartesianGeometry geometry = build(<VarietySeries>[
        VarietyLineSeries(
          name: 'a',
          data: points,
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFF3F6FE0), Color(0xFF18B47B)],
          ),
          borderGradient: const LinearGradient(
            colors: <Color>[Color(0xFF000000), Color(0xFFFFFFFF)],
          ),
        ),
      ]);
      final VarietyPathElement path =
          geometry.elements.whereType<VarietyPathElement>().first;
      expect(path.strokeGradient, isA<LinearGradient>());
      // The border gradient is the one a stroke uses when both are given.
      expect(
        (path.strokeGradient! as LinearGradient).colors,
        const <Color>[Color(0xFF000000), Color(0xFFFFFFFF)],
      );
    });

    test('markerSettings names what a line series draws at each point', () {
      final VarietyCartesianGeometry geometry = build(<VarietySeries>[
        VarietyLineSeries(
          name: 'a',
          data: points,
          markerSettings: const VarietyMarkerSettings(
            isVisible: true,
            shape: VarietyMarkerShape.diamond,
            color: Color(0xFF18B47B),
          ),
        ),
      ]);
      final VarietyMarkersElement element =
          geometry.elements.whereType<VarietyMarkersElement>().single;
      expect(element.shape, VarietyMarkerShape.diamond);
      expect(element.markers, hasLength(points.length));
      expect(element.markers.first.color, const Color(0xFF18B47B));
    });

    test('enableTrackball keeps a series out of the trackball', () {
      final VarietyCartesianGeometry geometry = build(<VarietySeries>[
        VarietyLineSeries(name: 'a', data: points, enableTrackball: false),
        VarietyLineSeries(name: 'b', data: points),
      ]);
      final Offset at = geometry.pointPositions[1][2];
      final List<VarietyHitResult> hits = geometry.hitsAtSlot(
        Offset(at.dx, plotRect.center.dy),
        displayMode: VarietyTrackballDisplayMode.groupAllPoints,
      );
      expect(
          hits.map((VarietyHitResult hit) => hit.series.name), contains('b'));
      expect(
        hits.map((VarietyHitResult hit) => hit.series.name),
        isNot(contains('a')),
        reason: 'a series asking to stay out of the trackball joined it',
      );
    });

    testWidgets('legendItemText and isVisibleInLegend filter the legend',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        chart(<VarietySeries>[
          VarietyLineSeries(
              name: 'a', data: points, legendItemText: 'Series A'),
          VarietyLineSeries(name: 'b', data: points, isVisibleInLegend: false),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Series A'), findsOneWidget);
      expect(find.text('b'), findsNothing);
    });

    testWidgets('a series can stretch the entry animation',
        (WidgetTester tester) async {
      Future<double> progressAt900(Duration? seriesDuration) async {
        await tester.pumpWidget(
          chart(<VarietySeries>[
            VarietyLineSeries(
              name: 'a',
              data: points,
              animationDuration: seriesDuration,
            ),
          ]),
        );
        await tester.pump(const Duration(milliseconds: 900));
        return chartGeometry(tester).progress;
      }

      // The chart itself settles in 800 ms, so by 900 ms it is done unless a
      // series asked for longer.
      expect(await progressAt900(null), 1);
      final double slow = await progressAt900(const Duration(seconds: 3));
      expect(slow, greaterThan(0));
      expect(slow, lessThan(1));

      await tester.pumpAndSettle();
      expect(chartGeometry(tester).progress, 1);
    });
  });
}

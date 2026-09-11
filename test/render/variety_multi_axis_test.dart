import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../test_helpers.dart';

const VarietyAxis rateAxis = VarietyAxis(
  type: VarietyAxisType.numeric,
  name: 'rate',
  minimum: 0,
  maximum: 100,
  title: 'Rate (%)',
);

VarietyCartesianGeometry build({
  required List<VarietySeries> series,
  List<VarietyAxis> secondary = const <VarietyAxis>[rateAxis],
}) {
  return VarietyCartesianGeometry(
    series: series,
    xAxis: const VarietyAxis(type: VarietyAxisType.category),
    yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
    plotRect: defaultPlotRect,
    progress: 1,
    secondaryYAxes: secondary,
  );
}

void main() {
  group('axis resolution', () {
    test('a series without an axis name uses the primary axis', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[VarietyColumnSeries(data: monthly())],
      );
      expect(geometry.yAxes.length, 2);
      expect(geometry.axisIndexOf(0), 0);
    });

    test('a series bound by name uses the matching axis', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyColumnSeries(data: monthly()),
          VarietyLineSeries(
            data: const <VarietyChartData>[
              VarietyChartData('Jan', 10),
              VarietyChartData('Feb', 20),
            ],
            yAxisName: 'rate',
          ),
        ],
      );
      expect(geometry.axisIndexOf(0), 0);
      expect(geometry.axisIndexOf(1), 1);
    });

    test('an unknown axis name falls back to the primary axis', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(data: monthly(), yAxisName: 'missing'),
        ],
      );
      expect(geometry.axisIndexOf(0), 0);
    });

    test('each axis resolves its own range', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyColumnSeries(data: monthly()),
          VarietyLineSeries(
            data: const <VarietyChartData>[
              VarietyChartData('Jan', 10),
              VarietyChartData('Feb', 20),
            ],
            yAxisName: 'rate',
          ),
        ],
      );
      // The secondary axis is pinned by the axis settings.
      expect(geometry.axisMinimums[1], 0);
      expect(geometry.axisMaximums[1], 100);
      // The primary axis keeps its own, much smaller range.
      expect(geometry.axisMaximums[0], lessThan(100));
    });

    test('a derived range is used when the axis leaves it open', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyColumnSeries(data: monthly()),
          VarietyLineSeries(
            data: const <VarietyChartData>[
              VarietyChartData('Jan', 200),
              VarietyChartData('Feb', 400),
            ],
            yAxisName: 'rate',
          ),
        ],
        secondary: const <VarietyAxis>[
          VarietyAxis(type: VarietyAxisType.numeric, name: 'rate'),
        ],
      );
      expect(geometry.axisMaximums[1], greaterThanOrEqualTo(400));
      expect(geometry.axisMaximums[0], lessThan(200));
    });
  });

  group('pixel mapping', () {
    test('the same value maps to different pixels on different axes', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyColumnSeries(data: monthly()),
          VarietyLineSeries(
            data: const <VarietyChartData>[VarietyChartData('Jan', 50)],
            yAxisName: 'rate',
          ),
        ],
      );
      final double onPrimary = geometry.pixelYOn(0, 50);
      final double onSecondary = geometry.pixelYOn(1, 50);
      expect(onPrimary, isNot(closeTo(onSecondary, 0.5)));
    });

    test('the secondary tick values follow its own interval', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(
            data: const <VarietyChartData>[VarietyChartData('Jan', 50)],
            yAxisName: 'rate',
          ),
        ],
      );
      final List<double> ticks = geometry.yTicksOn(1);
      expect(ticks.first, 0);
      expect(ticks.last, 100);
      expect(ticks.length, greaterThan(2));
    });

    test('the secondary caption uses the axis formatter', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyLineSeries(
            data: const <VarietyChartData>[VarietyChartData('Jan', 50)],
            yAxisName: 'rate',
          ),
        ],
        secondary: const <VarietyAxis>[
          VarietyAxis(
            type: VarietyAxisType.numeric,
            name: 'rate',
            minimum: 0,
            maximum: 100,
            numberFormat: '0.0',
          ),
        ],
      );
      expect(geometry.secondaryTickLabelOn(1, 25), '25.0');
    });

    test('the secondary axis has its own baseline', () {
      final VarietyCartesianGeometry geometry = build(
        series: <VarietySeries>[
          VarietyColumnSeries(data: monthly()),
          VarietyLineSeries(
            data: const <VarietyChartData>[VarietyChartData('Jan', 50)],
            yAxisName: 'rate',
          ),
        ],
        secondary: const <VarietyAxis>[
          VarietyAxis(
            type: VarietyAxisType.numeric,
            name: 'rate',
            minimum: 40,
            maximum: 60,
          ),
        ],
      );
      expect(geometry.baselineYOn(1), closeTo(geometry.pixelYOn(1, 40), 0.5));
    });
  });

  group('chart widget', () {
    testWidgets('renders a dual axis chart', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            secondaryYAxes: const <VarietyAxis>[rateAxis],
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'Revenue', data: monthly()),
              VarietyLineSeries(
                name: 'Rate',
                yAxisName: 'rate',
                data: const <VarietyChartData>[
                  VarietyChartData('Jan', 10),
                  VarietyChartData('Feb', 60),
                  VarietyChartData('Mar', 30),
                  VarietyChartData('Apr', 80),
                ],
              ),
            ],
          ),
          height: 360,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(VarietyCartesianChart), findsOneWidget);
    });

    testWidgets('a chart without extra axes still renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'Revenue', data: monthly()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

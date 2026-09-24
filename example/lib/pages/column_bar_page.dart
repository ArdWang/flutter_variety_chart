import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../data/sample_data.dart';
import '../widgets/demo_scaffold.dart';

/// Demonstrates column, bar, scatter and bubble series.
class ColumnBarPage extends StatelessWidget {
  /// Creates the column and bar demo page.
  const ColumnBarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Column and bar',
      description:
          'Grouped columns and bars share one slot; scatter and bubble series '
          'draw unconnected markers whose size can carry a third value.',
      children: <Widget>[
        ChartCard(
          title: 'Grouped columns with rounded corners',
          height: 280,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyColumnSeries(
                name: 'Revenue',
                cornerRadius: 4,
                data: monthlyRevenue,
              ),
              VarietyColumnSeries(
                name: 'Target',
                widthFactor: 0.45,
                cornerRadius: 4,
                data: monthlyTarget,
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'The same group with a gap between the columns',
          height: 280,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyColumnSeries(
                name: 'Revenue',
                cornerRadius: 4,
                // `spacing` takes the gap out of each column's own width, so
                // the pair still fits the slot it was given.
                spacing: 0.3,
                data: monthlyRevenue,
              ),
              VarietyColumnSeries(
                name: 'Target',
                widthFactor: 0.45,
                cornerRadius: 4,
                spacing: 0.3,
                data: monthlyTarget,
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Bars with data labels',
          height: 300,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyBarSeries(
                name: 'Bars',
                cornerRadius: 6,
                dataLabelSettings:
                    const VarietyDataLabelSettings(isVisible: true),
                data: monthlyRevenue,
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Scatter with a trendline',
          height: 280,
          child: VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(type: VarietyAxisType.numeric),
            primaryYAxis: const VarietyAxis(type: VarietyAxisType.numeric),
            series: <VarietySeries>[
              VarietyScatterSeries(
                name: 'Samples',
                markerSize: 12,
                markerShape: VarietyMarkerShape.circle,
                trendlines: const <VarietyTrendline>[
                  VarietyTrendline(
                    type: VarietyTrendlineType.linear,
                    forwardForecast: 2,
                    name: 'Linear',
                  ),
                  VarietyTrendline(
                    type: VarietyTrendlineType.polynomial,
                    order: 2,
                    color: Color(0xFFE0603F),
                  ),
                ],
                data: scatterSamples,
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Bubbles sized by magnitude',
          height: 280,
          child: VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(type: VarietyAxisType.numeric),
            primaryYAxis: const VarietyAxis(type: VarietyAxisType.numeric),
            series: <VarietySeries>[
              VarietyBubbleSeries(
                name: 'Bubbles',
                maximumRadius: 30,
                data: bubbleSamples,
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Logarithmic axis',
          height: 280,
          child: VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(type: VarietyAxisType.numeric),
            primaryYAxis: const VarietyAxis(
              type: VarietyAxisType.logarithmic,
              title: 'Log scale',
            ),
            series: <VarietySeries>[
              VarietyColumnSeries(
                name: 'Magnitudes',
                data: const <VarietyChartData>[
                  VarietyChartData(1, 2),
                  VarietyChartData(2, 20),
                  VarietyChartData(3, 200),
                  VarietyChartData(4, 2000),
                  VarietyChartData(5, 20000),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

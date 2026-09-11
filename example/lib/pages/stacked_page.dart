import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../data/sample_data.dart';
import '../widgets/demo_scaffold.dart';

/// Demonstrates the stacking modes available on cartesian series.
class StackedPage extends StatelessWidget {
  /// Creates the stacking demo page.
  const StackedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Stacking',
      description:
          'Stacking combines a series with the ones declared before it. '
          'VarietyStackingMode.percent100 normalises every stack to 100%.',
      children: <Widget>[
        ChartCard(
          title: 'Normal stacked columns',
          height: 280,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyColumnSeries(
                name: 'Mobile',
                stackMode: VarietyStackingMode.normal,
                cornerRadius: 2,
                data: stackedMobile,
              ),
              VarietyColumnSeries(
                name: 'Desktop',
                stackMode: VarietyStackingMode.normal,
                cornerRadius: 2,
                data: stackedDesktop,
              ),
              VarietyColumnSeries(
                name: 'Tablet',
                stackMode: VarietyStackingMode.normal,
                cornerRadius: 2,
                data: stackedTablet,
              ),
            ],
          ),
        ),
        ChartCard(
          title: '100% stacked columns',
          height: 280,
          child: VarietyCartesianChart(
            primaryYAxis: const VarietyAxis(
              type: VarietyAxisType.numeric,
              title: 'Share (%)',
            ),
            series: <VarietySeries>[
              VarietyColumnSeries(
                name: 'Mobile',
                stackMode: VarietyStackingMode.percent100,
                data: stackedMobile,
              ),
              VarietyColumnSeries(
                name: 'Desktop',
                stackMode: VarietyStackingMode.percent100,
                data: stackedDesktop,
              ),
              VarietyColumnSeries(
                name: 'Tablet',
                stackMode: VarietyStackingMode.percent100,
                data: stackedTablet,
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Stacked area',
          height: 280,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyAreaSeries(
                name: 'Mobile',
                stackMode: VarietyStackingMode.normal,
                fillOpacity: 0.7,
                data: stackedMobile,
              ),
              VarietyAreaSeries(
                name: 'Desktop',
                stackMode: VarietyStackingMode.normal,
                fillOpacity: 0.7,
                data: stackedDesktop,
              ),
              VarietyAreaSeries(
                name: 'Tablet',
                stackMode: VarietyStackingMode.normal,
                fillOpacity: 0.7,
                data: stackedTablet,
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Stacked lines',
          height: 280,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'Mobile',
                stackMode: VarietyStackingMode.normal,
                data: stackedMobile,
              ),
              VarietyLineSeries(
                name: 'Desktop',
                stackMode: VarietyStackingMode.normal,
                data: stackedDesktop,
              ),
              VarietyLineSeries(
                name: 'Tablet',
                stackMode: VarietyStackingMode.normal,
                data: stackedTablet,
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Stacked bars',
          height: 300,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyBarSeries(
                name: 'Mobile',
                stackMode: VarietyStackingMode.normal,
                data: stackedMobile,
              ),
              VarietyBarSeries(
                name: 'Desktop',
                stackMode: VarietyStackingMode.normal,
                data: stackedDesktop,
              ),
              VarietyBarSeries(
                name: 'Tablet',
                stackMode: VarietyStackingMode.normal,
                data: stackedTablet,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

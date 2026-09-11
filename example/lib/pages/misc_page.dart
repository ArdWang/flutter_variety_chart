import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../data/sample_data.dart';
import '../widgets/demo_scaffold.dart';

/// Demonstrates funnel, pyramid, sparkline and edge-case behaviour.
class MiscPage extends StatelessWidget {
  /// Creates the miscellaneous demo page.
  const MiscPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Funnel, pyramid and sparkline',
      description:
          'Funnel and pyramid charts narrow a set of values into stages. '
          'Sparklines are axis-free and fit inside tables and list tiles.',
      children: <Widget>[
        ChartCard(
          title: 'Funnel',
          height: 320,
          child: VarietyFunnelChart(
            series: VarietyFunnelSeries(
              name: 'Conversion',
              dataLabelSettings: const VarietyDataLabelSettings(isVisible: true),
              data: funnelStages,
            ),
          ),
        ),
        ChartCard(
          title: 'Pyramid with an exploded stage',
          height: 320,
          child: VarietyFunnelChart(
            series: VarietyPyramidSeries(
              name: 'Stages',
              gapRatio: 0.08,
              explodeIndexes: const <int>[1],
              dataLabelSettings: const VarietyDataLabelSettings(isVisible: true),
              data: funnelStages,
            ),
          ),
        ),
        ChartCard(
          title: 'Sparkline variants',
          height: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: VarietySparkline.fromValues(
                  sparklineValues,
                  showHighPoint: true,
                  showLowPoint: true,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: VarietySparkline.fromValues(
                  sparklineValues,
                  type: VarietySparklineType.area,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: VarietySparkline.fromValues(
                  sparklineValues,
                  type: VarietySparklineType.column,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: VarietySparkline.fromValues(
                  const <double>[1, -1, 1, 1, -1, 1, -1, -1, 1, 1],
                  type: VarietySparklineType.winLoss,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Empty points produce gaps',
          height: 280,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'With gaps',
                lineStyle: VarietyLineStyle.curved,
                showMarkers: true,
                data: const <VarietyChartData>[
                  VarietyChartData('Jan', 32),
                  VarietyChartData('Feb', 48),
                  VarietyChartData('Mar', 0, isEmpty: true),
                  VarietyChartData('Apr', 55),
                  VarietyChartData('May', 49),
                  VarietyChartData('Jun', 0, isEmpty: true),
                  VarietyChartData('Jul', 58),
                  VarietyChartData('Aug', 72),
                ],
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Custom per-point colours',
          height: 280,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyColumnSeries(
                name: 'Signed',
                cornerRadius: 3,
                data: const <VarietyChartData>[
                  VarietyChartData('A', 42, color: Color(0xFF2FA37A)),
                  VarietyChartData('B', -18, color: Color(0xFFE0603F)),
                  VarietyChartData('C', 26, color: Color(0xFF2FA37A)),
                  VarietyChartData('D', -9, color: Color(0xFFE0603F)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

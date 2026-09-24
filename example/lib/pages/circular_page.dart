import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../data/sample_data.dart';
import '../widgets/demo_scaffold.dart';

/// Demonstrates pie, doughnut and radial bar series.
class CircularPage extends StatelessWidget {
  /// Creates the circular demo page.
  const CircularPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Circular',
      description:
          'Pie and doughnut series divide a circle proportionally. Radial bar '
          'series draw one concentric ring per value.',
      children: <Widget>[
        ChartCard(
          title: 'Pie with outside labels',
          height: 320,
          child: VarietyCircularChart(
            series: <VarietySeries>[
              VarietyPieSeries(
                name: 'Traffic',
                dataLabelSettings: const VarietyDataLabelSettings(
                  isVisible: true,
                  position: VarietyLabelPosition.outside,
                ),
                data: trafficSources,
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Doughnut with a centre widget',
          height: 320,
          child: VarietyCircularChart(
            series: <VarietySeries>[
              VarietyDoughnutSeries(
                name: 'Traffic',
                innerRadiusFactor: 0.62,
                // Deliberately left without a corner radius. A rounded join has
                // to give up the arc it turns in, which opens a gap to its
                // neighbour — fine on its own, but the point of this chart is
                // the widget in the middle, and the ring reads better whole.
                // The radial bars further down show what the corners look like.
                data: trafficSources,
              ),
            ],
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '100',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text('sessions', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        ChartCard(
          title: 'Exploded slice with small slices grouped',
          height: 320,
          child: VarietyCircularChart(
            legendPosition: VarietyLegendPosition.bottom,
            series: <VarietySeries>[
              VarietyPieSeries(
                name: 'Traffic',
                explodeIndex: 0,
                explodeOffset: 18,
                groupSmallSlices: true,
                groupTo: 10,
                data: trafficSources,
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Radial bars',
          height: 320,
          child: VarietyCircularChart(
            series: <VarietySeries>[
              VarietyRadialBarSeries(
                name: 'Traffic',
                gap: 0.45,
                cornerRadius: 6,
                data: trafficSources,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

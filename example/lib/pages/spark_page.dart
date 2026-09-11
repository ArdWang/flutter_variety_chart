import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../data/sample_data.dart';
import '../widgets/demo_scaffold.dart';

/// Demonstrates the four spark chart widgets and their options.
class SparkPage extends StatelessWidget {
  /// Creates the spark chart demo page.
  const SparkPage({super.key});

  /// A rising series used by the line and area demos.
  static const List<double> rising = <double>[
    18, 22, 20, 26, 24, 31, 29, 35, 33, 41, 38, 46,
  ];

  /// A series with wins, losses and a draw.
  static const List<double> wins = <double>[
    1, -1, 1, 1, -1, 0, 1, -1, -1, 1, 1, 1,
  ];

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Spark charts',
      description:
          'Spark charts are compact, axis-free charts. Each widget fills the '
          'box it is given, so wrap it in a SizedBox.',
      children: <Widget>[
        ChartCard(
          title: 'Line',
          height: 90,
          child: const VarietySparkLineChart(data: rising),
        ),
        ChartCard(
          title: 'Line with a dash pattern and an axis line',
          height: 90,
          child: const VarietySparkLineChart(
            data: rising,
            dashArray: <double>[6, 3],
            strokeWidth: 3,
            axisCrossesAt: 25,
            axisLineColor: Color(0xFF9AA0A6),
            axisLineDashArray: <double>[4, 4],
          ),
        ),
        ChartCard(
          title: 'Area with a border',
          height: 90,
          child: const VarietySparkAreaChart(
            data: rising,
            borderWidth: 2,
            borderColor: Color(0xFF3F6FE0),
          ),
        ),
        ChartCard(
          title: 'Bar with a plot band',
          height: 90,
          child: const VarietySparkBarChart(
            data: rising,
            plotBand: VarietySparkPlotBand(
              start: 30,
              end: 40,
              color: Color(0x33E0A93F),
              borderColor: Color(0xFFE0A93F),
              borderWidth: 1,
            ),
          ),
        ),
        ChartCard(
          title: 'Win / loss with a tie colour',
          height: 90,
          child: const VarietySparkWinLossChart(
            data: wins,
            tiePointColor: Color(0xFF9AA0A6),
            negativePointColor: Color(0xFFE0603F),
            borderColor: Color(0x22000000),
            borderWidth: 1,
          ),
        ),
        ChartCard(
          title: 'Markers on the high and low points',
          height: 90,
          child: const VarietySparkLineChart(
            data: rising,
            marker: VarietySparkMarker(
              displayMode: VarietySparkMarkerDisplayMode.all,
              shape: VarietySparkMarkerShape.diamond,
              size: 7,
              borderColor: Color(0xFFFFFFFF),
              borderWidth: 1,
            ),
            highPointColor: Color(0xFF2FA37A),
            lowPointColor: Color(0xFFE0603F),
          ),
        ),
        ChartCard(
          title: 'Data labels',
          height: 110,
          child: const VarietySparkColumnChartExample(),
        ),
        ChartCard(
          title: 'Inverted area',
          height: 90,
          child: const VarietySparkAreaChart(
            data: rising,
            isInversed: true,
            color: Color(0xFF8A5CD6),
          ),
        ),
        ChartCard(
          title: 'Trackball (tap the chart)',
          height: 110,
          child: VarietySparkLineChart(
            data: rising,
            marker: const VarietySparkMarker(
              displayMode: VarietySparkMarkerDisplayMode.all,
              size: 5,
            ),
            trackball: VarietySparkTrackball(
              activationMode: VarietySparkActivationMode.tap,
              shouldAlwaysShow: true,
              color: Theme.of(context).colorScheme.primary,
              dashArray: const <double>[3, 3],
            ),
          ),
        ),
        ChartCard(
          title: 'In a table row',
          height: 140,
          child: Column(
            children: <Widget>[
              for (int i = 0; i < 3; i++)
                Expanded(
                  child: Row(
                    children: <Widget>[
                      SizedBox(width: 72, child: Text('Region ${1 + i}')),
                      Expanded(
                        child: VarietySparkLineChart(
                          data: List<double>.generate(
                            12,
                            (int j) => sparklineValues[(i * 3 + j) % sparklineValues.length],
                          ),
                          labelDisplayMode: i == 0
                              ? VarietySparkLabelDisplayMode.last
                              : VarietySparkLabelDisplayMode.none,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A bar spark chart that labels every point.
class VarietySparkColumnChartExample extends StatelessWidget {
  /// Creates the labelled bar spark chart example.
  const VarietySparkColumnChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const VarietySparkBarChart(
      data: <double>[12, 18, 15, 24, 21, 30],
      labelDisplayMode: VarietySparkLabelDisplayMode.all,
      labelStyle: TextStyle(fontSize: 9),
    );
  }
}

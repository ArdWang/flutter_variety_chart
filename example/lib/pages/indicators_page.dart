import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../data/sample_data.dart';
import '../widgets/demo_scaffold.dart';

/// Demonstrates the technical indicators bundled with the package.
class IndicatorsPage extends StatelessWidget {
  /// Creates the indicators demo page.
  const IndicatorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final VarietyLineSeries source = VarietyLineSeries(
      name: 'Close',
      showMarkers: true,
      markerSize: 4,
      strokeWidth: 1.6,
      data: dailyPrices
          .map(
            (VarietyChartData point) => VarietyChartData(point.x, point.closeValue),
          )
          .toList(growable: false),
    );
    final VarietyBollingerBandsIndicator bollinger =
        VarietyBollingerBandsIndicator(source: source, period: 5);
    final VarietyMacdIndicator macd = VarietyMacdIndicator(source: source);
    final VarietyStochasticIndicator stochastic =
        VarietyStochasticIndicator(source: source, period: 5);

    return DemoScaffold(
      title: 'Indicators',
      description:
          'Indicators are computed from a source series. Single-line '
          'indicators are ordinary series, so they can be dropped straight into '
          'the series list; multi-line indicators expose a build() method.',
      children: <Widget>[
        ChartCard(
          title: 'Moving averages',
          height: 300,
          child: VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(type: VarietyAxisType.numeric),
            series: <VarietySeries>[
              source,
              VarietySmaIndicator(name: 'SMA 3', period: 3, source: source),
              VarietyEmaIndicator(name: 'EMA 3', period: 3, source: source),
              VarietyWmaIndicator(name: 'WMA 3', period: 3, source: source),
              VarietyTmaIndicator(name: 'TMA 4', period: 4, source: source),
            ],
          ),
        ),
        ChartCard(
          title: 'Bollinger bands',
          height: 300,
          child: VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(type: VarietyAxisType.numeric),
            series: <VarietySeries>[
              source,
              ...bollinger.build(),
            ],
          ),
        ),
        ChartCard(
          title: 'RSI',
          height: 260,
          child: VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(type: VarietyAxisType.numeric),
            series: <VarietySeries>[
              VarietyRsiIndicator(name: 'RSI 5', period: 5, source: source),
            ],
          ),
        ),
        ChartCard(
          title: 'MACD',
          height: 260,
          child: VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(type: VarietyAxisType.numeric),
            series: macd.build(),
          ),
        ),
        ChartCard(
          title: 'Stochastic oscillator',
          height: 260,
          child: VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(type: VarietyAxisType.numeric),
            series: <VarietySeries>[
              ...stochastic.build(),
            ],
          ),
        ),
        ChartCard(
          title: 'Momentum, rate of change and average true range',
          height: 300,
          child: VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(type: VarietyAxisType.numeric),
            series: <VarietySeries>[
              VarietyMomentumIndicator(name: 'Momentum', period: 3, source: source),
              VarietyRocIndicator(name: 'ROC', period: 3, source: source),
              VarietyAtrIndicator(name: 'ATR', period: 3, source: source),
            ],
          ),
        ),
      ],
    );
  }
}

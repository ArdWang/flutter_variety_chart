import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../data/sample_data.dart';
import '../widgets/demo_scaffold.dart';

/// Demonstrates the financial series family.
class FinancialPage extends StatelessWidget {
  /// Creates the financial demo page.
  const FinancialPage({super.key});

  /// The same prices anchored on real dates, for the date-time axis demo.
  List<VarietyChartData> _datedPrices() {
    final DateTime start = DateTime(2026, 1, 1);
    return dailyPrices
        .map(
          (VarietyChartData point) => VarietyChartData(
            start.add(Duration(days: point.x as int)),
            0,
            open: point.open,
            high: point.high,
            low: point.low,
            close: point.close,
          ),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Financial',
      description:
          'Candlesticks, hi-lo stems, hi-lo-open-close bars, volume columns and '
          'waterfall deltas all reuse the standard data model.',
      children: <Widget>[
        ChartCard(
          title: 'Candlestick with a moving average',
          height: 300,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyCandleSeries(name: 'ACME', data: _datedPrices()),
              VarietySmaIndicator(
                name: 'SMA 3',
                period: 3,
                color: const Color(0xFF8A5CD6),
                source: VarietyLineSeries(data: _datedPrices()),
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Hollow rising candles',
          height: 300,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyCandleSeries(
                name: 'ACME',
                // Only the falling candles keep a solid body here, which makes
                // a dense series easier to scan.
                enableSolidCandles: false,
                data: _datedPrices(),
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Hi-lo and hi-lo-open-close',
          height: 300,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyHiLoSeries(
                name: 'Hi-lo',
                data: _datedPrices(),
                color: const Color(0xFF3F6FE0),
              ),
              VarietyHiLoOpenCloseSeries(
                name: 'OHLC',
                data: _datedPrices(),
                color: const Color(0xFFE0603F),
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Date-time axis candles',
          height: 300,
          child: VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(
              type: VarietyAxisType.dateTime,
              dateFormat: 'dd MMM',
              dateTimeIntervalType: VarietyDateTimeIntervalType.days,
              labelRotation: -30,
            ),
            series: <VarietySeries>[
              VarietyCandleSeries(name: 'ACME', data: _datedPrices()),
            ],
          ),
        ),
        ChartCard(
          title: 'Waterfall',
          height: 300,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyWaterfallSeries(name: 'P&L bridge', data: waterfallDeltas),
            ],
          ),
        ),
        ChartCard(
          title: 'Histogram with a fitted normal curve',
          height: 300,
          child: VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(
              type: VarietyAxisType.numeric,
              title: 'Value',
            ),
            series: <VarietySeries>[
              VarietyHistogramSeries(
                name: 'Distribution',
                binCount: 12,
                showNormalDistribution: true,
                data: histogramSamples(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

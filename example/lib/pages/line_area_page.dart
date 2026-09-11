import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../data/sample_data.dart';
import '../widgets/demo_scaffold.dart';

/// Demonstrates the line and area family of series.
class LineAreaPage extends StatelessWidget {
  /// Creates the line and area demo page.
  const LineAreaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Line and area',
      description:
          'The same data rendered as a straight line, a cardinal spline, a '
          'stepped staircase, a fast line and a filled area.',
      children: <Widget>[
        ChartCard(
          title: 'Straight line with markers',
          height: 280,
          child: VarietyCartesianChart(
            title: 'Monthly revenue',
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'Revenue',
                showMarkers: true,
                markerShape: VarietyMarkerShape.circle,
                data: monthlyRevenue,
              ),
              VarietyLineSeries(
                name: 'Target',
                dashPattern: const <double>[6, 4],
                data: monthlyTarget,
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Curved spline',
          height: 260,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'Curved',
                lineStyle: VarietyLineStyle.curved,
                strokeWidth: 3,
                showMarkers: true,
                data: monthlyRevenue,
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Stepped and fast line',
          height: 260,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'Stepped',
                lineStyle: VarietyLineStyle.stepped,
                data: monthlyRevenue,
              ),
              VarietyLineSeries(
                name: 'Fast',
                lineStyle: VarietyLineStyle.fastLine,
                data: monthlyTarget,
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Area and range area',
          height: 280,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyAreaSeries(
                name: 'Area',
                lineStyle: VarietyLineStyle.curved,
                data: monthlyRevenue,
              ),
              VarietyRangeAreaSeries(
                name: 'Band',
                fillOpacity: 0.22,
                data: const <VarietyChartData>[
                  VarietyChartData('Jan', 24, secondaryY: 40),
                  VarietyChartData('Feb', 34, secondaryY: 52),
                  VarietyChartData('Mar', 30, secondaryY: 50),
                  VarietyChartData('Apr', 42, secondaryY: 62),
                  VarietyChartData('May', 38, secondaryY: 58),
                  VarietyChartData('Jun', 48, secondaryY: 70),
                  VarietyChartData('Jul', 44, secondaryY: 66),
                  VarietyChartData('Aug', 56, secondaryY: 80),
                ],
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Numeric axis with data labels',
          height: 280,
          child: VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(
              type: VarietyAxisType.numeric,
              title: 'Index',
            ),
            primaryYAxis: const VarietyAxis(
              type: VarietyAxisType.numeric,
              title: 'Value',
            ),
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'Numeric',
                showMarkers: true,
                markerShape: VarietyMarkerShape.diamond,
                dataLabelSettings: const VarietyDataLabelSettings(isVisible: true),
                data: scatterSamples,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

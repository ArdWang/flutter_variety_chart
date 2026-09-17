import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../data/sample_data.dart';
import '../widgets/demo_scaffold.dart';

/// Demonstrates the capabilities added after the initial release.
class AdvancedPage extends StatefulWidget {
  /// Creates the advanced demo page.
  const AdvancedPage({super.key});

  @override
  State<AdvancedPage> createState() => _AdvancedPageState();
}

class _AdvancedPageState extends State<AdvancedPage> {
  final VarietySelectionController _selection = VarietySelectionController();
  String _status = 'Tap a point to select it.';

  @override
  void initState() {
    super.initState();
    _selection.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = _selection.isEmpty
            ? 'Selection cleared.'
            : 'Selected ${_selection.selected.length} point(s).';
      });
    });
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Advanced',
      description:
          'Box and whisker, error bars, spline and step areas, empty point '
          'modes, label intersection handling and the interaction callbacks.',
      children: <Widget>[
        ChartCard(
          title: 'Box and whisker',
          height: 300,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyBoxAndWhiskerSeries(
                name: 'Distribution',
                showOutliers: true,
                showMean: true,
                data: const <VarietyChartData>[
                  VarietyChartData('Mon', 12, label: 'Mon'),
                  VarietyChartData('Mon', 15, label: 'Mon'),
                  VarietyChartData('Mon', 18, label: 'Mon'),
                  VarietyChartData('Mon', 21, label: 'Mon'),
                  VarietyChartData('Mon', 54, label: 'Mon'),
                  VarietyChartData('Tue', 16, label: 'Tue'),
                  VarietyChartData('Tue', 19, label: 'Tue'),
                  VarietyChartData('Tue', 24, label: 'Tue'),
                  VarietyChartData('Tue', 28, label: 'Tue'),
                  VarietyChartData('Wed', 10, label: 'Wed'),
                  VarietyChartData('Wed', 14, label: 'Wed'),
                  VarietyChartData('Wed', 17, label: 'Wed'),
                  VarietyChartData('Wed', 22, label: 'Wed'),
                ],
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Error bars attached to a column series',
          height: 300,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyColumnSeries(
                name: 'Measured',
                cornerRadius: 3,
                errorBar: const VarietyErrorBarSeries(
                  data: <VarietyChartData>[],
                  type: VarietyErrorBarType.percentage,
                  errorValue: 12,
                ),
                data: monthlyRevenue,
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Spline area and step area',
          height: 300,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietySplineAreaSeries(
                name: 'Spline',
                splineType: VarietySplineType.monotonic,
                fillOpacity: 0.3,
                data: monthlyRevenue,
              ),
              VarietyStepAreaSeries(
                name: 'Steps',
                fillOpacity: 0.25,
                data: monthlyTarget,
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Empty point modes',
          height: 300,
          child: VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'gap',
                data: _withHoles(),
                emptyPointSettings: const VarietyEmptyPointSettings(
                  mode: VarietyEmptyPointMode.gap,
                ),
              ),
              VarietyLineSeries(
                name: 'average',
                data: _withHoles(),
                emptyPointSettings: const VarietyEmptyPointSettings(
                  mode: VarietyEmptyPointMode.average,
                ),
              ),
              VarietyLineSeries(
                name: 'zero',
                data: _withHoles(),
                emptyPointSettings: const VarietyEmptyPointSettings(
                  mode: VarietyEmptyPointMode.zero,
                ),
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Dense axis with rotation and minor grid lines',
          height: 300,
          child: VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(
              type: VarietyAxisType.category,
              labelRotation: -45,
              labelIntersectAction: VarietyLabelIntersectAction.rotate45,
              edgeLabelPlacement: VarietyEdgeLabelPlacement.shift,
              minorTicksPerInterval: 1,
            ),
            primaryYAxis: const VarietyAxis(
              type: VarietyAxisType.numeric,
              minorTicksPerInterval: 1,
              minorGridLines: VarietyMinorGridLines(),
              borderType: VarietyAxisBorderType.rectangle,
            ),
            series: <VarietySeries>[
              VarietyFastLineSeries(
                name: 'Daily',
                decimationFactor: 3,
                data: _dense(),
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Two horizontal axes, one plot area',
          height: 340,
          child: VarietyCartesianChart(
            // A dyno plot: the same two curves read against engine speed and
            // against road speed. Each axis resolves its own range from the
            // series pointed at it, so neither curve is squeezed into the
            // other's scale.
            primaryXAxis: VarietyAxis(
              type: VarietyAxisType.numeric,
              name: 'rpm',
              title: 'Engine speed (rpm)',
              minimum: 0,
              maximum: 7000,
              labelFormatter: (dynamic value) =>
                  '${((value as num) / 1000).round()}k',
            ),
            secondaryXAxes: <VarietyAxis>[
              VarietyAxis(
                type: VarietyAxisType.numeric,
                name: 'road',
                title: 'Road speed (km/h)',
                minimum: 0,
                maximum: 220,
              ),
            ],
            primaryYAxis: const VarietyAxis(
              type: VarietyAxisType.numeric,
              title: 'Output',
            ),
            legendSettings: const VarietyLegendSettings(title: 'Measured'),
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'Torque vs rpm',
                data: _dynoTorque(),
              ),
              VarietyLineSeries(
                name: 'Power vs road speed',
                xAxisName: 'road',
                data: _dynoPower(),
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Selection controller and tooltip callback',
          height: 320,
          child: VarietyCartesianChart(
            selectionController: _selection,
            selectionBehavior: const VarietySelectionBehavior(
              enableMultiSelection: true,
            ),
            legendSettings: const VarietyLegendSettings(
              title: 'Series',
              toggleSeriesVisibility: true,
              overflowMode: VarietyLegendOverflowMode.wrap,
            ),
            onTooltipRender: (VarietyTooltipDetails details) {
              // Suppress tooltips for the target line.
              return details.hit.series.name != 'Target';
            },
            onLegendTapped: (VarietyLegendTapDetails details) {
              setState(() {
                _status =
                    '${details.series.name} visible: ${details.isVisible}';
              });
            },
            series: <VarietySeries>[
              VarietyColumnSeries(
                  name: 'Revenue', cornerRadius: 3, data: monthlyRevenue),
              VarietyLineSeries(name: 'Target', data: monthlyTarget),
            ],
          ),
        ),
        ChartCard(
          title: 'Result',
          height: 60,
          child: Center(child: Text(_status)),
        ),
        ChartCard(
          title: 'On-demand rendering',
          height: 300,
          child: VarietyCartesianChart(
            renderingMode: VarietyRenderingMode.onDemand,
            loadingBuilder: (BuildContext context) => const Center(
              child: Text('Tap or hover the chart to load the series'),
            ),
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'Revenue', data: monthlyRevenue),
            ],
          ),
        ),
      ],
    );
  }

  List<VarietyChartData> _withHoles() => const <VarietyChartData>[
        VarietyChartData('Jan', 32),
        VarietyChartData('Feb', 48),
        VarietyChartData('Mar', null, isEmpty: true),
        VarietyChartData('Apr', 55),
        VarietyChartData('May', 49),
        VarietyChartData('Jun', null, isEmpty: true),
        VarietyChartData('Jul', 58),
        VarietyChartData('Aug', 72),
      ];

  List<VarietyChartData> _dense() {
    final DateTime start = DateTime(2026, 1, 1);
    return List<VarietyChartData>.generate(60, (int i) {
      final double value = 40 + 25 * (i % 11) / 10 - (i % 5);
      return VarietyChartData(start.add(Duration(days: i)), value);
    });
  }

  /// Torque against engine speed, on the primary horizontal axis.
  List<VarietyChartData> _dynoTorque() => const <VarietyChartData>[
        VarietyChartData(1000, 160),
        VarietyChartData(2000, 250),
        VarietyChartData(3000, 310),
        VarietyChartData(4000, 320),
        VarietyChartData(5000, 300),
        VarietyChartData(6000, 250),
        VarietyChartData(7000, 180),
      ];

  /// The same engine read against road speed, on the second horizontal axis.
  List<VarietyChartData> _dynoPower() => const <VarietyChartData>[
        VarietyChartData(20, 60),
        VarietyChartData(55, 130),
        VarietyChartData(90, 195),
        VarietyChartData(125, 240),
        VarietyChartData(160, 265),
        VarietyChartData(195, 235),
        VarietyChartData(220, 180),
      ];
}

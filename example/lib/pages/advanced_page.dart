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
}

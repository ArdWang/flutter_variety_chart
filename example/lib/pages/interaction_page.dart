import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../data/sample_data.dart';
import '../widgets/demo_scaffold.dart';

/// Demonstrates the interactive behaviours.
class InteractionPage extends StatefulWidget {
  /// Creates the interaction demo page.
  const InteractionPage({super.key});

  @override
  State<InteractionPage> createState() => _InteractionPageState();
}

class _InteractionPageState extends State<InteractionPage> {
  String _status = 'No point selected yet.';

  /// Shared zoom configuration so every chart on the page zooms and pans,
  /// including the ones that mix several series.
  static const VarietyZoomPanBehavior _zoom = VarietyZoomPanBehavior(
    enablePinchZooming: true,
    enablePanning: true,
    enableMouseWheelZooming: true,
    enableDoubleTapZooming: true,
  );

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Interactions',
      description:
          'Hover or drag to reveal the tooltip. Tap to reveal the trackball. '
          'Every chart below zooms and pans, including the multi-series ones: '
          'drag to pan, pinch with two fingers to zoom the X and Y axes '
          'together, scroll to zoom, and double tap to reset.',
      children: <Widget>[
        ChartCard(
          title: 'Tooltip with zoom (two series)',
          height: 280,
          child: VarietyCartesianChart(
            zoomPanBehavior: _zoom,
            onPointTap: (VarietyHitResult? hit) => setState(() {
              _status = hit == null
                  ? 'Tap missed the plot area.'
                  : 'Tapped ${hit.series.name} at ${hit.point.label ?? hit.point.x}.';
            }),
            series: <VarietySeries>[
              VarietyColumnSeries(name: 'Revenue', cornerRadius: 3, data: monthlyRevenue),
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
          title: 'Trackball with zoom (two series)',
          height: 280,
          child: VarietyCartesianChart(
            zoomPanBehavior: _zoom,
            trackballBehavior: const VarietyTrackballBehavior(
              activationMode: VarietyActivationMode.tap,
            ),
            series: <VarietySeries>[
              VarietyLineSeries(name: 'Revenue', showMarkers: true, data: monthlyRevenue),
              VarietyLineSeries(name: 'Target', data: monthlyTarget),
            ],
          ),
        ),
        ChartCard(
          title: 'Crosshair on hover with zoom',
          height: 280,
          child: VarietyCartesianChart(
            zoomPanBehavior: _zoom,
            crosshairBehavior: const VarietyCrosshairBehavior(
              activationMode: VarietyActivationMode.auto,
              showHorizontalLine: true,
              showVerticalLine: true,
            ),
            series: <VarietySeries>[
              VarietyAreaSeries(name: 'Load', data: monthlyRevenue),
            ],
          ),
        ),
        ChartCard(
          title: 'Zoom, pan and selection',
          height: 300,
          child: VarietyCartesianChart(
            zoomPanBehavior: const VarietyZoomPanBehavior(
              mode: VarietyZoomMode.both,
              enableMouseWheelZooming: true,
              enableDoubleTapZooming: true,
              enablePanning: true,
            ),
            selectionBehavior: VarietySelectionBehavior(
              selectionType: VarietySelectionType.point,
              onSelectionChanged: (List<VarietyHitResult> selected) => setState(() {
                _status = selected.isEmpty
                    ? 'Selection cleared.'
                    : 'Selected ${selected.length} point(s).';
              }),
            ),
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'Zoomable',
                lineStyle: VarietyLineStyle.curved,
                showMarkers: true,
                data: monthlyRevenue,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

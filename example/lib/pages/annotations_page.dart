import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../data/sample_data.dart';
import '../widgets/demo_scaffold.dart';

/// Demonstrates plot bands, multi-level labels and annotations.
class AnnotationsPage extends StatelessWidget {
  /// Creates the annotations demo page.
  const AnnotationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Annotations and plot bands',
      description:
          'Plot bands shade a range of an axis. Annotations decorate the plot '
          'with lines, shapes and captions anchored to a data coordinate.',
      children: <Widget>[
        ChartCard(
          title: 'Horizontal plot bands',
          height: 300,
          child: VarietyCartesianChart(
            primaryYAxis: const VarietyAxis(
              type: VarietyAxisType.numeric,
              plotBands: <VarietyPlotBand>[
                VarietyPlotBand(
                  start: 0,
                  end: 40,
                  color: Color(0xFFE0603F),
                  opacity: 0.14,
                  label: 'Below target',
                ),
                VarietyPlotBand(
                  start: 60,
                  end: 80,
                  color: Color(0xFF2FA37A),
                  opacity: 0.14,
                  label: 'Above target',
                ),
              ],
            ),
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'Revenue',
                lineStyle: VarietyLineStyle.curved,
                showMarkers: true,
                data: monthlyRevenue,
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'Vertical plot bands on a category axis',
          height: 280,
          child: VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(
              type: VarietyAxisType.category,
              plotBands: <VarietyPlotBand>[
                VarietyPlotBand(
                    start: 1.5,
                    end: 3.5,
                    color: Color(0xFF3F6FE0),
                    opacity: 0.12),
                VarietyPlotBand(
                    start: 5.5,
                    end: 7.5,
                    color: Color(0xFF8A5CD6),
                    opacity: 0.12),
              ],
            ),
            series: <VarietySeries>[
              VarietyColumnSeries(
                  name: 'Revenue', cornerRadius: 3, data: monthlyRevenue),
            ],
          ),
        ),
        ChartCard(
          title: 'Multi-level category labels',
          height: 320,
          child: VarietyCartesianChart(
            primaryXAxis: const VarietyAxis(
              type: VarietyAxisType.category,
              multiLevelLabels: VarietyMultiLevelLabels(
                groups: <VarietyLabelGroup>[
                  VarietyLabelGroup(start: 0, end: 2, text: 'H1'),
                  VarietyLabelGroup(start: 3, end: 7, text: 'H2'),
                  VarietyLabelGroup(
                      start: 0, end: 3, text: 'First half', level: 1),
                  VarietyLabelGroup(
                      start: 4, end: 7, text: 'Second half', level: 1),
                ],
              ),
            ),
            series: <VarietySeries>[
              VarietyColumnSeries(
                  name: 'Revenue', cornerRadius: 3, data: monthlyRevenue),
            ],
          ),
        ),
        ChartCard(
          title: 'Annotations',
          height: 300,
          child: VarietyCartesianChart(
            annotations: const <VarietyAnnotation>[
              VarietyAnnotation.horizontalLine(
                y: 55,
                text: 'Target 55',
                borderColor: Color(0xFFE0603F),
              ),
              VarietyAnnotation.verticalLine(
                x: 4,
                text: 'Launch',
                borderColor: Color(0xFF3F6FE0),
              ),
              VarietyAnnotation(
                shapeType: VarietyShapeType.text,
                x: 6,
                y: 34,
                text: 'Dipped after launch',
                textStyle: TextStyle(fontSize: 11, color: Color(0xFF8A5CD6)),
              ),
              VarietyAnnotation(
                shapeType: VarietyShapeType.rectangle,
                x: 7,
                y: 66,
                width: 90,
                height: 42,
                text: 'Peak',
                borderColor: Color(0xFF2FA37A),
                fillColor: Color(0x222FA37A),
              ),
            ],
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'Revenue',
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

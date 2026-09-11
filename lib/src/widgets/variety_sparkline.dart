import 'package:flutter/material.dart';

import '../models/variety_chart_data.dart';
import '../models/variety_enums.dart';
import '../models/variety_spark.dart';
import 'variety_spark_charts.dart';

/// A compact, axis-free chart used inside tables and list tiles.
///
/// This widget is a convenience wrapper over the four dedicated spark charts
/// ([VarietySparkLineChart], [VarietySparkAreaChart], [VarietySparkBarChart]
/// and [VarietySparkWinLossChart]). Prefer those when you need markers, data
/// labels, plot bands or a trackball.
///
/// A sparkline fills the box it is given, so wrap it in a [SizedBox] with an
/// explicit height.
class VarietySparkline extends StatelessWidget {
  /// Creates a sparkline from the given [data] points.
  const VarietySparkline({
    super.key,
    required this.data,
    this.type = VarietySparklineType.line,
    this.color,
    this.lineWidth = 2,
    this.fillOpacity = 0.25,
    this.strokeWidth = 1,
    this.showHighPoint = false,
    this.showLowPoint = false,
    this.highPointColor,
    this.lowPointColor,
    this.markerSize = 6,
    this.animate = true,
  });

  /// Creates a sparkline from a list of raw values.
  factory VarietySparkline.fromValues(
    List<double> values, {
    Key? key,
    VarietySparklineType type = VarietySparklineType.line,
    Color? color,
    double lineWidth = 2,
    double fillOpacity = 0.25,
    bool showHighPoint = false,
    bool showLowPoint = false,
    Color? highPointColor,
    Color? lowPointColor,
    double markerSize = 6,
    bool animate = true,
  }) {
    return VarietySparkline(
      key: key,
      data: List<VarietyChartData>.generate(
        values.length,
        (int i) => VarietyChartData(i, values[i]),
      ),
      type: type,
      color: color,
      lineWidth: lineWidth,
      fillOpacity: fillOpacity,
      showHighPoint: showHighPoint,
      showLowPoint: showLowPoint,
      highPointColor: highPointColor,
      lowPointColor: lowPointColor,
      markerSize: markerSize,
      animate: animate,
    );
  }

  /// The values plotted by the sparkline.
  final List<VarietyChartData> data;

  /// The shape of the sparkline.
  final VarietySparklineType type;

  /// The stroke colour. Defaults to the theme primary colour.
  final Color? color;

  /// The stroke thickness.
  final double lineWidth;

  /// The alpha applied to the filled region of an area sparkline.
  final double fillOpacity;

  /// The border thickness applied to column and win/loss sparklines.
  final double strokeWidth;

  /// Whether the maximum value is marked.
  final bool showHighPoint;

  /// Whether the minimum value is marked.
  final bool showLowPoint;

  /// The colour of the high point marker.
  final Color? highPointColor;

  /// The colour of the low point marker.
  final Color? lowPointColor;

  /// The diameter of the point markers.
  final double markerSize;

  /// Whether the sparkline animates when it first appears.
  final bool animate;

  List<double> get _values => data
      .map((VarietyChartData point) => point.y ?? 0)
      .toList(growable: false);

  VarietySparkMarker? get _marker {
    if (!showHighPoint && !showLowPoint) {
      return null;
    }
    return VarietySparkMarker(
      displayMode: showHighPoint && showLowPoint
          ? VarietySparkMarkerDisplayMode.all
          : (showHighPoint
              ? VarietySparkMarkerDisplayMode.high
              : VarietySparkMarkerDisplayMode.low),
      size: markerSize,
      color: highPointColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case VarietySparklineType.line:
        return VarietySparkLineChart(
          data: _values,
          color: color,
          strokeWidth: lineWidth,
          marker: _marker,
          enableAnimation: animate,
        );
      case VarietySparklineType.area:
        return VarietySparkAreaChart(
          data: _values,
          color: color,
          strokeWidth: lineWidth,
          borderWidth: 0,
          marker: _marker,
          enableAnimation: animate,
        );
      case VarietySparklineType.column:
        return VarietySparkBarChart(
          data: _values,
          color: color,
          enableAnimation: animate,
        );
      case VarietySparklineType.winLoss:
        return VarietySparkWinLossChart(
          data: _values,
          color: color,
          enableAnimation: animate,
        );
    }
  }
}

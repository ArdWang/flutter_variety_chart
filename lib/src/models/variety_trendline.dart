import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'variety_enums.dart';

/// Describes a regression line fitted to the points of a series.
@immutable
class VarietyTrendline {
  /// Creates a trendline description.
  const VarietyTrendline({
    this.type = VarietyTrendlineType.linear,
    this.order = 2,
    this.period = 3,
    this.dashArray = const <double>[6, 4],
    this.color,
    this.width = 1.6,
    this.name,
    this.forwardForecast = 0,
    this.backwardForecast = 0,
    this.isVisible = true,
  });

  /// The regression model to fit.
  final VarietyTrendlineType type;

  /// The polynomial degree, used when [type] is [VarietyTrendlineType.polynomial].
  final int order;

  /// The window size, used when [type] is [VarietyTrendlineType.movingAverage].
  final int period;

  /// The dash pattern of the trendline. Empty means solid.
  final List<double> dashArray;

  /// The stroke colour. Defaults to the owning series colour.
  final Color? color;

  /// The stroke thickness.
  final double width;

  /// An optional name surfaced by the legend.
  final String? name;

  /// How many points beyond the last data point the line is extrapolated.
  final int forwardForecast;

  /// How many points before the first data point the line is extrapolated.
  final int backwardForecast;

  /// Whether the trendline is drawn.
  final bool isVisible;
}

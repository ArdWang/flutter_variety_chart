import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'variety_options.dart';

/// Controls how a point that is flagged empty, or whose value is `null`, is
/// rendered by a series.
///
/// A point is considered empty when [VarietyChartData.isEmpty] is `true` or its
/// value cannot be read. Every series reads this configuration, and the mode
/// changes both the geometry and what tooltips report.
@immutable
class VarietyEmptyPointSettings {
  /// Creates empty point settings.
  const VarietyEmptyPointSettings({
    this.mode = VarietyEmptyPointMode.gap,
    this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1.0,
    this.showMarker = false,
    this.markerSize = 6,
  });

  /// How the empty point is treated.
  final VarietyEmptyPointMode mode;

  /// The fill colour used when the mode keeps the point visible.
  final Color? fillColor;

  /// The outline colour used when the mode keeps the point visible.
  final Color? strokeColor;

  /// The outline thickness used when the mode keeps the point visible.
  final double strokeWidth;

  /// Whether a marker is drawn at the substituted value.
  final bool showMarker;

  /// The diameter of the substituted marker.
  final double markerSize;

  /// Returns a copy of these settings with the supplied fields replaced.
  VarietyEmptyPointSettings copyWith({
    VarietyEmptyPointMode? mode,
    Color? fillColor,
    Color? strokeColor,
    double? strokeWidth,
    bool? showMarker,
    double? markerSize,
  }) {
    return VarietyEmptyPointSettings(
      mode: mode ?? this.mode,
      fillColor: fillColor ?? this.fillColor,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      showMarker: showMarker ?? this.showMarker,
      markerSize: markerSize ?? this.markerSize,
    );
  }
}

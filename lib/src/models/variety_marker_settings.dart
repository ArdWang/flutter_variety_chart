import 'package:flutter/widgets.dart';

import 'variety_enums.dart';

/// Groups the marker configuration of a series.
///
/// A series accepts either this object through `markerSettings`, or the
/// individual marker properties. When both are supplied the object wins.
@immutable
class VarietyMarkerSettings {
  /// Creates marker settings.
  const VarietyMarkerSettings({
    this.isVisible = false,
    this.shape = VarietyMarkerShape.circle,
    this.height = 8,
    this.width = 8,
    this.color,
    this.borderColor,
    this.borderWidth = 1.4,
    this.markerPosition = VarietyMarkerPosition.auto,
  });

  /// Whether markers are drawn.
  final bool isVisible;

  /// The glyph of the marker.
  final VarietyMarkerShape shape;

  /// The height of the marker. `-1` falls back to [width].
  final double height;

  /// The width of the marker.
  final double width;

  /// The fill colour. Defaults to the series colour.
  final Color? color;

  /// The outline colour.
  final Color? borderColor;

  /// The outline thickness.
  final double borderWidth;

  /// Where the marker is anchored with respect to its point.
  final VarietyMarkerPosition markerPosition;

  /// The effective marker height.
  double get resolvedHeight => height < 0 ? width : height;

  /// Returns a copy of these settings with the supplied fields replaced.
  VarietyMarkerSettings copyWith({
    bool? isVisible,
    VarietyMarkerShape? shape,
    double? height,
    double? width,
    Color? color,
    Color? borderColor,
    double? borderWidth,
    VarietyMarkerPosition? markerPosition,
  }) {
    return VarietyMarkerSettings(
      isVisible: isVisible ?? this.isVisible,
      shape: shape ?? this.shape,
      height: height ?? this.height,
      width: width ?? this.width,
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      markerPosition: markerPosition ?? this.markerPosition,
    );
  }
}

/// Where a marker is anchored with respect to its data point.
enum VarietyMarkerPosition {
  /// The marker is centred on the point.
  auto,

  /// The marker is centred on the point. Same as [auto].
  center,

  /// The marker sits above the point.
  top,

  /// The marker sits below the point.
  bottom,
}

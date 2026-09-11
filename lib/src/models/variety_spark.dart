import 'package:flutter/widgets.dart';

/// The modes that decide which points of a spark chart carry a marker.
enum VarietySparkMarkerDisplayMode {
  /// No marker is drawn.
  none,

  /// Every point carries a marker.
  all,

  /// Only the highest point carries a marker.
  high,

  /// Only the lowest point carries a marker.
  low,

  /// Only the first point carries a marker.
  first,

  /// Only the last point carries a marker.
  last,
}

/// The glyph drawn by a spark chart marker.
enum VarietySparkMarkerShape {
  /// A circle.
  circle,

  /// A diamond.
  diamond,

  /// A square.
  square,

  /// An upward triangle.
  triangle,

  /// A downward triangle.
  invertedTriangle,
}

/// The gesture that reveals a spark chart trackball.
enum VarietySparkActivationMode {
  /// A single tap.
  tap,

  /// A double tap.
  doubleTap,

  /// A long press.
  longPress,
}

/// The modes that decide which points of a spark chart carry a data label.
enum VarietySparkLabelDisplayMode {
  /// No label is drawn.
  none,

  /// Every point carries a label.
  all,

  /// Only the highest point carries a label.
  high,

  /// Only the lowest point carries a label.
  low,

  /// Only the first point carries a label.
  first,

  /// Only the last point carries a label.
  last,
}

/// Which spark chart shape a widget draws.
enum VarietySparkSeriesType {
  /// A stroked line.
  line,

  /// A filled area below the line.
  area,

  /// A column per value.
  bar,

  /// A win/loss bar where the sign drives the direction.
  winLoss,
}

/// Configures the marker drawn on a spark chart.
@immutable
class VarietySparkMarker {
  /// Creates a spark chart marker configuration.
  const VarietySparkMarker({
    this.displayMode = VarietySparkMarkerDisplayMode.none,
    this.borderColor,
    this.borderWidth = 2,
    this.color,
    this.size = 5,
    this.shape = VarietySparkMarkerShape.circle,
  });

  /// Which points carry a marker.
  final VarietySparkMarkerDisplayMode displayMode;

  /// The outline colour of the marker.
  final Color? borderColor;

  /// The outline thickness of the marker.
  final double borderWidth;

  /// The fill colour of the marker.
  final Color? color;

  /// The diameter of the marker.
  final double size;

  /// The glyph of the marker.
  final VarietySparkMarkerShape shape;

  /// Returns a copy of this configuration with the supplied fields replaced.
  VarietySparkMarker copyWith({
    VarietySparkMarkerDisplayMode? displayMode,
    Color? borderColor,
    double? borderWidth,
    Color? color,
    double? size,
    VarietySparkMarkerShape? shape,
  }) {
    return VarietySparkMarker(
      displayMode: displayMode ?? this.displayMode,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      color: color ?? this.color,
      size: size ?? this.size,
      shape: shape ?? this.shape,
    );
  }
}

/// Shades a value range of a spark chart, improving readability.
@immutable
class VarietySparkPlotBand {
  /// Creates a spark chart plot band.
  const VarietySparkPlotBand({
    this.color = const Color.fromRGBO(191, 212, 252, 0.5),
    this.start,
    this.end,
    this.borderColor,
    this.borderWidth = 0,
  });

  /// The fill colour of the band.
  final Color color;

  /// The lowest shaded value. Both [start] and [end] must be set.
  final double? start;

  /// The highest shaded value. Both [start] and [end] must be set.
  final double? end;

  /// The outline colour of the band.
  final Color? borderColor;

  /// The outline thickness of the band.
  final double borderWidth;

  /// Returns a copy of this band with the supplied fields replaced.
  VarietySparkPlotBand copyWith({
    Color? color,
    double? start,
    double? end,
    Color? borderColor,
    double? borderWidth,
  }) {
    return VarietySparkPlotBand(
      color: color ?? this.color,
      start: start ?? this.start,
      end: end ?? this.end,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }
}

/// The values handed to a spark chart trackball formatter.
@immutable
class VarietySparkTooltipFormatterDetails {
  /// Creates a tooltip formatter argument.
  const VarietySparkTooltipFormatterDetails({
    required this.index,
    required this.x,
    required this.y,
    this.label,
  });

  /// The index of the point under the trackball.
  final int index;

  /// The x value of the point, which is its index by default.
  final dynamic x;

  /// The y value of the point.
  final double? y;

  /// The caption the trackball is about to show.
  final String? label;

  /// Returns a copy of these details with a replacement caption.
  VarietySparkTooltipFormatterDetails withLabel(String value) =>
      VarietySparkTooltipFormatterDetails(
        index: index,
        x: x,
        y: y,
        label: value,
      );
}

/// Configures the trackball shown on a spark chart.
@immutable
class VarietySparkTrackball {
  /// Creates a spark chart trackball configuration.
  const VarietySparkTrackball({
    this.width = 2,
    this.color,
    this.dashArray,
    this.activationMode = VarietySparkActivationMode.tap,
    this.labelStyle,
    this.tooltipFormatter,
    this.backgroundColor,
    this.shouldAlwaysShow = false,
    this.hideDelay = 0,
    this.borderColor,
    this.borderWidth = 0,
    this.borderRadius = const BorderRadius.all(Radius.circular(5)),
  });

  /// The thickness of the trackball line.
  final double width;

  /// The colour of the trackball line.
  final Color? color;

  /// A dash pattern applied to the trackball line. Empty means solid.
  final List<double>? dashArray;

  /// The gesture that reveals the trackball.
  final VarietySparkActivationMode activationMode;

  /// The text style of the tooltip caption.
  final TextStyle? labelStyle;

  /// Rewrites the tooltip caption before it is drawn.
  final String Function(VarietySparkTooltipFormatterDetails details)? tooltipFormatter;

  /// The background colour of the tooltip card.
  final Color? backgroundColor;

  /// Whether the trackball stays on screen once it has been revealed.
  final bool shouldAlwaysShow;

  /// How long the trackball lingers after the pointer leaves, in milliseconds.
  final double hideDelay;

  /// The outline colour of the tooltip card.
  final Color? borderColor;

  /// The outline thickness of the tooltip card.
  final double borderWidth;

  /// The corner radius of the tooltip card.
  final BorderRadius borderRadius;

  /// Returns a copy of this configuration with the supplied fields replaced.
  VarietySparkTrackball copyWith({
    double? width,
    Color? color,
    List<double>? dashArray,
    VarietySparkActivationMode? activationMode,
    TextStyle? labelStyle,
    String Function(VarietySparkTooltipFormatterDetails details)? tooltipFormatter,
    Color? backgroundColor,
    bool? shouldAlwaysShow,
    double? hideDelay,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
  }) {
    return VarietySparkTrackball(
      width: width ?? this.width,
      color: color ?? this.color,
      dashArray: dashArray ?? this.dashArray,
      activationMode: activationMode ?? this.activationMode,
      labelStyle: labelStyle ?? this.labelStyle,
      tooltipFormatter: tooltipFormatter ?? this.tooltipFormatter,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      shouldAlwaysShow: shouldAlwaysShow ?? this.shouldAlwaysShow,
      hideDelay: hideDelay ?? this.hideDelay,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }
}

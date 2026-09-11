import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'variety_enums.dart';

/// A single data point consumed by every series in this package.
///
/// A point always carries an [x] value and a primary [y] value. Financial
/// series additionally read [open], [high], [low] and [close]; bubble series
/// read [size]; range series read [secondaryY].
@immutable
class VarietyChartData {
  /// Creates a data point with the given [x] and [y] values.
  const VarietyChartData(
    this.x,
    this.y, {
    this.secondaryY,
    this.open,
    this.high,
    this.low,
    this.close,
    this.size,
    this.label,
    this.color,
    this.isEmpty = false,
  });

  /// The category name, numeric position or [DateTime] along the primary axis.
  final dynamic x;

  /// The value plotted along the secondary axis.
  final double? y;

  /// An optional companion value. Used as the low bound by range series.
  final double? secondaryY;

  /// The opening price, read by candle and open-close series.
  final double? open;

  /// The highest price, read by candle and hi-lo series.
  final double? high;

  /// The lowest price, read by candle and hi-lo series.
  final double? low;

  /// The closing price, read by candle and open-close series.
  final double? close;

  /// The bubble magnitude, read by bubble series.
  final double? size;

  /// An optional caption shown by tooltips and data labels.
  final String? label;

  /// An optional colour that overrides the colour of the owning series.
  final Color? color;

  /// When `true` the point is skipped and a gap is rendered instead.
  final bool isEmpty;

  /// The high bound used by range series, falling back to [y].
  double get highValue => high ?? secondaryY ?? y ?? 0;

  /// The low bound used by range series, falling back to [y].
  double get lowValue => low ?? y ?? secondaryY ?? 0;

  /// The opening value used by financial series, falling back to [y].
  double get openValue => open ?? y ?? 0;

  /// The closing value used by financial series, falling back to [y].
  double get closeValue => close ?? y ?? 0;

  /// The numeric reading used when a single magnitude is required.
  double get magnitude => size ?? y ?? 0;

  /// Returns a copy of this point with [value] as its new [y].
  ///
  /// Unlike [copyWith] this accepts `null`, which is what indicator warm-up
  /// points need in order to render as gaps.
  VarietyChartData withValue(double? value) => VarietyChartData(
        x,
        value,
        secondaryY: secondaryY,
        open: open,
        high: high,
        low: low,
        close: close,
        size: size,
        label: label,
        color: color,
        isEmpty: isEmpty,
      );

  /// Returns a copy of this point with the supplied fields replaced.
  ///
  /// Passing `null` for a field keeps its current value; use [withValue] when
  /// the new value may legitimately be `null`.
  VarietyChartData copyWith({
    dynamic x,
    double? y,
    double? secondaryY,
    double? open,
    double? high,
    double? low,
    double? close,
    double? size,
    String? label,
    Color? color,
    bool? isEmpty,
  }) {
    return VarietyChartData(
      x ?? this.x,
      y ?? this.y,
      secondaryY: secondaryY ?? this.secondaryY,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      close: close ?? this.close,
      size: size ?? this.size,
      label: label ?? this.label,
      color: color ?? this.color,
      isEmpty: isEmpty ?? this.isEmpty,
    );
  }

  @override
  String toString() =>
      'VarietyChartData(x: $x, y: $y, label: $label, isEmpty: $isEmpty)';
}

/// Customizes the captions drawn next to each data point.
@immutable
class VarietyDataLabelSettings {
  /// Creates data label settings.
  const VarietyDataLabelSettings({
    this.isVisible = false,
    this.position = VarietyLabelPosition.auto,
    this.textStyle,
    this.color,
    this.margin = const EdgeInsets.all(4),
    this.labelOffset = 6,
    this.builder,
    this.showCumulativeTotal = false,
  });

  /// Whether labels are painted at all.
  final bool isVisible;

  /// Where the label is anchored with respect to its point.
  final VarietyLabelPosition position;

  /// The text style applied to the label.
  final TextStyle? textStyle;

  /// The text colour applied to the label.
  final Color? color;

  /// Padding reserved around the label text.
  final EdgeInsets margin;

  /// Distance in logical pixels between the marker and the label.
  final double labelOffset;

  /// Builds the caption for a point. Defaults to the raw value.
  final String Function(VarietyChartData data)? builder;

  /// When `true` stacked series also show a running total label.
  final bool showCumulativeTotal;
}

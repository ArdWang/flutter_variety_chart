import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'variety_enums.dart';
import 'variety_options.dart';

/// How a chart scrolls as new points arrive when auto scrolling is enabled.
enum VarietyAutoScrollingMode {
  /// The window grows to the right and the left edge stays put.
  start,

  /// The window keeps its span and slides towards the newest point.
  end,
}

/// The styling of an axis' major grid lines.
@immutable
class VarietyMajorGridLines {
  /// Creates a major grid line style.
  const VarietyMajorGridLines({
    this.width = 1.0,
    this.color,
    this.dashArray = const <double>[],
  });

  /// The line thickness.
  final double width;

  /// The line colour. Falls back to the axis colour.
  final Color? color;

  /// A dash pattern of alternating on/off lengths. Empty means solid.
  final List<double> dashArray;
}

/// The styling of an axis' minor grid lines.
@immutable
class VarietyMinorGridLines {
  /// Creates a minor grid line style.
  const VarietyMinorGridLines({
    this.width = 0.6,
    this.color,
    this.dashArray = const <double>[],
  });

  /// The line thickness.
  final double width;

  /// The line colour. Falls back to the axis colour at reduced opacity.
  final Color? color;

  /// A dash pattern of alternating on/off lengths. Empty means solid.
  final List<double> dashArray;
}

/// The styling of an axis' major tick marks.
@immutable
class VarietyMajorTickLines {
  /// Creates a major tick mark style.
  const VarietyMajorTickLines({
    this.size = 4.0,
    this.width = 1.0,
    this.color,
  });

  /// The length of a tick mark.
  final double size;

  /// The thickness of a tick mark.
  final double width;

  /// The tick colour. Falls back to the axis colour.
  final Color? color;
}

/// The styling of an axis' minor tick marks.
@immutable
class VarietyMinorTickLines {
  /// Creates a minor tick mark style.
  const VarietyMinorTickLines({
    this.size = 2.5,
    this.width = 1.0,
    this.color,
  });

  /// The length of a tick mark.
  final double size;

  /// The thickness of a tick mark.
  final double width;

  /// The tick colour. Falls back to the axis colour.
  final Color? color;
}

/// A coloured band painted behind a range of an axis.
@immutable
class VarietyPlotBand {
  /// Creates a plot band spanning [start] to [end].
  ///
  /// Both bounds are expressed in the axis' own unit: a number for numeric and
  /// logarithmic axes, the category index for category axes, and milliseconds
  /// since the epoch for date time axes.
  const VarietyPlotBand({
    required this.start,
    required this.end,
    this.color,
    this.opacity = 0.12,
    this.label,
    this.labelStyle,
    this.isVisible = true,
    this.repeatEvery,
  });

  /// The lower bound of the band.
  final num start;

  /// The upper bound of the band.
  final num end;

  /// The fill colour of the band.
  final Color? color;

  /// The alpha multiplier applied to [color].
  final double opacity;

  /// An optional caption centred inside the band.
  final String? label;

  /// The text style applied to [label].
  final TextStyle? labelStyle;

  /// Whether the band is painted.
  final bool isVisible;

  /// When set, the band repeats every `repeatEvery` units across the axis.
  final num? repeatEvery;

  /// Returns a copy of this band with the supplied fields replaced.
  VarietyPlotBand copyWith({
    num? start,
    num? end,
    Color? color,
    double? opacity,
    String? label,
    TextStyle? labelStyle,
    bool? isVisible,
    num? repeatEvery,
  }) {
    return VarietyPlotBand(
      start: start ?? this.start,
      end: end ?? this.end,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      label: label ?? this.label,
      labelStyle: labelStyle ?? this.labelStyle,
      isVisible: isVisible ?? this.isVisible,
      repeatEvery: repeatEvery ?? this.repeatEvery,
    );
  }
}

/// A bracket drawn above a range of categories on a category axis.
@immutable
class VarietyLabelGroup {
  /// Creates a label group covering the category indexes [start]..[end].
  const VarietyLabelGroup({
    required this.start,
    required this.end,
    required this.text,
    this.level = 0,
  });

  /// The first category index covered by the group.
  final int start;

  /// The last category index covered by the group.
  final int end;

  /// The caption rendered above the covered categories.
  final String text;

  /// The nesting depth, where `0` is the row closest to the axis.
  final int level;

  /// Returns a copy of this group with the supplied fields replaced.
  VarietyLabelGroup copyWith({int? start, int? end, String? text, int? level}) {
    return VarietyLabelGroup(
      start: start ?? this.start,
      end: end ?? this.end,
      text: text ?? this.text,
      level: level ?? this.level,
    );
  }
}

/// The multi-level label configuration of a category axis.
@immutable
class VarietyMultiLevelLabels {
  /// Creates a multi-level label configuration.
  const VarietyMultiLevelLabels({
    required this.groups,
    this.borderType = VarietyMultiLevelBorderType.rectangle,
    this.borderColor,
    this.borderWidth = 1,
    this.textStyle,
    this.margin = const EdgeInsets.symmetric(vertical: 4),
    this.merge = false,
    this.overlap = 0,
    this.rowHeight = 22,
  });

  /// The groups rendered above the axis.
  final List<VarietyLabelGroup> groups;

  /// The shape of the bracket drawn around each group.
  final VarietyMultiLevelBorderType borderType;

  /// The colour of the bracket borders.
  final Color? borderColor;

  /// The thickness of the bracket borders.
  final double borderWidth;

  /// The text style applied to group captions.
  final TextStyle? textStyle;

  /// Padding inserted between the bracket and its caption.
  final EdgeInsets margin;

  /// When `true` adjacent groups sharing a caption are merged.
  final bool merge;

  /// How far neighbouring brackets may overlap, in logical pixels.
  final double overlap;

  /// The height of one nesting row.
  final double rowHeight;
}

/// Describes one axis of a cartesian chart.
///
/// An axis is declarative: it only carries configuration. The concrete range,
/// tick values and pixel positions are derived at layout time.
@immutable
class VarietyAxis {
  /// Creates an axis description.
  const VarietyAxis({
    this.type,
    this.name,
    this.minimum,
    this.maximum,
    this.interval,
    this.title,
    this.showGridLines = true,
    this.gridLineColor,
    this.gridLineWidth = 1.0,
    this.gridLineDashPattern = const <double>[],
    this.majorGridLines,
    this.minorGridLines,
    this.majorTickLines,
    this.minorTickLines,
    this.labelStyle,
    this.labelRotation = 0.0,
    this.labelOffset = 8.0,
    this.labelAlignment = VarietyLabelPosition.auto,
    this.labelPlacement = VarietyLabelPlacement.outside,
    this.labelIntersectAction = VarietyLabelIntersectAction.hide,
    this.edgeLabelPlacement = VarietyEdgeLabelPlacement.none,
    this.axisLineColor,
    this.axisLineWidth = 1.2,
    this.borderType = VarietyAxisBorderType.line,
    this.showAxisLine = true,
    this.showLabels = true,
    this.showTicks = true,
    this.tickLength = 4,
    this.tickPosition = VarietyTickPosition.outside,
    this.minorTicksPerInterval = 0,
    this.opposedPosition = false,
    this.isInversed = false,
    this.rangePadding = VarietyRangePadding.auto,
    this.labelFormatter,
    this.numberFormat,
    this.desiredIntervals = 5,
    this.maximumLabels = 3,
    this.dateTimeIntervalType = VarietyDateTimeIntervalType.auto,
    this.dateTimeInterval,
    this.dateFormat,
    this.logBase = 10,
    this.plotBands = const <VarietyPlotBand>[],
    this.multiLevelLabels,
    this.crossesAt,
    this.plotOffset = 0,
    this.plotOffsetStart = 0,
    this.plotOffsetEnd = 0,
    this.anchorRangeToVisiblePoints = true,
    this.autoScrollingDelta,
    this.autoScrollingMode,
    this.visible = true,
  });

  /// How the values are interpreted. When `null` the chart picks a default:
  /// category for the primary axis and numeric for the secondary one.
  final VarietyAxisType? type;

  /// An optional identifier, surfaced by axis related callbacks.
  final String? name;

  /// The lowest value shown. Derived from the data when omitted.
  final double? minimum;

  /// The highest value shown. Derived from the data when omitted.
  final double? maximum;

  /// The spacing between consecutive ticks. Derived automatically when omitted.
  final double? interval;

  /// An optional caption rendered next to the axis.
  final String? title;

  /// Whether grid lines are painted across the plot area.
  final bool showGridLines;

  /// The grid line colour.
  final Color? gridLineColor;

  /// The grid line thickness.
  final double gridLineWidth;

  /// A dash pattern applied to grid lines. Empty means solid.
  final List<double> gridLineDashPattern;

  /// Detailed styling for the major grid lines.
  final VarietyMajorGridLines? majorGridLines;

  /// Styling for the minor grid lines. Minor lines appear only when
  /// [minorTicksPerInterval] is greater than zero.
  final VarietyMinorGridLines? minorGridLines;

  /// Detailed styling for the major tick marks.
  final VarietyMajorTickLines? majorTickLines;

  /// Styling for the minor tick marks.
  final VarietyMinorTickLines? minorTickLines;

  /// The text style applied to tick labels.
  final TextStyle? labelStyle;

  /// The rotation applied to tick labels, in degrees.
  final double labelRotation;

  /// The gap between the axis line and its labels.
  final double labelOffset;

  /// Where tick labels are anchored relative to the axis line.
  final VarietyLabelPosition labelAlignment;

  /// Whether labels sit inside or outside the plot area.
  final VarietyLabelPlacement labelPlacement;

  /// What happens when two labels would overlap.
  final VarietyLabelIntersectAction labelIntersectAction;

  /// How the first and last labels are kept inside the axis.
  final VarietyEdgeLabelPlacement edgeLabelPlacement;

  /// The colour of the axis line itself.
  final Color? axisLineColor;

  /// The thickness of the axis line.
  final double axisLineWidth;

  /// Whether the plot area is outlined with a rectangle or just two lines.
  final VarietyAxisBorderType borderType;

  /// Whether the axis line is painted.
  final bool showAxisLine;

  /// Whether tick labels are painted.
  final bool showLabels;

  /// Whether small tick marks are painted next to the axis line.
  final bool showTicks;

  /// The length of a tick mark.
  final double tickLength;

  /// Whether tick marks point into or away from the plot area.
  final VarietyTickPosition tickPosition;

  /// The number of minor ticks drawn between two major ticks.
  final int minorTicksPerInterval;

  /// Whether the axis is rendered on the opposite side of the plot area.
  final bool opposedPosition;

  /// Whether the axis runs from high to low instead of low to high.
  final bool isInversed;

  /// How much empty space is reserved around the data range.
  final VarietyRangePadding rangePadding;

  /// Formats a numeric or date time tick into a caption.
  final String Function(dynamic value)? labelFormatter;

  /// A numeric format pattern such as `0.00`, `#,##0` or `0%`.
  ///
  /// A practical subset is supported: digit placeholders, thousands separators
  /// and a trailing percent sign.
  final String? numberFormat;

  /// The approximate number of grid lines requested when [interval] is omitted.
  final int desiredIntervals;

  /// The largest number of labels allowed to share a slot.
  final int maximumLabels;

  /// The granularity used by a date time axis.
  final VarietyDateTimeIntervalType dateTimeIntervalType;

  /// The number of [dateTimeIntervalType] units between two ticks.
  final double? dateTimeInterval;

  /// A date format pattern such as `MMM yyyy` or `dd/MM`.
  final String? dateFormat;

  /// The base of a logarithmic axis.
  final double logBase;

  /// Bands painted behind the plot area for this axis.
  final List<VarietyPlotBand> plotBands;

  /// Multi-level labels rendered above a category axis.
  final VarietyMultiLevelLabels? multiLevelLabels;

  /// The value at which the opposite axis crosses this one.
  final double? crossesAt;

  /// Empty space reserved between the axis and the plot area.
  final double plotOffset;

  /// Extra space reserved before the first plot point.
  final double plotOffsetStart;

  /// Extra space reserved after the last plot point.
  final double plotOffsetEnd;

  /// Whether the range ignores points that are scrolled out of view.
  final bool anchorRangeToVisiblePoints;

  /// The span kept visible when auto scrolling is enabled.
  final double? autoScrollingDelta;

  /// How the window slides when auto scrolling is enabled.
  final VarietyAutoScrollingMode? autoScrollingMode;

  /// Whether the axis is laid out at all.
  final bool visible;

  /// Returns a copy of this axis with the supplied fields replaced.
  VarietyAxis copyWith({
    VarietyAxisType? type,
    String? name,
    double? minimum,
    double? maximum,
    double? interval,
    String? title,
    bool? showGridLines,
    Color? gridLineColor,
    double? gridLineWidth,
    List<double>? gridLineDashPattern,
    VarietyMajorGridLines? majorGridLines,
    VarietyMinorGridLines? minorGridLines,
    VarietyMajorTickLines? majorTickLines,
    VarietyMinorTickLines? minorTickLines,
    TextStyle? labelStyle,
    double? labelRotation,
    double? labelOffset,
    VarietyLabelPosition? labelAlignment,
    VarietyLabelPlacement? labelPlacement,
    VarietyLabelIntersectAction? labelIntersectAction,
    VarietyEdgeLabelPlacement? edgeLabelPlacement,
    Color? axisLineColor,
    double? axisLineWidth,
    VarietyAxisBorderType? borderType,
    bool? showAxisLine,
    bool? showLabels,
    bool? showTicks,
    double? tickLength,
    VarietyTickPosition? tickPosition,
    int? minorTicksPerInterval,
    bool? opposedPosition,
    bool? isInversed,
    VarietyRangePadding? rangePadding,
    String Function(dynamic value)? labelFormatter,
    String? numberFormat,
    int? desiredIntervals,
    int? maximumLabels,
    VarietyDateTimeIntervalType? dateTimeIntervalType,
    double? dateTimeInterval,
    String? dateFormat,
    double? logBase,
    List<VarietyPlotBand>? plotBands,
    VarietyMultiLevelLabels? multiLevelLabels,
    double? crossesAt,
    double? plotOffset,
    double? plotOffsetStart,
    double? plotOffsetEnd,
    bool? anchorRangeToVisiblePoints,
    double? autoScrollingDelta,
    VarietyAutoScrollingMode? autoScrollingMode,
    bool? visible,
  }) {
    return VarietyAxis(
      type: type ?? this.type,
      name: name ?? this.name,
      minimum: minimum ?? this.minimum,
      maximum: maximum ?? this.maximum,
      interval: interval ?? this.interval,
      title: title ?? this.title,
      showGridLines: showGridLines ?? this.showGridLines,
      gridLineColor: gridLineColor ?? this.gridLineColor,
      gridLineWidth: gridLineWidth ?? this.gridLineWidth,
      gridLineDashPattern: gridLineDashPattern ?? this.gridLineDashPattern,
      majorGridLines: majorGridLines ?? this.majorGridLines,
      minorGridLines: minorGridLines ?? this.minorGridLines,
      majorTickLines: majorTickLines ?? this.majorTickLines,
      minorTickLines: minorTickLines ?? this.minorTickLines,
      labelStyle: labelStyle ?? this.labelStyle,
      labelRotation: labelRotation ?? this.labelRotation,
      labelOffset: labelOffset ?? this.labelOffset,
      labelAlignment: labelAlignment ?? this.labelAlignment,
      labelPlacement: labelPlacement ?? this.labelPlacement,
      labelIntersectAction: labelIntersectAction ?? this.labelIntersectAction,
      edgeLabelPlacement: edgeLabelPlacement ?? this.edgeLabelPlacement,
      axisLineColor: axisLineColor ?? this.axisLineColor,
      axisLineWidth: axisLineWidth ?? this.axisLineWidth,
      borderType: borderType ?? this.borderType,
      showAxisLine: showAxisLine ?? this.showAxisLine,
      showLabels: showLabels ?? this.showLabels,
      showTicks: showTicks ?? this.showTicks,
      tickLength: tickLength ?? this.tickLength,
      tickPosition: tickPosition ?? this.tickPosition,
      minorTicksPerInterval: minorTicksPerInterval ?? this.minorTicksPerInterval,
      opposedPosition: opposedPosition ?? this.opposedPosition,
      isInversed: isInversed ?? this.isInversed,
      rangePadding: rangePadding ?? this.rangePadding,
      labelFormatter: labelFormatter ?? this.labelFormatter,
      numberFormat: numberFormat ?? this.numberFormat,
      desiredIntervals: desiredIntervals ?? this.desiredIntervals,
      maximumLabels: maximumLabels ?? this.maximumLabels,
      dateTimeIntervalType: dateTimeIntervalType ?? this.dateTimeIntervalType,
      dateTimeInterval: dateTimeInterval ?? this.dateTimeInterval,
      dateFormat: dateFormat ?? this.dateFormat,
      logBase: logBase ?? this.logBase,
      plotBands: plotBands ?? this.plotBands,
      multiLevelLabels: multiLevelLabels ?? this.multiLevelLabels,
      crossesAt: crossesAt ?? this.crossesAt,
      plotOffset: plotOffset ?? this.plotOffset,
      plotOffsetStart: plotOffsetStart ?? this.plotOffsetStart,
      plotOffsetEnd: plotOffsetEnd ?? this.plotOffsetEnd,
      anchorRangeToVisiblePoints:
          anchorRangeToVisiblePoints ?? this.anchorRangeToVisiblePoints,
      autoScrollingDelta: autoScrollingDelta ?? this.autoScrollingDelta,
      autoScrollingMode: autoScrollingMode ?? this.autoScrollingMode,
      visible: visible ?? this.visible,
    );
  }
}

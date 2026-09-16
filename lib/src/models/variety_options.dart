/// Option enumerations for axes, legends, behaviours and series.
///
/// These live in their own library to keep `variety_enums.dart` focused on the
/// core series and axis vocabulary.
library;

/// How a tick label behaves when it would overlap its neighbour.
enum VarietyLabelIntersectAction {
  /// Labels are drawn even when they overlap.
  none,

  /// Overlapping labels are dropped.
  hide,

  /// Overlapping labels are rotated by 45 degrees.
  rotate45,

  /// Overlapping labels are rotated by 90 degrees.
  rotate90,

  /// Overlapping labels are split onto two lines.
  wrap,

  /// Overlapping labels are stacked onto several rows.
  multipleRows,
}

/// How the value range is padded once the data range is known.
enum VarietyRangePadding {
  /// The axis spans exactly the data range.
  none,

  /// The range is extended outwards to the enclosing tick values.
  normal,

  /// The range is extended to round tick values.
  round,

  /// A small margin is added around the data range.
  extra,

  /// The padding style is chosen from the axis type.
  auto,

  /// The range is rounded outwards and then padded so the first and last
  /// labels stay inside.
  additional,

  /// Like [additional], but only the low end of the axis is padded.
  additionalStart,

  /// Like [additional], but only the high end of the axis is padded.
  additionalEnd,

  /// Like [round], but only the low end is rounded outwards.
  roundStart,

  /// Like [round], but only the high end is rounded outwards.
  roundEnd,
}

/// How the first and last tick labels are kept inside the axis.
enum VarietyEdgeLabelPlacement {
  /// Labels are left as they are.
  none,

  /// Out-of-range labels are dropped.
  hide,

  /// Out-of-range labels are nudged back inside.
  shift,
}

/// Where tick labels sit relative to the axis line.
enum VarietyLabelPlacement {
  /// Labels sit on the plot side of the axis.
  inside,

  /// Labels sit away from the plot.
  outside,
}

/// Where tick marks point.
enum VarietyTickPosition {
  /// Tick marks point into the plot area.
  inside,

  /// Tick marks point away from the plot area.
  outside,
}

/// The line drawn around the axis.
enum VarietyAxisBorderType {
  /// A full rectangle around the plot area.
  rectangle,

  /// Only the two axis lines.
  line,
}

/// How an empty point is rendered.
enum VarietyEmptyPointMode {
  /// The point is skipped and a gap is left behind.
  gap,

  /// The point is treated as zero.
  zero,

  /// The point is replaced by the average of its neighbours.
  average,

  /// The point and its neighbours are skipped.
  drop,
}

/// How the legend represents a series.
enum VarietyLegendIconType {
  /// The glyph matches the series kind.
  seriesType,

  /// A filled circle.
  circle,

  /// A filled square.
  rectangle,

  /// A filled diamond.
  diamond,

  /// A filled triangle.
  triangle,

  /// A horizontal rule.
  line,

  /// A cross glyph.
  cross,

  /// A plus glyph.
  plus,

  /// A filled downward triangle.
  invertedTriangle,
}

/// The direction a legend lays its items out in.
enum VarietyLegendItemOrientation {
  /// Items are stacked vertically.
  vertical,

  /// Items are laid out in a row.
  horizontal,

  /// The direction follows the legend placement.
  auto,
}

/// What happens when the legend runs out of room.
enum VarietyLegendOverflowMode {
  /// The legend becomes scrollable.
  scroll,

  /// The legend wraps onto more rows.
  wrap,

  /// Overflowing items are clipped.
  none,
}

/// How legend items are aligned along the cross axis.
enum VarietyLegendAlignment {
  /// Items are packed towards the start.
  start,

  /// Items are centred.
  center,

  /// Items are packed towards the end.
  end,
}

/// The order data points are sorted into before plotting.
enum VarietySortingOrder {
  /// The author order is kept.
  none,

  /// Points are sorted by their primary axis value, ascending.
  ascending,

  /// Points are sorted by their primary axis value, descending.
  descending,
}

/// The shape of the guide drawn by a trackball.
enum VarietyTrackballLineType {
  /// A vertical guide only.
  vertical,

  /// A horizontal guide only.
  horizontal,

  /// Both a vertical and a horizontal guide.
  both,
}

/// What a trackball shows for the active slot.
enum VarietyTrackballDisplayMode {
  /// One entry for every series at the active slot.
  groupAllPoints,

  /// Only the closest point is shown.
  nearestPoint,

  /// Every point in every series is shown.
  floatAllPoints,

  /// Nothing is shown.
  none,
}

/// When a trackball appears.
enum VarietyTrackballVisibilityMode {
  /// The trackball is always visible.
  always,

  /// The trackball appears on activation and fades out afterwards.
  auto,

  /// The trackball is never shown.
  hidden,
}

/// Which axis a zoom gesture affects.
enum VarietyZoomAxisMode {
  /// Only the primary axis zooms.
  x,

  /// Only the secondary axis zooms.
  y,

  /// Both axes zoom together.
  xy,
}

/// When a chart renders its content.
enum VarietyRenderingMode {
  /// Series are painted as soon as the chart lays out.
  onLoading,

  /// Series are painted only after the user interacts.
  onDemand,
}

/// The interpolation used by spline based series.
enum VarietySplineType {
  /// A natural cubic spline.
  natural,

  /// A cardinal spline, which is what a typical smooth line uses.
  cardinal,

  /// A clamped cubic spline.
  clamped,

  /// A monotonic cubic spline that never overshoots.
  monotonic,
}

/// How box plot quartiles are computed.
enum VarietyBoxPlotMode {
  /// Quartiles are computed with the exclusive median rule.
  exclusive,

  /// Quartiles are computed with the inclusive median rule.
  inclusive,

  /// Quartiles are computed from the raw order statistics.
  normal,
}

/// How the error range is derived.
enum VarietyErrorBarType {
  /// A constant plus/minus amount.
  fixed,

  /// A percentage of each value.
  percentage,

  /// A multiple of the series standard deviation.
  standardDeviation,

  /// A multiple of the standard error of the mean.
  standardError,

  /// A per-point amount supplied in the secondary value.
  custom,
}

/// The shape of the line joining a data label to its slice.
enum VarietyConnectorType {
  /// A single straight segment.
  line,

  /// A bezier curve.
  bezier,
}

/// How a circular data label is aligned.
enum VarietyChartDataLabelAlignment {
  /// The label sits above the slice.
  top,

  /// The label sits at the slice centre.
  middle,

  /// The label sits below the slice.
  bottom,

  /// The alignment is chosen from the slice angle.
  auto,
}

/// The bracket drawn around a group of multi-level labels.
enum VarietyMultiLevelBorderType {
  /// A rounded rectangle.
  rectangle,

  /// A curly bracket.
  curlyBracket,

  /// A square bracket.
  brace,
}

/// The area an annotation is positioned against.
enum VarietyAnnotationRegion {
  /// Coordinates are read against the whole chart.
  chart,

  /// Coordinates are read against the plot area.
  plotArea,
}

/// How the entrance animation interpolates.
enum VarietyAnimationType {
  /// The animation follows an ease curve.
  load,

  /// The animation advances linearly.
  linear,
}

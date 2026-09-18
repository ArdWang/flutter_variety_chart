/// Enumerations shared across the `flutter_variety_chart` package.
///
/// Every public type in this library is prefixed with `Variety` so the API
/// stays self-describing and never collides with other chart packages.
library;

/// Controls how the values fed into an axis are interpreted.
enum VarietyAxisType {
  /// Values are treated as numbers and laid out proportionally.
  numeric,

  /// Values are treated as discrete buckets and spaced evenly.
  category,

  /// Values are treated as [DateTime] instances along a timeline.
  dateTime,

  /// Values are [DateTime] instances bucketed into discrete categories.
  dateTimeCategory,

  /// Values are laid out on a logarithmic scale.
  logarithmic,
}

/// The granularity used when generating secondary ticks on a date time axis.
enum VarietyDateTimeIntervalType {
  /// Picks a granularity from the visible span.
  auto,

  /// One tick per year.
  years,

  /// One tick per month.
  months,

  /// One tick per day.
  days,

  /// One tick per hour.
  hours,

  /// One tick per minute.
  minutes,

  /// One tick per second.
  seconds,

  /// One tick per millisecond.
  milliseconds,
}

/// The placement of a legend relative to the plot area.
enum VarietyLegendPosition {
  /// Picks a side from the shape of the chart: a chart taller than it is wide
  /// puts the legend underneath, a wider one puts it at the right.
  ///
  /// This mirrors `LegendPosition.auto` in the reference implementation.
  auto,

  /// Renders the legend above the plot area.
  top,

  /// Renders the legend below the plot area.
  bottom,

  /// Renders the legend on the left side of the plot area.
  left,

  /// Renders the legend on the right side of the plot area.
  right,
}

/// The shape used to render a data marker.
enum VarietyMarkerShape {
  /// No glyph is drawn at all.
  ///
  /// Useful for switching markers off for one series in a chart that turns
  /// them on for the rest.
  none,

  /// A filled circle.
  circle,

  /// A filled square.
  square,

  /// A filled diamond.
  diamond,

  /// A filled upward triangle.
  triangle,

  /// A filled downward triangle.
  invertedTriangle,

  /// A plus sign.
  plus,

  /// A multiplication sign.
  cross,

  /// A filled five sided polygon.
  pentagon,

  /// A vertical stroke through the point, the `|` half of a cross.
  verticalLine,

  /// A horizontal stroke through the point, the `-` half of a cross.
  horizontalLine,
}

/// Determines where data labels are placed with respect to their point.
enum VarietyLabelPosition {
  /// Places the label inside the shape whenever it fits.
  inside,

  /// Always places the label outside the shape.
  outside,

  /// Chooses inside/outside automatically based on available room.
  auto,

  /// Places the label above the point.
  top,

  /// Places the label below the point.
  bottom,

  /// Places the label to the left of the point.
  left,

  /// Places the label to the right of the point.
  right,
}

/// The direction in which circular series slices are swept.
enum VarietySliceDirection {
  /// Slices are drawn in clockwise order.
  clockwise,

  /// Slices are drawn in counter-clockwise order.
  counterClockwise,
}

/// The stroke style applied to a line-like series.
enum VarietyLineStyle {
  /// A straight segment between consecutive points.
  straight,

  /// A smooth cardinal spline through the points.
  curved,

  /// A horizontal/vertical staircase between points.
  stepped,

  /// A straight segment optimised for large data sets.
  fastLine,
}

/// How a series combines its values with the series drawn before it.
enum VarietyStackingMode {
  /// Values are drawn from the baseline, independently of other series.
  none,

  /// Values are stacked on top of the previous series.
  normal,

  /// Values are normalised so that each stack sums to 100%.
  percent100,
}

/// The kind of selection a user gesture performs.
enum VarietySelectionType {
  /// A single data point is selected.
  point,

  /// The whole series is selected.
  series,

  /// Every series' point that shares the tapped slot is selected, which is the
  /// way to highlight one x position across several series at once.
  cluster,

  /// Selection is disabled.
  none,
}

/// The gesture that reveals a trackball or crosshair.
enum VarietyActivationMode {
  /// A single tap reveals the overlay.
  tap,

  /// A double tap reveals the overlay.
  ///
  /// A chart with both a double-tap zoom and a double-tap overlay on the same
  /// gesture is ambiguous, so the zoom is the one that wins when it is
  /// enabled; use [tap] or [longPress] alongside it.
  doubleTap,

  /// A long press reveals the overlay.
  longPress,

  /// Pressing and holding reveals the overlay.
  press,

  /// Every pointer movement reveals the overlay.
  auto,

  /// The overlay never appears.
  none,
}

/// The regression model fitted by a trendline.
enum VarietyTrendlineType {
  /// Fits `y = a + b * x`.
  linear,

  /// Fits `y = a * exp(b * x)`.
  exponential,

  /// Fits `y = a + b * ln(x)`.
  logarithmic,

  /// Fits a polynomial of the requested [VarietyTrendline.order].
  polynomial,

  /// Fits `y = a * x^b`.
  power,

  /// Draws a simple moving average of the previous `period` values.
  movingAverage,
}

/// The primitive drawn by an annotation.
enum VarietyShapeType {
  /// A horizontal rule spanning the plot width.
  horizontalLine,

  /// A vertical rule spanning the plot height.
  verticalLine,

  /// A rectangle anchored to a data point.
  rectangle,

  /// An ellipse anchored to a data point.
  ellipse,

  /// A text caption anchored to a data point.
  text,

  /// An arrow pointing at a data point.
  arrow,

  /// An image loaded from an [ImageProvider] and anchored to a data point.
  image,
}

/// The activation mode understood by the zoom and pan behaviour.
///
/// This bundles the independent zooming flags — `enablePinching`,
/// `enablePanning`, `enableMouseWheelZooming`, `enableDoubleTapZooming` and
/// `enableSelectionZooming` — into the combinations that are actually useful.
///
/// Selection zooming is always driven by a **long press**: press, drag out a
/// region, release. That is what lets it
/// run alongside panning, which keeps the plain drag gesture.
enum VarietyZoomMode {
  /// Pinch and mouse wheel zoom, double tap to zoom in or reset, and drag to
  /// pan while zoomed.
  pinch,

  /// Long-press and drag to rubber-band select a region. A plain drag still
  /// pans whenever `enablePanning` is set.
  selection,

  /// Everything from [pinch] plus long-press selection zooming.
  both,

  /// Zooming is disabled; the chart ignores every zoom and pan gesture.
  none,
}

/// Where a sparkline draws its baseline.
enum VarietySparklineType {
  /// A stroked line through the values.
  line,

  /// A filled area below the line.
  area,

  /// A column per value.
  column,

  /// A win/loss bar where sign drives the direction.
  winLoss,
}

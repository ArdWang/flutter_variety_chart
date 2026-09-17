import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../behaviors/variety_behaviors.dart';
import '../painters/variety_element_renderer.dart';
import 'variety_chart_data.dart';
import 'variety_empty_points.dart';
import 'variety_enums.dart';
import 'variety_marker_settings.dart';
import 'variety_options.dart';
import 'variety_trendline.dart';

/// The colour cycle used when a series does not declare its own colour.
const List<Color> varietyDefaultPalette = <Color>[
  Color(0xFF3F6FE0),
  Color(0xFFE0603F),
  Color(0xFF2FA37A),
  Color(0xFFE0A93F),
  Color(0xFF8A5CD6),
  Color(0xFF2FA6C4),
  Color(0xFFD64F8A),
  Color(0xFF7A8B3F),
  Color(0xFFB0562F),
  Color(0xFF4C69A8),
];

/// Base class for every series understood by this package.
///
/// A series owns a list of [VarietyChartData] plus the styling shared by all
/// series kinds. Concrete subclasses describe how the points become geometry:
/// strokes, bands, rectangles, candles or circular slices.
@immutable
abstract class VarietySeries {
  /// Creates a series around the given [data] points.
  const VarietySeries({
    required this.data,
    this.name,
    this.color,
    this.opacity = 1.0,
    this.dataLabelSettings = const VarietyDataLabelSettings(),
    this.dataLabelMapper,
    this.pointColorMapper,
    this.legendIconType,
    this.enableTooltip = true,
    this.animate = true,
    this.stackMode = VarietyStackingMode.none,
    this.trendlines = const <VarietyTrendline>[],
    this.selectionColor,
    this.unselectedOpacity = 1.0,
    this.legendIconShape = VarietyMarkerShape.circle,
    this.animationDelay = Duration.zero,
    this.emptyPointSettings = const VarietyEmptyPointSettings(),
    this.sortingOrder = VarietySortingOrder.none,
    this.sortFieldValueMapper,
    this.errorBar,
    this.xAxisName,
    this.yAxisName,
    this.markerSettings,
    this.gradient,
    this.borderGradient,
    this.enableTrackball = true,
    this.initialIsVisible = true,
    this.isVisibleInLegend = true,
    this.legendItemText,
    this.animationDuration,
    this.initialSelectedDataIndexes = const <int>[],
    this.onPointTap,
    this.onPointDoubleTap,
    this.onPointLongPress,
    this.onCreateRenderer,
    this.onCreateShader,
    this.onRendererCreated,
    this.selectionBehavior,
  });

  /// The points plotted by this series.
  final List<VarietyChartData> data;

  /// An optional name, shown by the legend and tooltips.
  final String? name;

  /// The series colour. When omitted the palette colour is used.
  final Color? color;

  /// A multiplier applied to the series colour's alpha channel.
  final double opacity;

  /// The data label configuration for this series.
  final VarietyDataLabelSettings dataLabelSettings;

  /// Returns the label text for a point, overriding [VarietyDataLabelSettings].
  ///
  /// When `null`, the renderer falls back to the point's `y` value formatted
  /// by [VarietyDataLabelSettings.builder].
  final String Function(VarietyChartData point, int index)? dataLabelMapper;

  /// Returns a per-point colour override.
  ///
  /// Returning `null` keeps the series colour for that point. The painter
  /// walks this callback once per rendered marker and label.
  final Color? Function(VarietyChartData point, int index)? pointColorMapper;

  /// The icon used by the chart's legend when [legendIconShape] is omitted.
  final VarietyLegendIconType? legendIconType;

  /// Builds a per-series element renderer.
  ///
  /// When `null`, every series shares the default renderer. When supplied,
  /// the painter keeps one renderer per series and uses it for every
  /// element produced by that series. This is the equivalent of the
  /// upstream library's `onCreateRenderer` hook.
  final VarietyRendererFactory? onCreateRenderer;

  /// Builds a `Shader` that overrides [gradient] and [borderGradient].
  ///
  /// When the callback returns `null`, the painter uses the supplied
  /// gradient. Otherwise it paints with the returned shader.
  final VarietyShaderFactory? onCreateShader;

  /// Fires after the series renderer is constructed.
  ///
  /// Equivalent to the upstream `onRendererCreated`. The chart widget
  /// also passes the series index so a chart-scoped controller can be
  /// updated.
  final void Function(VarietyElementRenderer renderer, int seriesIndex)?
      onRendererCreated;

  /// A per-series selection configuration that overrides the chart-wide
  /// one. When `null`, the chart-wide `selectionBehavior` is used.
  final VarietySelectionBehavior? selectionBehavior;

  /// Whether this series participates in tooltips.
  final bool enableTooltip;

  /// Whether this series animates when the chart first appears.
  final bool animate;

  /// How this series combines with the previous ones.
  final VarietyStackingMode stackMode;

  /// Regression lines fitted to this series.
  final List<VarietyTrendline> trendlines;

  /// The colour applied to this series when it is selected.
  final Color? selectionColor;

  /// The opacity applied to a series while another one is selected.
  final double unselectedOpacity;

  /// The glyph used to represent this series in the legend.
  final VarietyMarkerShape legendIconShape;

  /// A delay inserted before the entrance animation of this series starts.
  final Duration animationDelay;

  /// How empty points in this series are rendered.
  final VarietyEmptyPointSettings emptyPointSettings;

  /// The order the points are sorted into before they are plotted.
  final VarietySortingOrder sortingOrder;

  /// A mapper that returns the value used for ordering when
  /// [sortingOrder] is not [VarietySortingOrder.none].
  ///
  /// When `null` the x coordinate is used. Override this to sort by a
  /// derived value, e.g. by a numeric column on your data record.
  final double Function(VarietyChartData point)? sortFieldValueMapper;

  /// An optional error bar drawn alongside this series.
  final VarietyErrorBarSeries? errorBar;

  /// The name of the horizontal axis this series is plotted against.
  ///
  /// When `null` the series uses the chart's primary horizontal axis. Name one
  /// of the chart's `secondaryXAxes` to plot this series against its own
  /// horizontal scale: the axis resolves its range from the series pointed at
  /// it, prints its own ticks in its own row, and hands its columns their own
  /// slot width. A name that matches no axis falls back to the primary one.
  final String? xAxisName;

  /// The name of the secondary axis this series is plotted against.
  ///
  /// When `null` the series uses the chart's primary secondary axis. A name
  /// that matches no axis falls back to the primary one.
  final String? yAxisName;

  /// A grouped marker configuration.
  ///
  /// When supplied it wins over the individual marker properties declared by a
  /// concrete series.
  final VarietyMarkerSettings? markerSettings;

  /// A gradient painted inside the series shape.
  final Gradient? gradient;

  /// A gradient painted along the series outline.
  final Gradient? borderGradient;

  /// Whether the trackball picks this series up.
  final bool enableTrackball;

  /// Whether the series is visible when the chart first appears.
  final bool initialIsVisible;

  /// Whether the series is listed in the legend.
  final bool isVisibleInLegend;

  /// The caption shown by the legend. Falls back to [name].
  final String? legendItemText;

  /// How long this series animates for. Falls back to the chart duration.
  final Duration? animationDuration;

  /// The data indexes selected when the chart first appears.
  final List<int> initialSelectedDataIndexes;

  /// Called when a point of this series is tapped.
  final void Function(VarietyChartData point, int index)? onPointTap;

  /// Called when a point of this series is double tapped.
  final void Function(VarietyChartData point, int index)? onPointDoubleTap;

  /// Called when a point of this series is long pressed.
  final void Function(VarietyChartData point, int index)? onPointLongPress;

  /// Whether this series is rendered using polar coordinates.
  bool get isCircular => false;

  /// Whether this series stacks its values on top of the previous series.
  bool get isStacked => stackMode != VarietyStackingMode.none;

  /// Whether this series normalises its values so each stack sums to 100%.
  bool get isPercentStacked => stackMode == VarietyStackingMode.percent100;

  /// Whether this series draws banded (rectangular) shapes.
  bool get isBanded => false;

  /// Whether this series draws a high/low envelope.
  bool get isRange => false;

  /// Whether this series draws uncertainty whiskers.
  bool get isErrorBar => false;

  /// Whether this series draws a box plot.
  bool get isBoxPlot => false;

  /// The interpolation a curved line uses.
  ///
  /// Only the line-like series carry a `splineType` field of their own and
  /// override this; every other kind ignores it.
  VarietySplineType get splineType => VarietySplineType.cardinal;
}

/// A series that connects its points with a stroked path.
class VarietyLineSeries extends VarietySeries {
  /// Creates a line series.
  const VarietyLineSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.stackMode,
    super.trendlines,
    super.selectionColor,
    super.unselectedOpacity,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.lineStyle = VarietyLineStyle.straight,
    this.splineType = VarietySplineType.cardinal,
    this.strokeWidth = 2.0,
    this.dashPattern = const <double>[],
    this.borderWidth = 0,
    this.showMarkers = false,
    this.markerSize = 6.0,
    this.markerShape = VarietyMarkerShape.circle,
    this.markerColor,
    this.fillOpacity = 0.0,
  });

  /// How consecutive points are joined.
  final VarietyLineStyle lineStyle;

  /// The interpolation used when [lineStyle] is [VarietyLineStyle.curved].
  @override
  final VarietySplineType splineType;

  /// The stroke thickness in logical pixels.
  final double strokeWidth;

  /// A dash pattern of alternating on/off lengths. Empty means solid.
  final List<double> dashPattern;

  /// The thickness of an outer line painted around the series. Defaults
  /// to `0`, which means no border is drawn.
  final double borderWidth;

  /// An alias for [dashPattern], matching the original library's naming.
  /// When supplied during construction it overrides [dashPattern].

  /// Whether a marker is drawn at every point.
  final bool showMarkers;

  /// The diameter of a marker in logical pixels.
  final double markerSize;

  /// The shape of the marker.
  final VarietyMarkerShape markerShape;

  /// The marker colour, defaulting to the series colour.
  final Color? markerColor;

  /// When greater than zero, the area under the line is filled.
  final double fillOpacity;
}

/// A series that fills the region between the line and the primary axis.
class VarietyAreaSeries extends VarietySeries {
  /// Creates an area series.
  const VarietyAreaSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.stackMode,
    super.trendlines,
    super.selectionColor,
    super.unselectedOpacity,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.lineStyle = VarietyLineStyle.straight,
    this.splineType = VarietySplineType.cardinal,
    this.strokeWidth = 2.0,
    this.fillOpacity = 0.35,
    this.showMarkers = false,
    this.markerSize = 5.0,
  });

  /// How consecutive points are joined.
  final VarietyLineStyle lineStyle;

  /// The interpolation used when [lineStyle] is [VarietyLineStyle.curved].
  @override
  final VarietySplineType splineType;

  /// The stroke thickness of the outline.
  final double strokeWidth;

  /// The alpha applied to the filled region.
  final double fillOpacity;

  /// Whether a marker is drawn at every point.
  final bool showMarkers;

  /// The diameter of a marker in logical pixels.
  final double markerSize;
}

/// A series that fills the region between a high bound and a low bound.
class VarietyRangeAreaSeries extends VarietySeries {
  /// Creates a range area series.
  const VarietyRangeAreaSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.trendlines,
    super.selectionColor,
    super.unselectedOpacity,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.lineStyle = VarietyLineStyle.straight,
    this.splineType = VarietySplineType.cardinal,
    this.strokeWidth = 1.6,
    this.fillOpacity = 0.3,
    this.showMarkers = false,
    this.markerSize = 5.0,
  });

  /// How consecutive points are joined.
  final VarietyLineStyle lineStyle;

  /// The interpolation used when [lineStyle] is [VarietyLineStyle.curved].
  @override
  final VarietySplineType splineType;

  /// The stroke thickness of the outline.
  final double strokeWidth;

  /// The alpha applied to the filled region.
  final double fillOpacity;

  /// Whether a marker is drawn at every bound.
  final bool showMarkers;

  /// The diameter of a marker in logical pixels.
  final double markerSize;

  @override
  bool get isRange => true;
}

/// A series that draws one vertical rectangle per point.
class VarietyColumnSeries extends VarietySeries {
  /// Creates a column series.
  const VarietyColumnSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.stackMode,
    super.trendlines,
    super.selectionColor,
    super.unselectedOpacity,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.widthFactor = 0.7,
    this.cornerRadius = 0.0,
    this.borderColor,
    this.borderWidth = 0.0,
    this.showTrack = false,
    this.trackColor,
  });

  /// The share of the available band occupied by the rectangle.
  final double widthFactor;

  /// The corner radius applied to the rectangle.
  final double cornerRadius;

  /// An optional stroke colour for the rectangle outline.
  final Color? borderColor;

  /// The thickness of the rectangle outline.
  final double borderWidth;

  /// Whether a faint track is painted behind the rectangle.
  final bool showTrack;

  /// The colour of the track.
  final Color? trackColor;

  @override
  bool get isBanded => true;
}

/// A series that draws a rectangle between a high and a low value per point.
class VarietyRangeColumnSeries extends VarietySeries {
  /// Creates a range column series.
  const VarietyRangeColumnSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.trendlines,
    super.selectionColor,
    super.unselectedOpacity,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.widthFactor = 0.7,
    this.cornerRadius = 0.0,
  });

  /// The share of the available band occupied by the rectangle.
  final double widthFactor;

  /// The corner radius applied to the rectangle.
  final double cornerRadius;

  @override
  bool get isBanded => true;

  @override
  bool get isRange => true;
}

/// A series that draws one horizontal rectangle per point.
class VarietyBarSeries extends VarietySeries {
  /// Creates a bar series.
  const VarietyBarSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.stackMode,
    super.trendlines,
    super.selectionColor,
    super.unselectedOpacity,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.widthFactor = 0.7,
    this.cornerRadius = 0.0,
    this.borderColor,
    this.borderWidth = 0.0,
  });

  /// The share of the available band occupied by the rectangle.
  final double widthFactor;

  /// The corner radius applied to the rectangle.
  final double cornerRadius;

  /// An optional stroke colour for the rectangle outline.
  final Color? borderColor;

  /// The thickness of the rectangle outline.
  final double borderWidth;

  @override
  bool get isBanded => true;
}

/// A series that draws an unconnected marker for every point.
class VarietyScatterSeries extends VarietySeries {
  /// Creates a scatter series.
  const VarietyScatterSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.trendlines,
    super.selectionColor,
    super.unselectedOpacity,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.markerSize = 10.0,
    this.markerShape = VarietyMarkerShape.circle,
  });

  /// The diameter of a marker in logical pixels.
  final double markerSize;

  /// The shape of the marker.
  final VarietyMarkerShape markerShape;
}

/// A series whose marker radius is driven by a third value.
class VarietyBubbleSeries extends VarietySeries {
  /// Creates a bubble series.
  const VarietyBubbleSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.trendlines,
    super.selectionColor,
    super.unselectedOpacity,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.minimumRadius = 4.0,
    this.maximumRadius = 26.0,
    this.borderColor,
    this.borderWidth = 1.5,
    this.fillOpacity = 0.7,
  });

  /// The radius used for the smallest bubble.
  final double minimumRadius;

  /// The radius used for the largest bubble.
  final double maximumRadius;

  /// The outline colour of the bubble.
  final Color? borderColor;

  /// The thickness of the bubble outline.
  final double borderWidth;

  /// The alpha applied to the bubble fill.
  final double fillOpacity;
}

/// A series that draws open/high/low/close candlesticks.
class VarietyCandleSeries extends VarietySeries {
  /// Creates a candle series.
  const VarietyCandleSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.bullFillColor,
    this.bearFillColor,
    this.borderColor,
    this.showWicks = true,
    this.widthFactor = 0.7,
  });

  /// The fill colour of rising candles.
  final Color? bullFillColor;

  /// The fill colour of falling candles.
  final Color? bearFillColor;

  /// The outline colour of the candles.
  final Color? borderColor;

  /// Whether the high/low wicks are drawn.
  final bool showWicks;

  /// The share of the available band occupied by one candle.
  final double widthFactor;
}

/// A series that draws a vertical line between the high and the low value.
class VarietyHiLoSeries extends VarietySeries {
  /// Creates a hi-lo series.
  const VarietyHiLoSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.strokeWidth = 1.6,
    this.showMarkers = true,
    this.markerSize = 6.0,
  });

  /// The stroke thickness of the stem.
  final double strokeWidth;

  /// Whether markers are drawn at the high and low values.
  final bool showMarkers;

  /// The diameter of a marker in logical pixels.
  final double markerSize;
}

/// A series that draws a hi-lo stem with open and close ticks.
class VarietyHiLoOpenCloseSeries extends VarietySeries {
  /// Creates a hi-lo-open-close series.
  const VarietyHiLoOpenCloseSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.strokeWidth = 1.6,
    this.tickWidth = 10.0,
  });

  /// The stroke thickness of the stem.
  final double strokeWidth;

  /// The width of the open and close ticks.
  final double tickWidth;
}

/// A series that accumulates deltas into a running total.
class VarietyWaterfallSeries extends VarietySeries {
  /// Creates a waterfall series.
  const VarietyWaterfallSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.widthFactor = 0.7,
    this.cornerRadius = 0.0,
    this.showConnectorLines = true,
    this.connectorLineColor,
    this.connectorLineWidth = 1.2,
    this.positiveColor,
    this.negativeColor,
    this.totalColor,
    this.showTotal = true,
    this.summaryIndexes = const <int>[],
  });

  /// The share of the available band occupied by one column.
  final double widthFactor;

  /// The corner radius applied to the columns.
  final double cornerRadius;

  /// Whether horizontal connector lines are drawn between columns.
  final bool showConnectorLines;

  /// The colour of the connector lines.
  final Color? connectorLineColor;

  /// The thickness of the connector lines.
  final double connectorLineWidth;

  /// The fill colour of a rising step.
  final Color? positiveColor;

  /// The fill colour of a falling step.
  final Color? negativeColor;

  /// The fill colour of a total column.
  final Color? totalColor;

  /// Whether a trailing total column is appended.
  final bool showTotal;

  /// The indexes rendered as totals rather than deltas.
  final List<int> summaryIndexes;

  @override
  bool get isBanded => true;
}

/// A series that bins raw samples into a frequency distribution.
class VarietyHistogramSeries extends VarietySeries {
  /// Creates a histogram series.
  const VarietyHistogramSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.binCount = 10,
    this.widthFactor = 1.0,
    this.cornerRadius = 0.0,
    this.showNormalDistribution = false,
    this.normalDistributionColor,
    this.normalDistributionWidth = 2.0,
  });

  /// The number of equal-width bins the samples are grouped into.
  final int binCount;

  /// The share of the available band occupied by one bar.
  final double widthFactor;

  /// The corner radius applied to the bars.
  final double cornerRadius;

  /// Whether a fitted normal curve is overlaid.
  final bool showNormalDistribution;

  /// The colour of the normal curve.
  final Color? normalDistributionColor;

  /// The thickness of the normal curve.
  final double normalDistributionWidth;

  @override
  bool get isBanded => true;
}

/// A series that divides a circle into slices proportional to each value.
class VarietyPieSeries extends VarietySeries {
  /// Creates a pie series.
  const VarietyPieSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.xAxisName,
    super.yAxisName,
    this.radiusFactor = 0.85,
    this.startAngle = -90.0,
    this.endAngle = 270.0,
    this.direction = VarietySliceDirection.clockwise,
    this.explodeIndex = -1,
    this.explodeOffset = 12.0,
    this.groupSmallSlices = false,
    this.groupTo = 12.0,
    this.groupLabel = 'Others',
    this.strokeColor,
    this.strokeWidth = 1.5,
    this.equalSlices = false,
  });

  /// The share of the available radius used by the pie.
  final double radiusFactor;

  /// The angle, in degrees, at which the first slice starts.
  final double startAngle;

  /// The angle, in degrees, at which the last slice ends.
  final double endAngle;

  /// The sweep direction.
  final VarietySliceDirection direction;

  /// The index of a slice to offset, or `-1` for none.
  final int explodeIndex;

  /// The distance the exploded slice is pushed outwards.
  final double explodeOffset;

  /// Whether slices below [groupTo] percent are folded into one slice.
  final bool groupSmallSlices;

  /// The threshold in percent below which a slice is grouped.
  final double groupTo;

  /// The caption of the grouped slice.
  final String groupLabel;

  /// The outline colour between slices.
  final Color? strokeColor;

  /// The thickness of the slice outline.
  final double strokeWidth;

  /// When `true` every slice spans the same angle.
  final bool equalSlices;

  @override
  bool get isCircular => true;
}

/// A pie series with a hollow centre.
class VarietyDoughnutSeries extends VarietySeries {
  /// Creates a doughnut series.
  const VarietyDoughnutSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.xAxisName,
    super.yAxisName,
    this.radiusFactor = 0.85,
    this.innerRadiusFactor = 0.55,
    this.startAngle = -90.0,
    this.endAngle = 270.0,
    this.direction = VarietySliceDirection.clockwise,
    this.explodeIndex = -1,
    this.explodeOffset = 12.0,
    this.groupSmallSlices = false,
    this.groupTo = 12.0,
    this.groupLabel = 'Others',
    this.strokeColor,
    this.strokeWidth = 1.5,
    this.equalSlices = false,
    this.cornerRadius = 0.0,
  });

  /// The share of the available radius used by the outer edge.
  final double radiusFactor;

  /// The share of the outer radius occupied by the hollow centre.
  final double innerRadiusFactor;

  /// The angle, in degrees, at which the first slice starts.
  final double startAngle;

  /// The angle, in degrees, at which the last slice ends.
  final double endAngle;

  /// The sweep direction.
  final VarietySliceDirection direction;

  /// The index of a slice to offset, or `-1` for none.
  final int explodeIndex;

  /// The distance the exploded slice is pushed outwards.
  final double explodeOffset;

  /// Whether slices below [groupTo] percent are folded into one slice.
  final bool groupSmallSlices;

  /// The threshold in percent below which a slice is grouped.
  final double groupTo;

  /// The caption of the grouped slice.
  final String groupLabel;

  /// The outline colour between slices.
  final Color? strokeColor;

  /// The thickness of the slice outline.
  final double strokeWidth;

  /// When `true` every slice spans the same angle.
  final bool equalSlices;

  /// The corner radius gripping each ring segment.
  final double cornerRadius;

  @override
  bool get isCircular => true;
}

/// A circular series that draws one concentric ring per value.
class VarietyRadialBarSeries extends VarietySeries {
  /// Creates a radial bar series.
  const VarietyRadialBarSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.xAxisName,
    super.yAxisName,
    this.maximum,
    this.gap = 0.35,
    this.startAngle = -90.0,
    this.endAngle = 270.0,
    this.trackColor,
    this.trackOpacity = 0.12,
    this.showTrack = true,
    this.cornerRadius = 0.0,
  });

  /// The value mapped to a full ring. Derived from the data when omitted.
  final double? maximum;

  /// The share of each ring slot left empty between rings.
  final double gap;

  /// The angle, in degrees, at which every ring starts.
  final double startAngle;

  /// The angle, in degrees, at which every ring ends.
  final double endAngle;

  /// The colour of the unfilled track.
  final Color? trackColor;

  /// The alpha applied to the track.
  final double trackOpacity;

  /// Whether the unfilled track is drawn.
  final bool showTrack;

  /// The corner radius applied to the ring ends.
  final double cornerRadius;

  @override
  bool get isCircular => true;
}

/// A series that narrows a set of values into a funnel.
class VarietyFunnelSeries extends VarietySeries {
  /// Creates a funnel series.
  const VarietyFunnelSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.xAxisName,
    super.yAxisName,
    this.gapRatio = 0.0,
    this.explodeOffset = 12.0,
    this.explodeIndexes = const <int>[],
    this.strokeColor,
    this.strokeWidth = 1.5,
    this.showNeck = true,
  });

  /// The vertical gap between two segments as a ratio of the segment height.
  final double gapRatio;

  /// The distance an exploded segment is pushed sideways.
  final double explodeOffset;

  /// The indexes of the segments that are exploded.
  final List<int> explodeIndexes;

  /// The outline colour between segments.
  final Color? strokeColor;

  /// The thickness of the segment outline.
  final double strokeWidth;

  /// Whether the narrow neck of the funnel is drawn.
  final bool showNeck;

  @override
  bool get isCircular => false;
}

/// A series that widens a set of values into an inverted funnel.
class VarietyPyramidSeries extends VarietySeries {
  /// Creates a pyramid series.
  const VarietyPyramidSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.xAxisName,
    super.yAxisName,
    this.gapRatio = 0.0,
    this.explodeOffset = 12.0,
    this.explodeIndexes = const <int>[],
    this.strokeColor,
    this.strokeWidth = 1.5,
    this.mode = VarietyPyramidMode.linear,
  });

  /// The vertical gap between two segments as a ratio of the segment height.
  final double gapRatio;

  /// The distance an exploded segment is pushed sideways.
  final double explodeOffset;

  /// The indexes of the segments that are exploded.
  final List<int> explodeIndexes;

  /// The outline colour between segments.
  final Color? strokeColor;

  /// The thickness of the segment outline.
  final double strokeWidth;

  /// How the segment widths are derived from the values.
  final VarietyPyramidMode mode;

  @override
  bool get isCircular => false;
}

/// How a funnel or pyramid derives its segment widths.
enum VarietyPyramidMode {
  /// Width is proportional to the value.
  linear,

  /// Width is proportional to the value's surface area.
  surface,
}

/// A series that fills the region under a smooth spline.
///
/// It is equivalent to a [VarietyAreaSeries] with
/// `lineStyle: VarietyLineStyle.curved`, but the spline interpolation can be
/// chosen independently through [splineType].
class VarietySplineAreaSeries extends VarietySeries {
  /// Creates a spline area series.
  const VarietySplineAreaSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.stackMode,
    super.trendlines,
    super.selectionColor,
    super.unselectedOpacity,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.splineType = VarietySplineType.cardinal,
    this.strokeWidth = 2.0,
    this.fillOpacity = 0.35,
    this.showMarkers = false,
    this.markerSize = 5.0,
  });

  /// The interpolation used between points.
  @override
  final VarietySplineType splineType;

  /// The stroke thickness of the outline.
  final double strokeWidth;

  /// The alpha applied to the filled region.
  final double fillOpacity;

  /// Whether a marker is drawn at every point.
  final bool showMarkers;

  /// The diameter of a marker in logical pixels.
  final double markerSize;
}

/// A series that fills a staircase built from the points.
///
/// Unlike [VarietyAreaSeries] with `VarietyLineStyle.stepped`, the change can be
/// anchored at the centre of each slot through [verticalStep].
class VarietyStepAreaSeries extends VarietySeries {
  /// Creates a step area series.
  const VarietyStepAreaSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.stackMode,
    super.trendlines,
    super.selectionColor,
    super.unselectedOpacity,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.strokeWidth = 2.0,
    this.fillOpacity = 0.35,
    this.verticalStep = false,
    this.showMarkers = false,
    this.markerSize = 5.0,
  });

  /// The stroke thickness of the outline.
  final double strokeWidth;

  /// The alpha applied to the filled region.
  final double fillOpacity;

  /// Whether the step changes at the middle of a slot instead of at the point.
  final bool verticalStep;

  /// Whether a marker is drawn at every point.
  final bool showMarkers;

  /// The diameter of a marker in logical pixels.
  final double markerSize;
}

/// A series that fills the band between two smooth splines.
class VarietySplineRangeAreaSeries extends VarietySeries {
  /// Creates a spline range area series.
  const VarietySplineRangeAreaSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.trendlines,
    super.selectionColor,
    super.unselectedOpacity,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.splineType = VarietySplineType.cardinal,
    this.strokeWidth = 1.6,
    this.fillOpacity = 0.3,
    this.showMarkers = false,
    this.markerSize = 5.0,
  });

  /// The interpolation used between points.
  @override
  final VarietySplineType splineType;

  /// The stroke thickness of the outline.
  final double strokeWidth;

  /// The alpha applied to the filled region.
  final double fillOpacity;

  /// Whether a marker is drawn at every bound.
  final bool showMarkers;

  /// The diameter of a marker in logical pixels.
  final double markerSize;

  @override
  bool get isRange => true;
}

/// A straight line series tuned for very large data sets.
///
/// The renderer skips anti-aliasing and can decimate the input so that plotting
/// tens of thousands of points stays responsive.
class VarietyFastLineSeries extends VarietySeries {
  /// Creates a fast line series.
  const VarietyFastLineSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.trendlines,
    super.selectionColor,
    super.unselectedOpacity,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.errorBar,
    super.xAxisName,
    super.yAxisName,
    this.strokeWidth = 1.4,
    this.dashPattern = const <double>[],
    this.enableAntiAlias = false,
    this.decimationFactor = 1,
  });

  /// The stroke thickness in logical pixels.
  final double strokeWidth;

  /// A dash pattern of alternating on/off lengths. Empty means solid.
  final List<double> dashPattern;

  /// Whether the stroke is anti-aliased. Disabling it is faster.
  final bool enableAntiAlias;

  /// When greater than one, only every n-th point is plotted.
  final int decimationFactor;
}

/// The direction an error bar extends in.
enum VarietyErrorBarMode {
  /// Whiskers extend up and down from each value.
  vertical,

  /// Whiskers extend left and right from each value.
  horizontal,

  /// Whiskers extend in both directions.
  both,
}

/// A series that draws an uncertainty whisker for every point.
///
/// The whisker is normally attached to another cartesian series through
/// [VarietySeries.errorBar], but it can also be declared on its own.
class VarietyErrorBarSeries extends VarietySeries {
  /// Creates an error bar series.
  const VarietyErrorBarSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.xAxisName,
    super.yAxisName,
    this.type = VarietyErrorBarType.fixed,
    this.errorValue = 1,
    this.mode = VarietyErrorBarMode.vertical,
    this.strokeWidth = 1.6,
    this.capLength = 8,
    this.showCap = true,
  });

  /// How the whisker length is derived.
  final VarietyErrorBarType type;

  /// The magnitude used by the fixed, percentage, deviation and error types.
  final double errorValue;

  /// The direction the whisker extends in.
  final VarietyErrorBarMode mode;

  /// The stroke thickness of the whisker.
  final double strokeWidth;

  /// The width of the caps at the end of a whisker.
  final double capLength;

  /// Whether caps are drawn at the whisker ends.
  final bool showCap;

  @override
  bool get isErrorBar => true;
}

/// A series that summarises a distribution as a box and its whiskers.
///
/// Points that share the same primary axis key are grouped into one box, so a
/// distribution is expressed by repeating the category label:
///
/// ```dart
/// VarietyBoxAndWhiskerSeries(
///   data: const <VarietyChartData>[
///     VarietyChartData('Q1', 12),
///     VarietyChartData('Q1', 15),
///     VarietyChartData('Q1', 19),
///     VarietyChartData('Q1', 44), // treated as an outlier
///   ],
/// )
/// ```
class VarietyBoxAndWhiskerSeries extends VarietySeries {
  /// Creates a box and whisker series.
  const VarietyBoxAndWhiskerSeries({
    required super.data,
    super.name,
    super.color,
    super.opacity,
    super.dataLabelSettings,
    super.dataLabelMapper,
    super.pointColorMapper,
    super.legendIconType,
    super.onCreateRenderer,
    super.onCreateShader,
    super.onRendererCreated,
    super.selectionBehavior,
    super.enableTooltip,
    super.animate,
    super.trendlines,
    super.selectionColor,
    super.unselectedOpacity,
    super.legendIconShape,
    super.animationDelay,
    super.markerSettings,
    super.gradient,
    super.borderGradient,
    super.enableTrackball,
    super.initialIsVisible,
    super.isVisibleInLegend,
    super.legendItemText,
    super.animationDuration,
    super.initialSelectedDataIndexes,
    super.onPointTap,
    super.onPointDoubleTap,
    super.onPointLongPress,
    super.emptyPointSettings,
    super.sortingOrder,
    super.sortFieldValueMapper,
    super.xAxisName,
    super.yAxisName,
    this.boxPlotMode = VarietyBoxPlotMode.exclusive,
    this.widthFactor = 0.5,
    this.cornerRadius = 0.0,
    this.strokeWidth = 1.5,
    this.showOutliers = true,
    this.outlierShape = VarietyMarkerShape.circle,
    this.outlierSize = 7,
    this.showMean = false,
    this.meanColor,
    this.medianColor,
    this.whiskerColor,
    this.showInnerPoints = false,
  });

  /// How the quartiles are computed.
  final VarietyBoxPlotMode boxPlotMode;

  /// The share of the available band occupied by one box.
  final double widthFactor;

  /// The corner radius applied to the box.
  final double cornerRadius;

  /// The stroke thickness of the box and whiskers.
  final double strokeWidth;

  /// Whether points outside the whisker range are marked.
  final bool showOutliers;

  /// The glyph used for an outlier.
  final VarietyMarkerShape outlierShape;

  /// The diameter of an outlier glyph.
  final double outlierSize;

  /// Whether the mean is marked inside the box.
  final bool showMean;

  /// The colour of the mean marker.
  final Color? meanColor;

  /// The colour of the median line.
  final Color? medianColor;

  /// The colour of the whiskers.
  final Color? whiskerColor;

  /// Whether the raw values are drawn on top of the box.
  final bool showInnerPoints;

  @override
  bool get isBanded => true;

  @override
  bool get isBoxPlot => true;
}

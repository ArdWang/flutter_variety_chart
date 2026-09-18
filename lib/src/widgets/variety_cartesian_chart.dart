import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../behaviors/variety_behaviors.dart';
import '../behaviors/variety_interaction_details.dart';
import '../models/variety_annotation.dart';
import '../models/variety_axis.dart';
import '../models/variety_chart_data.dart';
import '../models/variety_enums.dart';
import '../models/variety_legend_settings.dart';
import '../models/variety_options.dart';
import '../models/variety_series.dart';
import '../painters/variety_cartesian_painter.dart';
import '../render/variety_chart_theme.dart';
import '../render/variety_geometry.dart';
import '../utils/variety_label_utils.dart';
import 'variety_chart_title.dart';
import 'variety_legend.dart';
import 'variety_tooltip.dart';

/// A cartesian chart that renders line, area, column, bar, scatter, bubble,
/// candle, hi-lo, waterfall, histogram and stacked series.
///
/// The widget fills the box it is given, so place it inside a widget that
/// provides a bounded size such as [SizedBox], [Expanded] or [AspectRatio].
class VarietyCartesianChart extends StatefulWidget {
  /// Creates a cartesian chart from the supplied [series].
  const VarietyCartesianChart({
    super.key,
    required this.series,
    this.primaryXAxis = const VarietyAxis(type: VarietyAxisType.category),
    this.primaryYAxis = const VarietyAxis(type: VarietyAxisType.numeric),
    this.secondaryYAxes = const <VarietyAxis>[],
    this.secondaryXAxes = const <VarietyAxis>[],
    this.palette,
    this.title,
    this.titleStyle,
    this.showLegend = true,
    this.legendPosition = VarietyLegendPosition.bottom,
    this.legendTextStyle,
    this.legendBuilder,
    this.tooltipBehavior = const VarietyTooltipBehavior(),
    this.trackballBehavior,
    this.crosshairBehavior,
    this.zoomPanBehavior,
    this.selectionBehavior,
    this.annotations = const <VarietyAnnotation>[],
    this.animationDuration = const Duration(milliseconds: 800),
    this.enableAnimation = true,
    this.backgroundColor,
    this.plotAreaBackgroundColor,
    this.plotAreaBorderColor,
    this.plotAreaBorderWidth = 0,
    this.borderColor,
    this.borderWidth = 0,
    this.padding = const EdgeInsets.fromLTRB(12, 14, 18, 10),
    this.onPointTap,
    this.onPointHover,
    this.legendSettings = const VarietyLegendSettings(),
    this.onLegendTapped,
    this.selectionController,
    this.onTooltipRender,
    this.onDataLabelRender,
    this.onAxisLabelTapped,
    this.onActualRangeChanged,
    this.renderingMode = VarietyRenderingMode.onLoading,
    this.loadingBuilder,
    this.onChartTouchInteractionDown,
    this.onChartTouchInteractionMove,
    this.onChartTouchInteractionUp,
    this.onPlotAreaSwipe,
    this.loadMoreIndicatorBuilder,
  });

  /// The series plotted by the chart.
  final List<VarietySeries> series;

  /// The horizontal axis configuration.
  final VarietyAxis primaryXAxis;

  /// The vertical axis configuration.
  final VarietyAxis primaryYAxis;

  /// Additional secondary axes rendered to the right of the plot area.
  ///
  /// Give an axis a [VarietyAxis.name] and point a series at it through
  /// `yAxisName` to plot that series against its own scale.
  final List<VarietyAxis> secondaryYAxes;

  /// Additional horizontal axes rendered below the plot area.
  ///
  /// Give an axis a [VarietyAxis.name] and point a series at it through
  /// `xAxisName` to plot that series against its own horizontal scale. Each
  /// extra axis resolves its own range from its own series, prints its own
  /// ticks in its own row, and gives its columns their own slot width, so two
  /// series measured in different units can share one plot area without one of
  /// them being squeezed into the other's scale.
  ///
  /// Grid lines and plot bands stay with [primaryXAxis], and so does the zoom
  /// window: pinching zooms the primary axis only, because a window expressed
  /// in its units is meaningless on another scale.
  final List<VarietyAxis> secondaryXAxes;

  /// A colour cycle for this chart, overriding the one on the theme.
  ///
  /// A series that does not declare its own colour takes the next entry, so
  /// giving one chart its own palette leaves every other chart alone.
  final List<Color>? palette;

  /// An optional caption rendered above the chart.
  final String? title;

  /// An optional override for the title text style.
  final TextStyle? titleStyle;

  /// Whether the legend is rendered.
  final bool showLegend;

  /// Where the legend is placed.
  final VarietyLegendPosition legendPosition;

  /// An optional override for the legend text style.
  final TextStyle? legendTextStyle;

  /// Builds custom legend items.
  final Widget Function(BuildContext context, VarietySeries series, int index)?
      legendBuilder;

  /// The single-point tooltip configuration.
  final VarietyTooltipBehavior tooltipBehavior;

  /// The trackball configuration. Disabled when `null`.
  final VarietyTrackballBehavior? trackballBehavior;

  /// The crosshair configuration. Disabled when `null`.
  final VarietyCrosshairBehavior? crosshairBehavior;

  /// The zoom and pan configuration. Disabled when `null`.
  final VarietyZoomPanBehavior? zoomPanBehavior;

  /// The selection configuration. Disabled when `null`.
  final VarietySelectionBehavior? selectionBehavior;

  /// Decorations drawn on top of the series.
  final List<VarietyAnnotation> annotations;

  /// How long the entrance animation runs.
  final Duration animationDuration;

  /// Whether the entrance animation is played.
  final bool enableAnimation;

  /// An optional background colour painted behind the plot area.
  final Color? backgroundColor;

  /// A fill painted behind the plot area only, leaving the axis margins on
  /// [backgroundColor].
  final Color? plotAreaBackgroundColor;

  /// The colour of the box drawn around the plot area.
  final Color? plotAreaBorderColor;

  /// The thickness of the box drawn around the plot area. Zero skips it.
  final double plotAreaBorderWidth;

  /// The colour of the box drawn around the whole chart.
  final Color? borderColor;

  /// The thickness of the box drawn around the whole chart. Zero skips it.
  final double borderWidth;

  /// Padding reserved inside the plot area for axis captions.
  final EdgeInsets padding;

  /// Called when a data point is tapped. Receives `null` when the tap misses.
  final ValueChanged<VarietyHitResult?>? onPointTap;

  /// Called when the pointer moves onto or off a data point.
  final ValueChanged<VarietyHitResult?>? onPointHover;

  /// Presentation options for the legend.
  final VarietyLegendSettings legendSettings;

  /// Called when a legend item is tapped.
  final void Function(VarietyLegendTapDetails details)? onLegendTapped;

  /// Lets an application drive and observe the selection programmatically.
  final VarietySelectionController? selectionController;

  /// Lets an application rewrite, or suppress, a tooltip before it is shown.
  ///
  /// Returning `false` cancels the tooltip for that point.
  final bool Function(VarietyTooltipDetails details)? onTooltipRender;

  /// Lets an application rewrite, or suppress, a data label before it is drawn.
  ///
  /// Return `null` to keep the default caption, or an empty string to drop it.
  final String? Function(VarietyDataLabelRenderDetails details)?
      onDataLabelRender;

  /// Called when a tick label is tapped.
  final void Function(VarietyAxisLabelTapDetails details)? onAxisLabelTapped;

  /// Called whenever the visible range of either axis changes.
  final void Function(VarietyRangeChangedDetails details)? onActualRangeChanged;

  /// Controls when the series are painted.
  final VarietyRenderingMode renderingMode;

  /// Builds the placeholder shown while [renderingMode] is
  /// [VarietyRenderingMode.onDemand] and the user has not interacted yet.
  final WidgetBuilder? loadingBuilder;

  /// Called when a pointer goes down anywhere on the chart.
  ///
  /// Unlike [onPointTap] this fires for every touch, series or not, which is
  /// what driving an outside control from a drag over the plot needs.
  final void Function(VarietyChartTouchArgs args)? onChartTouchInteractionDown;

  /// Called as a pointer moves anywhere on the chart.
  final void Function(VarietyChartTouchArgs args)? onChartTouchInteractionMove;

  /// Called when a pointer is lifted anywhere on the chart.
  final void Function(VarietyChartTouchArgs args)? onChartTouchInteractionUp;

  /// Called when a pan runs out of data at one end of the primary axis.
  ///
  /// This is the hook an infinite scroll needs: report the direction, fetch
  /// the next page, and rebuild with more points. It fires once per arrival at
  /// an end rather than on every frame of the drag.
  final void Function(VarietySwipeDirection direction)? onPlotAreaSwipe;

  /// A widget shown over the bottom of the plot while the reader is sitting at
  /// an end of the axis.
  ///
  /// Typical use is a "loading more" spinner that the app shows after
  /// [onPlotAreaSwipe] asked for another page.
  final WidgetBuilder? loadMoreIndicatorBuilder;

  @override
  State<VarietyCartesianChart> createState() => VarietyCartesianChartState();
}

/// The state of a [VarietyCartesianChart], which also exposes [toImage].
class VarietyCartesianChartState extends State<VarietyCartesianChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Duration _effectiveAnimationDuration() {
    Duration longest = widget.animationDuration;
    for (final VarietySeries s in widget.series) {
      final Duration? override = s.animationDuration;
      if (override != null && override > longest) {
        longest = override;
      }
    }
    return longest;
  }

  /// The whole entrance timeline, delays included.
  ///
  /// A series held back by `animationDelay` starts that much later, so the
  /// controller has to run for the delay *plus* the longest rise or the last
  /// series would never finish drawing.
  Duration _timelineDuration() {
    Duration delay = Duration.zero;
    for (final VarietySeries item in widget.series) {
      if (item.animationDelay > delay) {
        delay = item.animationDelay;
      }
    }
    return _effectiveAnimationDuration() + delay;
  }

  /// The entrance progress of each series, staggered by `animationDelay`.
  ///
  /// A delayed series owns the tail of the same timeline: with a delay worth
  /// half the total it is only half risen when the chart finishes, which is
  /// what makes a set of series read as a sequence instead of one block.
  List<double> get _seriesProgress {
    final double global = _progress;
    final Duration total = _timelineDuration();
    final List<double> out = <double>[];
    for (int i = 0; i < _items.length; i++) {
      final Duration delay = _items[i].animationDelay;
      if (delay <= Duration.zero || total <= Duration.zero) {
        out.add(global);
        continue;
      }
      final double start =
          (delay.inMicroseconds / total.inMicroseconds).clamp(0.0, 1.0);
      if (start >= 1) {
        out.add(global >= 1 ? 1 : 0);
        continue;
      }
      out.add(((global - start) / (1 - start)).clamp(0.0, 1.0));
    }
    return out;
  }

  VarietyHitResult? _hit;
  List<VarietyHitResult> _trackballHits = const <VarietyHitResult>[];
  // Auto-hides the trackball [VarietyTrackballBehavior.hideDelay] after a tap
  // activation. Restarted on every activation, cancelled on clear/dispose.
  Timer? _trackballHideTimer;
  // Holds a tooltip back for `VarietyTooltipBehavior.showDuration`, so a
  // pointer crossing the plot does not flash a card at every point it passes.
  Timer? _tooltipDelayTimer;
  double? _trackballSlot;
  List<VarietyHitResult> _selected = const <VarietyHitResult>[];
  final Set<int> _hiddenSeries = <int>{};
  final List<VarietyAxisLabelHit> _labelHits = <VarietyAxisLabelHit>[];
  bool _revealed = false;
  bool _initialSelectionSeeded = false;
  // The end of the axis the last pan ran out at, and whether that has already
  // been reported, so a drag does not fire the callback over and over.
  VarietySwipeDirection? _swipeDirection;
  VarietySwipeDirection? _reportedSwipe;
  // The last pointer position seen, so `VarietyTooltipPosition.pointer` has
  // something to follow.
  Offset? _pointerPosition;
  (double, double)? _lastPrimaryRange;
  (double, double)? _lastSecondaryRange;

  // Zoom state, held as a per-axis window: every axis keeps a
  // normalised window made of a `factor` (the visible fraction of the full
  // range, 1 meaning fully zoomed out) and a `position` (where that window
  // starts, as a fraction of the full range). Gestures only ever touch those
  // two numbers, so the focal point of a pinch stays pinned while it applies.
  double _xZoomFactor = 1;
  double _xZoomPosition = 0;
  double _yZoomFactor = 1;
  double _yZoomPosition = 0;

  // The x window auto scrolling seeded, while it is in force. Comparing the
  // normalised state against it is how the chart tells an untouched auto scroll
  // window from one the reader has pinched, panned or zoomed by hand.
  double? _autoScrolledFactor;
  double? _autoScrolledPosition;

  // The full, un-zoomed range of each axis. Zoom gestures are always measured
  // against this, never against the current window, otherwise zooming back out
  // would be clamped to the window the gesture started from.
  double _baseXMin = 0;
  double _baseXMax = 1;
  double _baseYMin = 0;
  double _baseYMax = 1;

  // The data-space windows projected from the normalised state during build.
  (double, double)? _zoomX;
  (double, double)? _zoomY;
  VarietyCartesianGeometry? _display;

  // Magnification captured for each axis when the current pinch began, the
  // counterpart of the magnification captured when the pinch began.
  double? _startScaleX;
  double? _startScaleY;
  int _scalePointerCount = 0;
  Offset _previousPanPosition = Offset.zero;
  bool _panStarted = false;
  bool _gestureChanged = false;
  Offset? _selectionStart;
  Rect? _selectionRect;

  /// Whether the x window is still the one auto scrolling put there.
  bool get _autoScrollingInForce =>
      _autoScrolledFactor != null &&
      _xZoomFactor == _autoScrolledFactor &&
      _xZoomPosition == _autoScrolledPosition;

  /// Whether either axis currently shows a window the reader asked for.
  ///
  /// The auto scrolling window does not count: it is where the chart starts,
  /// not a zoom, and treating it as one would flip a double tap from zooming
  /// in to resetting on a chart nobody has touched.
  bool get _hasZoom =>
      _yZoomFactor < 1 || (_xZoomFactor < 1 && !_autoScrollingInForce);

  List<VarietySeries> get _items {
    final List<VarietySeries> all = widget.series
        .where((VarietySeries item) => !item.isCircular)
        .toList(growable: false);
    if (_hiddenSeries.isEmpty) {
      return all;
    }
    return <VarietySeries>[
      for (int i = 0; i < all.length; i++)
        if (!_hiddenSeries.contains(i)) all[i],
    ];
  }

  /// Whether the series should be painted for the current rendering mode.
  bool get _paintsSeries =>
      widget.renderingMode == VarietyRenderingMode.onLoading || _revealed;

  bool get _zooming =>
      widget.zoomPanBehavior != null &&
      widget.zoomPanBehavior!.enabled &&
      widget.zoomPanBehavior!.mode != VarietyZoomMode.none;

  /// Whether a long press may drag out a zoom region. The gesture model uses
  /// selection zooming from a long press and pans from a plain drag, which is
  /// what lets pinch, pan and selection all stay live at the same time.
  bool get _selectionZoomEnabled =>
      _zooming &&
      (widget.zoomPanBehavior!.mode == VarietyZoomMode.selection ||
          widget.zoomPanBehavior!.mode == VarietyZoomMode.both);

  @override
  void initState() {
    super.initState();
    widget.selectionController?.addListener(_syncSelectionFromController);
    _selected =
        widget.selectionController?.selected ?? const <VarietyHitResult>[];
    _applyInitialZoom();
    _controller =
        AnimationController(vsync: this, duration: _timelineDuration());
    if (widget.enableAnimation && _shouldAnimate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  bool get _shouldAnimate =>
      _items.any((VarietySeries item) => item.animate && item.data.isNotEmpty);

  /// Seeds the zoom state an axis declares through `initialZoomFactor` and
  /// `initialZoomPosition`.
  ///
  /// This runs once, so a reader who has pinched, panned or double tapped is
  /// never overruled by the declared window on a later rebuild.
  void _applyInitialZoom() {
    final double factor = widget.primaryXAxis.initialZoomFactor;
    if (factor < 1) {
      _xZoomFactor = factor.clamp(0.001, 1.0);
      _xZoomPosition = widget.primaryXAxis.initialZoomPosition
          .clamp(0.0, 1.0 - _xZoomFactor);
    }
    final double yFactor = widget.primaryYAxis.initialZoomFactor;
    if (yFactor < 1) {
      _yZoomFactor = yFactor.clamp(0.001, 1.0);
      _yZoomPosition = widget.primaryYAxis.initialZoomPosition
          .clamp(0.0, 1.0 - _yZoomFactor);
    }
  }

  @override
  void didUpdateWidget(covariant VarietyCartesianChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series != widget.series ||
        oldWidget.animationDuration != widget.animationDuration ||
        oldWidget.series.length != widget.series.length) {
      _hit = null;
      _trackballHits = const <VarietyHitResult>[];
      _trackballSlot = null;
      if (widget.enableAnimation && _shouldAnimate) {
        _controller
          ..reset()
          ..forward();
      } else {
        _controller.value = 1;
      }
    }
  }

  @override
  void dispose() {
    widget.selectionController?.removeListener(_syncSelectionFromController);
    _trackballHideTimer?.cancel();
    _tooltipDelayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _syncSelectionFromController() {
    final List<VarietyHitResult> next =
        widget.selectionController?.selected ?? const <VarietyHitResult>[];
    if (next == _selected) {
      return;
    }
    setState(() => _selected = next);
  }

  VarietySelectionBehavior? _seriesSelection(int seriesIndex) {
    if (seriesIndex < 0 || seriesIndex >= widget.series.length) {
      return widget.selectionBehavior;
    }
    return widget.series[seriesIndex].selectionBehavior ??
        widget.selectionBehavior;
  }

  void _reveal() {
    if (_revealed || widget.renderingMode == VarietyRenderingMode.onLoading) {
      return;
    }
    setState(() => _revealed = true);
  }

  /// Rewrites or suppresses a data label caption.
  String? _resolveDataLabel(
    VarietySeries series,
    int seriesIndex,
    VarietyChartData point,
    int pointIndex,
    String caption,
  ) {
    final String? Function(VarietyDataLabelRenderDetails)? callback =
        widget.onDataLabelRender;
    if (callback == null) {
      return null;
    }
    final VarietyDataLabelRenderDetails details = VarietyDataLabelRenderDetails(
      series: series,
      seriesIndex: seriesIndex,
      point: point,
      pointIndex: pointIndex,
      text: caption,
    );
    return callback(details);
  }

  /// Notifies the host when the visible range settles on a new value.
  void _reportRangeChanges(
    VarietyCartesianGeometry base,
    VarietyCartesianGeometry display,
  ) {
    final void Function(VarietyRangeChangedDetails)? callback =
        widget.onActualRangeChanged;
    final (double, double) primary = (display.xMinimum, display.xMaximum);
    final (double, double) secondary = (display.yMinimum, display.yMaximum);
    final (double, double)? previousPrimary = _lastPrimaryRange;
    final (double, double)? previousSecondary = _lastSecondaryRange;
    _lastPrimaryRange = primary;
    _lastSecondaryRange = secondary;
    if (callback == null) {
      return;
    }
    if (previousPrimary != null && previousPrimary != primary) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        callback(
          VarietyRangeChangedDetails(
            axis: widget.primaryXAxis,
            minimum: primary.$1,
            maximum: primary.$2,
            oldMinimum: previousPrimary.$1,
            oldMaximum: previousPrimary.$2,
          ),
        );
      });
    }
    if (previousSecondary != null && previousSecondary != secondary) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        callback(
          VarietyRangeChangedDetails(
            axis: widget.primaryYAxis,
            minimum: secondary.$1,
            maximum: secondary.$2,
            oldMinimum: previousSecondary.$1,
            oldMaximum: previousSecondary.$2,
          ),
        );
      });
    }
  }

  void _handleLegendTap(VarietySeries series, int index) {
    // Tapping toggles, so a currently hidden series becomes visible.
    final bool willBeVisible = _hiddenSeries.contains(index);
    if (widget.legendSettings.toggleSeriesVisibility) {
      setState(() {
        if (willBeVisible) {
          _hiddenSeries.add(index);
        } else {
          _hiddenSeries.remove(index);
        }
      });
    }
    widget.onLegendTapped?.call(
      VarietyLegendTapDetails(
        series: series,
        seriesIndex: index,
        isVisible: willBeVisible,
      ),
    );
  }

  void _applySelection(List<VarietyHitResult> next) {
    setState(() => _selected = next);
    if (widget.selectionController != null &&
        widget.selectionController!.selected != next) {
      widget.selectionController!.select(next);
    }
  }

  double get _progress => widget.enableAnimation ? _controller.value : 1.0;

  @override
  Widget build(BuildContext context) {
    // The chart owns a repaint boundary so [toImage] captures the chart and
    // nothing that happens to sit behind it.
    return RepaintBoundary(child: _buildContent(context));
  }

  /// Renders the chart to an image, exactly as it looks right now.
  ///
  /// Give the chart a [GlobalKey] typed to this state to reach it:
  ///
  /// ```dart
  /// final GlobalKey<VarietyCartesianChartState> key =
  ///     GlobalKey<VarietyCartesianChartState>();
  /// // ...
  /// final ui.Image image = await key.currentState!.toImage(pixelRatio: 3);
  /// ```
  Future<ui.Image> toImage({double pixelRatio = 1.0}) {
    final RenderObject? object = context.findRenderObject();
    if (object is! RenderRepaintBoundary) {
      throw StateError(
        'The chart has not been laid out yet, so there is nothing to export.',
      );
    }
    return object.toImage(pixelRatio: pixelRatio);
  }

  Widget _buildContent(BuildContext context) {
    final VarietyChartTheme theme = VarietyChartTheme.of(context);
    final List<VarietySeries> items = _items;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool bounded =
            constraints.hasBoundedHeight && constraints.hasBoundedWidth;
        final List<Widget> column = <Widget>[];
        if (widget.title != null && widget.title!.isNotEmpty) {
          column.add(VarietyChartTitle(
              text: widget.title!, textStyle: widget.titleStyle));
        }
        final bool wantsLegend =
            widget.showLegend && items.any((VarietySeries s) => s.name != null);
        // `auto` is resolved against the box the chart was given, so a wide
        // chart puts the legend beside the plot and a tall one underneath.
        final VarietyLegendPosition legendPosition =
            VarietyLegend.resolvePosition(
          widget.legendPosition,
          Size(constraints.maxWidth, constraints.maxHeight),
        );
        final bool legendOnSide =
            legendPosition == VarietyLegendPosition.left ||
                legendPosition == VarietyLegendPosition.right;
        final Widget? legend = wantsLegend
            ? VarietyLegend(
                series: widget.series
                    .where((VarietySeries item) => !item.isCircular)
                    .toList(growable: false),
                position: legendPosition,
                textStyle: widget.legendTextStyle,
                itemBuilder: widget.legendBuilder,
                settings: widget.legendSettings,
                hiddenIndexes: _hiddenSeries,
                onItemTap: _handleLegendTap,
              )
            : null;
        if (legend != null && legendPosition == VarietyLegendPosition.top) {
          column.add(legend);
        }
        final Widget plot = AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) => _buildPlot(theme),
        );
        if (legend != null && legendOnSide) {
          column.add(
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (legendPosition == VarietyLegendPosition.left) legend,
                  Expanded(child: plot),
                  if (legendPosition == VarietyLegendPosition.right) legend,
                ],
              ),
            ),
          );
        } else {
          column.add(Expanded(child: plot));
        }
        if (legend != null && legendPosition == VarietyLegendPosition.bottom) {
          column.add(legend);
        }
        final Widget body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: column,
        );
        if (bounded) {
          return body;
        }
        return SizedBox(height: 320, width: double.infinity, child: body);
      },
    );
  }

  /// Applies the selection a series declares through
  /// `initialSelectedDataIndexes`.
  ///
  /// It runs once, on the first layout that has positions to aim at, and only
  /// when nothing else already owns the selection.
  void _seedInitialSelection(VarietyCartesianGeometry geometry) {
    if (_initialSelectionSeeded) {
      return;
    }
    _initialSelectionSeeded = true;
    if (widget.selectionController != null || _selected.isNotEmpty) {
      return;
    }
    final List<VarietyHitResult> seeded = <VarietyHitResult>[];
    for (int s = 0; s < geometry.series.length; s++) {
      final VarietySeries item = geometry.series[s];
      if (item.initialSelectedDataIndexes.isEmpty) {
        continue;
      }
      final List<Offset> positions = geometry.pointPositions[s];
      for (final int p in item.initialSelectedDataIndexes) {
        if (p < 0 || p >= positions.length) {
          continue;
        }
        seeded.add(
          VarietyHitResult(
            series: item,
            seriesIndex: s,
            point: geometry.sourceData[s][p],
            pointIndex: p,
            position: positions[p],
          ),
        );
      }
    }
    if (seeded.isEmpty) {
      return;
    }
    _selected = seeded;
    final void Function(List<VarietyHitResult> selected)? report =
        widget.selectionBehavior?.onSelectionChanged;
    if (report != null) {
      // Reporting during a build would rebuild in the middle of one, so the
      // callback is deferred to the end of the frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => report(seeded));
    }
  }

  Widget _buildPlot(VarietyChartTheme theme) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        final (_, VarietyCartesianGeometry display) = _geometries(size);
        _display = display;
        _seedInitialSelection(display);
        final Widget canvas = CustomPaint(
          size: size,
          painter: VarietyCartesianPainter(
            geometry: display,
            theme: theme,
            trackball: widget.trackballBehavior,
            crosshair: widget.crosshairBehavior,
            annotations: widget.annotations,
            highlights: _activeHighlights,
            trackballSlot: _trackballSlot,
            selectionRect: _selectionRect,
            labelHits: _labelHits,
            showElements: _paintsSeries,
            selected: _selected,
            selection: widget.selectionBehavior,
            plotAreaBackgroundColor:
                widget.plotAreaBackgroundColor ?? theme.plotAreaBackgroundColor,
            plotAreaBorderColor:
                widget.plotAreaBorderColor ?? theme.plotAreaBorderColor,
            plotAreaBorderWidth: widget.plotAreaBorderWidth,
            borderColor: widget.borderColor,
            borderWidth: widget.borderWidth,
            selectionRectColor: widget.zoomPanBehavior?.selectionRectColor,
            selectionRectBorderColor:
                widget.zoomPanBehavior?.selectionRectBorderColor,
            axisTooltip: _activeAxisTooltip,
          ),
        );
        // Gesture recognisers are only attached when the behaviour that needs them
        // is enabled. Registering the double tap recogniser unconditionally would
        // delay every single tap by the double tap timeout.
        final VarietyZoomPanBehavior? zoom = widget.zoomPanBehavior;
        final bool zoomEnabled =
            zoom != null && zoom.enabled && zoom.mode != VarietyZoomMode.none;
        final bool doubleTapOverlay =
            (widget.trackballBehavior?.enabled ?? false) &&
                    widget.trackballBehavior!.activationMode ==
                        VarietyActivationMode.doubleTap ||
                (widget.crosshairBehavior?.enabled ?? false) &&
                    widget.crosshairBehavior!.activationMode ==
                        VarietyActivationMode.doubleTap;
        final bool doubleTapEnabled =
            doubleTapOverlay || (zoomEnabled && zoom.enableDoubleTapZooming);
        return Listener(
          onPointerSignal: _onPointerSignal,
          onPointerDown: widget.onChartTouchInteractionDown == null
              ? null
              : (PointerDownEvent event) => widget.onChartTouchInteractionDown!(
                    VarietyChartTouchArgs(position: event.localPosition),
                  ),
          onPointerMove: widget.onChartTouchInteractionMove == null
              ? null
              : (PointerMoveEvent event) => widget.onChartTouchInteractionMove!(
                    VarietyChartTouchArgs(position: event.localPosition),
                  ),
          onPointerUp: widget.onChartTouchInteractionUp == null
              ? null
              : (PointerUpEvent event) => widget.onChartTouchInteractionUp!(
                    VarietyChartTouchArgs(position: event.localPosition),
                  ),
          child: MouseRegion(
            onHover: _onHover,
            onExit: (_) => _clearPointerState(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (TapUpDetails details) =>
                  _onTap(details.localPosition, display),
              onLongPressStart: (LongPressStartDetails details) =>
                  _onLongPressStart(details.localPosition, display),
              onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) =>
                  _onLongPressMove(details.localPosition, display),
              onLongPressEnd: (_) => _onLongPressEnd(),
              onDoubleTapDown: doubleTapEnabled
                  ? (TapDownDetails details) =>
                      _onDoubleTap(details.localPosition, display)
                  : null,
              onScaleStart: zoomEnabled
                  ? (ScaleStartDetails details) => _onScaleStart(details)
                  : null,
              onScaleUpdate: zoomEnabled
                  ? (ScaleUpdateDetails details) => _onScaleUpdate(details)
                  : null,
              onScaleEnd: zoomEnabled ? (_) => _onScaleEnd() : null,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(child: canvas),
                  if (widget.loadMoreIndicatorBuilder != null &&
                      _swipeDirection != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Center(
                          child: widget.loadMoreIndicatorBuilder!(context),
                        ),
                      ),
                    ),
                  // The placeholder must not swallow the gestures that reveal
                  // the series, so it is wrapped in an IgnorePointer.
                  if (!_paintsSeries && widget.loadingBuilder != null)
                    Positioned.fill(
                      child:
                          IgnorePointer(child: widget.loadingBuilder!(context)),
                    ),
                  ..._overlayWidgets(theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// The axis value box settings of whichever guide is currently up.
  VarietyAxisTooltipSettings? get _activeAxisTooltip {
    if (_trackballHits.isNotEmpty) {
      return widget.trackballBehavior?.axisTooltip;
    }
    final VarietyCrosshairBehavior? cross = widget.crosshairBehavior;
    if (cross != null && cross.enabled && !cross.showTooltip) {
      return cross.axisTooltip;
    }
    return cross?.axisTooltip;
  }

  List<VarietyHitResult> get _activeHighlights {
    if (_trackballHits.isNotEmpty) {
      return _trackballHits;
    }
    if (_selected.isNotEmpty) {
      return _selected;
    }
    final VarietyHitResult? hit = _hit;
    return hit == null ? const <VarietyHitResult>[] : <VarietyHitResult>[hit];
  }

  // ---------------------------------------------------------------------------
  // Geometry
  // ---------------------------------------------------------------------------

  (VarietyCartesianGeometry, VarietyCartesianGeometry) _geometries(Size size) {
    final Size safe = Size(math.max(size.width, 1), math.max(size.height, 1));
    final VarietyCartesianGeometry probe = VarietyCartesianGeometry(
      series: _items,
      xAxis: widget.primaryXAxis,
      yAxis: widget.primaryYAxis,
      plotRect: Offset.zero & safe,
      progress: _progress,
      secondaryYAxes: widget.secondaryYAxes,
      secondaryXAxes: widget.secondaryXAxes,
      palette: widget.palette ?? VarietyChartTheme.of(context).palette,
    );
    final EdgeInsets insets = _insetsFor(probe);
    Rect plotRect = Rect.fromLTRB(
      insets.left,
      insets.top,
      safe.width - insets.right,
      safe.height - insets.bottom,
    );
    if (plotRect.width <= 8 || plotRect.height <= 8) {
      plotRect = Rect.fromLTWH(
          0, 0, math.max(safe.width, 1), math.max(safe.height, 1));
    }
    final VarietyCartesianGeometry base = VarietyCartesianGeometry(
      series: _items,
      xAxis: widget.primaryXAxis,
      yAxis: widget.primaryYAxis,
      plotRect: plotRect,
      progress: _progress,
      dataLabelResolver: _resolveDataLabel,
      secondaryYAxes: widget.secondaryYAxes,
      secondaryXAxes: widget.secondaryXAxes,
      palette: widget.palette ?? VarietyChartTheme.of(context).palette,
    );
    _baseXMin = base.xMinimum;
    _baseXMax = base.xMaximum;
    _applyAutoScrolling();
    _zoomX = _windowFor(_baseXMin, _baseXMax, _xZoomPosition, _xZoomFactor);
    // Each value axis reads its own `anchorRangeToVisiblePoints`, so the window
    // only has to be handed over for the axis to fit itself to it.
    final VarietyCartesianGeometry yRange = _yRangeBase(base, plotRect);
    _baseYMin = yRange.yMinimum;
    _baseYMax = yRange.yMaximum;
    _zoomY = _windowFor(_baseYMin, _baseYMax, _yZoomPosition, _yZoomFactor);
    final VarietyCartesianGeometry display = VarietyCartesianGeometry(
      series: _items,
      xAxis: widget.primaryXAxis,
      yAxis: widget.primaryYAxis,
      plotRect: plotRect,
      progress: _progress,
      seriesProgress: _seriesProgress,
      visibleXRange: _zoomX,
      visibleYRange: _zoomY,
      dataLabelResolver: _resolveDataLabel,
      secondaryYAxes: widget.secondaryYAxes,
      secondaryXAxes: widget.secondaryXAxes,
      palette: widget.palette ?? VarietyChartTheme.of(context).palette,
    );
    _reportRangeChanges(base, display);
    return (base, display);
  }

  /// Seeds the x window with the span `autoScrollingDelta` keeps visible.
  ///
  /// The delta is a span in axis units, which on a category axis means the
  /// number of points: a delta of 20 keeps the last twenty categories in view,
  /// and `VarietyAutoScrollingMode.start` keeps the first twenty instead.
  ///
  /// It is seeded into the zoom state rather than clamped into the range,
  /// because the points outside the window still have to be reachable by
  /// panning. Doing it that way also means a fresh window is seeded whenever a
  /// point is appended, so the chart keeps showing the newest data.
  ///
  /// A window the reader has moved by hand is left alone, so setting the delta
  /// and then pinching into the data does not fight the gesture.
  void _applyAutoScrolling() {
    final double? delta = widget.primaryXAxis.autoScrollingDelta;
    if (delta == null || delta <= 0) {
      return;
    }
    final double span = _baseXMax - _baseXMin;
    // Fewer points than the delta shows all of them, which is what the plain
    // full range already does.
    if (span <= 0 || delta >= span) {
      return;
    }
    final bool untouched =
        (_xZoomFactor >= 1 && _xZoomPosition == 0) || _autoScrollingInForce;
    if (!untouched) {
      return;
    }
    final bool fromStart =
        widget.primaryXAxis.autoScrollingMode == VarietyAutoScrollingMode.start;
    final double factor = delta / span;
    _xZoomFactor = factor;
    _xZoomPosition = fromStart ? 0 : 1 - factor;
    _autoScrolledFactor = _xZoomFactor;
    _autoScrolledPosition = _xZoomPosition;
  }

  /// The geometry the value axes take their range from.
  ///
  /// Normally that is the full-range [base]. While the x window is narrower
  /// than the data, an axis whose [VarietyAxis.anchorRangeToVisiblePoints] is
  /// set fits itself to the points inside the window instead, which is what
  /// makes a value axis rescale as the reader pans along a long series.
  VarietyCartesianGeometry _yRangeBase(
    VarietyCartesianGeometry base,
    Rect plotRect,
  ) {
    final (double, double)? window = _zoomX;
    if (window == null || (window.$1 <= _baseXMin && window.$2 >= _baseXMax)) {
      return base;
    }
    final bool anchored = widget.primaryYAxis.anchorRangeToVisiblePoints ||
        widget.secondaryYAxes.any(
          (VarietyAxis axis) => axis.anchorRangeToVisiblePoints,
        );
    if (!anchored) {
      return base;
    }
    return VarietyCartesianGeometry(
      series: _items,
      xAxis: widget.primaryXAxis,
      yAxis: widget.primaryYAxis,
      plotRect: plotRect,
      progress: _progress,
      visibleXRange: window,
      dataLabelResolver: _resolveDataLabel,
      secondaryYAxes: widget.secondaryYAxes,
      secondaryXAxes: widget.secondaryXAxes,
      palette: VarietyChartTheme.of(context).palette,
    );
  }

  EdgeInsets _insetsFor(VarietyCartesianGeometry probe) {
    final TextStyle yStyle = _tickLabelStyle(probe.yAxis);
    double left = 10;
    for (final double tick in probe.yTicks) {
      final String caption = probe.secondaryTickLabel(tick);
      left = math.max(left, _textSize(caption, yStyle).width + 12);
    }
    if ((probe.yAxis.title ?? '').isNotEmpty) {
      left += 18;
    }
    final TextStyle xStyle = _tickLabelStyle(probe.xAxis);
    double bottom = 10;
    final double rotation = probe.xAxis.labelRotation * math.pi / 180;
    if (probe.xAxisType == VarietyAxisType.category ||
        probe.xAxisType == VarietyAxisType.dateTimeCategory) {
      for (final String caption in probe.categories) {
        bottom =
            math.max(bottom, _rotatedHeight(caption, xStyle, rotation) + 8);
      }
    } else if (probe.xAxisType == VarietyAxisType.dateTime) {
      for (final DateTime tick in probe.dateTimeTicks) {
        bottom = math.max(
          bottom,
          _rotatedHeight(probe.dateTimeTickLabel(tick), xStyle, rotation) + 8,
        );
      }
    } else {
      // Measure the captions that will actually be drawn: the tick values come
      // from the geometry so this agrees with the painted grid lines and labels.
      for (final double value in probe.xNumericTicks) {
        final String caption = probe.xAxis.labelFormatter?.call(value) ??
            varietyFormatNumber(value);
        bottom =
            math.max(bottom, _rotatedHeight(caption, xStyle, rotation) + 8);
      }
    }
    if ((probe.xAxis.title ?? '').isNotEmpty) {
      bottom += 22;
    }
    final VarietyMultiLevelLabels? groups = probe.xAxis.multiLevelLabels;
    if (groups != null && groups.groups.isNotEmpty) {
      int levels = 0;
      for (final VarietyLabelGroup group in groups.groups) {
        levels = math.max(levels, group.level + 1);
      }
      // The row height the painter will use, so the room reserved here and
      // the brackets drawn under the captions agree. Hard coding 22 here was
      // the same half wired mistake the tick label style used to have.
      bottom += levels * math.max(groups.rowHeight, 8) + 4;
    }
    final (double extraBelow, double extraAbove) = _extraXAxisInset(probe);
    return EdgeInsets.fromLTRB(
      left + widget.padding.left,
      widget.padding.top + extraAbove,
      widget.padding.right + _secondaryAxisInset(probe),
      bottom + extraBelow + widget.padding.bottom,
    );
  }

  /// The caption texts a horizontal axis prints, in tick order.
  Iterable<String> _xCaptions(VarietyCartesianGeometry probe, int axisIndex) {
    final VarietyAxis axis = probe.xAxes[axisIndex];
    switch (probe.axisXTypes[axisIndex]) {
      case VarietyAxisType.category:
      case VarietyAxisType.dateTimeCategory:
        return probe.axisCategories[axisIndex];
      case VarietyAxisType.dateTime:
        return probe.axisDateTimeTicks[axisIndex].map(
          (DateTime tick) => probe.dateTimeTickLabelOn(axisIndex, tick),
        );
      case VarietyAxisType.numeric:
      case VarietyAxisType.logarithmic:
        return probe.xNumericTicksOn(axisIndex).map(
              (double value) =>
                  axis.labelFormatter?.call(value) ??
                  varietyFormatNumber(value),
            );
    }
  }

  /// The vertical room the extra horizontal axes need, below and above.
  ///
  /// Mirrors how the painter stacks them: one caption row per axis, plus a row
  /// for the title when the axis has one. An opposed axis prints above the plot
  /// area instead, so its row is measured against the top inset.
  (double, double) _extraXAxisInset(VarietyCartesianGeometry probe) {
    if (probe.xAxes.length < 2) {
      return (0, 0);
    }
    double below = 0;
    double above = 0;
    for (int i = 1; i < probe.xAxes.length; i++) {
      final VarietyAxis axis = probe.xAxes[i];
      if (!axis.visible) {
        continue;
      }
      final TextStyle style = _tickLabelStyle(axis);
      final double rotation = axis.labelRotation * math.pi / 180;
      double height = 0;
      for (final String caption in _xCaptions(probe, i)) {
        height = math.max(height, _rotatedHeight(caption, style, rotation));
      }
      double row = math.max(height, _textSize('0', style).height) + 8;
      final String? title = axis.title;
      if (title != null && title.isNotEmpty) {
        row += 6 + _textSize(title, _xAxisTitleStyle()).height;
      }
      if (axis.opposedPosition) {
        above += row;
      } else {
        below += row;
      }
    }
    return (below, above);
  }

  /// The style an axis tick label is painted in, matching the painter's.
  ///
  /// The room reserved here and the text drawn by the painter have to be
  /// measured with the very same style, so this chain is kept identical to
  /// `VarietyCartesianPainter._tickLabelStyle`.
  TextStyle _tickLabelStyle(VarietyAxis axis) {
    final VarietyChartTheme theme = VarietyChartTheme.of(context);
    return axis.labelStyle ??
        theme.axisLabelTextStyle ??
        TextStyle(fontSize: 11, color: theme.labelColor);
  }

  /// The style an axis title is painted in, matching the painter's.
  TextStyle _xAxisTitleStyle() {
    final VarietyChartTheme theme = VarietyChartTheme.of(context);
    return theme.axisTitleTextStyle ??
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.axisTitleColor,
        );
  }

  /// The horizontal room the secondary axes need on the right.
  double _secondaryAxisInset(VarietyCartesianGeometry probe) {
    if (probe.yAxes.length < 2) {
      return 0;
    }
    double total = 0;
    for (int i = 1; i < probe.yAxes.length; i++) {
      final VarietyAxis axis = probe.yAxes[i];
      if (!axis.visible) {
        continue;
      }
      final TextStyle style = axis.labelStyle ??
          TextStyle(
              fontSize: 11, color: Theme.of(context).colorScheme.onSurface);
      double width = 0;
      for (final double tick in probe.yTicksOn(i)) {
        width = math.max(
          width,
          _textSize(probe.secondaryTickLabelOn(i, tick), style).width,
        );
      }
      total += width +
          axis.labelOffset +
          14 +
          ((axis.title ?? '').isNotEmpty ? 20 : 0);
    }
    return total;
  }

  double _rotatedHeight(String text, TextStyle style, double rotation) {
    final Size size = _textSize(text, style);
    if (rotation == 0) {
      return size.height;
    }
    return (size.height * math.cos(rotation)).abs() +
        (size.width * math.sin(rotation)).abs();
  }

  Size _textSize(String text, TextStyle style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.size;
  }

  // ---------------------------------------------------------------------------
  // Pointer handling
  // ---------------------------------------------------------------------------

  void _onHover(PointerHoverEvent event) {
    _reveal();
    _pointerPosition = event.localPosition;
    final VarietyCartesianGeometry? geometry = _display;
    if (geometry == null) {
      return;
    }
    final VarietyTrackballBehavior? ball = widget.trackballBehavior;
    if (ball != null &&
        ball.enabled &&
        ball.activationMode == VarietyActivationMode.auto) {
      _updateTrackball(event.localPosition, geometry);
      return;
    }
    final VarietyCrosshairBehavior? cross = widget.crosshairBehavior;
    if (cross != null &&
        cross.enabled &&
        cross.activationMode == VarietyActivationMode.auto) {
      _updateSingleHit(geometry.hitTest(event.localPosition), hover: true);
      return;
    }
    if (widget.tooltipBehavior.enabled) {
      _updateSingleHitAfterDelay(
        geometry.hitTest(event.localPosition),
      );
    }
  }

  /// Reveals a hovered tooltip once the configured delay has passed.
  ///
  /// With no delay this is the plain reveal it has always been; with one, the
  /// timer is restarted on every move and a pointer that keeps travelling
  /// never shows a card at all.
  void _updateSingleHitAfterDelay(VarietyHitResult? result) {
    final Duration delay = widget.tooltipBehavior.showDuration;
    _tooltipDelayTimer?.cancel();
    _tooltipDelayTimer = null;
    if (delay <= Duration.zero || result == null) {
      // Leaving a point hides the card at once; the delay is only ever about
      // showing one.
      _updateSingleHit(result, hover: true);
      return;
    }
    _tooltipDelayTimer = Timer(delay, () {
      _tooltipDelayTimer = null;
      if (!mounted) {
        return;
      }
      _updateSingleHit(result, hover: true);
    });
  }

  void _onTap(Offset position, VarietyCartesianGeometry geometry) {
    _reveal();
    _pointerPosition = position;
    final void Function(VarietyAxisLabelTapDetails)? labelCallback =
        widget.onAxisLabelTapped;
    if (labelCallback != null && _labelHits.isNotEmpty) {
      for (final VarietyAxisLabelHit hit in _labelHits) {
        if (hit.rect.inflate(2).contains(position)) {
          labelCallback(
            VarietyAxisLabelTapDetails(
              axis: hit.axis,
              text: hit.text,
              value: hit.value,
            ),
          );
          return;
        }
      }
    }
    final VarietyHitResult? probe = geometry.hitTest(position);
    final VarietySelectionBehavior? selection = probe == null
        ? widget.selectionBehavior
        : _seriesSelection(probe.seriesIndex);
    if (selection != null &&
        selection.enabled &&
        selection.selectionType != VarietySelectionType.none) {
      final VarietyHitResult? hit = geometry.hitTest(position);
      if (hit == null) {
        _applySelection(const <VarietyHitResult>[]);
      } else if (selection.selectionType == VarietySelectionType.series) {
        _applySelection(
          List<VarietyHitResult>.generate(
            geometry.pointPositions[hit.seriesIndex].length,
            (int i) => VarietyHitResult(
              series: hit.series,
              seriesIndex: hit.seriesIndex,
              point: geometry.sourceData[hit.seriesIndex][i],
              pointIndex: i,
              position: geometry.pointPositions[hit.seriesIndex][i],
            ),
          ),
        );
      } else if (selection.selectionType == VarietySelectionType.cluster) {
        // Every series' nearest point at the tapped slot, so one x position
        // can be highlighted across the whole stack.
        _applySelection(geometry.hitsAtSlot(hit.position));
      } else {
        final bool alreadySelected = _selected.contains(hit);
        if (selection.enableMultiSelection) {
          final List<VarietyHitResult> next =
              List<VarietyHitResult>.of(_selected);
          if (alreadySelected) {
            // Without toggling, a second tap on a selected point is a no-op,
            // so a selection cannot be lost by an accidental extra touch.
            if (selection.toggleSelection) {
              next.remove(hit);
              _applySelection(next);
            }
          } else {
            next.add(hit);
            _applySelection(next);
          }
        } else if (alreadySelected && !selection.toggleSelection) {
          // Keep what is already selected.
        } else {
          _applySelection(
            alreadySelected
                ? const <VarietyHitResult>[]
                : <VarietyHitResult>[hit],
          );
        }
      }
    }
    final VarietyTrackballBehavior? ball = widget.trackballBehavior;
    if (ball != null &&
        ball.enabled &&
        ball.activationMode == VarietyActivationMode.tap) {
      // Taps outside the plot area never activate the trackball; they
      // dismiss it, matching how blank touches behave in fl_chart.
      if (!geometry.plotRect.inflate(12).contains(position)) {
        _clearTrackball();
        return;
      }
      _updateTrackball(position, geometry);
      return;
    }
    final VarietyHitResult? hit = geometry.hitTest(position);
    setState(() => _hit = hit);
    widget.onPointTap?.call(hit);
  }

  void _onLongPressStart(Offset position, VarietyCartesianGeometry geometry) {
    _reveal();
    _pointerPosition = position;
    // Selection zooming owns the long press whenever it is enabled, so a
    // long-press trackball would never see the gesture.
    if (_selectionZoomEnabled) {
      _selectionStart = position;
      setState(() => _selectionRect = null);
      return;
    }
    final VarietyTrackballBehavior? ball = widget.trackballBehavior;
    if (ball != null &&
        ball.enabled &&
        (ball.activationMode == VarietyActivationMode.longPress ||
            ball.activationMode == VarietyActivationMode.press)) {
      _updateTrackball(position, geometry);
      return;
    }
    final VarietyHitResult? hit = geometry.hitTest(position);
    _updateSingleHit(hit, hover: true);
    if (hit != null) {
      final int s = hit.seriesIndex;
      final int p = hit.pointIndex;
      final List<List<VarietyChartData>> rows = geometry.resolvedData;
      if (s < rows.length && p < rows[s].length) {
        geometry.series[s].onPointLongPress?.call(rows[s][p], p);
      } else {
        geometry.series[s].onPointLongPress?.call(
            geometry
                .series[s].data[p.clamp(0, geometry.series[s].data.length - 1)],
            p);
      }
    }
  }

  void _onLongPressMove(Offset position, VarietyCartesianGeometry geometry) {
    final Offset? start = _selectionStart;
    if (start != null) {
      setState(() => _selectionRect = Rect.fromPoints(start, position));
      return;
    }
    final VarietyTrackballBehavior? ball = widget.trackballBehavior;
    if (ball != null && ball.enabled && _trackballHits.isNotEmpty) {
      _updateTrackball(position, geometry);
      return;
    }
    _updateSingleHit(geometry.hitTest(position), hover: true);
  }

  void _onLongPressEnd() {
    final Rect? rect = _selectionRect;
    final VarietyCartesianGeometry? geometry = _display;
    _selectionStart = null;
    if (rect != null && geometry != null) {
      setState(() => _selectionRect = null);
      if (_applySelectionZoom(rect, geometry)) {
        _notifyZoom(geometry);
      }
      return;
    }
    if (!widget.tooltipBehavior.enabled && _trackballHits.isEmpty) {
      setState(() => _hit = null);
    }
  }

  void _clearPointerState() {
    _cancelTrackballTimer();
    _tooltipDelayTimer?.cancel();
    _tooltipDelayTimer = null;
    if (_hit == null && _trackballHits.isEmpty) {
      return;
    }
    setState(() {
      _hit = null;
      _trackballHits = const <VarietyHitResult>[];
      _trackballSlot = null;
    });
    widget.onPointHover?.call(null);
  }

  void _updateSingleHit(VarietyHitResult? result, {bool hover = false}) {
    _cancelTrackballTimer();
    final bool changed = _hit != result || _trackballHits.isNotEmpty;
    if (!changed) {
      return;
    }
    setState(() {
      _hit = result;
      _trackballHits = const <VarietyHitResult>[];
      _trackballSlot = null;
    });
    if (hover) {
      widget.onPointHover?.call(result);
    }
  }

  /// Cancels the pending auto-hide timer, if any.
  void _cancelTrackballTimer() {
    _trackballHideTimer?.cancel();
    _trackballHideTimer = null;
  }

  /// Clears an active trackball without touching hover state.
  void _clearTrackball() {
    _cancelTrackballTimer();
    if (_trackballHits.isEmpty && _trackballSlot == null && _hit == null) {
      return;
    }
    setState(() {
      _trackballHits = const <VarietyHitResult>[];
      _trackballSlot = null;
      // Tap activation also seeds [_hit]; leaving it set would downgrade the
      // card to the plain point tooltip and keep the bubble on screen after
      // the guide disappeared.
      _hit = null;
    });
  }

  /// Restarts the auto-hide countdown. Tap activations expire after the
  /// behaviour's hideDelay unless the trackball is meant to stay put.
  void _scheduleTrackballHide(VarietyTrackballBehavior ball) {
    _cancelTrackballTimer();
    if (ball.shouldAlwaysShow ||
        ball.visibilityMode == VarietyTrackballVisibilityMode.visible) {
      return;
    }
    _trackballHideTimer = Timer(ball.hideDelay, _clearTrackball);
  }

  void _updateTrackball(Offset position, VarietyCartesianGeometry geometry) {
    final VarietyTrackballBehavior? ball = widget.trackballBehavior;
    if (ball != null &&
        ball.visibilityMode == VarietyTrackballVisibilityMode.hidden) {
      // A hidden trackball still needs the dismissal: the gesture reached an
      // active behaviour, so whatever was on screen has to go.
      _clearTrackball();
      return;
    }
    final List<VarietyHitResult> hits = geometry.hitsAtSlot(
      position,
      displayMode:
          ball?.displayMode ?? VarietyTrackballDisplayMode.groupAllPoints,
    );
    if (hits.isEmpty) {
      _clearTrackball();
      return;
    }
    final bool tapMode =
        ball != null && ball.activationMode == VarietyActivationMode.tap;
    if (tapMode) {
      // fl_chart style activation radius: a tap landing farther than
      // activationDistance from every point counts as a blank tap and
      // dismisses the trackball instead of moving it.
      if ((hits.first.position - position).distance > ball.activationDistance) {
        _clearTrackball();
        return;
      }
      _scheduleTrackballHide(ball);
    }
    final double slot = hits.first.position.dx;
    final bool changed = _trackballHits.length != hits.length ||
        _trackballSlot != slot ||
        _trackballHits.first.pointIndex != hits.first.pointIndex;
    if (!changed) {
      return;
    }
    setState(() {
      _trackballHits = hits;
      _trackballSlot = slot;
      _hit = hits.first;
    });
  }

  // ---------------------------------------------------------------------------
  // Zoom and pan
  // ---------------------------------------------------------------------------

  void _onPointerSignal(PointerSignalEvent event) {
    final VarietyZoomPanBehavior? behavior = widget.zoomPanBehavior;
    if (behavior == null ||
        !_zooming ||
        !behavior.enableMouseWheelZooming ||
        event is! PointerScrollEvent) {
      return;
    }
    final VarietyCartesianGeometry? geometry = _display;
    if (geometry == null) {
      return;
    }
    // One wheel notch is a quarter of a magnification step
    // applied at the pointer, so the value under the cursor stays put and the
    // chart can be zoomed back out again.
    _zoomInAndOut(
      event.scrollDelta.dy > 0 ? -0.25 : 0.25,
      event.localPosition,
      geometry,
    );
  }

  void _onDoubleTap(
    Offset position,
    VarietyCartesianGeometry display,
  ) {
    // The user might just want to know a point was double-clicked; honour
    // per-series `onPointDoubleTap` before the zoom logic kicks in.
    final VarietyHitResult? hit = display.hitTest(position);
    if (hit != null) {
      final int s = hit.seriesIndex;
      final int p = hit.pointIndex;
      final List<List<VarietyChartData>> rows = display.resolvedData;
      if (s < rows.length && p < rows[s].length) {
        display.series[s].onPointDoubleTap?.call(rows[s][p], p);
      }
    }
    final VarietyZoomPanBehavior? behavior = widget.zoomPanBehavior;
    if (behavior != null &&
        behavior.enabled &&
        behavior.enableDoubleTapZooming) {
      if (_hasZoom) {
        _resetZoom(display);
        return;
      }
      _zoomInAndOut(0.5, position, display);
      return;
    }
    // No zoom claimed the gesture, so a behaviour that asked for a double tap
    // can have it.
    final VarietyTrackballBehavior? ball = widget.trackballBehavior;
    if (ball != null &&
        ball.enabled &&
        ball.activationMode == VarietyActivationMode.doubleTap) {
      _updateTrackball(position, display);
      return;
    }
    final VarietyCrosshairBehavior? cross = widget.crosshairBehavior;
    if (cross != null &&
        cross.enabled &&
        cross.activationMode == VarietyActivationMode.doubleTap) {
      _updateSingleHit(display.hitTest(position), hover: true);
    }
  }

  // ---------------------------------------------------------------------------
  // Zoom maths
  //
  // The zoom and pan maths, in one place. The helpers keep the names the
  // gestures use elsewhere, so a number can be followed from the gesture that
  // produced it down to the window it ends up as.
  // ---------------------------------------------------------------------------

  double _minMax(double value, double min, double max) =>
      value > max ? max : (value < min ? min : value);

  /// The smallest window a gesture may leave behind, as a fraction of the full
  /// range. This is the ceiling on magnification.
  double get _maxZoomInFactor =>
      _minMax(widget.zoomPanBehavior!.minimumZoomLevel, 1e-4, 1);

  /// The largest window a gesture may leave behind.
  double get _maxZoomOutFactor =>
      _minMax(widget.zoomPanBehavior!.maximumZoomLevel, 1e-4, 1);

  /// Converts a zoom window into the magnification the maths works with: a
  /// factor of 0.5 shows half the range, which is a scale of 2. This is
  /// the scale conversion.
  double _toScaleValue(double zoomFactor) =>
      math.max(1 / _minMax(zoomFactor, 1e-6, 1), 1);

  /// Projects a normalised window back onto the full range of an axis.
  (double, double)? _windowFor(
    double min,
    double max,
    double position,
    double factor,
  ) {
    final double span = max - min;
    if (span <= 0 || !factor.isFinite || factor <= 0 || factor >= 1) {
      return null;
    }
    final double start = min + position * span;
    return (start, start + factor * span);
  }

  /// Applies a cumulative magnification to a window, keeping [origin] fixed.
  /// The window maths; [origin] is the fraction of the plot under
  /// the gesture, measured from the minimum end of the axis.
  (double, double) _zoomWindow({
    required double factor,
    required double position,
    required double origin,
    required double cumulativeZoomLevel,
  }) {
    if (cumulativeZoomLevel <= 1) {
      // Pinching back past the full range always restores it exactly.
      return (1, 0);
    }
    final double nextFactor = _minMax(
      1 / cumulativeZoomLevel,
      _maxZoomInFactor,
      _maxZoomOutFactor,
    );
    final double nextPosition = position + (factor - nextFactor) * origin;
    return (nextFactor, _minMax(nextPosition, 0, 1 - nextFactor));
  }

  /// The fraction of the plot under [position], measured from the minimum end
  /// of the primary axis.
  double _originForX(Offset position, VarietyCartesianGeometry geometry) {
    final Rect plot = geometry.plotRect;
    final double fromLeft = plot.width <= 0
        ? 0.5
        : ((position.dx - plot.left) / plot.width).clamp(0.0, 1.0);
    return geometry.xAxis.isInversed ? 1 - fromLeft : fromLeft;
  }

  /// The same fraction for the secondary axis. The vertical axis grows
  /// upwards, so the distance is counted from the bottom of the plot.
  double _originForY(Offset position, VarietyCartesianGeometry geometry) {
    final Rect plot = geometry.plotRect;
    final double fromTop = plot.height <= 0
        ? 0.5
        : ((position.dy - plot.top) / plot.height).clamp(0.0, 1.0);
    return geometry.yAxis.isInversed ? fromTop : 1 - fromTop;
  }

  /// Zooms both axes by a fixed magnification step around [origin], the
  /// workhorse of the double tap zoom.
  void _zoomInAndOut(
    double zoomLevel,
    Offset origin,
    VarietyCartesianGeometry geometry,
  ) {
    final VarietyZoomPanBehavior behavior = widget.zoomPanBehavior!;
    final double maxScale = _toScaleValue(_maxZoomInFactor);
    final bool zoomX = behavior.axisMode != VarietyZoomAxisMode.y;
    final bool zoomY = behavior.axisMode != VarietyZoomAxisMode.x;
    final double originX = _originForX(origin, geometry);
    final double originY = _originForY(origin, geometry);
    setState(() {
      if (zoomX) {
        final double level = _minMax(
          _toScaleValue(_xZoomFactor) + zoomLevel,
          1,
          maxScale,
        );
        final (double, double) next = _zoomWindow(
          factor: _xZoomFactor,
          position: _xZoomPosition,
          origin: originX,
          cumulativeZoomLevel: level,
        );
        _xZoomFactor = next.$1;
        _xZoomPosition = next.$2;
      }
      if (zoomY) {
        final double level = _minMax(
          _toScaleValue(_yZoomFactor) + zoomLevel,
          1,
          maxScale,
        );
        final (double, double) next = _zoomWindow(
          factor: _yZoomFactor,
          position: _yZoomPosition,
          origin: originY,
          cumulativeZoomLevel: level,
        );
        _yZoomFactor = next.$1;
        _yZoomPosition = next.$2;
      }
    });
    _gestureChanged = true;
    // `moving` reports the window while the fingers are still down, which is
    // what a live readout follows; the settled value comes from `onZoomEnd`.
    _notifyZoom(geometry, moving: true);
  }

  /// Restores both axes to their full range.
  void _resetZoom(VarietyCartesianGeometry geometry) {
    setState(() {
      _xZoomFactor = 1;
      _xZoomPosition = 0;
      _yZoomFactor = 1;
      _yZoomPosition = 0;
    });
    _notifyZoom(geometry);
    widget.zoomPanBehavior?.onZoomReset?.call(_zoomDetails());
  }

  /// Reports a pan that ran out of data at one end of the primary axis.
  ///
  /// The window is read after the gesture settles rather than during it, so a
  /// long drag reports once instead of once per frame, and the same end is
  /// never reported twice in a row.
  void _reportSwipeAtEnd() {
    // A chart that is not zoomed has nothing to pan, so a drag over it is not
    // a request for more data.
    if (!_hasZoom) {
      return;
    }
    final (double, double)? window = _zoomX;
    if (window == null) {
      return;
    }
    final double tolerance =
        math.max((_baseXMax - _baseXMin).abs() * 1e-6, 1e-9);
    VarietySwipeDirection? direction;
    if (window.$2 >= _baseXMax - tolerance) {
      direction = VarietySwipeDirection.end;
    } else if (window.$1 <= _baseXMin + tolerance) {
      direction = VarietySwipeDirection.start;
    }
    if (direction != _swipeDirection) {
      setState(() => _swipeDirection = direction);
    }
    if (direction == null || direction == _reportedSwipe) {
      return;
    }
    _reportedSwipe = direction;
    widget.onPlotAreaSwipe?.call(direction);
  }

  /// The current window, as the zoom callbacks see it.
  VarietyZoomDetails _zoomDetails() {
    final (double, double)? window = _windowFor(
      _baseXMin,
      _baseXMax,
      _xZoomPosition,
      _xZoomFactor,
    );
    return VarietyZoomDetails(
      axis: widget.primaryXAxis,
      minimum: window?.$1 ?? _baseXMin,
      maximum: window?.$2 ?? _baseXMax,
      factor: _xZoomFactor,
    );
  }

  /// Reports the visible window to the behaviour's zoom callbacks.
  void _notifyZoom(
    VarietyCartesianGeometry geometry, {
    bool start = false,
    bool moving = false,
  }) {
    final VarietyZoomPanBehavior? behavior = widget.zoomPanBehavior;
    if (behavior == null) {
      return;
    }
    final VarietyZoomDetails details = _zoomDetails();
    if (start) {
      behavior.onZoomStart?.call(details);
      return;
    }
    if (moving) {
      behavior.onZooming?.call(details);
      return;
    }
    behavior.onZoomEnd?.call(details);
  }

  /// Pans a zoomed axis by a pixel delta. [delta] is `previous - current`, so
  /// the content
  /// follows the finger on both axes.
  void _pan(Offset position, VarietyCartesianGeometry geometry) {
    if (!_panStarted) {
      _previousPanPosition = position;
      _panStarted = true;
      return;
    }
    final Offset delta = _previousPanPosition - position;
    _previousPanPosition = position;
    if (delta == Offset.zero) {
      return;
    }
    final VarietyZoomPanBehavior behavior = widget.zoomPanBehavior!;
    final Rect plot = geometry.plotRect;
    final bool panX = behavior.axisMode != VarietyZoomAxisMode.y &&
        _xZoomFactor < 1 &&
        plot.width > 0;
    final bool panY = behavior.axisMode != VarietyZoomAxisMode.x &&
        _yZoomFactor < 1 &&
        plot.height > 0;
    if (!panX && !panY) {
      return;
    }
    double nextX = _xZoomPosition;
    double nextY = _yZoomPosition;
    if (panX) {
      final double offset =
          (delta.dx / plot.width) / _toScaleValue(_xZoomFactor);
      nextX = _minMax(
        geometry.xAxis.isInversed
            ? _xZoomPosition - offset
            : _xZoomPosition + offset,
        0,
        1 - _xZoomFactor,
      );
    }
    if (panY) {
      final double offset =
          (delta.dy / plot.height) / _toScaleValue(_yZoomFactor);
      nextY = _minMax(
        geometry.yAxis.isInversed
            ? _yZoomPosition + offset
            : _yZoomPosition - offset,
        0,
        1 - _yZoomFactor,
      );
    }
    if (nextX == _xZoomPosition && nextY == _yZoomPosition) {
      return;
    }
    if (behavior.enableDeferredZooming) {
      setState(() {
        _xZoomPosition = nextX;
        _yZoomPosition = nextY;
      });
    } else {
      _xZoomPosition = nextX;
      _yZoomPosition = nextY;
    }
    _gestureChanged = true;
  }

  void _onScaleStart(ScaleStartDetails details) {
    _scalePointerCount = 0;
    _panStarted = false;
    _gestureChanged = false;
    _previousPanPosition = details.localFocalPoint;
    _startScaleX = _toScaleValue(_xZoomFactor);
    _startScaleY = _toScaleValue(_yZoomFactor);
    final VarietyCartesianGeometry? geometry = _display;
    if (geometry != null) {
      _notifyZoom(geometry, start: true);
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final VarietyZoomPanBehavior behavior = widget.zoomPanBehavior!;
    final VarietyCartesianGeometry? geometry = _display;
    if (geometry == null) {
      return;
    }

    // Re-baseline whenever a finger is added or lifted so neither the pinch
    // nor the pan ever sees a jump in its reference frame.
    if (details.pointerCount != _scalePointerCount) {
      _scalePointerCount = details.pointerCount;
      _startScaleX = _toScaleValue(_xZoomFactor);
      _startScaleY = _toScaleValue(_yZoomFactor);
      _panStarted = false;
    }

    if (_selectionRect != null) {
      // A long-press selection is in flight; the scale recogniser must not
      // fight it for the same pointer.
      return;
    }

    if (details.pointerCount >= 2 && behavior.enablePinchZooming) {
      final bool both = behavior.axisMode == VarietyZoomAxisMode.xy;
      final bool zoomX = behavior.axisMode != VarietyZoomAxisMode.y;
      final bool zoomY = behavior.axisMode != VarietyZoomAxisMode.x;
      final double maxScale = _toScaleValue(_maxZoomInFactor);
      final double originX = _originForX(details.localFocalPoint, geometry);
      final double originY = _originForY(details.localFocalPoint, geometry);
      // The magnification captured when the pinch began is multiplied
      // by the gesture's scale, which keeps the window stable across frames.
      final double rawScaleX = (_startScaleX ?? 1) *
          (both ? details.scale : details.horizontalScale);
      final double rawScaleY =
          (_startScaleY ?? 1) * (both ? details.scale : details.verticalScale);
      void applyZoom() {
        if (zoomX) {
          final (double, double) next = _zoomWindow(
            factor: _xZoomFactor,
            position: _xZoomPosition,
            origin: originX,
            cumulativeZoomLevel: _minMax(rawScaleX, 1, maxScale),
          );
          _xZoomFactor = next.$1;
          _xZoomPosition = next.$2;
        }
        if (zoomY) {
          final (double, double) next = _zoomWindow(
            factor: _yZoomFactor,
            position: _yZoomPosition,
            origin: originY,
            cumulativeZoomLevel: _minMax(rawScaleY, 1, maxScale),
          );
          _yZoomFactor = next.$1;
          _yZoomPosition = next.$2;
        }
      }

      if (behavior.enableDeferredZooming) {
        setState(applyZoom);
      } else {
        // Deferred zooming keeps the state moving but holds the repaint back
        // until the fingers are off, which is what makes a pinch on a very
        // large data set cheap. The window still ends up exactly where the
        // gesture put it.
        applyZoom();
      }
      _panStarted = false;
      _gestureChanged = true;
      return;
    }

    if (!behavior.enablePanning) {
      _panStarted = false;
      return;
    }
    _pan(details.localFocalPoint, geometry);
    // A drag that cannot move the window any further has run out of data at
    // one end, which is what an infinite scroll listens for. Reporting while
    // the finger is still down gives the indicator immediate feedback, and the
    // callback itself only fires on arriving at an end rather than per frame.
    _reportSwipeAtEnd();
  }

  void _onScaleEnd() {
    final VarietyCartesianGeometry? geometry = _display;
    final bool wasChanged = _gestureChanged;
    _scalePointerCount = 0;
    _panStarted = false;
    _gestureChanged = false;
    _previousPanPosition = Offset.zero;
    if (geometry != null && wasChanged) {
      // A deferred gesture has not repainted yet, so this is where its window
      // finally reaches the screen.
      if (!widget.zoomPanBehavior!.enableDeferredZooming) {
        setState(() {});
      }
      _notifyZoom(geometry);
    }
  }

  /// Converts the rubber band into a new window. Returns whether anything was
  /// zoomed, so a
  /// stray long press with no drag does not report a zoom.
  bool _applySelectionZoom(Rect rect, VarietyCartesianGeometry geometry) {
    final VarietyZoomPanBehavior behavior = widget.zoomPanBehavior!;
    final Rect plot = geometry.plotRect;
    final bool zoomX = behavior.axisMode != VarietyZoomAxisMode.y &&
        plot.width > 0 &&
        rect.width >= 12;
    final bool zoomY = behavior.axisMode != VarietyZoomAxisMode.x &&
        plot.height > 0 &&
        rect.height >= 12;
    if (!zoomX && !zoomY) {
      return false;
    }
    setState(() {
      if (zoomX) {
        final double factor = _minMax(
          _xZoomFactor * rect.width / plot.width,
          _maxZoomInFactor,
          _maxZoomOutFactor,
        );
        final double position = _xZoomPosition +
            ((rect.left - plot.left) / plot.width) * _xZoomFactor;
        _xZoomFactor = factor;
        _xZoomPosition = _minMax(position, 0, 1 - factor);
      }
      if (zoomY) {
        final double factor = _minMax(
          _yZoomFactor * rect.height / plot.height,
          _maxZoomInFactor,
          _maxZoomOutFactor,
        );
        // The vertical window is measured from the bottom of the plot, so the
        // offset is the distance from the band's bottom edge.
        final double position = _yZoomPosition +
            ((plot.bottom - rect.bottom) / plot.height) * _yZoomFactor;
        _yZoomFactor = factor;
        _yZoomPosition = _minMax(position, 0, 1 - factor);
      }
    });
    _gestureChanged = true;
    return true;
  }

  // ---------------------------------------------------------------------------
  // Tooltip overlay
  // ---------------------------------------------------------------------------

  List<Widget> _overlayWidgets(VarietyChartTheme theme) {
    final bool hasTrackball =
        _trackballHits.isNotEmpty && _trackballSlot != null;
    if (hasTrackball) {
      final VarietyTrackballBehavior ball = widget.trackballBehavior!;
      if (!ball.showTooltip) {
        return const <Widget>[];
      }
      final Offset anchor = Offset(
        _trackballSlot!,
        _trackballHits.first.position.dy,
      );
      return _positionedCard(
        anchor,
        VarietyTrackballTooltipCard(
          results: _trackballHits,
          theme: theme,
          builder: ball.builder,
          behavior: widget.tooltipBehavior,
        ),
      );
    }
    final VarietyHitResult? hit = _hit;
    if (hit == null) {
      return const <Widget>[];
    }
    final String header = widget.tooltipBehavior.header ??
        hit.point.label ??
        hit.point.x?.toString() ??
        '';
    final VarietyTooltipBehavior tooltip = widget.tooltipBehavior;
    final Offset anchor =
        tooltip.tooltipPosition == VarietyTooltipPosition.pointer &&
                _pointerPosition != null
            ? _pointerPosition!
            : hit.position;
    final String valueText = VarietyTooltipCard.formatValue(
      hit.point.y,
      decimalPlaces: tooltip.decimalPlaces,
      template: tooltip.format,
    );
    if (widget.onTooltipRender != null &&
        !widget.onTooltipRender!(
          VarietyTooltipDetails(hit: hit, header: header, text: valueText),
        )) {
      return const <Widget>[];
    }
    final VarietyCrosshairBehavior? cross = widget.crosshairBehavior;
    if (cross != null && cross.enabled && cross.showTooltip) {
      return _positionedCard(
        anchor,
        VarietyTooltipCard(
          result: hit,
          theme: theme,
          builder: cross.builder,
          behavior: tooltip,
        ),
      );
    }
    if (!tooltip.enabled) {
      return const <Widget>[];
    }
    return _positionedCard(
      anchor,
      VarietyTooltipCard(
        result: hit,
        theme: theme,
        builder: tooltip.builder,
        behavior: tooltip,
      ),
    );
  }

  List<Widget> _positionedCard(Offset anchor, Widget card) {
    return <Widget>[
      Positioned.fill(
        child: IgnorePointer(
          child: VarietyAnchoredCard(anchor: anchor, child: card),
        ),
      ),
    ];
  }
}

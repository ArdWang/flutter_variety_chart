import 'dart:math' as math;

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

  @override
  State<VarietyCartesianChart> createState() => _VarietyCartesianChartState();
}

class _VarietyCartesianChartState extends State<VarietyCartesianChart>
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

  VarietyHitResult? _hit;
  List<VarietyHitResult> _trackballHits = const <VarietyHitResult>[];
  // Auto-hides the trackball [VarietyTrackballBehavior.hideDelay] after a tap
  // activation. Restarted on every activation, cancelled on clear/dispose.
  Timer? _trackballHideTimer;
  double? _trackballSlot;
  List<VarietyHitResult> _selected = const <VarietyHitResult>[];
  final Set<int> _hiddenSeries = <int>{};
  final List<VarietyAxisLabelHit> _labelHits = <VarietyAxisLabelHit>[];
  bool _revealed = false;
  (double, double)? _lastPrimaryRange;
  (double, double)? _lastSecondaryRange;

  // Zoom state, held the same way Syncfusion holds it: every axis keeps a
  // normalised window made of a `factor` (the visible fraction of the full
  // range, 1 meaning fully zoomed out) and a `position` (where that window
  // starts, as a fraction of the full range). Gestures only ever touch those
  // two numbers, so the focal point of a pinch stays pinned while it applies.
  double _xZoomFactor = 1;
  double _xZoomPosition = 0;
  double _yZoomFactor = 1;
  double _yZoomPosition = 0;

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
  // counterpart of Syncfusion's `_previousScale`.
  double? _startScaleX;
  double? _startScaleY;
  int _scalePointerCount = 0;
  Offset _previousPanPosition = Offset.zero;
  bool _panStarted = false;
  bool _gestureChanged = false;
  Offset? _selectionStart;
  Rect? _selectionRect;

  /// Whether either axis currently shows a zoomed window.
  bool get _hasZoom => _xZoomFactor < 1 || _yZoomFactor < 1;

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

  /// Whether a long press may drag out a zoom region. Syncfusion drives
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
    _controller = AnimationController(
        vsync: this, duration: _effectiveAnimationDuration());
    if (widget.enableAnimation && _shouldAnimate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  bool get _shouldAnimate =>
      _items.any((VarietySeries item) => item.animate && item.data.isNotEmpty);

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
        final bool legendOnSide =
            widget.legendPosition == VarietyLegendPosition.left ||
                widget.legendPosition == VarietyLegendPosition.right;
        final Widget? legend = wantsLegend
            ? VarietyLegend(
                series: widget.series
                    .where((VarietySeries item) => !item.isCircular)
                    .toList(growable: false),
                position: widget.legendPosition,
                textStyle: widget.legendTextStyle,
                itemBuilder: widget.legendBuilder,
                settings: widget.legendSettings,
                hiddenIndexes: _hiddenSeries,
                onItemTap: _handleLegendTap,
              )
            : null;
        if (legend != null &&
            widget.legendPosition == VarietyLegendPosition.top) {
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
                  if (widget.legendPosition == VarietyLegendPosition.left)
                    legend,
                  Expanded(child: plot),
                  if (widget.legendPosition == VarietyLegendPosition.right)
                    legend,
                ],
              ),
            ),
          );
        } else {
          column.add(Expanded(child: plot));
        }
        if (legend != null &&
            widget.legendPosition == VarietyLegendPosition.bottom) {
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

  Widget _buildPlot(VarietyChartTheme theme) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        final (_, VarietyCartesianGeometry display) = _geometries(size);
        _display = display;
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
          ),
        );
        // Gesture recognisers are only attached when the behaviour that needs them
        // is enabled. Registering the double tap recogniser unconditionally would
        // delay every single tap by the double tap timeout.
        final VarietyZoomPanBehavior? zoom = widget.zoomPanBehavior;
        final bool zoomEnabled =
            zoom != null && zoom.enabled && zoom.mode != VarietyZoomMode.none;
        final bool doubleTapEnabled =
            zoomEnabled && zoom.enableDoubleTapZooming;
        return Listener(
          onPointerSignal: _onPointerSignal,
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
    );
    _baseXMin = base.xMinimum;
    _baseXMax = base.xMaximum;
    _baseYMin = base.yMinimum;
    _baseYMax = base.yMaximum;
    _zoomX = _windowFor(_baseXMin, _baseXMax, _xZoomPosition, _xZoomFactor);
    _zoomY = _windowFor(_baseYMin, _baseYMax, _yZoomPosition, _yZoomFactor);
    final VarietyCartesianGeometry display = VarietyCartesianGeometry(
      series: _items,
      xAxis: widget.primaryXAxis,
      yAxis: widget.primaryYAxis,
      plotRect: plotRect,
      progress: _progress,
      visibleXRange: _zoomX,
      visibleYRange: _zoomY,
      dataLabelResolver: _resolveDataLabel,
      secondaryYAxes: widget.secondaryYAxes,
    );
    _reportRangeChanges(base, display);
    return (base, display);
  }

  EdgeInsets _insetsFor(VarietyCartesianGeometry probe) {
    final TextStyle yStyle = probe.yAxis.labelStyle ??
        TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface);
    double left = 10;
    for (final double tick in probe.yTicks) {
      final String caption = probe.secondaryTickLabel(tick);
      left = math.max(left, _textSize(caption, yStyle).width + 12);
    }
    if ((probe.yAxis.title ?? '').isNotEmpty) {
      left += 18;
    }
    final TextStyle xStyle = probe.xAxis.labelStyle ?? yStyle;
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
      final double span = probe.xMaximum - probe.xMinimum;
      final int steps = math.max(probe.xAxis.desiredIntervals, 1);
      for (int i = 0; i <= steps; i++) {
        final double value = probe.xMinimum + span * i / steps;
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
      bottom += levels * 22 + 4;
    }
    return EdgeInsets.fromLTRB(
      left + widget.padding.left,
      widget.padding.top,
      widget.padding.right + _secondaryAxisInset(probe),
      bottom + widget.padding.bottom,
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
      _updateSingleHit(geometry.hitTest(event.localPosition), hover: true);
    }
  }

  void _onTap(Offset position, VarietyCartesianGeometry geometry) {
    _reveal();
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
      } else {
        final bool alreadySelected = _selected.contains(hit);
        if (selection.enableMultiSelection) {
          final List<VarietyHitResult> next =
              List<VarietyHitResult>.of(_selected);
          if (alreadySelected) {
            next.remove(hit);
          } else {
            next.add(hit);
          }
          _applySelection(next);
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
  /// behaviour's hideDelay unless the trackball should always stay visible.
  void _scheduleTrackballHide(VarietyTrackballBehavior ball) {
    _cancelTrackballTimer();
    if (ball.shouldAlwaysShow) {
      return;
    }
    _trackballHideTimer = Timer(ball.hideDelay, _clearTrackball);
  }

  void _updateTrackball(Offset position, VarietyCartesianGeometry geometry) {
    final List<VarietyHitResult> hits = geometry.hitsAtSlot(position);
    if (hits.isEmpty) {
      _clearTrackball();
      return;
    }
    final VarietyTrackballBehavior? ball = widget.trackballBehavior;
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
    // Mirror Syncfusion: one wheel notch is a quarter of a magnification step
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
    if (behavior == null ||
        !behavior.enabled ||
        !behavior.enableDoubleTapZooming) {
      return;
    }
    if (_hasZoom) {
      _resetZoom(display);
      return;
    }
    _zoomInAndOut(0.5, position, display);
  }

  // ---------------------------------------------------------------------------
  // Zoom maths
  //
  // Ported from Syncfusion's `ZoomPanBehavior` (behaviors/zooming.dart). The
  // helpers keep the same names and semantics as the original so the two
  // implementations can be compared side by side.
  // ---------------------------------------------------------------------------

  double _minMax(double value, double min, double max) =>
      value > max ? max : (value < min ? min : value);

  /// The smallest window a gesture may leave behind, as a fraction of the full
  /// range. Syncfusion spells this `maximumZoomLevel`.
  double get _maxZoomInFactor =>
      _minMax(widget.zoomPanBehavior!.minimumZoomLevel, 1e-4, 1);

  /// The largest window a gesture may leave behind.
  double get _maxZoomOutFactor =>
      _minMax(widget.zoomPanBehavior!.maximumZoomLevel, 1e-4, 1);

  /// Converts a zoom window into the magnification the maths works with: a
  /// factor of 0.5 shows half the range, which is a scale of 2. This is
  /// Syncfusion's `_toScaleValue`.
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
  /// This is Syncfusion's `_zoom`; [origin] is the fraction of the plot under
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
  /// counterpart of Syncfusion's `_zoomInAndOut`.
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
    _notifyZoom(geometry);
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
  }

  /// Reports the visible window to the behaviour's zoom callbacks.
  void _notifyZoom(VarietyCartesianGeometry geometry, {bool start = false}) {
    final VarietyZoomPanBehavior? behavior = widget.zoomPanBehavior;
    if (behavior == null) {
      return;
    }
    final (double, double)? window = _windowFor(
      _baseXMin,
      _baseXMax,
      _xZoomPosition,
      _xZoomFactor,
    );
    final VarietyZoomDetails details = VarietyZoomDetails(
      axis: widget.primaryXAxis,
      minimum: window?.$1 ?? _baseXMin,
      maximum: window?.$2 ?? _baseXMax,
      factor: _xZoomFactor,
    );
    if (start) {
      behavior.onZoomStart?.call(details);
    } else {
      behavior.onZoomEnd?.call(details);
    }
  }

  /// Pans a zoomed axis by a pixel delta, the counterpart of Syncfusion's
  /// `_toPanValue` and `_pan`. [delta] is `previous - current`, so the content
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
    setState(() {
      _xZoomPosition = nextX;
      _yZoomPosition = nextY;
    });
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
      // Syncfusion multiplies the magnification captured when the pinch began
      // by the gesture's scale, which keeps the window stable across frames.
      final double rawScaleX = (_startScaleX ?? 1) *
          (both ? details.scale : details.horizontalScale);
      final double rawScaleY =
          (_startScaleY ?? 1) * (both ? details.scale : details.verticalScale);
      setState(() {
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
      });
      _panStarted = false;
      _gestureChanged = true;
      return;
    }

    if (!behavior.enablePanning) {
      _panStarted = false;
      return;
    }
    _pan(details.localFocalPoint, geometry);
  }

  void _onScaleEnd() {
    final VarietyCartesianGeometry? geometry = _display;
    final bool wasChanged = _gestureChanged;
    _scalePointerCount = 0;
    _panStarted = false;
    _gestureChanged = false;
    _previousPanPosition = Offset.zero;
    if (geometry != null && wasChanged) {
      _notifyZoom(geometry);
    }
  }

  /// Converts the rubber band into a new window, the same way Syncfusion's
  /// `_drawSelectionZoomRect` does. Returns whether anything was zoomed, so a
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
        ),
      );
    }
    final VarietyHitResult? hit = _hit;
    if (hit == null) {
      return const <Widget>[];
    }
    final String header = hit.point.label ?? hit.point.x?.toString() ?? '';
    final String valueText = VarietyTooltipCard.formatValue(hit.point.y);
    if (widget.onTooltipRender != null &&
        !widget.onTooltipRender!(
          VarietyTooltipDetails(hit: hit, header: header, text: valueText),
        )) {
      return const <Widget>[];
    }
    final VarietyTooltipBehavior tooltip = widget.tooltipBehavior;
    final VarietyCrosshairBehavior? cross = widget.crosshairBehavior;
    if (cross != null && cross.enabled && cross.showTooltip) {
      return _positionedCard(
        hit.position,
        VarietyTooltipCard(
          result: hit,
          theme: theme,
          builder: cross.builder,
        ),
      );
    }
    if (!tooltip.enabled) {
      return const <Widget>[];
    }
    return _positionedCard(
      hit.position,
      VarietyTooltipCard(
        result: hit,
        theme: theme,
        builder: tooltip.builder,
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

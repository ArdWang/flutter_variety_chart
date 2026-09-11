import 'dart:math' as math;

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
  final Widget Function(BuildContext context, VarietySeries series, int index)? legendBuilder;

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
  final String? Function(VarietyDataLabelRenderDetails details)? onDataLabelRender;

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
  double? _trackballSlot;
  List<VarietyHitResult> _selected = const <VarietyHitResult>[];
  final Set<int> _hiddenSeries = <int>{};
  final List<VarietyAxisLabelHit> _labelHits = <VarietyAxisLabelHit>[];
  bool _revealed = false;
  (double, double)? _lastPrimaryRange;
  (double, double)? _lastSecondaryRange;

  (double, double)? _zoomX;
  (double, double)? _zoomY;
  VarietyCartesianGeometry? _display;

  double? _scaleStartSpan;
  (double, double)? _scaleStartZoom;
  double? _scaleStartSpanY;
  (double, double)? _scaleStartZoomY;
  Offset _lastFocal = Offset.zero;
  Offset? _selectionStart;
  Rect? _selectionRect;

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
      widget.zoomPanBehavior != null && widget.zoomPanBehavior!.enabled;

  bool get _isRubberBand =>
      _zooming && widget.zoomPanBehavior!.mode == VarietyZoomMode.selection;

  @override
  void initState() {
    super.initState();
    widget.selectionController?.addListener(_syncSelectionFromController);
    _selected = widget.selectionController?.selected ?? const <VarietyHitResult>[];
    _controller = AnimationController(vsync: this, duration: _effectiveAnimationDuration());
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
        final bool bounded = constraints.hasBoundedHeight && constraints.hasBoundedWidth;
        final List<Widget> column = <Widget>[];
        if (widget.title != null && widget.title!.isNotEmpty) {
          column.add(VarietyChartTitle(text: widget.title!, textStyle: widget.titleStyle));
        }
        final bool wantsLegend =
            widget.showLegend && items.any((VarietySeries s) => s.name != null);
        final bool legendOnSide = widget.legendPosition == VarietyLegendPosition.left ||
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
        if (legend != null && widget.legendPosition == VarietyLegendPosition.top) {
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
                  if (widget.legendPosition == VarietyLegendPosition.left) legend,
                  Expanded(child: plot),
                  if (widget.legendPosition == VarietyLegendPosition.right) legend,
                ],
              ),
            ),
          );
        } else {
          column.add(Expanded(child: plot));
        }
        if (legend != null && widget.legendPosition == VarietyLegendPosition.bottom) {
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
        final (VarietyCartesianGeometry base, VarietyCartesianGeometry display) =
            _geometries(size);
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
      final bool zoomEnabled = zoom != null && zoom.enabled;
      final bool doubleTapEnabled = zoomEnabled && zoom.enableDoubleTapZooming;
      return Listener(
          onPointerSignal: _onPointerSignal,
          child: MouseRegion(
            onHover: _onHover,
            onExit: (_) => _clearPointerState(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (TapUpDetails details) => _onTap(details.localPosition, display),
              onLongPressStart: (LongPressStartDetails details) =>
                  _onLongPressStart(details.localPosition, display),
              onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) =>
                  _onLongPressMove(details.localPosition, display),
              onLongPressEnd: (_) => _onLongPressEnd(),
              onDoubleTapDown: doubleTapEnabled
                  ? (TapDownDetails details) =>
                      _onDoubleTap(details.localPosition, base, display)
                  : null,
              onScaleStart:
                  zoomEnabled ? (ScaleStartDetails details) => _onScaleStart(details, base) : null,
              onScaleUpdate: zoomEnabled
                  ? (ScaleUpdateDetails details) => _onScaleUpdate(details, base, display)
                  : null,
              onScaleEnd: zoomEnabled ? (_) => _onScaleEnd() : null,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(child: canvas),
                  // The placeholder must not swallow the gestures that reveal
                  // the series, so it is wrapped in an IgnorePointer.
                  if (!_paintsSeries && widget.loadingBuilder != null)
                    Positioned.fill(
                      child: IgnorePointer(child: widget.loadingBuilder!(context)),
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
      plotRect = Rect.fromLTWH(0, 0, math.max(safe.width, 1), math.max(safe.height, 1));
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
        bottom = math.max(bottom, _rotatedHeight(caption, xStyle, rotation) + 8);
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
        final String caption =
            probe.xAxis.labelFormatter?.call(value) ?? varietyFormatNumber(value);
        bottom = math.max(bottom, _rotatedHeight(caption, xStyle, rotation) + 8);
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
      final TextStyle style =
          axis.labelStyle ?? TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface);
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

  double _axisXFor(Offset position, VarietyCartesianGeometry geometry) {
    final double ratio =
        ((position.dx - geometry.plotRect.left) / math.max(geometry.plotRect.width, 1))
            .clamp(0.0, 1.0);
    return geometry.xMinimum + ratio * (geometry.xMaximum - geometry.xMinimum);
  }

  double _axisYFor(Offset position, VarietyCartesianGeometry geometry) {
    final double ratio =
        ((position.dy - geometry.plotRect.top) / math.max(geometry.plotRect.height, 1))
            .clamp(0.0, 1.0);
    return geometry.yMinimum + ratio * (geometry.yMaximum - geometry.yMinimum);
  }

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
          final List<VarietyHitResult> next = List<VarietyHitResult>.of(_selected);
          if (alreadySelected) {
            next.remove(hit);
          } else {
            next.add(hit);
          }
          _applySelection(next);
        } else {
          _applySelection(
            alreadySelected ? const <VarietyHitResult>[] : <VarietyHitResult>[hit],
          );
        }
      }
    }
    final VarietyTrackballBehavior? ball = widget.trackballBehavior;
    if (ball != null &&
        ball.enabled &&
        ball.activationMode == VarietyActivationMode.tap) {
      _updateTrackball(position, geometry);
      return;
    }
    final VarietyHitResult? hit = geometry.hitTest(position);
    setState(() => _hit = hit);
    widget.onPointTap?.call(hit);
  }

  void _onLongPressStart(Offset position, VarietyCartesianGeometry geometry) {
    _reveal();
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
        geometry.series[s].onPointLongPress?.call(geometry.series[s].data[p.clamp(0, geometry.series[s].data.length - 1)], p);
      }
    }
  }

  void _onLongPressMove(Offset position, VarietyCartesianGeometry geometry) {
    final VarietyTrackballBehavior? ball = widget.trackballBehavior;
    if (ball != null && ball.enabled && _trackballHits.isNotEmpty) {
      _updateTrackball(position, geometry);
      return;
    }
    _updateSingleHit(geometry.hitTest(position), hover: true);
  }

  void _onLongPressEnd() {
    if (!widget.tooltipBehavior.enabled && _trackballHits.isEmpty) {
      setState(() => _hit = null);
    }
  }

  void _clearPointerState() {
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

  void _updateTrackball(Offset position, VarietyCartesianGeometry geometry) {
    final List<VarietyHitResult> hits = geometry.hitsAtSlot(position);
    if (hits.isEmpty) {
      if (_trackballHits.isEmpty) {
        return;
      }
      setState(() {
        _trackballHits = const <VarietyHitResult>[];
        _trackballSlot = null;
      });
      return;
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
        !behavior.enabled ||
        !behavior.enableMouseWheelZooming ||
        event is! PointerScrollEvent) {
      return;
    }
    final VarietyCartesianGeometry? geometry = _display;
    if (geometry == null) {
      return;
    }
    final bool zoomIn = event.scrollDelta.dy < 0;
    _applyZoom(
      geometry,
      zoomIn ? 0.75 : 1.33,
      event.localPosition,
    );
  }

  void _onDoubleTap(
    Offset position,
    VarietyCartesianGeometry base,
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
    if (_zoomX != null || _zoomY != null) {
      setState(() {
        _zoomX = null;
        _zoomY = null;
      });
      widget.zoomPanBehavior?.onZoomEnd?.call(
        VarietyZoomDetails(
          axis: widget.primaryXAxis,
          minimum: base.xMinimum,
          maximum: base.xMaximum,
          factor: 1,
        ),
      );
      return;
    }
    _applyZoom(display, 0.5, position);
  }

  void _applyZoom(
    VarietyCartesianGeometry geometry,
    double factor,
    Offset focal,
  ) {
    final VarietyZoomPanBehavior behavior = widget.zoomPanBehavior!;
    final double baseMin = geometry.xMinimum;
    final double baseMax = geometry.xMaximum;
    final double baseSpan = math.max(baseMax - baseMin, 1e-9);
    final double currentMin = _zoomX?.$1 ?? baseMin;
    final double currentMax = _zoomX?.$2 ?? baseMax;
    final double currentSpan = currentMax - currentMin;
    final double targetSpan =
        (currentSpan * factor).clamp(baseSpan * behavior.minimumZoomLevel, baseSpan * behavior.maximumZoomLevel);
    final double anchor = _axisXFor(focal, geometry);
    final double ratio =
        currentSpan <= 0 ? 0.5 : ((anchor - currentMin) / currentSpan).clamp(0.0, 1.0);
    if (behavior.axisMode != VarietyZoomAxisMode.x) {
      _zoomSecondary(factor, geometry);
    }
    double newMin = anchor - targetSpan * ratio;
    double newMax = newMin + targetSpan;
    if (newMin < baseMin) {
      newMin = baseMin;
      newMax = baseMin + targetSpan;
    }
    if (newMax > baseMax) {
      newMax = baseMax;
      newMin = baseMax - targetSpan;
    }
    setState(() {
      if (targetSpan >= baseSpan * 0.999) {
        _zoomX = null;
      } else {
        _zoomX = (newMin, newMax);
      }
    });
    behavior.onZoomEnd?.call(
      VarietyZoomDetails(
        axis: widget.primaryXAxis,
        minimum: newMin,
        maximum: newMax,
        factor: targetSpan / baseSpan,
      ),
    );
  }

  /// Applies the same zoom factor to the secondary axis.
  void _zoomSecondary(double factor, VarietyCartesianGeometry geometry) {
    final double baseMin = geometry.yMinimum;
    final double baseMax = geometry.yMaximum;
    final double baseSpan = math.max(baseMax - baseMin, 1e-9);
    final double currentMin = _zoomY?.$1 ?? baseMin;
    final double currentMax = _zoomY?.$2 ?? baseMax;
    final double span = math.max(currentMax - currentMin, 1e-9);
    final double target = (span * factor).clamp(baseSpan * 0.02, baseSpan);
    final double center = (currentMin + currentMax) / 2;
    double newMin = center - target / 2;
    double newMax = center + target / 2;
    if (newMin < baseMin) {
      newMin = baseMin;
      newMax = baseMin + target;
    }
    if (newMax > baseMax) {
      newMax = baseMax;
      newMin = baseMax - target;
    }
    setState(() => _zoomY = target >= baseSpan * 0.999 ? null : (newMin, newMax));
  }

  void _onScaleStart(ScaleStartDetails details, VarietyCartesianGeometry base) {
    _lastFocal = details.localFocalPoint;
    final double baseSpan = base.xMaximum - base.xMinimum;
    _scaleStartSpan = _zoomX == null ? baseSpan : _zoomX!.$2 - _zoomX!.$1;
    _scaleStartZoom = _zoomX;
    final double baseSpanY = base.yMaximum - base.yMinimum;
    _scaleStartSpanY = _zoomY == null ? baseSpanY : _zoomY!.$2 - _zoomY!.$1;
    _scaleStartZoomY = _zoomY;
    if (_isRubberBand && details.pointerCount == 1) {
      _selectionStart = details.localFocalPoint;
      setState(() => _selectionRect = null);
    }
  }

  void _onScaleUpdate(
    ScaleUpdateDetails details,
    VarietyCartesianGeometry base,
    VarietyCartesianGeometry display,
  ) {
    final VarietyZoomPanBehavior behavior = widget.zoomPanBehavior!;
    if (_isRubberBand) {
      final Offset? start = _selectionStart;
      if (start != null) {
        setState(() {
          _selectionRect = Rect.fromPoints(start, details.localFocalPoint);
        });
      }
      return;
    }
    if (details.pointerCount >= 2 && behavior.enablePinchZooming) {
      final double baseSpan = base.xMaximum - base.xMinimum;
      final double startSpan = _scaleStartSpan ?? baseSpan;
      final double targetSpan = (startSpan / math.max(details.scale, 1e-3)).clamp(
        baseSpan * behavior.minimumZoomLevel,
        baseSpan * behavior.maximumZoomLevel,
      );
      final double anchor = _axisXFor(details.localFocalPoint, display);
      final (double, double) startZoom =
          _scaleStartZoom ?? (base.xMinimum, base.xMaximum);
      final double ratio = startSpan <= 0
          ? 0.5
          : ((anchor - startZoom.$1) / startSpan).clamp(0.0, 1.0);
      double newMin = anchor - targetSpan * ratio;
      double newMax = newMin + targetSpan;
      if (newMin < base.xMinimum) {
        newMin = base.xMinimum;
        newMax = base.xMinimum + targetSpan;
      }
      if (newMax > base.xMaximum) {
        newMax = base.xMaximum;
        newMin = base.xMaximum - targetSpan;
      }
      // The secondary axis zooms around the same focal point so a pinch
      // scales both axes at once, mirroring the primary-axis maths.
      (double, double)? nextY;
      if (behavior.axisMode != VarietyZoomAxisMode.x) {
        final double baseSpanY = math.max(base.yMaximum - base.yMinimum, 1e-9);
        final double startSpanY = _scaleStartSpanY ?? baseSpanY;
        final double targetSpanY =
            (startSpanY / math.max(details.scale, 1e-3)).clamp(
          baseSpanY * behavior.minimumZoomLevel,
          baseSpanY * behavior.maximumZoomLevel,
        );
        final double anchorY = _axisYFor(details.localFocalPoint, display);
        final (double, double) startZoomY =
            _scaleStartZoomY ?? (base.yMinimum, base.yMaximum);
        final double ratioY = startSpanY <= 0
            ? 0.5
            : ((anchorY - startZoomY.$1) / startSpanY).clamp(0.0, 1.0);
        double newMinY = anchorY - targetSpanY * ratioY;
        double newMaxY = newMinY + targetSpanY;
        if (newMinY < base.yMinimum) {
          newMinY = base.yMinimum;
          newMaxY = base.yMinimum + targetSpanY;
        }
        if (newMaxY > base.yMaximum) {
          newMaxY = base.yMaximum;
          newMinY = base.yMaximum - targetSpanY;
        }
        nextY = targetSpanY >= baseSpanY * 0.999 ? null : (newMinY, newMaxY);
      }
      setState(() {
        _zoomX = targetSpan >= baseSpan * 0.999 ? null : (newMin, newMax);
        if (behavior.axisMode != VarietyZoomAxisMode.x) {
          _zoomY = nextY;
        }
      });
      _lastFocal = details.localFocalPoint;
      return;
    }
    if (!behavior.enablePanning) {
      _lastFocal = details.localFocalPoint;
      return;
    }
    final Offset delta = details.localFocalPoint - _lastFocal;
    _lastFocal = details.localFocalPoint;
    if (delta == Offset.zero) {
      return;
    }
    (double, double)? nextX;
    if (_zoomX != null) {
      final double baseSpan = base.xMaximum - base.xMinimum;
      final double span = _zoomX!.$2 - _zoomX!.$1;
      if (span < baseSpan * 0.999) {
        final double shift = -delta.dx / math.max(display.plotRect.width, 1) * span;
        double newMin = _zoomX!.$1 + shift;
        double newMax = _zoomX!.$2 + shift;
        if (newMin < base.xMinimum) {
          newMin = base.xMinimum;
          newMax = newMin + span;
        }
        if (newMax > base.xMaximum) {
          newMax = base.xMaximum;
          newMin = newMax - span;
        }
        nextX = (newMin, newMax);
      }
    }
    (double, double)? nextY;
    if (_zoomY != null && behavior.axisMode != VarietyZoomAxisMode.x) {
      final double baseSpanY = base.yMaximum - base.yMinimum;
      final double spanY = _zoomY!.$2 - _zoomY!.$1;
      if (spanY < baseSpanY * 0.999) {
        final double shiftY =
            -delta.dy / math.max(display.plotRect.height, 1) * spanY;
        double newMinY = _zoomY!.$1 + shiftY;
        double newMaxY = _zoomY!.$2 + shiftY;
        if (newMinY < base.yMinimum) {
          newMinY = base.yMinimum;
          newMaxY = newMinY + spanY;
        }
        if (newMaxY > base.yMaximum) {
          newMaxY = base.yMaximum;
          newMinY = newMaxY - spanY;
        }
        nextY = (newMinY, newMaxY);
      }
    }
    if (nextX == null && nextY == null) {
      return;
    }
    setState(() {
      if (nextX != null) {
        _zoomX = nextX;
      }
      if (nextY != null) {
        _zoomY = nextY;
      }
    });
  }

  void _onScaleEnd() {
    final Rect? rect = _selectionRect;
    final VarietyCartesianGeometry? display = _display;
    _selectionStart = null;
    if (rect == null || display == null || rect.width < 12) {
      setState(() => _selectionRect = null);
      return;
    }
    final double left = _axisXFor(Offset(rect.left, 0), display);
    final double right = _axisXFor(Offset(rect.right, 0), display);
    setState(() {
      _selectionRect = null;
      _zoomX = (math.min(left, right), math.max(left, right));
    });
  }

  // ---------------------------------------------------------------------------
  // Tooltip overlay
  // ---------------------------------------------------------------------------

  List<Widget> _overlayWidgets(VarietyChartTheme theme) {
    final bool hasTrackball = _trackballHits.isNotEmpty && _trackballSlot != null;
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

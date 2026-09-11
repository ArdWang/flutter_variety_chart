import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/variety_spark.dart';
import '../painters/variety_spark_painter.dart';
import '../render/variety_chart_theme.dart';

/// Shared behaviour for the four spark chart widgets.
///
/// A spark chart is a compact, axis free chart. Every widget in this family
/// fills the box it is given, so wrap it in a [SizedBox] with an explicit
/// height.
abstract class VarietySparkChart extends StatefulWidget {
  /// Creates a spark chart.
  const VarietySparkChart({
    super.key,
    required this.data,
    this.plotBand,
    this.color,
    this.strokeWidth = 2,
    this.dashArray,
    this.borderWidth = 0,
    this.borderColor,
    this.isInversed = false,
    this.axisCrossesAt = 0,
    this.axisLineColor,
    this.axisLineWidth = 2,
    this.axisLineDashArray,
    this.highPointColor,
    this.lowPointColor,
    this.negativePointColor,
    this.firstPointColor,
    this.lastPointColor,
    this.tiePointColor,
    this.marker,
    this.labelDisplayMode,
    this.labelStyle,
    this.trackball,
    this.animationDuration = const Duration(milliseconds: 600),
    this.enableAnimation = true,
  });

  /// The values plotted by the chart.
  final List<double> data;

  /// An optional shaded value range.
  final VarietySparkPlotBand? plotBand;

  /// The base series colour.
  final Color? color;

  /// The stroke thickness of a line.
  final double strokeWidth;

  /// A dash pattern applied to the line.
  final List<double>? dashArray;

  /// The outline thickness of an area or bar.
  final double borderWidth;

  /// The outline colour of an area or bar.
  final Color? borderColor;

  /// Whether the value axis runs from high to low.
  final bool isInversed;

  /// The value the axis line is drawn at.
  final double axisCrossesAt;

  /// The colour of the axis line.
  final Color? axisLineColor;

  /// The thickness of the axis line.
  final double axisLineWidth;

  /// A dash pattern applied to the axis line.
  final List<double>? axisLineDashArray;

  /// The colour of the highest point.
  final Color? highPointColor;

  /// The colour of the lowest point.
  final Color? lowPointColor;

  /// The colour of a point whose value is below zero.
  final Color? negativePointColor;

  /// The colour of the first point.
  final Color? firstPointColor;

  /// The colour of the last point.
  final Color? lastPointColor;

  /// The colour of a win/loss bar whose value is exactly zero.
  final Color? tiePointColor;

  /// The marker configuration.
  final VarietySparkMarker? marker;

  /// Which points carry a data label.
  final VarietySparkLabelDisplayMode? labelDisplayMode;

  /// The text style of the data labels.
  final TextStyle? labelStyle;

  /// The trackball configuration.
  final VarietySparkTrackball? trackball;

  /// How long the entrance animation runs.
  final Duration animationDuration;

  /// Whether the entrance animation is played.
  final bool enableAnimation;

  /// The shape this widget draws.
  VarietySparkSeriesType get seriesType;

  @override
  State<VarietySparkChart> createState() => _VarietySparkChartState();
}

class _VarietySparkChartState extends State<VarietySparkChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _trackballIndex;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.animationDuration);
    if (widget.enableAnimation) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant VarietySparkChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.animationDuration != widget.animationDuration) {
      _cancelHide();
      _trackballIndex = null;
      if (widget.enableAnimation) {
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
    _cancelHide();
    _controller.dispose();
    super.dispose();
  }

  void _cancelHide() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void _scheduleHide() {
    final VarietySparkTrackball? config = widget.trackball;
    if (config == null || config.shouldAlwaysShow) {
      return;
    }
    _cancelHide();
    final int delay = config.hideDelay.round();
    if (delay <= 0) {
      return;
    }
    _hideTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) {
        return;
      }
      setState(() => _trackballIndex = null);
    });
  }

  void _activate(Offset position, Size size) {
    final VarietySparkTrackball? config = widget.trackball;
    if (config == null || widget.data.isEmpty) {
      return;
    }
    _cancelHide();
    final int index = _indexFor(position, size);
    if (index != _trackballIndex) {
      setState(() => _trackballIndex = index);
    }
    if (config.activationMode != VarietySparkActivationMode.longPress) {
      _scheduleHide();
    }
  }

  int _indexFor(Offset position, Size size) {
    final int count = widget.data.length;
    if (count <= 1) {
      return 0;
    }
    final bool band = widget.seriesType == VarietySparkSeriesType.bar ||
        widget.seriesType == VarietySparkSeriesType.winLoss;
    double ratio;
    if (band) {
      ratio = position.dx / math.max(size.width, 1);
    } else {
      ratio = position.dx / math.max(size.width, 1);
    }
    return (ratio * count).floor().clamp(0, count - 1);
  }

  void _release() {
    if (widget.trackball == null) {
      return;
    }
    if (!widget.trackball!.shouldAlwaysShow) {
      _scheduleHide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final VarietyChartTheme theme = VarietyChartTheme.of(context);
    final VarietySparkTrackball? ball = widget.trackball;
    final VarietySparkActivationMode? activation = ball?.activationMode;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // The reference widget can size itself: an unbounded axis falls back to
        // a 16:9 box, or to 480 x 270 when both axes are unbounded.
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;
        final double width = maxWidth.isFinite
            ? maxWidth
            : (maxHeight.isFinite ? maxHeight / 9 * 16 : 480);
        final double height = maxHeight.isFinite
            ? maxHeight
            : (maxWidth.isFinite ? maxWidth / 16 * 9 : 270);
        final Size size = Size(math.max(width, 1), math.max(height, 1));
        // `isInversed` mirrors the series horizontally, so the points are
        // reversed before they reach the painter.
        final List<double> values = widget.isInversed
            ? widget.data.reversed.toList(growable: false)
            : widget.data;
        return MouseRegion(
            onExit: (_) => _release(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: activation == VarietySparkActivationMode.tap
                  ? (TapUpDetails details) => _activate(details.localPosition, size)
                  : null,
              onTapDown: activation == VarietySparkActivationMode.doubleTap
                  ? (_) => _cancelHide()
                  : null,
              onDoubleTapDown: activation == VarietySparkActivationMode.doubleTap
                  ? (TapDownDetails details) => _activate(details.localPosition, size)
                  : null,
              onLongPressStart: activation == VarietySparkActivationMode.longPress
                  ? (LongPressStartDetails details) =>
                      _activate(details.localPosition, size)
                  : null,
              onLongPressMoveUpdate:
                  activation == VarietySparkActivationMode.longPress
                      ? (LongPressMoveUpdateDetails details) =>
                          _activate(details.localPosition, size)
                      : null,
              onLongPressEnd:
                  activation == VarietySparkActivationMode.longPress
                      ? (_) => _release()
                      : null,
              child: SizedBox(
                width: width,
                height: height,
                child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) => CustomPaint(
                  size: size,
                  painter: VarietySparkPainter(
                    data: values,
                    seriesType: widget.seriesType,
                    theme: theme,
                    progress: widget.enableAnimation ? _controller.value : 1,
                    color: widget.color ?? Theme.of(context).colorScheme.primary,
                    strokeWidth: widget.strokeWidth,
                    dashArray: widget.dashArray,
                    borderWidth: widget.borderWidth,
                    borderColor: widget.borderColor,
                    axisCrossesAt: widget.axisCrossesAt,
                    axisLineColor: widget.axisLineColor,
                    axisLineWidth: widget.axisLineWidth,
                    axisLineDashArray: widget.axisLineDashArray,
                    highPointColor: widget.highPointColor,
                    lowPointColor: widget.lowPointColor,
                    negativePointColor: widget.negativePointColor,
                    firstPointColor: widget.firstPointColor,
                    lastPointColor: widget.lastPointColor,
                    tiePointColor: widget.tiePointColor,
                    plotBand: widget.plotBand,
                    marker: widget.marker,
                    labelDisplayMode: widget.labelDisplayMode,
                    labelStyle: widget.labelStyle,
                    trackball: widget.trackball,
                    trackballIndex: _trackballIndex,
                  ),
                ),
              ),
              ),
            ),
          );
      },
    );
  }
}

/// A spark chart that strokes a line through the values.
class VarietySparkLineChart extends VarietySparkChart {
  /// Creates a line spark chart.
  const VarietySparkLineChart({
    super.key,
    required super.data,
    super.plotBand,
    super.color,
    super.strokeWidth = 2,
    super.dashArray,
    super.isInversed = false,
    super.axisCrossesAt = 0,
    super.axisLineColor,
    super.axisLineWidth = 2,
    super.axisLineDashArray,
    super.highPointColor,
    super.lowPointColor,
    super.negativePointColor,
    super.firstPointColor,
    super.lastPointColor,
    super.marker,
    super.labelDisplayMode,
    super.labelStyle,
    super.trackball,
    super.animationDuration,
    super.enableAnimation,
  });

  @override
  VarietySparkSeriesType get seriesType => VarietySparkSeriesType.line;
}

/// A spark chart that fills the region below the line.
class VarietySparkAreaChart extends VarietySparkChart {
  /// Creates an area spark chart.
  const VarietySparkAreaChart({
    super.key,
    required super.data,
    super.plotBand,
    super.color,
    super.strokeWidth = 2,
    super.borderWidth = 0,
    super.borderColor,
    super.isInversed = false,
    super.axisCrossesAt = 0,
    super.axisLineColor,
    super.axisLineWidth = 2,
    super.axisLineDashArray,
    super.highPointColor,
    super.lowPointColor,
    super.negativePointColor,
    super.firstPointColor,
    super.lastPointColor,
    super.marker,
    super.labelDisplayMode,
    super.labelStyle,
    super.trackball,
    super.animationDuration,
    super.enableAnimation,
  });

  @override
  VarietySparkSeriesType get seriesType => VarietySparkSeriesType.area;
}

/// A spark chart that draws one column per value.
class VarietySparkBarChart extends VarietySparkChart {
  /// Creates a bar spark chart.
  const VarietySparkBarChart({
    super.key,
    required super.data,
    super.plotBand,
    super.color,
    super.borderWidth = 0,
    super.borderColor,
    super.isInversed = false,
    super.axisCrossesAt = 0,
    super.axisLineColor,
    super.axisLineWidth = 2,
    super.axisLineDashArray,
    super.highPointColor,
    super.lowPointColor,
    super.negativePointColor,
    super.firstPointColor,
    super.lastPointColor,
    super.labelDisplayMode,
    super.labelStyle,
    super.trackball,
    super.animationDuration,
    super.enableAnimation,
  });

  @override
  VarietySparkSeriesType get seriesType => VarietySparkSeriesType.bar;
}

/// A spark chart whose bars point up or down according to the sign.
class VarietySparkWinLossChart extends VarietySparkChart {
  /// Creates a win/loss spark chart.
  const VarietySparkWinLossChart({
    super.key,
    required super.data,
    super.plotBand,
    super.color,
    super.borderWidth = 0,
    super.borderColor,
    super.tiePointColor,
    super.isInversed = false,
    super.axisCrossesAt = 0,
    super.axisLineColor,
    super.axisLineWidth = 2,
    super.axisLineDashArray,
    super.highPointColor,
    super.lowPointColor,
    super.negativePointColor,
    super.firstPointColor,
    super.lastPointColor,
    super.labelDisplayMode,
    super.labelStyle,
    super.trackball,
    super.animationDuration,
    super.enableAnimation,
  });

  @override
  VarietySparkSeriesType get seriesType => VarietySparkSeriesType.winLoss;
}

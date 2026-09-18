import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../behaviors/variety_behaviors.dart';
import '../models/variety_enums.dart';
import '../models/variety_series.dart';
import '../painters/variety_funnel_painter.dart';
import '../render/variety_chart_theme.dart';
import '../render/variety_geometry.dart';
import 'variety_chart_title.dart';
import 'variety_legend.dart';
import 'variety_tooltip.dart';

/// Renders a [VarietyFunnelSeries] or a [VarietyPyramidSeries].
///
/// The widget fills the box it is given, so place it inside a widget that
/// provides a bounded size such as [SizedBox], [Expanded] or [AspectRatio].
class VarietyFunnelChart extends StatefulWidget {
  /// Creates a funnel or pyramid chart from a single [series].
  const VarietyFunnelChart({
    super.key,
    required this.series,
    this.title,
    this.titleStyle,
    this.showLegend = false,
    this.legendPosition = VarietyLegendPosition.bottom,
    this.legendTextStyle,
    this.legendBuilder,
    this.enableTooltip = true,
    this.tooltipBuilder,
    this.tooltipBehavior = const VarietyTooltipBehavior(),
    this.animationDuration = const Duration(milliseconds: 800),
    this.enableAnimation = true,
    this.padding = const EdgeInsets.fromLTRB(24, 12, 24, 12),
    this.onPointTap,
  });

  /// The funnel or pyramid series to render.
  final VarietySeries series;

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

  /// Whether the tooltip reacts to pointer input.
  final bool enableTooltip;

  /// Builds a custom tooltip body.
  final Widget Function(BuildContext context, VarietyHitResult result)?
      tooltipBuilder;

  /// Styling for the tooltip card. [enableTooltip] is the on/off switch;
  /// this covers the fill, border, opacity, marker dot, value formatting and
  /// a body builder of its own.
  final VarietyTooltipBehavior tooltipBehavior;

  /// How long the entrance animation runs.
  final Duration animationDuration;

  /// Whether the entrance animation is played.
  final bool enableAnimation;

  /// Padding reserved around the funnel.
  final EdgeInsets padding;

  /// Called when a segment is tapped. Receives `null` when the tap misses.
  final ValueChanged<VarietyHitResult?>? onPointTap;

  @override
  State<VarietyFunnelChart> createState() => VarietyFunnelChartState();
}

/// The state of a [VarietyFunnelChart], which also exposes [toImage].
class VarietyFunnelChartState extends State<VarietyFunnelChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  VarietyHitResult? _hit;

  bool get _isPyramid => widget.series is VarietyPyramidSeries;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.animationDuration);
    if (widget.enableAnimation) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant VarietyFunnelChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series != widget.series && widget.enableAnimation) {
      _hit = null;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            widget.showLegend && widget.series.name != null;
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
                series: <VarietySeries>[widget.series],
                position: legendPosition,
                textStyle: widget.legendTextStyle,
                itemBuilder: widget.legendBuilder,
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

  Widget _buildPlot(VarietyChartTheme theme) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        final Rect plotRect = Rect.fromLTWH(
          widget.padding.left,
          widget.padding.top,
          math.max(size.width - widget.padding.horizontal, 1),
          math.max(size.height - widget.padding.vertical, 1),
        );
        final VarietyFunnelGeometry geometry = VarietyFunnelGeometry(
          series: widget.series,
          plotRect: plotRect,
          progress: _progress,
          isPyramid: _isPyramid,
        );
        return MouseRegion(
          onHover: (PointerHoverEvent event) =>
              _update(geometry.hitTest(event.localPosition)),
          onExit: (_) => _update(null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (TapUpDetails details) {
              final VarietyHitResult? hit =
                  geometry.hitTest(details.localPosition);
              setState(() => _hit = hit);
              widget.onPointTap?.call(hit);
            },
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: CustomPaint(
                    size: size,
                    painter: VarietyFunnelPainter(
                      geometry: geometry,
                      theme: theme,
                      highlights: _hit == null
                          ? const <VarietyHitResult>[]
                          : <VarietyHitResult>[_hit!],
                    ),
                  ),
                ),
                if (_hit != null &&
                    widget.enableTooltip &&
                    widget.tooltipBehavior.enabled)
                  ..._overlay(theme, _hit!),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _overlay(VarietyChartTheme theme, VarietyHitResult hit) {
    return <Widget>[
      Positioned.fill(
        child: IgnorePointer(
          child: VarietyAnchoredCard(
            anchor: hit.position,
            child: VarietyTooltipCard(
              result: hit,
              theme: theme,
              builder: widget.tooltipBuilder,
              behavior: widget.tooltipBehavior,
              constraints: const BoxConstraints(maxWidth: 200),
            ),
          ),
        ),
      ),
    ];
  }

  void _update(VarietyHitResult? result) {
    if (!widget.enableTooltip && widget.tooltipBehavior.enabled) {
      return;
    }
    if (_hit == result) {
      return;
    }
    setState(() => _hit = result);
  }
}

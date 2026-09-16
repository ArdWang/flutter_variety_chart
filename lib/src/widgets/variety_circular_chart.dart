import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../behaviors/variety_behaviors.dart';
import '../models/variety_enums.dart';
import '../models/variety_series.dart';
import '../painters/variety_circular_painter.dart';
import '../render/variety_chart_theme.dart';
import '../render/variety_geometry.dart';
import 'variety_chart_title.dart';
import 'variety_legend.dart';
import 'variety_tooltip.dart';

/// A circular chart that renders pie and doughnut series.
///
/// The widget fills the box it is given, so place it inside a widget that
/// provides a bounded size such as [SizedBox], [Expanded] or [AspectRatio].
class VarietyCircularChart extends StatefulWidget {
  /// Creates a circular chart from the supplied [series].
  const VarietyCircularChart({
    super.key,
    required this.series,
    this.title,
    this.titleStyle,
    this.showLegend = true,
    this.legendPosition = VarietyLegendPosition.right,
    this.legendTextStyle,
    this.legendBuilder,
    this.enableTooltip = true,
    this.tooltipBuilder,
    this.tooltipBehavior = const VarietyTooltipBehavior(),
    this.animationDuration = const Duration(milliseconds: 800),
    this.enableAnimation = true,
    this.padding = const EdgeInsets.all(20),
    this.center,
  });

  /// The pie or doughnut series plotted by the chart.
  final List<VarietySeries> series;

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

  /// Padding reserved around the circle.
  final EdgeInsets padding;

  /// An optional widget rendered inside a doughnut hole.
  final Widget? center;

  @override
  State<VarietyCircularChart> createState() => _VarietyCircularChartState();
}

class _VarietyCircularChartState extends State<VarietyCircularChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  VarietyHitResult? _hit;

  List<VarietySeries> get _circular => widget.series
      .where((VarietySeries item) => item.isCircular)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.animationDuration);
    if (widget.enableAnimation && _circular.isNotEmpty) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant VarietyCircularChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series != widget.series ||
        oldWidget.animationDuration != widget.animationDuration) {
      _hit = null;
      if (widget.enableAnimation && _circular.isNotEmpty) {
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
    _controller.dispose();
    super.dispose();
  }

  double get _progress => widget.enableAnimation ? _controller.value : 1.0;

  @override
  Widget build(BuildContext context) {
    final VarietyChartTheme theme = VarietyChartTheme.of(context);
    final List<VarietySeries> items = _circular;
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
                series: items,
                position: widget.legendPosition,
                textStyle: widget.legendTextStyle,
                itemBuilder: widget.legendBuilder,
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
        final double radius = math.max(
          math.min(size.width, size.height) / 2 -
              math.max(widget.padding.horizontal, widget.padding.vertical) / 2,
          1,
        );
        final VarietyCircularGeometry geometry = VarietyCircularGeometry(
          series: _circular,
          center: size.center(Offset.zero),
          maxRadius: radius,
          progress: _progress,
        );
        final Widget canvas = CustomPaint(
          size: size,
          painter: VarietyCircularPainter(geometry: geometry, theme: theme),
        );
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: MouseRegion(
                onHover: (PointerHoverEvent event) => _updateHit(
                  geometry.hitTest(event.localPosition),
                ),
                onExit: (_) => _updateHit(null),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (TapUpDetails details) => _handleTap(
                    geometry.hitTest(details.localPosition),
                  ),
                  child: canvas,
                ),
              ),
            ),
            if (widget.center != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: SizedBox(
                      width: radius * 1.1,
                      height: radius * 1.1,
                      child: Center(child: widget.center),
                    ),
                  ),
                ),
              ),
            if (_hit != null &&
                widget.enableTooltip &&
                widget.tooltipBehavior.enabled)
              ..._overlay(theme),
          ],
        );
      },
    );
  }

  List<Widget> _overlay(VarietyChartTheme theme) {
    final VarietyHitResult hit = _hit!;
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

  void _handleTap(VarietyHitResult? result) {
    setState(() => _hit = result);
  }

  void _updateHit(VarietyHitResult? result) {
    if (!widget.enableTooltip && widget.tooltipBehavior.enabled) {
      return;
    }
    final bool changed = (_hit == null) != (result == null) ||
        _hit?.seriesIndex != result?.seriesIndex ||
        _hit?.pointIndex != result?.pointIndex;
    if (!changed) {
      return;
    }
    setState(() => _hit = result);
  }
}

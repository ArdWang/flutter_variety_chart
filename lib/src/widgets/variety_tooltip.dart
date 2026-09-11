import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/variety_chart_data.dart';
import '../models/variety_series.dart';
import '../render/variety_chart_theme.dart';
import '../render/variety_geometry.dart';

/// The card shown next to the pointer when a single data point is highlighted.
class VarietyTooltipCard extends StatelessWidget {
  /// Creates a tooltip card for [result].
  const VarietyTooltipCard({
    super.key,
    required this.result,
    required this.theme,
    this.builder,
    this.constraints = const BoxConstraints(maxWidth: 220),
  });

  /// The highlighted point.
  final VarietyHitResult result;

  /// The resolved chart colours.
  final VarietyChartTheme theme;

  /// Builds a fully custom tooltip body.
  final Widget Function(BuildContext context, VarietyHitResult result)? builder;

  /// Constraints applied to the card.
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final Widget body = builder?.call(context, result) ?? _defaultBody(context);
    return ConstrainedBox(
      constraints: constraints,
      child: Material(
        color: theme.tooltipBackgroundColor,
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: body,
        ),
      ),
    );
  }

  Widget _defaultBody(BuildContext context) {
    final VarietyChartData point = result.point;
    final Color color = point.color ??
        result.series.color ??
        Theme.of(context).colorScheme.primary;
    final String? caption = point.label ?? point.x?.toString();
    final List<Widget> lines = <Widget>[];
    if (result.series.name != null) {
      lines.add(
        Text(
          result.series.name!,
          style: TextStyle(
            color: theme.tooltipTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (caption != null && caption != result.series.name) {
      lines.add(
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            caption,
            style: TextStyle(
              color: theme.tooltipTextColor.withValues(alpha: 0.75),
              fontSize: 11,
            ),
          ),
        ),
      );
    }
    lines.add(_valueRow(context, color, point));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }

  Widget _valueRow(BuildContext context, Color color, VarietyChartData point) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            formatValue(point.y),
            style: TextStyle(
              color: theme.tooltipTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a tooltip value, dropping the decimals of whole numbers.
  static String formatValue(double? value) {
    if (value == null) {
      return '-';
    }
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}

/// The shared card shown by a trackball for every series at one primary index.
class VarietyTrackballTooltipCard extends StatelessWidget {
  /// Creates a multi-series tooltip card.
  const VarietyTrackballTooltipCard({
    super.key,
    required this.results,
    required this.theme,
    this.builder,
    this.constraints = const BoxConstraints(maxWidth: 240),
  });

  /// Every series reading at the active primary-axis slot.
  final List<VarietyHitResult> results;

  /// The resolved chart colours.
  final VarietyChartTheme theme;

  /// Builds a fully custom tooltip body.
  final Widget Function(BuildContext context, List<VarietyHitResult> results)? builder;

  /// Constraints applied to the card.
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final Widget body = builder?.call(context, results) ?? _defaultBody(context);
    return ConstrainedBox(
      constraints: constraints,
      child: Material(
        color: theme.tooltipBackgroundColor,
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: body,
        ),
      ),
    );
  }

  Widget _defaultBody(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    if (results.isNotEmpty) {
      final VarietyChartData first = results.first.point;
      final String? caption = first.label ?? first.x?.toString();
      if (caption != null && caption.isNotEmpty) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              caption,
              style: TextStyle(
                color: theme.tooltipTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    }
    for (final VarietyHitResult result in results) {
      final Color color = result.point.color ??
          result.series.color ??
          varietyDefaultPalette[result.seriesIndex % varietyDefaultPalette.length];
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                result.series.name ?? 'Series ${result.seriesIndex + 1}',
                style: TextStyle(
                  color: theme.tooltipTextColor.withValues(alpha: 0.85),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                VarietyTooltipCard.formatValue(result.point.y),
                style: TextStyle(
                  color: theme.tooltipTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}

/// Pins a tooltip card next to a data point.
///
/// The widget fills its parent — place it inside a [Positioned.fill] within
/// the chart's [Stack] — and lays [child] out at its natural size before
/// placing it relative to [anchor]:
///
/// * Horizontally the card is centred on the anchor, clamped to the parent
///   bounds.
/// * Vertically the card sits above the anchor, leaving a [gap] between the
///   point and the card. When there is no room above, the card flips below
///   the anchor instead.
///
/// Placing with the measured card size — rather than a guessed one — keeps
/// the card glued to the point even next to the plot edges, where a
/// pre-computed flip would otherwise detach it.
class VarietyAnchoredCard extends SingleChildRenderObjectWidget {
  /// Creates a card anchored to a data point.
  const VarietyAnchoredCard({
    super.key,
    required this.anchor,
    this.gap = 7.0,
    super.child,
  });

  /// The point, in this widget's coordinate space, the card clings to.
  final Offset anchor;

  /// The clearance kept between the anchor and the card.
  final double gap;

  @override
  RenderVarietyAnchoredCard createRenderObject(BuildContext context) {
    return RenderVarietyAnchoredCard()
      ..anchor = anchor
      ..gap = gap;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderVarietyAnchoredCard renderObject,
  ) {
    renderObject
      ..anchor = anchor
      ..gap = gap;
  }
}

/// The render object behind [VarietyAnchoredCard].
///
/// It sizes itself to the chart area, lays the card out at its natural size
/// and keeps the resulting placement for [paint], [hitTestChildren] and
/// [applyPaintTransform].
class RenderVarietyAnchoredCard extends RenderProxyBox {
  Offset _anchor = Offset.zero;

  set anchor(Offset value) {
    if (_anchor == value) {
      return;
    }
    _anchor = value;
    markNeedsLayout();
  }

  double _gap = 7.0;

  set gap(double value) {
    if (_gap == value) {
      return;
    }
    _gap = value;
    markNeedsLayout();
  }

  Offset _childOffset = Offset.zero;

  @override
  void performLayout() {
    size = constraints.biggest;
    final RenderBox? child = this.child;
    if (child == null) {
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    final Size cardSize = child.size;
    double left = _anchor.dx - cardSize.width / 2;
    left = left.clamp(0.0, math.max(size.width - cardSize.width, 0.0));
    final bool roomAbove = _anchor.dy - cardSize.height - _gap >= 0;
    double top = roomAbove
        ? _anchor.dy - cardSize.height - _gap
        : _anchor.dy + _gap;
    if (top + cardSize.height > size.height) {
      top = math.max(size.height - cardSize.height, 0.0);
    }
    _childOffset = Offset(left, top);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return child?.hitTest(result, position: position - _childOffset) ?? false;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    transform.translateByDouble(_childOffset.dx, _childOffset.dy, 0.0, 1.0);
    super.applyPaintTransform(child, transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      context.paintChild(child!, _childOffset + offset);
    }
  }
}

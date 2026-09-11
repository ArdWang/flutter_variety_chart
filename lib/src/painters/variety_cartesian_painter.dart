import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../behaviors/variety_behaviors.dart';
import '../models/variety_annotation.dart';
import '../models/variety_axis.dart';
import '../models/variety_enums.dart';
import '../models/variety_options.dart';
import '../models/variety_series.dart';
import '../render/variety_chart_theme.dart';
import '../render/variety_elements.dart';
import '../render/variety_geometry.dart';
import 'variety_element_renderer.dart';

/// The on-screen rectangle of a tick label, used for label hit testing.
class VarietyAxisLabelHit {
  /// Creates a tick label hit record.
  const VarietyAxisLabelHit({
    required this.rect,
    required this.text,
    required this.value,
    required this.axis,
  });

  /// The painted rectangle of the label.
  final Rect rect;

  /// The caption that was painted.
  final String text;

  /// The value the caption represents.
  final double value;

  /// The axis the label belongs to.
  final VarietyAxis axis;
}

class _AxisTick {
  const _AxisTick(this.position, this.text, this.value);

  final double position;
  final String text;
  final double value;
}

/// Paints a cartesian chart.
///
/// The painter is intentionally thin: it draws the axis furniture, then walks
/// the element list produced by [geometry]. Adding a new series kind therefore
/// never requires touching this file.
class VarietyCartesianPainter extends CustomPainter {
  /// Creates a painter for the supplied geometry.
  VarietyCartesianPainter({
    required this.geometry,
    required this.theme,
    this.trackball,
    this.crosshair,
    this.annotations = const <VarietyAnnotation>[],
    this.highlights = const <VarietyHitResult>[],
    this.trackballSlot,
    this.selectionRect,
    this.labelHits,
    this.showElements = true,
    this.selected = const <VarietyHitResult>[],
  });

  /// The pre-computed layout shared with hit testing.
  final VarietyCartesianGeometry geometry;

  /// Shared default renderer used for non-element utilities such as
  /// [layoutText] and [drawLine]. Per-series overrides live in [_renderers].
  VarietyElementRenderer get _renderer =>
      _sharedRenderer ??= VarietyElementRenderer(theme);
  VarietyElementRenderer? _sharedRenderer;

  /// Toggle per series index to honour [VarietySeries.initialIsVisible].
  final Map<int, bool> _seriesVisible = <int, bool>{};

  /// One renderer per series, built from [VarietySeries.onCreateRenderer]
  /// or the default renderer as a fallback.
  late final Map<int, VarietyElementRenderer> _renderers = _buildRendererMap();

  Map<int, VarietyElementRenderer> _buildRendererMap() {
    final Map<int, VarietyElementRenderer> map =
        <int, VarietyElementRenderer>{};
    for (int s = 0; s < geometry.series.length; s++) {
      final VarietySeries series = geometry.series[s];
      final VarietyElementRenderer renderer =
          series.onCreateRenderer?.call(theme, series) ??
              VarietyElementRenderer(theme);
      map[s] = renderer;
      try {
        series.onRendererCreated?.call(renderer, s);
      } catch (_) {
        // Users may throw in their callback; a broken callback should not
        // take down the chart.
      }
    }
    return map;
  }

  /// The resolved colours for this build.
  final VarietyChartTheme theme;

  /// The trackball configuration, if enabled.
  final VarietyTrackballBehavior? trackball;

  /// The crosshair configuration, if enabled.
  final VarietyCrosshairBehavior? crosshair;

  /// Decorations drawn on top of the series.
  final List<VarietyAnnotation> annotations;

  /// The points that should be highlighted.
  final List<VarietyHitResult> highlights;

  /// The X pixel of the active trackball slot.
  final double? trackballSlot;

  /// The rubber-band rectangle used by selection zoom.
  final Rect? selectionRect;

  /// Collects the rectangles of the tick labels that were painted, so the host
  /// widget can hit test taps against them.
  final List<VarietyAxisLabelHit>? labelHits;

  /// Whether the series elements are painted. When `false` only the axis
  /// furniture is drawn, which is what a deferred rendering mode needs.
  final bool showElements;

  /// Selected points supplied by the chart widget; used for highlight rings
  /// and to dim unselected markers when [unselectedOpacity] < 1.
  final List<VarietyHitResult> selected;

  @override
  void paint(Canvas canvas, Size size) {
    if (_seriesVisible.isEmpty) {
      for (int s = 0; s < geometry.series.length; s++) {
        _seriesVisible[s] = geometry.series[s].initialIsVisible;
      }
    }
    _paintPlotBands(canvas);
    _paintGrid(canvas);
    if (showElements) {
      canvas.save();
      canvas.clipRect(geometry.plotRect.inflate(1));
      for (final VarietyElement el in geometry.elements) {
        if (el.seriesIndex != null && _seriesVisible[el.seriesIndex] == false) {
          continue;
        }
        final int key = el.seriesIndex ?? 0;
        final VarietyElementRenderer r = _renderers[key] ?? _renderer;
        final VarietySeries? series =
            el.seriesIndex != null ? geometry.series[el.seriesIndex!] : null;
        r.paintWith(canvas, el, series);
      }
      canvas.restore();
    }
    _paintAxisLines(canvas);
    _paintAnnotations(canvas);
    _paintHighlights(canvas);
    _paintSelectionRect(canvas);
  }

  // ---------------------------------------------------------------------------
  // Background furniture
  // ---------------------------------------------------------------------------

  void _paintPlotBands(Canvas canvas) {
    for (final VarietyPlotBand band in geometry.yAxis.plotBands) {
      if (!band.isVisible) {
        continue;
      }
      final Paint paint = Paint()
        ..color =
            (band.color ?? theme.gridLineColor).withValues(alpha: band.opacity);
      final double from = band.start.toDouble();
      final double to = band.end.toDouble();
      final num? repeat = band.repeatEvery;
      if (repeat != null && repeat > 0) {
        for (double value = from;
            value <= geometry.yMaximum;
            value += repeat.toDouble()) {
          final double top = geometry.pixelY(value + (to - from));
          final double bottom = geometry.pixelY(value);
          canvas.drawRect(
            Rect.fromLTRB(
                geometry.plotRect.left, top, geometry.plotRect.right, bottom),
            paint,
          );
        }
        continue;
      }
      final double top = geometry.pixelY(math.max(from, to));
      final double bottom = geometry.pixelY(math.min(from, to));
      canvas.drawRect(
        Rect.fromLTRB(
            geometry.plotRect.left, top, geometry.plotRect.right, bottom),
        paint,
      );
      if (band.label != null) {
        final TextPainter painter = _renderer.layoutText(
          band.label!,
          band.labelStyle ?? TextStyle(fontSize: 11, color: theme.labelColor),
        );
        painter.paint(
          canvas,
          Offset(
            geometry.plotRect.right - painter.width - 6,
            (top + bottom) / 2 - painter.height / 2,
          ),
        );
      }
    }
    for (final VarietyPlotBand band in geometry.xAxis.plotBands) {
      if (!band.isVisible) {
        continue;
      }
      final Paint paint = Paint()
        ..color =
            (band.color ?? theme.gridLineColor).withValues(alpha: band.opacity);
      final double left = _bandX(band.start.toDouble());
      final double right = _bandX(band.end.toDouble());
      canvas.drawRect(
        Rect.fromLTRB(
          math.min(left, right),
          geometry.plotRect.top,
          math.max(left, right),
          geometry.plotRect.bottom,
        ),
        paint,
      );
    }
  }

  double _bandX(double value) {
    if (geometry.xAxisType == VarietyAxisType.category ||
        geometry.xAxisType == VarietyAxisType.dateTimeCategory) {
      return geometry.plotRect.left + geometry.slotWidth * value;
    }
    final double span = math.max(geometry.xMaximum - geometry.xMinimum, 1e-9);
    return geometry.plotRect.left +
        (value - geometry.xMinimum) / span * geometry.plotRect.width;
  }

  void _paintGrid(Canvas canvas) {
    if (geometry.yAxis.showGridLines) {
      final Paint paint = Paint()
        ..color = geometry.yAxis.gridLineColor ?? theme.gridLineColor
        ..strokeWidth = geometry.yAxis.gridLineWidth
        ..isAntiAlias = true;
      for (final double tick in geometry.yTicks) {
        final double y = geometry.pixelY(tick);
        if (y < geometry.plotRect.top - 0.5 ||
            y > geometry.plotRect.bottom + 0.5) {
          continue;
        }
        _renderer.drawLine(
          canvas,
          Offset(geometry.plotRect.left, y),
          Offset(geometry.plotRect.right, y),
          paint,
          geometry.yAxis.gridLineDashPattern,
        );
      }
    }
    if (geometry.xAxis.showGridLines) {
      final Paint paint = Paint()
        ..color = geometry.xAxis.gridLineColor ?? theme.gridLineColor
        ..strokeWidth = geometry.xAxis.gridLineWidth
        ..isAntiAlias = true;
      for (final double x in _primaryGridPositions()) {
        _renderer.drawLine(
          canvas,
          Offset(x, geometry.plotRect.top),
          Offset(x, geometry.plotRect.bottom),
          paint,
          geometry.xAxis.gridLineDashPattern,
        );
      }
    }
    _paintMinorGrid(canvas);
  }

  void _paintMinorGrid(Canvas canvas) {
    final VarietyMinorGridLines? minorY = geometry.yAxis.minorGridLines;
    final List<double> minorTicks = geometry.yMinorTicks;
    if (minorY != null && minorTicks.isNotEmpty) {
      final Paint paint = Paint()
        ..color = minorY.color ??
            (geometry.yAxis.gridLineColor ?? theme.gridLineColor)
                .withValues(alpha: 0.6)
        ..strokeWidth = minorY.width
        ..isAntiAlias = true;
      for (final double tick in minorTicks) {
        final double y = geometry.pixelY(tick);
        if (y < geometry.plotRect.top || y > geometry.plotRect.bottom) {
          continue;
        }
        _renderer.drawLine(
          canvas,
          Offset(geometry.plotRect.left, y),
          Offset(geometry.plotRect.right, y),
          paint,
          minorY.dashArray,
        );
      }
    }
    final VarietyMinorGridLines? minorX = geometry.xAxis.minorGridLines;
    final List<double> minorPositions = geometry.xMinorTickPositions;
    if (minorX != null && minorPositions.isNotEmpty) {
      final Paint paint = Paint()
        ..color = minorX.color ??
            (geometry.xAxis.gridLineColor ?? theme.gridLineColor)
                .withValues(alpha: 0.6)
        ..strokeWidth = minorX.width
        ..isAntiAlias = true;
      for (final double x in minorPositions) {
        _renderer.drawLine(
          canvas,
          Offset(x, geometry.plotRect.top),
          Offset(x, geometry.plotRect.bottom),
          paint,
          minorX.dashArray,
        );
      }
    }
  }

  List<double> _primaryGridPositions() {
    switch (geometry.xAxisType) {
      case VarietyAxisType.category:
      case VarietyAxisType.dateTimeCategory:
        return geometry.slotCenters;
      case VarietyAxisType.dateTime:
        return geometry.dateTimeTicks
            .map(
              (DateTime tick) => geometry
                  .toPixel(
                      tick.millisecondsSinceEpoch.toDouble(), geometry.yMinimum)
                  .dx,
            )
            .toList(growable: false);
      case VarietyAxisType.numeric:
      case VarietyAxisType.logarithmic:
        final double span = geometry.xMaximum - geometry.xMinimum;
        final int steps = math.max(geometry.xAxis.desiredIntervals, 1);
        return List<double>.generate(
          steps + 1,
          (int i) =>
              geometry.toPixel(geometry.xMinimum + span * i / steps, 0).dx,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Axes
  // ---------------------------------------------------------------------------

  void _paintAxisLines(Canvas canvas) {
    if (geometry.yAxis.visible && geometry.yAxis.showAxisLine) {
      final double x = geometry.yAxis.opposedPosition
          ? geometry.plotRect.right
          : geometry.plotRect.left;
      canvas.drawLine(
        Offset(x, geometry.plotRect.top),
        Offset(x, geometry.plotRect.bottom),
        Paint()
          ..color = geometry.yAxis.axisLineColor ?? theme.axisLineColor
          ..strokeWidth = geometry.yAxis.axisLineWidth
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true,
      );
    }
    if (geometry.xAxis.visible && geometry.xAxis.showAxisLine) {
      final double y = geometry.xAxis.opposedPosition
          ? geometry.plotRect.top
          : geometry.plotRect.bottom;
      canvas.drawLine(
        Offset(geometry.plotRect.left, y),
        Offset(geometry.plotRect.right, y),
        Paint()
          ..color = geometry.xAxis.axisLineColor ?? theme.axisLineColor
          ..strokeWidth = geometry.xAxis.axisLineWidth
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true,
      );
    }
    if (geometry.yAxis.borderType == VarietyAxisBorderType.rectangle ||
        geometry.xAxis.borderType == VarietyAxisBorderType.rectangle) {
      canvas.drawRect(
        geometry.plotRect,
        Paint()
          ..color = geometry.yAxis.axisLineColor ?? theme.axisLineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(
            geometry.yAxis.axisLineWidth,
            geometry.xAxis.axisLineWidth,
          )
          ..isAntiAlias = true,
      );
    }
    _paintSecondaryLabels(canvas);
    _paintExtraAxes(canvas);
    _paintPrimaryLabels(canvas);
    _paintMultiLevelLabels(canvas);
  }

  /// Draws every secondary axis declared after the primary one.
  ///
  /// Each axis is stacked further to the right of the plot area, in the order
  /// it was declared.
  void _paintExtraAxes(Canvas canvas) {
    final List<VarietyAxis> axes = geometry.yAxes;
    if (axes.length < 2) {
      return;
    }
    double offset = 0;
    for (int i = 1; i < axes.length; i++) {
      final VarietyAxis axis = axes[i];
      if (!axis.visible) {
        continue;
      }
      final TextStyle style =
          axis.labelStyle ?? TextStyle(fontSize: 11, color: theme.labelColor);
      final List<double> ticks = geometry.yTicksOn(i);
      double labelWidth = 0;
      for (final double tick in ticks) {
        labelWidth = math.max(
          labelWidth,
          _renderer
              .layoutText(geometry.secondaryTickLabelOn(i, tick), style)
              .width,
        );
      }
      final double axisX = geometry.plotRect.right + offset;
      final Paint linePaint = Paint()
        ..color = axis.axisLineColor ?? theme.axisLineColor
        ..strokeWidth = axis.axisLineWidth
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;
      if (axis.showAxisLine) {
        canvas.drawLine(
          Offset(axisX, geometry.plotRect.top),
          Offset(axisX, geometry.plotRect.bottom),
          linePaint,
        );
      }
      for (final double tick in ticks) {
        final double y = geometry.pixelYOn(i, tick);
        if (y < geometry.plotRect.top - 0.5 ||
            y > geometry.plotRect.bottom + 0.5) {
          continue;
        }
        final String caption = geometry.secondaryTickLabelOn(i, tick);
        if (caption.isEmpty || !axis.showLabels) {
          continue;
        }
        final TextPainter painter = _renderer.layoutText(caption, style);
        painter.paint(
          canvas,
          Offset(axisX + axis.labelOffset, y - painter.height / 2),
        );
        if (axis.showTicks) {
          canvas.drawLine(
            Offset(axisX, y),
            Offset(axisX + axis.tickLength, y),
            linePaint,
          );
        }
      }
      final String? title = axis.title;
      if (title != null && title.isNotEmpty) {
        final TextPainter painter = _renderer.layoutText(
          title,
          TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.labelColor),
        );
        canvas.save();
        canvas.translate(axisX + labelWidth + 24, geometry.plotRect.center.dy);
        canvas.rotate(math.pi / 2);
        painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
        canvas.restore();
      }
      offset += labelWidth +
          axis.labelOffset +
          14 +
          ((title ?? '').isNotEmpty ? 20 : 0);
    }
  }

  void _paintSecondaryLabels(Canvas canvas) {
    if (!geometry.yAxis.showLabels || !geometry.yAxis.visible) {
      return;
    }
    final TextStyle style = geometry.yAxis.labelStyle ??
        TextStyle(fontSize: 11, color: theme.labelColor);
    final bool opposed = geometry.yAxis.opposedPosition;
    final double axisX =
        opposed ? geometry.plotRect.right : geometry.plotRect.left;
    for (final double tick in geometry.yTicks) {
      final double y = geometry.pixelY(tick);
      if (y < geometry.plotRect.top - 0.5 ||
          y > geometry.plotRect.bottom + 0.5) {
        continue;
      }
      final String caption = geometry.secondaryTickLabel(tick);
      if (caption.isEmpty) {
        continue;
      }
      final TextPainter painter = _renderer.layoutText(caption, style);
      final bool inside =
          geometry.yAxis.labelPlacement == VarietyLabelPlacement.inside;
      final double sign = opposed ? -1 : 1;
      painter.paint(
        canvas,
        opposed
            ? Offset(
                axisX +
                    (inside
                        ? -geometry.yAxis.labelOffset - painter.width
                        : geometry.yAxis.labelOffset),
                y - painter.height / 2,
              )
            : Offset(
                axisX +
                    (inside
                        ? geometry.yAxis.labelOffset
                        : -geometry.yAxis.labelOffset - painter.width),
                y - painter.height / 2,
              ),
      );
      assert(sign != 0);
      if (geometry.yAxis.showTicks) {
        final double sign = opposed ? 1 : -1;
        canvas.drawLine(
          Offset(axisX, y),
          Offset(axisX + sign * geometry.yAxis.tickLength, y),
          Paint()
            ..color = geometry.yAxis.axisLineColor ?? theme.axisLineColor
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );
      }
    }
    final String? title = geometry.yAxis.title;
    if (title != null && title.isNotEmpty) {
      final TextPainter painter = _renderer.layoutText(
        title,
        TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: theme.labelColor),
      );
      canvas.save();
      canvas.translate(14, geometry.plotRect.center.dy);
      canvas.rotate(-math.pi / 2);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
    }
  }

  List<_AxisTick> _primaryTicks() {
    switch (geometry.xAxisType) {
      case VarietyAxisType.category:
      case VarietyAxisType.dateTimeCategory:
        final List<_AxisTick> ticks = <_AxisTick>[];
        for (int i = 0;
            i < geometry.categories.length && i < geometry.slotCenters.length;
            i++) {
          final double center = geometry.slotCenters[i];
          // Zooming shifts categories outside the plot area; skip those.
          if (center < geometry.plotRect.left - 1 ||
              center > geometry.plotRect.right + 1) {
            continue;
          }
          ticks.add(_AxisTick(center, geometry.categories[i], i.toDouble()));
        }
        return ticks;
      case VarietyAxisType.dateTime:
        return geometry.dateTimeTicks
            .map(
              (DateTime tick) => _AxisTick(
                geometry
                    .toPixel(tick.millisecondsSinceEpoch.toDouble(),
                        geometry.yMinimum)
                    .dx,
                geometry.dateTimeTickLabel(tick),
                tick.millisecondsSinceEpoch.toDouble(),
              ),
            )
            .toList(growable: false);
      case VarietyAxisType.numeric:
      case VarietyAxisType.logarithmic:
        final double span = geometry.xMaximum - geometry.xMinimum;
        final int steps = math.max(geometry.xAxis.desiredIntervals, 1);
        return List<_AxisTick>.generate(
          steps + 1,
          (int i) {
            final double value = geometry.xMinimum + span * i / steps;
            return _AxisTick(
              geometry.toPixel(value, geometry.yMinimum).dx,
              geometry.primaryTickLabel(value),
              value,
            );
          },
        );
    }
  }

  double _projectedWidth(TextPainter painter, double rotationDegrees) {
    if (rotationDegrees == 0) {
      return painter.width;
    }
    final double radians = rotationDegrees.abs() * math.pi / 180;
    return painter.width * math.cos(radians).abs() +
        painter.height * math.sin(radians).abs();
  }

  void _paintPrimaryLabels(Canvas canvas) {
    if (!geometry.xAxis.showLabels || !geometry.xAxis.visible) {
      return;
    }
    final VarietyAxis axis = geometry.xAxis;
    final TextStyle style =
        axis.labelStyle ?? TextStyle(fontSize: 11, color: theme.labelColor);
    final List<_AxisTick> ticks = _primaryTicks();
    if (ticks.isEmpty) {
      return;
    }
    double rotation = axis.labelRotation;
    switch (axis.labelIntersectAction) {
      case VarietyLabelIntersectAction.rotate45:
        rotation = -45;
      case VarietyLabelIntersectAction.rotate90:
        rotation = -90;
      case VarietyLabelIntersectAction.none:
      case VarietyLabelIntersectAction.hide:
      case VarietyLabelIntersectAction.wrap:
      case VarietyLabelIntersectAction.multipleRows:
        break;
    }

    final List<TextPainter> painters = ticks
        .map((_AxisTick tick) => _renderer.layoutText(tick.text, style))
        .toList(growable: false);
    final List<double> extents = painters
        .map((TextPainter painter) => _projectedWidth(painter, rotation))
        .toList(growable: false);

    final List<bool> visible = List<bool>.filled(ticks.length, true);
    final bool thinning =
        axis.labelIntersectAction == VarietyLabelIntersectAction.hide ||
            axis.labelIntersectAction == VarietyLabelIntersectAction.rotate45 ||
            axis.labelIntersectAction == VarietyLabelIntersectAction.rotate90;
    if (thinning) {
      double lastRight = double.negativeInfinity;
      for (int i = 0; i < ticks.length; i++) {
        final double left = ticks[i].position - extents[i] / 2;
        if (left < lastRight + 2) {
          visible[i] = false;
          continue;
        }
        lastRight = ticks[i].position + extents[i] / 2;
      }
    }

    final bool inside = axis.labelPlacement == VarietyLabelPlacement.inside;
    final double baseY = axis.opposedPosition
        ? geometry.plotRect.top - axis.labelOffset
        : geometry.plotRect.bottom + axis.labelOffset;
    for (int i = 0; i < ticks.length; i++) {
      if (!visible[i]) {
        continue;
      }
      final TextPainter painter = painters[i];
      double x = ticks[i].position;
      if (axis.edgeLabelPlacement != VarietyEdgeLabelPlacement.none) {
        final double half = extents[i] / 2;
        if (x - half < geometry.plotRect.left) {
          if (axis.edgeLabelPlacement == VarietyEdgeLabelPlacement.hide &&
              i == 0) {
            continue;
          }
          x = geometry.plotRect.left + half;
        }
        if (x + half > geometry.plotRect.right) {
          if (axis.edgeLabelPlacement == VarietyEdgeLabelPlacement.hide &&
              i == ticks.length - 1) {
            continue;
          }
          x = geometry.plotRect.right - half;
        }
      }
      double rowOffset = 0;
      if (axis.labelIntersectAction ==
          VarietyLabelIntersectAction.multipleRows) {
        rowOffset = i.isOdd ? painter.height + 2 : 0;
      }
      final double anchorY =
          baseY + (inside ? -painter.height - 4 : 0) + rowOffset;
      labelHits?.add(
        VarietyAxisLabelHit(
          rect: Rect.fromCenter(
            center: Offset(x, anchorY + painter.height / 2),
            width: math.max(extents[i], 8),
            height: painter.height + 4,
          ),
          text: ticks[i].text,
          value: ticks[i].value,
          axis: axis,
        ),
      );
      if (axis.labelIntersectAction == VarietyLabelIntersectAction.wrap &&
          extents[i] > geometry.slotWidth * 0.95 &&
          ticks[i].text.contains(' ')) {
        _paintWrapped(canvas, ticks[i].text, Offset(x, anchorY), style);
        continue;
      }
      _paintRotated(canvas, ticks[i].text, Offset(x, anchorY), style, rotation);
    }

    final String? title = axis.title;
    if (title != null && title.isNotEmpty) {
      final TextPainter painter = _renderer.layoutText(
        title,
        TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: theme.labelColor),
      );
      painter.paint(
        canvas,
        Offset(
          geometry.plotRect.center.dx - painter.width / 2,
          baseY +
              _primaryLabelHeight(style) +
              (axis.labelIntersectAction ==
                      VarietyLabelIntersectAction.multipleRows
                  ? 20
                  : 0) +
              6,
        ),
      );
    }
  }

  void _paintWrapped(
      Canvas canvas, String text, Offset anchor, TextStyle style) {
    final List<String> words = text.split(' ');
    final int split = (words.length / 2).ceil();
    final String first = words.take(split).join(' ');
    final String second = words.skip(split).join(' ');
    final TextPainter top = _renderer.layoutText(first, style);
    final TextPainter bottom = _renderer.layoutText(second, style);
    final double width = math.max(top.width, bottom.width);
    top.paint(canvas, Offset(anchor.dx - width / 2, anchor.dy));
    bottom.paint(canvas, Offset(anchor.dx - width / 2, anchor.dy + top.height));
  }

  void _paintMultiLevelLabels(Canvas canvas) {
    final VarietyMultiLevelLabels? groups = geometry.xAxis.multiLevelLabels;
    if (groups == null ||
        groups.groups.isEmpty ||
        geometry.slotCenters.isEmpty) {
      return;
    }
    final Color borderColor = groups.borderColor ?? theme.axisLineColor;
    final TextStyle style = groups.textStyle ??
        TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: theme.labelColor);
    final double baseY = geometry.plotRect.bottom +
        geometry.xAxis.labelOffset +
        _primaryLabelHeight(
            geometry.xAxis.labelStyle ?? const TextStyle(fontSize: 11)) +
        6;
    for (final VarietyLabelGroup group in groups.groups) {
      final double top = baseY + group.level * 22;
      final double bottom = top + 22 - groups.margin.vertical;
      final double left = geometry
          .slotCenters[group.start.clamp(0, geometry.slotCenters.length - 1)];
      final double right = geometry
          .slotCenters[group.end.clamp(0, geometry.slotCenters.length - 1)];
      final Rect rect = Rect.fromLTRB(
        left - geometry.slotWidth / 2,
        top,
        right + geometry.slotWidth / 2,
        bottom,
      );
      final Paint border = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = groups.borderWidth
        ..isAntiAlias = true;
      switch (groups.borderType) {
        case VarietyMultiLevelBorderType.rectangle:
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              rect,
              topLeft: const Radius.circular(3),
              topRight: const Radius.circular(3),
            ),
            border,
          );
        case VarietyMultiLevelBorderType.brace:
          canvas.drawPath(
            Path()
              ..moveTo(rect.left, rect.bottom)
              ..lineTo(rect.left, rect.top)
              ..lineTo(rect.right, rect.top)
              ..lineTo(rect.right, rect.bottom),
            border,
          );
        case VarietyMultiLevelBorderType.curlyBracket:
          final double midY = rect.center.dy;
          final double notch = math.min(6, rect.height / 3);
          canvas.drawPath(
            Path()
              ..moveTo(rect.left, rect.bottom)
              ..lineTo(rect.left, midY + notch)
              ..quadraticBezierTo(rect.left, midY, rect.left + 5, midY)
              ..lineTo(rect.right - 5, midY)
              ..quadraticBezierTo(rect.right, midY, rect.right, midY + notch)
              ..lineTo(rect.right, rect.bottom),
            border,
          );
      }
      if (group.text.isEmpty) {
        continue;
      }
      final TextPainter painter = _renderer.layoutText(group.text, style);
      painter.paint(
        canvas,
        Offset(rect.center.dx - painter.width / 2,
            rect.center.dy - painter.height / 2),
      );
    }
  }

  double _primaryLabelHeight(TextStyle style) {
    final double rotation = geometry.xAxis.labelRotation * math.pi / 180;
    if (rotation == 0) {
      return _renderer.layoutText('0', style).height;
    }
    final Size sample = _renderer.layoutText('00 MMM', style).size;
    return sample.height * math.cos(rotation).abs() +
        sample.width * math.sin(rotation).abs();
  }

  void _paintRotated(
    Canvas canvas,
    String text,
    Offset anchor,
    TextStyle style,
    double rotationDegrees,
  ) {
    final TextPainter painter = _renderer.layoutText(text, style);
    canvas.save();
    if (rotationDegrees != 0) {
      canvas.translate(anchor.dx, anchor.dy);
      canvas.rotate(rotationDegrees * math.pi / 180);
      painter.paint(canvas, Offset(-painter.width, 0));
    } else {
      painter.paint(canvas, Offset(anchor.dx - painter.width / 2, anchor.dy));
    }
    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // Annotations and highlights
  // ---------------------------------------------------------------------------

  void _paintAnnotations(Canvas canvas) {
    for (final VarietyAnnotation annotation in annotations) {
      if (!annotation.isVisible) {
        continue;
      }
      final Color border = annotation.borderColor ?? theme.axisLineColor;
      final Color fill = annotation.fillColor ?? border.withValues(alpha: 0.15);
      switch (annotation.shapeType) {
        case VarietyShapeType.horizontalLine:
          if (annotation.y is! num) {
            break;
          }
          final double y = geometry.pixelY((annotation.y! as num).toDouble());
          _renderer.drawLine(
            canvas,
            Offset(geometry.plotRect.left, y),
            Offset(geometry.plotRect.right, y),
            Paint()
              ..color = border
              ..strokeWidth = annotation.borderWidth,
            annotation.dashArray,
          );
          _paintAnnotationText(
            canvas,
            annotation,
            Offset(geometry.plotRect.left + 6, y - 18),
          );
        case VarietyShapeType.verticalLine:
          final double x = _annotationX(annotation.x);
          _renderer.drawLine(
            canvas,
            Offset(x, geometry.plotRect.top),
            Offset(x, geometry.plotRect.bottom),
            Paint()
              ..color = border
              ..strokeWidth = annotation.borderWidth,
            annotation.dashArray,
          );
          _paintAnnotationText(
              canvas, annotation, Offset(x + 6, geometry.plotRect.top + 6));
        case VarietyShapeType.rectangle:
        case VarietyShapeType.ellipse:
          final Offset anchor = _annotationOffset(annotation);
          final Rect rect = Rect.fromCenter(
            center: anchor,
            width: annotation.width <= 0 ? 80 : annotation.width,
            height: annotation.height <= 0 ? 44 : annotation.height,
          );
          if (annotation.shapeType == VarietyShapeType.rectangle) {
            final RRect rrect =
                RRect.fromRectAndRadius(rect, const Radius.circular(6));
            canvas.drawRRect(rrect, Paint()..color = fill);
            canvas.drawRRect(
              rrect,
              Paint()
                ..color = border
                ..style = PaintingStyle.stroke
                ..strokeWidth = annotation.borderWidth,
            );
          } else {
            canvas.drawOval(rect, Paint()..color = fill);
            canvas.drawOval(
              rect,
              Paint()
                ..color = border
                ..style = PaintingStyle.stroke
                ..strokeWidth = annotation.borderWidth,
            );
          }
          _paintAnnotationText(
              canvas, annotation, rect.topLeft + const Offset(8, 6));
        case VarietyShapeType.text:
          _paintAnnotationText(
              canvas, annotation, _annotationOffset(annotation));
        case VarietyShapeType.arrow:
          final Offset anchor = _annotationOffset(annotation);
          final Path arrow = Path()
            ..moveTo(anchor.dx, anchor.dy)
            ..lineTo(anchor.dx - 14, anchor.dy - 18)
            ..lineTo(anchor.dx - 4, anchor.dy - 18)
            ..close();
          canvas.drawPath(arrow, Paint()..color = fill);
          _paintAnnotationText(canvas, annotation, anchor + const Offset(6, 6));
        case VarietyShapeType.image:
          final ImageProvider? provider = annotation.image;
          if (provider == null) {
            break;
          }
          final ImageStream stream = provider.resolve(ImageConfiguration.empty);
          stream.addListener(
            ImageStreamListener((ImageInfo info, bool synchronous) {
              final Offset anchor = _annotationOffset(annotation);
              final double width =
                  annotation.width <= 0 ? 48 : annotation.width;
              final double height = annotation.height <= 0
                  ? width * info.image.height / info.image.width
                  : annotation.height;
              canvas.drawImageRect(
                info.image,
                Rect.fromLTWH(
                  0,
                  0,
                  info.image.width.toDouble(),
                  info.image.height.toDouble(),
                ),
                Rect.fromCenter(center: anchor, width: width, height: height),
                Paint(),
              );
            }),
          );
      }
    }
  }

  double _annotationX(dynamic x) {
    if (x == null) {
      return geometry.plotRect.center.dx;
    }
    if (geometry.xAxisType == VarietyAxisType.category ||
        geometry.xAxisType == VarietyAxisType.dateTimeCategory) {
      final int index = x is num ? x.toInt() : 0;
      if (index >= 0 && index < geometry.slotCenters.length) {
        return geometry.slotCenters[index];
      }
      return geometry.plotRect.left + geometry.slotWidth * (index + 0.5);
    }
    final double value = x is DateTime
        ? x.millisecondsSinceEpoch.toDouble()
        : (x as num).toDouble();
    return geometry.toPixel(value, geometry.yMinimum).dx;
  }

  Offset _annotationOffset(VarietyAnnotation annotation) {
    final double x = _annotationX(annotation.x);
    final double y = annotation.y is num
        ? geometry.pixelY((annotation.y! as num).toDouble())
        : geometry.plotRect.center.dy;
    return Offset(x, y);
  }

  void _paintAnnotationText(
    Canvas canvas,
    VarietyAnnotation annotation,
    Offset position,
  ) {
    final String? text = annotation.text;
    if (text == null || text.isEmpty) {
      return;
    }
    final TextPainter painter = _renderer.layoutText(
      text,
      annotation.textStyle ??
          TextStyle(
            fontSize: annotation.fontSize,
            color: theme.labelColor,
            fontWeight: FontWeight.w500,
          ),
    );
    painter.paint(canvas, position);
  }

  void _paintHighlights(Canvas canvas) {
    final VarietyTrackballBehavior? ball = trackball;
    if (ball != null &&
        ball.enabled &&
        ball.showLine &&
        trackballSlot != null) {
      _renderer.drawLine(
        canvas,
        Offset(trackballSlot!, geometry.plotRect.top),
        Offset(trackballSlot!, geometry.plotRect.bottom),
        Paint()
          ..color = ball.lineColor ?? theme.axisLineColor
          ..strokeWidth = ball.lineWidth,
        ball.lineDashPattern,
      );
    }
    final VarietyCrosshairBehavior? cross = crosshair;
    if (cross != null && cross.enabled && highlights.isNotEmpty) {
      final VarietyHitResult first = highlights.first;
      final Paint paint = Paint()
        ..color = cross.lineColor ?? theme.axisLineColor
        ..strokeWidth = cross.lineWidth;
      if (cross.showVerticalLine) {
        _renderer.drawLine(
          canvas,
          Offset(first.position.dx, geometry.plotRect.top),
          Offset(first.position.dx, geometry.plotRect.bottom),
          paint,
          cross.lineDashPattern,
        );
      }
      if (cross.showHorizontalLine) {
        _renderer.drawLine(
          canvas,
          Offset(geometry.plotRect.left, first.position.dy),
          Offset(geometry.plotRect.right, first.position.dy),
          paint,
          cross.lineDashPattern,
        );
      }
    }
    final bool showMarkers = ball == null || ball.showMarkers;
    for (final VarietyHitResult hit in highlights) {
      if (!showMarkers) {
        continue;
      }
      final Color color = hit.point.color ??
          hit.series.color ??
          varietyDefaultPalette[hit.seriesIndex % varietyDefaultPalette.length];
      final double size = ball?.markerSize ?? 9;
      final VarietyMarkerShape shape =
          ball?.markerShape ?? VarietyMarkerShape.circle;
      final Path path = _renderer.markerPath(shape, hit.position, size);
      canvas.drawPath(path, Paint()..color = theme.markerBorderColor);
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..isAntiAlias = true,
      );
      if (hit.band != null) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(hit.band!, const Radius.circular(3)),
          Paint()
            ..color = color.withValues(alpha: 0.16)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  void _paintSelectionRect(Canvas canvas) {
    final Rect? rect = selectionRect;
    if (rect == null) {
      return;
    }
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF3F6FE0).withValues(alpha: 0.16)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF3F6FE0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant VarietyCartesianPainter oldDelegate) => true;
}

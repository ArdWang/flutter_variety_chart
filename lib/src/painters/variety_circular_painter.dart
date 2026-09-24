import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/variety_chart_data.dart';
import '../models/variety_enums.dart';
import '../models/variety_series.dart';
import '../render/variety_chart_theme.dart';
import '../render/variety_geometry.dart';

/// Paints a circular chart: pie and doughnut slices plus radial bar rings.
class VarietyCircularPainter extends CustomPainter {
  /// Creates a painter for the supplied [geometry].
  VarietyCircularPainter({
    required this.geometry,
    required this.theme,
    this.highlights = const <VarietyHitResult>[],
  });

  /// The pre-computed slice layout shared with hit testing.
  final VarietyCircularGeometry geometry;

  /// The resolved colours for this build.
  final VarietyChartTheme theme;

  /// The points that should be highlighted.
  final List<VarietyHitResult> highlights;

  @override
  void paint(Canvas canvas, Size size) {
    _paintRings(canvas);
    _paintSlices(canvas);
    _paintLabels(canvas);
  }

  void _paintRings(Canvas canvas) {
    for (final VarietySlice slice in geometry.rings) {
      _paintRing(canvas, slice, slice.point.y == null);
    }
  }

  void _paintRing(Canvas canvas, VarietySlice slice, bool isTrack) {
    final Path path = _ringPath(slice);
    canvas.drawPath(
      path,
      Paint()
        ..color = slice.color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    if (isTrack) {
      return;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = theme.markerBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..isAntiAlias = true,
    );
  }

  void _paintSlices(Canvas canvas) {
    for (final VarietySlice slice in geometry.slices) {
      final Path path = _slicePath(slice);
      canvas.drawPath(
        path,
        Paint()
          ..color = slice.color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      if (slice.strokeColor != null && slice.strokeWidth > 0) {
        canvas.drawPath(
          path,
          Paint()
            ..color = slice.strokeColor!
            ..style = PaintingStyle.stroke
            ..strokeWidth = slice.strokeWidth
            ..isAntiAlias = true,
        );
      }
    }
    for (final VarietyHitResult hit in highlights) {
      for (final VarietySlice slice in geometry.slices) {
        if (slice.seriesIndex != hit.seriesIndex ||
            slice.pointIndex != hit.pointIndex) {
          continue;
        }
        final double mid = slice.startAngle + slice.sweepAngle / 2;
        final double radius = (slice.outerRadius + slice.innerRadius) / 2;
        canvas.drawCircle(
          slice.center + Offset(math.cos(mid), math.sin(mid)) * radius,
          6,
          Paint()
            ..color = theme.markerBorderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
      }
    }
  }

  void _paintLabels(Canvas canvas) {
    for (final VarietySlice slice in geometry.slices) {
      final VarietySeries series = geometry.series[slice.seriesIndex];
      final VarietyDataLabelSettings settings = series.dataLabelSettings;
      if (!settings.isVisible) {
        continue;
      }
      final String caption = settings.builder?.call(slice.point) ??
          (slice.point.label ?? slice.point.y?.toString() ?? '');
      if (caption.isEmpty) {
        continue;
      }
      final TextStyle style =
          (settings.textStyle ?? const TextStyle(fontSize: 11))
              .copyWith(color: settings.color ?? Colors.white);
      final TextPainter painter = TextPainter(
        text: TextSpan(text: caption, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final double mid = slice.startAngle + slice.sweepAngle / 2;
      final bool outside = settings.position == VarietyLabelPosition.outside;
      final double distance = outside
          ? slice.outerRadius + settings.labelOffset + painter.width / 2
          : slice.outerRadius * 0.62;
      final Offset anchor =
          slice.center + Offset(math.cos(mid), math.sin(mid)) * distance;
      painter.paint(
        canvas,
        Offset(anchor.dx - painter.width / 2, anchor.dy - painter.height / 2),
      );
    }
  }

  Path _ringPath(VarietySlice slice) {
    final Offset center = slice.center;
    final double outer = slice.outerRadius;
    final double inner = slice.innerRadius;
    final double start = slice.startAngle;
    final double sweep = slice.sweepAngle;
    if (sweep.abs() >= 2 * math.pi - 1e-6) {
      final Path path = Path()
        ..addOval(Rect.fromCircle(center: center, radius: outer));
      if (inner > 0) {
        path.addOval(Rect.fromCircle(center: center, radius: inner));
        path.fillType = PathFillType.evenOdd;
      }
      return path;
    }
    final Path path = Path()
      ..moveTo(
        center.dx + outer * math.cos(start),
        center.dy + outer * math.sin(start),
      )
      ..arcTo(
          Rect.fromCircle(center: center, radius: outer), start, sweep, false);
    if (inner > 0) {
      path
        ..lineTo(
          center.dx + inner * math.cos(start + sweep),
          center.dy + inner * math.sin(start + sweep),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: inner),
          start + sweep,
          -sweep,
          false,
        );
    } else {
      path.lineTo(center.dx, center.dy);
    }
    path.close();
    return path;
  }

  /// The angle a corner takes off the two arcs beside it.
  ///
  /// A corner is as wide as the band it sits in, so it is measured against the
  /// radius halfway across that band: an arc gives up the slice of angle that a
  /// length of `corner` covers at that radius. Measuring each arc at its own
  /// radius instead gives the inner and outer gaps different angles, and the
  /// join reads as a wedge rather than an even gap.
  static double _cornerAngle(
    double innerRadius,
    double outerRadius,
    double corner,
  ) {
    final double mid = (innerRadius + outerRadius) / 2;
    if (mid <= 0) {
      return 0;
    }
    return corner / mid;
  }

  /// The outline of one slice, with its corners rounded when asked for.
  ///
  /// A slice is a band between two radii, so its outline turns four times: the
  /// outer arc, the right edge, the inner arc, and the left edge. `cornerRadius`
  /// runs a small arc through each turn, which means the two arcs stop short of
  /// the edges and the corner bridges the gap.
  ///
  /// A pie has no inner arc and nothing for a corner to turn against, and a
  /// radius wider than half the band would turn the slice inside out, so both
  /// fall back to the plain outline.
  Path _slicePath(VarietySlice slice) {
    final double outer = slice.outerRadius;
    final double inner = slice.innerRadius;
    if (slice.cornerRadius <= 0 || inner <= 0) {
      return _ringPath(slice);
    }
    final double corner = math.min(slice.cornerRadius, (outer - inner) / 2);
    final double sweep = slice.sweepAngle;
    if (corner <= 0.5 || sweep.abs() <= 1e-6) {
      return _ringPath(slice);
    }
    final Offset center = slice.center;
    final double start = slice.startAngle;
    final double end = start + sweep;
    // Angles run one way or the other depending on the slice's direction, and
    // every corner turns with them.
    final bool clockwise = sweep > 0;
    final double sign = clockwise ? 1 : -1;
    // Both arcs give up the same angle: the slice of angle a length of `corner`
    // covers at the radius halfway across the band. Capping it at a quarter of
    // the sweep keeps the two ends of one arc from meeting in the middle.
    final double trim = math.min(
      _cornerAngle(inner, outer, corner),
      sweep.abs() / 4,
    );
    Offset at(double radius, double angle) => Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );

    final Offset outerStart = at(outer, start + sign * trim);
    final Offset outerRight = at(outer - corner, end);
    final Offset innerRight = at(inner + corner, end);
    final Offset innerArcEnd = at(inner, end - sign * trim);
    final Offset innerLeft = at(inner + corner, start);
    final Offset outerLeft = at(outer - corner, start);
    final Radius cornerRadius = Radius.circular(corner);

    return Path()
      ..moveTo(outerStart.dx, outerStart.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: outer),
        start + sign * trim,
        sweep - 2 * sign * trim,
        false,
      )
      // Right edge, top to bottom.
      ..arcToPoint(outerRight, radius: cornerRadius, clockwise: clockwise)
      ..lineTo(innerRight.dx, innerRight.dy)
      ..arcToPoint(innerArcEnd, radius: cornerRadius, clockwise: !clockwise)
      ..arcTo(
        Rect.fromCircle(center: center, radius: inner),
        end - sign * trim,
        -(sweep - 2 * sign * trim),
        false,
      )
      // Left edge, bottom to top.
      ..arcToPoint(innerLeft, radius: cornerRadius, clockwise: clockwise)
      ..lineTo(outerLeft.dx, outerLeft.dy)
      ..arcToPoint(outerStart, radius: cornerRadius, clockwise: !clockwise)
      ..close();
  }

  @override
  bool shouldRepaint(covariant VarietyCircularPainter oldDelegate) => true;
}

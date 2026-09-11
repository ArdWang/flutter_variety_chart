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
        if (slice.seriesIndex != hit.seriesIndex || slice.pointIndex != hit.pointIndex) {
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
      final TextStyle style = (settings.textStyle ?? const TextStyle(fontSize: 11))
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
      ..arcTo(Rect.fromCircle(center: center, radius: outer), start, sweep, false);
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

  Path _slicePath(VarietySlice slice) {
    if (slice.cornerRadius <= 0) {
      return _ringPath(slice);
    }
    final Offset center = slice.center;
    final double outer = slice.outerRadius;
    final double inner = slice.innerRadius;
    final double start = slice.startAngle;
    final double sweep = slice.sweepAngle;
    final double radius = math.min(slice.cornerRadius, (outer - inner).abs() / 2);
    if (radius <= 0.5) {
      return _ringPath(slice);
    }
    final double insetOuter = outer - radius;
    final double insetInner = inner + radius;
    final Path path = Path()
      ..moveTo(
        center.dx + insetOuter * math.cos(start),
        center.dy + insetOuter * math.sin(start),
      )
      ..arcTo(Rect.fromCircle(center: center, radius: outer), start, sweep, false)
      ..lineTo(
        center.dx + outer * math.cos(start + sweep),
        center.dy + outer * math.sin(start + sweep),
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: insetOuter),
        start + sweep,
        -sweep,
        false,
      );
    if (inner > 0) {
      path
        ..lineTo(
          center.dx + insetInner * math.cos(start + sweep),
          center.dy + insetInner * math.sin(start + sweep),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: inner),
          start + sweep,
          -(-sweep),
          false,
        );
    } else {
      path.lineTo(center.dx, center.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant VarietyCircularPainter oldDelegate) => true;
}

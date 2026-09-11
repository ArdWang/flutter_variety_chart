import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/variety_enums.dart';
import '../models/variety_series.dart';
import '../render/variety_chart_theme.dart';
import '../render/variety_elements.dart';

/// Creates an element renderer for a single series.
///
/// The painter holds one of these per series, so a chart with three
/// series keeps three renderer instances. The factory is invoked when
/// the chart is first laid out; the [VarietySeries.onRendererCreated]
/// callback fires immediately afterwards.
typedef VarietyRendererFactory = VarietyElementRenderer Function(
  VarietyChartTheme theme,
  VarietySeries series,
);

/// Builds a shader for a series that overrides the default gradient.
///
/// Returning `null` falls through to [VarietySeries.gradient] or
/// [VarietySeries.borderGradient]. Returning a shader paints that shader
/// as the series fill / stroke instead.
typedef VarietyShaderFactory = Shader? Function(
  VarietySeries series,
  Rect bounds,
  // isFill: true for fill, false for stroke
  bool isFill,
);

/// Draws [VarietyElement] lists onto a canvas.
///
/// Every chart kind shares this renderer, so a series only has to describe its
/// geometry once and it renders identically in cartesian, circular, funnel and
/// sparkline charts.
class VarietyElementRenderer {
  /// Creates a renderer using the supplied [theme].
  const VarietyElementRenderer(this.theme);

  /// The resolved colours for this build.
  final VarietyChartTheme theme;

  /// Paints every element in order, skipping any series whose index is
  /// mapped to `false` in [visibleSeries].
  void paintAll(
    Canvas canvas,
    List<VarietyElement> elements, {
    Map<int, bool>? visibleSeries,
  }) {
    for (final VarietyElement element in elements) {
      final int? idx = element.seriesIndex;
      if (idx != null && visibleSeries?[idx] == false) {
        continue;
      }
      paint(canvas, element);
    }
  }

  /// Paints a single element, with optional series context for callbacks like
  /// [VarietySeries.onCreateShader].
  void paintWith(Canvas canvas, VarietyElement element, VarietySeries? series) {
    switch (element) {
      case VarietyPathElement():
        drawPath(canvas, element, series: series);
      case VarietyRectsElement():
        drawRects(canvas, element);
      case VarietySegmentsElement():
        drawSegments(canvas, element);
      case VarietyMarkersElement():
        drawMarkers(canvas, element);
      case VarietyBubblesElement():
        drawBubbles(canvas, element);
      case VarietyLabelsElement():
        drawLabels(canvas, element);
    }
  }

  /// Paints a single element.
  void paint(Canvas canvas, VarietyElement element) {
    switch (element) {
      case VarietyPathElement():
        drawPath(canvas, element);
      case VarietyRectsElement():
        drawRects(canvas, element);
      case VarietySegmentsElement():
        drawSegments(canvas, element);
      case VarietyMarkersElement():
        drawMarkers(canvas, element);
      case VarietyBubblesElement():
        drawBubbles(canvas, element);
      case VarietyLabelsElement():
        drawLabels(canvas, element);
    }
  }

  /// Paints a stroked and optionally filled path.
  ///
  /// When [series] is provided the renderer asks it for an
  /// [VarietySeries.onCreateShader]; a non-null shader overrides
  /// [element.fillGradient] / [element.strokeGradient].
  void drawPath(Canvas canvas, VarietyPathElement element,
      {VarietySeries? series, Rect? bounds}) {
    final Rect resolved = bounds ?? element.path.getBounds();
    if (element.fillGradient != null ||
        element.fillColor != null ||
        (series?.onCreateShader != null &&
            series!.onCreateShader!(series, resolved, true) != null)) {
      final Paint paint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = element.antiAlias;
      final Shader? shader =
          series?.onCreateShader?.call(series, resolved, true);
      if (shader != null) {
        paint.shader = shader;
      } else if (element.fillGradient != null) {
        paint.shader = element.fillGradient!.createShader(resolved);
      } else {
        paint.color = element.fillColor!.withValues(
          alpha: element.fillColor!.a * element.fillOpacity,
        );
      }
      canvas.drawPath(element.path, paint);
    }
    if ((element.strokeGradient == null && element.strokeColor == null) ||
        element.strokeWidth <= 0) {
      return;
    }
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = element.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = element.antiAlias;
    final Shader? shader =
        series?.onCreateShader?.call(series, resolved, false);
    if (shader != null) {
      paint.shader = shader;
    } else if (element.strokeGradient != null) {
      paint.shader = element.strokeGradient!.createShader(resolved);
    } else {
      paint.color = element.strokeColor!.withValues(
        alpha: element.strokeColor!.a * element.strokeOpacity,
      );
    }
    if (element.dashPattern.isEmpty) {
      canvas.drawPath(element.path, paint);
    } else {
      dashPath(canvas, element.path, paint, element.dashPattern);
    }
  }

  /// Paints a set of rectangles.
  void drawRects(Canvas canvas, VarietyRectsElement element) {
    for (final Rect rect in element.rects) {
      if (rect.width <= 0 || rect.height <= 0) {
        continue;
      }
      final RRect rrect =
          RRect.fromRectAndRadius(rect, Radius.circular(element.radius));
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = element.color
          ..isAntiAlias = true,
      );
      if (element.border != null && element.borderWidth > 0) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = element.border!
            ..style = PaintingStyle.stroke
            ..strokeWidth = element.borderWidth
            ..isAntiAlias = true,
        );
      }
    }
  }

  /// Paints a set of straight segments.
  void drawSegments(Canvas canvas, VarietySegmentsElement element) {
    final Paint paint = Paint()
      ..color = element.color
      ..strokeWidth = element.width
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    for (final VarietySegment segment in element.segments) {
      drawLine(canvas, segment.from, segment.to, paint, element.dashPattern);
    }
  }

  /// Paints a set of markers.
  void drawMarkers(Canvas canvas, VarietyMarkersElement element) {
    for (final VarietyMarker marker in element.markers) {
      final double size = marker.size ?? element.size;
      final Path path = markerPath(element.shape, marker.center, size);
      final Color color = marker.color ?? element.color;
      if (isStrokeMarker(element.shape)) {
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(size * 0.22, 1.4)
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true,
        );
        continue;
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      if (element.border != null) {
        canvas.drawPath(
          path,
          Paint()
            ..color = element.border!
            ..style = PaintingStyle.stroke
            ..strokeWidth = element.borderWidth
            ..isAntiAlias = true,
        );
      }
    }
  }

  /// Paints a set of bubbles.
  void drawBubbles(Canvas canvas, VarietyBubblesElement element) {
    for (final VarietyBubble bubble in element.bubbles) {
      if (bubble.radius <= 0) {
        continue;
      }
      final Color color = bubble.color ?? element.color;
      canvas.drawCircle(
        bubble.center,
        bubble.radius,
        Paint()
          ..color = color.withValues(alpha: color.a * element.fillOpacity)
          ..isAntiAlias = true,
      );
      if (element.border != null && element.borderWidth > 0) {
        canvas.drawCircle(
          bubble.center,
          bubble.radius,
          Paint()
            ..color = element.border!
            ..style = PaintingStyle.stroke
            ..strokeWidth = element.borderWidth
            ..isAntiAlias = true,
        );
      }
    }
  }

  /// Paints a set of captions.
  void drawLabels(Canvas canvas, VarietyLabelsElement element) {
    for (final VarietyLabelItem item in element.labels) {
      final TextStyle style = (element.style ?? const TextStyle(fontSize: 11))
          .copyWith(
              color: item.color ?? element.style?.color ?? theme.labelColor);
      final TextPainter painter = layoutText(item.text, style);
      painter.paint(canvas, anchorFor(painter, item));
    }
  }

  /// Resolves the top-left corner a caption should be painted at.
  Offset anchorFor(TextPainter painter, VarietyLabelItem item) {
    switch (item.position) {
      case VarietyLabelPosition.top:
      case VarietyLabelPosition.outside:
        return Offset(
          item.anchor.dx - painter.width / 2,
          item.anchor.dy - painter.height - item.offset,
        );
      case VarietyLabelPosition.bottom:
        return Offset(
            item.anchor.dx - painter.width / 2, item.anchor.dy + item.offset);
      case VarietyLabelPosition.left:
        return Offset(
          item.anchor.dx - painter.width - item.offset,
          item.anchor.dy - painter.height / 2,
        );
      case VarietyLabelPosition.right:
        return Offset(
            item.anchor.dx + item.offset, item.anchor.dy - painter.height / 2);
      case VarietyLabelPosition.inside:
      case VarietyLabelPosition.auto:
        return Offset(
          item.anchor.dx - painter.width / 2,
          item.anchor.dy - painter.height - item.offset,
        );
    }
  }

  /// Lays out a single-line text run.
  TextPainter layoutText(String text, TextStyle style) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
  }

  /// Draws a line, honouring an optional dash pattern.
  void drawLine(
      Canvas canvas, Offset from, Offset to, Paint paint, List<double> dash) {
    // A line is always a stroked primitive. Callers build paints inline
    // without setting a style; the fill default would silently drop
    // strokeWidth and rasterize the guide (grid, trackball, crosshair)
    // as a ~1px hairline regardless of the configured width.
    paint.style = PaintingStyle.stroke;
    if (dash.isEmpty) {
      canvas.drawLine(from, to, paint);
      return;
    }
    final Path path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy);
    dashPath(canvas, path, paint, dash);
  }

  /// Draws a path using a dash pattern.
  void dashPath(Canvas canvas, Path path, Paint paint, List<double> pattern) {
    if (pattern.isEmpty) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      int index = 0;
      while (distance < metric.length) {
        final double length = pattern[index % pattern.length];
        final double next = math.min(distance + length, metric.length);
        if (index.isEven) {
          canvas.drawPath(metric.extractPath(distance, next), paint);
        }
        distance = next;
        index++;
      }
    }
  }

  /// Whether a marker shape is drawn with strokes rather than a fill.
  static bool isStrokeMarker(VarietyMarkerShape shape) =>
      shape == VarietyMarkerShape.plus || shape == VarietyMarkerShape.cross;

  /// Builds the path of a marker glyph.
  Path markerPath(VarietyMarkerShape shape, Offset center, double size) {
    final double half = size / 2;
    final Path path = Path();
    switch (shape) {
      case VarietyMarkerShape.circle:
        path.addOval(Rect.fromCircle(center: center, radius: half));
      case VarietyMarkerShape.square:
        path.addRect(
            Rect.fromCenter(center: center, width: size, height: size));
      case VarietyMarkerShape.diamond:
        path
          ..moveTo(center.dx, center.dy - half)
          ..lineTo(center.dx + half, center.dy)
          ..lineTo(center.dx, center.dy + half)
          ..lineTo(center.dx - half, center.dy)
          ..close();
      case VarietyMarkerShape.triangle:
        path
          ..moveTo(center.dx, center.dy - half)
          ..lineTo(center.dx + half, center.dy + half)
          ..lineTo(center.dx - half, center.dy + half)
          ..close();
      case VarietyMarkerShape.invertedTriangle:
        path
          ..moveTo(center.dx, center.dy + half)
          ..lineTo(center.dx + half, center.dy - half)
          ..lineTo(center.dx - half, center.dy - half)
          ..close();
      case VarietyMarkerShape.plus:
        path
          ..moveTo(center.dx - half, center.dy)
          ..lineTo(center.dx + half, center.dy)
          ..moveTo(center.dx, center.dy - half)
          ..lineTo(center.dx, center.dy + half);
      case VarietyMarkerShape.cross:
        path
          ..moveTo(center.dx - half, center.dy - half)
          ..lineTo(center.dx + half, center.dy + half)
          ..moveTo(center.dx + half, center.dy - half)
          ..lineTo(center.dx - half, center.dy + half);
    }
    return path;
  }
}

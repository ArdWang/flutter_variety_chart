import io

# ---------------------------------------------------------------- elements: gradients
p = 'lib/src/render/variety_elements.dart'
s = io.open(p, encoding='utf-8').read()
o = s
s = s.replace(
    """    this.fillOpacity = 1.0,
    this.strokeOpacity = 1.0,
    this.antiAlias = true,
  });""",
    """    this.fillOpacity = 1.0,
    this.strokeOpacity = 1.0,
    this.antiAlias = true,
    this.fillGradient,
    this.strokeGradient,
  });""",
    1,
)
s = s.replace(
    """  /// Whether the path is drawn with anti-aliasing. Disabling it is faster and
  /// is what the fast line series does.
  final bool antiAlias;
}""",
    """  /// Whether the path is drawn with anti-aliasing. Disabling it is faster and
  /// is what the fast line series does.
  final bool antiAlias;

  /// A gradient painted inside the path, overriding [fillColor].
  final Gradient? fillGradient;

  /// A gradient stroked along the path, overriding [strokeColor].
  final Gradient? strokeGradient;
}""",
    1,
)
assert s != o
io.open(p, 'w', encoding='utf-8').write(s)
print('elements patched')

# ---------------------------------------------------------------- renderer: shader support
p = 'lib/src/painters/variety_element_renderer.dart'
s = io.open(p, encoding='utf-8').read()
o = s
s = s.replace(
    """  /// Paints a stroked and optionally filled path.
  void drawPath(Canvas canvas, VarietyPathElement element) {
    if (element.fillColor != null) {
      canvas.drawPath(
        element.path,
        Paint()
          ..color = element.fillColor!.withValues(
            alpha: element.fillColor!.a * element.fillOpacity,
          )
          ..style = PaintingStyle.fill
          ..isAntiAlias = element.antiAlias,
      );
    }
    if (element.strokeColor == null || element.strokeWidth <= 0) {
      return;
    }
    final Paint paint = Paint()
      ..color = element.strokeColor!.withValues(
        alpha: element.strokeColor!.a * element.strokeOpacity,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = element.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = element.antiAlias;""",
    """  /// Paints a stroked and optionally filled path.
  void drawPath(Canvas canvas, VarietyPathElement element) {
    final Rect bounds = element.path.getBounds();
    if (element.fillGradient != null || element.fillColor != null) {
      final Paint paint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = element.antiAlias;
      if (element.fillGradient != null) {
        paint.shader = element.fillGradient!.createShader(bounds);
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
    if (element.strokeGradient != null) {
      paint.shader = element.strokeGradient!.createShader(bounds);
    } else {
      paint.color = element.strokeColor!.withValues(
        alpha: element.strokeColor!.a * element.strokeOpacity,
      );
    }""",
    1,
)
# the dash branch used element.strokeColor; keep it working by guarding on the paint only
s = s.replace(
    """    if (element.dashPattern.isEmpty) {
      canvas.drawPath(element.path, paint);
    } else {
      dashPath(canvas, element.path, paint, element.dashPattern);
    }
  }

  /// Paints a set of rectangles.""",
    """    if (element.dashPattern.isEmpty) {
      canvas.drawPath(element.path, paint);
    } else {
      dashPath(canvas, element.path, paint, element.dashPattern);
    }
  }

  /// Paints a set of rectangles.""",
    1,
)
assert s != o
io.open(p, 'w', encoding='utf-8').write(s)
print('renderer patched')

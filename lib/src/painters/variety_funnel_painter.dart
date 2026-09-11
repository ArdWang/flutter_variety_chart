import 'package:flutter/material.dart';

import '../render/variety_chart_theme.dart';
import '../render/variety_geometry.dart';
import 'variety_element_renderer.dart';

/// Paints a funnel or pyramid chart.
class VarietyFunnelPainter extends CustomPainter {
  /// Creates a painter for the supplied [geometry].
  VarietyFunnelPainter({
    required this.geometry,
    required this.theme,
    this.highlights = const <VarietyHitResult>[],
  });

  /// The pre-computed segment layout shared with hit testing.
  final VarietyFunnelGeometry geometry;

  /// The resolved colours for this build.
  final VarietyChartTheme theme;

  /// The points that should be highlighted.
  final List<VarietyHitResult> highlights;

  @override
  void paint(Canvas canvas, Size size) {
    final VarietyElementRenderer renderer = VarietyElementRenderer(theme);
    renderer.paintAll(canvas, geometry.elements);
    for (final VarietyHitResult hit in highlights) {
      if (hit.pointIndex >= geometry.segments.length) {
        continue;
      }
      canvas.drawCircle(
        geometry.segments[hit.pointIndex].center,
        8,
        Paint()
          ..color = theme.markerBorderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant VarietyFunnelPainter oldDelegate) => true;
}

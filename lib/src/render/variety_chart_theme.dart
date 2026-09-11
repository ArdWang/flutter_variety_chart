import 'package:flutter/material.dart';

/// Resolved colours used while painting a chart.
///
/// A theme is derived once per build from the ambient [ThemeData] so that
/// charts automatically follow light and dark surfaces.
@immutable
class VarietyChartTheme {
  /// Creates a chart theme.
  const VarietyChartTheme({
    required this.gridLineColor,
    required this.axisLineColor,
    required this.labelColor,
    required this.tooltipBackgroundColor,
    required this.tooltipTextColor,
    required this.markerBorderColor,
  });

  /// Derives a theme from the surrounding [context].
  factory VarietyChartTheme.of(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color onSurface = theme.colorScheme.onSurface;
    return VarietyChartTheme(
      gridLineColor: onSurface.withValues(alpha: isDark ? 0.18 : 0.12),
      axisLineColor: onSurface.withValues(alpha: isDark ? 0.45 : 0.35),
      labelColor: onSurface.withValues(alpha: 0.75),
      tooltipBackgroundColor:
          isDark ? const Color(0xFF2C2C33) : const Color(0xFF32323A),
      tooltipTextColor: Colors.white,
      markerBorderColor: theme.colorScheme.surface,
    );
  }

  /// The colour of grid lines drawn across the plot area.
  final Color gridLineColor;

  /// The colour of the axis lines.
  final Color axisLineColor;

  /// The colour applied to tick labels.
  final Color labelColor;

  /// The background colour of the tooltip card.
  final Color tooltipBackgroundColor;

  /// The text colour inside the tooltip card.
  final Color tooltipTextColor;

  /// The outline drawn around markers so they stay legible when overlapping.
  final Color markerBorderColor;
}

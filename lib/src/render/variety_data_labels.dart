import '../models/variety_chart_data.dart';
import '../models/variety_series.dart';
import '../utils/variety_label_utils.dart';

/// The caption a data label shows for [point], or `null` when the settings
/// hide it.
///
/// Every family that draws data labels asks this, so a series level
/// [VarietySeries.dataLabelMapper], a [VarietyDataLabelSettings.builder] and
/// the "hide a zero" switch mean the same thing on a column, a slice and a
/// funnel segment.
///
/// Each family used to answer the question on its own, and two of the three
/// answered a shorter one: a pie and a funnel never consulted the mapper, and
/// captioned a zero the reader had asked to hide. Keeping one answer here is
/// what stops the three from drifting apart again.
///
/// [value] is the number the caption falls back to, and [fallback] is what a
/// family shows instead of that number when its points carry captions of their
/// own — a pie slice reads its label before its value. The text may come back
/// empty, because a caller decides for itself whether an empty caption is worth
/// drawing; a point the settings hide is reported as `null` instead, so that no
/// caller can draw one by accident.
String? varietyDataLabelCaption(
  VarietySeries series,
  VarietyChartData point,
  int pointIndex,
  double value, {
  String? fallback,
}) {
  final VarietyDataLabelSettings settings = series.dataLabelSettings;
  if (!settings.showZeroValue && (point.y ?? 0) == 0) {
    return null;
  }
  return series.dataLabelMapper?.call(point, pointIndex) ??
      settings.builder?.call(point) ??
      fallback ??
      varietyFormatNumber(value);
}

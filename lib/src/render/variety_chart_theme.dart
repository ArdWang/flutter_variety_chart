import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Resolved colours and text styles used while painting a chart.
///
/// A theme is derived once per build from the ambient [ThemeData] so that
/// charts automatically follow light and dark surfaces. Every extra field is
/// optional: leaving one out falls back to the six base colours, which in turn
/// come from the surrounding theme.
///
/// Set one for the whole app with [VarietyChartThemeScope], or hand a single
/// chart a theme through its own `theme` argument.
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
    Color? minorGridLineColor,
    Color? majorTickLineColor,
    Color? axisTitleColor,
    Color? titleTextColor,
    Color? titleBackgroundColor,
    Color? legendTextColor,
    Color? legendTitleColor,
    Color? legendBackgroundColor,
    Color? plotAreaBackgroundColor,
    Color? plotAreaBorderColor,
    Color? dataLabelColor,
    Color? crosshairLineColor,
    Color? selectionRectColor,
    Color? selectionRectBorderColor,
    Color? tooltipSeparatorColor,
    List<Color>? palette,
    this.titleTextStyle,
    this.axisLabelTextStyle,
    this.axisTitleTextStyle,
    this.legendTextStyle,
    this.legendTitleTextStyle,
    this.tooltipTextStyle,
    this.dataLabelTextStyle,
  })  : _minorGridLineColor = minorGridLineColor,
        _majorTickLineColor = majorTickLineColor,
        _axisTitleColor = axisTitleColor,
        _titleTextColor = titleTextColor,
        _titleBackgroundColor = titleBackgroundColor,
        _legendTextColor = legendTextColor,
        _legendTitleColor = legendTitleColor,
        _legendBackgroundColor = legendBackgroundColor,
        _plotAreaBackgroundColor = plotAreaBackgroundColor,
        _plotAreaBorderColor = plotAreaBorderColor,
        _dataLabelColor = dataLabelColor,
        _crosshairLineColor = crosshairLineColor,
        _selectionRectColor = selectionRectColor,
        _selectionRectBorderColor = selectionRectBorderColor,
        _tooltipSeparatorColor = tooltipSeparatorColor,
        _palette = palette;

  /// Derives a theme from the surrounding [context].
  ///
  /// A [VarietyChartThemeScope] further up the tree wins, so an app can
  /// restyle every chart at once without touching each one.
  factory VarietyChartTheme.of(BuildContext context) {
    final VarietyChartTheme? scoped = VarietyChartThemeScope.maybeOf(context);
    if (scoped != null) {
      return scoped;
    }
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

  final Color? _minorGridLineColor;
  final Color? _majorTickLineColor;
  final Color? _axisTitleColor;
  final Color? _titleTextColor;
  final Color? _titleBackgroundColor;
  final Color? _legendTextColor;
  final Color? _legendTitleColor;
  final Color? _legendBackgroundColor;
  final Color? _plotAreaBackgroundColor;
  final Color? _plotAreaBorderColor;
  final Color? _dataLabelColor;
  final Color? _crosshairLineColor;
  final Color? _selectionRectColor;
  final Color? _selectionRectBorderColor;
  final Color? _tooltipSeparatorColor;
  final List<Color>? _palette;

  /// The colour of the minor grid lines. Defaults to a fainter [gridLineColor].
  Color get minorGridLineColor =>
      _minorGridLineColor ?? gridLineColor.withValues(alpha: 0.6);

  /// The colour of the major tick marks. Defaults to [axisLineColor].
  Color get majorTickLineColor => _majorTickLineColor ?? axisLineColor;

  /// The colour of the axis titles. Defaults to [labelColor].
  Color get axisTitleColor => _axisTitleColor ?? labelColor;

  /// The colour of the chart title. Defaults to [labelColor].
  Color get titleTextColor => _titleTextColor ?? labelColor;

  /// A fill drawn behind the chart title. Null draws no fill.
  Color? get titleBackgroundColor => _titleBackgroundColor;

  /// The colour of the legend entries. Defaults to [labelColor].
  Color get legendTextColor => _legendTextColor ?? labelColor;

  /// The colour of the legend title. Defaults to [legendTextColor].
  Color get legendTitleColor => _legendTitleColor ?? legendTextColor;

  /// A fill drawn behind the legend. Null draws no fill.
  Color? get legendBackgroundColor => _legendBackgroundColor;

  /// A fill drawn behind the plot area. Null draws no fill.
  Color? get plotAreaBackgroundColor => _plotAreaBackgroundColor;

  /// The outline of the plot area. Null draws no outline.
  Color? get plotAreaBorderColor => _plotAreaBorderColor;

  /// The colour of data labels. Defaults to [labelColor].
  Color get dataLabelColor => _dataLabelColor ?? labelColor;

  /// The colour of the crosshair guides. Defaults to [axisLineColor].
  Color get crosshairLineColor => _crosshairLineColor ?? axisLineColor;

  /// The fill of the rubber-band selection rectangle.
  Color get selectionRectColor =>
      _selectionRectColor ?? axisLineColor.withValues(alpha: 0.16);

  /// The outline of the rubber-band selection rectangle. Defaults to
  /// [axisLineColor].
  Color get selectionRectBorderColor =>
      _selectionRectBorderColor ?? axisLineColor;

  /// The rule drawn between the header and the rows of a shared tooltip.
  /// Defaults to [tooltipTextColor] at low opacity.
  Color get tooltipSeparatorColor =>
      _tooltipSeparatorColor ?? tooltipTextColor.withValues(alpha: 0.2);

  /// The series colours, cycled by series index. Null uses the built-in
  /// palette.
  List<Color>? get palette => _palette;

  /// The text style of the chart title.
  final TextStyle? titleTextStyle;

  /// The text style of axis tick labels.
  final TextStyle? axisLabelTextStyle;

  /// The text style of axis titles.
  final TextStyle? axisTitleTextStyle;

  /// The text style of legend entries.
  final TextStyle? legendTextStyle;

  /// The text style of the legend title.
  final TextStyle? legendTitleTextStyle;

  /// The text style inside a tooltip card.
  final TextStyle? tooltipTextStyle;

  /// The text style of data labels.
  final TextStyle? dataLabelTextStyle;

  /// Returns a copy of this theme with the supplied fields replaced.
  VarietyChartTheme copyWith({
    Color? gridLineColor,
    Color? axisLineColor,
    Color? labelColor,
    Color? tooltipBackgroundColor,
    Color? tooltipTextColor,
    Color? markerBorderColor,
    Color? minorGridLineColor,
    Color? majorTickLineColor,
    Color? axisTitleColor,
    Color? titleTextColor,
    Color? titleBackgroundColor,
    Color? legendTextColor,
    Color? legendTitleColor,
    Color? legendBackgroundColor,
    Color? plotAreaBackgroundColor,
    Color? plotAreaBorderColor,
    Color? dataLabelColor,
    Color? crosshairLineColor,
    Color? selectionRectColor,
    Color? selectionRectBorderColor,
    Color? tooltipSeparatorColor,
    List<Color>? palette,
    TextStyle? titleTextStyle,
    TextStyle? axisLabelTextStyle,
    TextStyle? axisTitleTextStyle,
    TextStyle? legendTextStyle,
    TextStyle? legendTitleTextStyle,
    TextStyle? tooltipTextStyle,
    TextStyle? dataLabelTextStyle,
  }) {
    return VarietyChartTheme(
      gridLineColor: gridLineColor ?? this.gridLineColor,
      axisLineColor: axisLineColor ?? this.axisLineColor,
      labelColor: labelColor ?? this.labelColor,
      tooltipBackgroundColor:
          tooltipBackgroundColor ?? this.tooltipBackgroundColor,
      tooltipTextColor: tooltipTextColor ?? this.tooltipTextColor,
      markerBorderColor: markerBorderColor ?? this.markerBorderColor,
      minorGridLineColor: minorGridLineColor ?? _minorGridLineColor,
      majorTickLineColor: majorTickLineColor ?? _majorTickLineColor,
      axisTitleColor: axisTitleColor ?? _axisTitleColor,
      titleTextColor: titleTextColor ?? _titleTextColor,
      titleBackgroundColor: titleBackgroundColor ?? _titleBackgroundColor,
      legendTextColor: legendTextColor ?? _legendTextColor,
      legendTitleColor: legendTitleColor ?? _legendTitleColor,
      legendBackgroundColor: legendBackgroundColor ?? _legendBackgroundColor,
      plotAreaBackgroundColor:
          plotAreaBackgroundColor ?? _plotAreaBackgroundColor,
      plotAreaBorderColor: plotAreaBorderColor ?? _plotAreaBorderColor,
      dataLabelColor: dataLabelColor ?? _dataLabelColor,
      crosshairLineColor: crosshairLineColor ?? _crosshairLineColor,
      selectionRectColor: selectionRectColor ?? _selectionRectColor,
      selectionRectBorderColor:
          selectionRectBorderColor ?? _selectionRectBorderColor,
      tooltipSeparatorColor: tooltipSeparatorColor ?? _tooltipSeparatorColor,
      palette: palette ?? _palette,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      axisLabelTextStyle: axisLabelTextStyle ?? this.axisLabelTextStyle,
      axisTitleTextStyle: axisTitleTextStyle ?? this.axisTitleTextStyle,
      legendTextStyle: legendTextStyle ?? this.legendTextStyle,
      legendTitleTextStyle: legendTitleTextStyle ?? this.legendTitleTextStyle,
      tooltipTextStyle: tooltipTextStyle ?? this.tooltipTextStyle,
      dataLabelTextStyle: dataLabelTextStyle ?? this.dataLabelTextStyle,
    );
  }

  /// Every field, in a fixed order, for equality and hashing.
  List<Object?> get _identity => <Object?>[
        gridLineColor,
        axisLineColor,
        labelColor,
        tooltipBackgroundColor,
        tooltipTextColor,
        markerBorderColor,
        _minorGridLineColor,
        _majorTickLineColor,
        _axisTitleColor,
        _titleTextColor,
        _titleBackgroundColor,
        _legendTextColor,
        _legendTitleColor,
        _legendBackgroundColor,
        _plotAreaBackgroundColor,
        _plotAreaBorderColor,
        _dataLabelColor,
        _crosshairLineColor,
        _selectionRectColor,
        _selectionRectBorderColor,
        _tooltipSeparatorColor,
        _palette,
        titleTextStyle,
        axisLabelTextStyle,
        axisTitleTextStyle,
        legendTextStyle,
        legendTitleTextStyle,
        tooltipTextStyle,
        dataLabelTextStyle,
      ];

  @override
  bool operator ==(Object other) =>
      other is VarietyChartTheme &&
      other.runtimeType == runtimeType &&
      listEquals(other._identity, _identity);

  @override
  int get hashCode => Object.hashAll(_identity);
}

/// Applies a [VarietyChartTheme] to every chart below it.
///
/// ```dart
/// VarietyChartThemeScope(
///   data: VarietyChartTheme.of(context).copyWith(
///     gridLineColor: Colors.black12,
///     palette: <Color>[Colors.indigo, Colors.teal],
///   ),
///   child: MyDashboard(),
/// )
/// ```
class VarietyChartThemeScope extends InheritedWidget {
  /// Applies [data] to the charts below this widget.
  const VarietyChartThemeScope({
    super.key,
    required this.data,
    required super.child,
  });

  /// The theme the charts below should use.
  final VarietyChartTheme data;

  /// The theme of the nearest scope, or `null` when there is none.
  static VarietyChartTheme? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<VarietyChartThemeScope>()
      ?.data;

  /// The theme of the nearest scope.
  ///
  /// Throws when there is no scope, so prefer [VarietyChartTheme.of] unless
  /// the scope is known to exist.
  static VarietyChartTheme of(BuildContext context) {
    final VarietyChartTheme? theme = maybeOf(context);
    assert(theme != null, 'No VarietyChartThemeScope found in context');
    return theme!;
  }

  @override
  bool updateShouldNotify(VarietyChartThemeScope oldWidget) =>
      data != oldWidget.data;
}

import io

p = 'lib/src/models/variety_series.dart'
s = io.open(p, encoding='utf-8').read()
orig = s

# ---- imports
s = s.replace(
    "import 'variety_enums.dart';\nimport 'variety_options.dart';",
    "import 'variety_enums.dart';\nimport 'variety_marker_settings.dart';\nimport 'variety_options.dart';",
    1,
)

# ---- base constructor params
s = s.replace(
    """    this.errorBar,
    this.xAxisName,
    this.yAxisName,
  });""",
    """    this.errorBar,
    this.xAxisName,
    this.yAxisName,
    this.markerSettings,
    this.gradient,
    this.borderGradient,
    this.enableTrackball = true,
    this.initialIsVisible = true,
    this.isVisibleInLegend = true,
    this.legendItemText,
    this.animationDuration,
    this.initialSelectedDataIndexes = const <int>[],
    this.onPointTap,
    this.onPointDoubleTap,
    this.onPointLongPress,
  });""",
    1,
)

# ---- base fields
s = s.replace(
    """  /// The name of the secondary axis this series is plotted against.
  ///
  /// When `null` the series uses the chart's primary secondary axis.
  final String? yAxisName;""",
    """  /// The name of the secondary axis this series is plotted against.
  ///
  /// When `null` the series uses the chart's primary secondary axis.
  final String? yAxisName;

  /// A grouped marker configuration.
  ///
  /// When supplied it wins over the individual marker properties declared by a
  /// concrete series.
  final VarietyMarkerSettings? markerSettings;

  /// A gradient painted inside the series shape.
  final Gradient? gradient;

  /// A gradient painted along the series outline.
  final Gradient? borderGradient;

  /// Whether the trackball picks this series up.
  final bool enableTrackball;

  /// Whether the series is visible when the chart first appears.
  final bool initialIsVisible;

  /// Whether the series is listed in the legend.
  final bool isVisibleInLegend;

  /// The caption shown by the legend. Falls back to [name].
  final String? legendItemText;

  /// How long this series animates for. Falls back to the chart duration.
  final Duration? animationDuration;

  /// The data indexes selected when the chart first appears.
  final List<int> initialSelectedDataIndexes;

  /// Called when a point of this series is tapped.
  final void Function(VarietyChartData point, int index)? onPointTap;

  /// Called when a point of this series is double tapped.
  final void Function(VarietyChartData point, int index)? onPointDoubleTap;

  /// Called when a point of this series is long pressed.
  final void Function(VarietyChartData point, int index)? onPointLongPress;""",
    1,
)

# ---- forward the new fields from every concrete series
s = s.replace(
    "    super.animationDelay,\n",
    "    super.animationDelay,\n"
    "    super.markerSettings,\n"
    "    super.gradient,\n"
    "    super.borderGradient,\n"
    "    super.enableTrackball,\n"
    "    super.initialIsVisible,\n"
    "    super.isVisibleInLegend,\n"
    "    super.legendItemText,\n"
    "    super.animationDuration,\n"
    "    super.initialSelectedDataIndexes,\n"
    "    super.onPointTap,\n"
    "    super.onPointDoubleTap,\n"
    "    super.onPointLongPress,\n",
)

assert s != orig
io.open(p, 'w', encoding='utf-8').write(s)
print('base extended; super forwardings:', s.count('super.onPointLongPress,'))

import io

# 1) Add the field declaration properly (exact text in current file)
M = 'lib/src/models/variety_series.dart'
m = io.open(M, encoding='utf-8').read()

m = m.replace(
    "  /// The order the points are sorted into before they are plotted.\n"
    "  final VarietySortingOrder sortingOrder;\n"
    "\n"
    "  /// An optional error bar drawn alongside this series.",
    "  /// The order the points are sorted into before they are plotted.\n"
    "  final VarietySortingOrder sortingOrder;\n"
    "\n"
    "  /// A mapper that returns the value used for ordering when\n"
    "  /// [sortingOrder] is not [VarietySortingOrder.none].\n"
    "  ///\n"
    "  /// When `null` the x coordinate is used. Override this to sort by a\n"
    "  /// derived value, e.g. by a numeric column on your data record.\n"
    "  final double Function(VarietyChartData point)? sortFieldValueMapper;\n"
    "\n"
    "  /// An optional error bar drawn alongside this series.",
    1,
)
assert 'sortFieldValueMapper' in m, 'field decl not inserted'
io.open(M, 'w', encoding='utf-8').write(m)
print('field declared')

# 2) Painter: revert the broken override and use a different channel
P = 'lib/src/painters/variety_cartesian_painter.dart'
p = io.open(P, encoding='utf-8').read()

p = p.replace(
    "  @override\n"
    "  void paint(Canvas canvas, Size size, {double progress = 1}) {\n"
    "    // The widget may ask the painter to skip series that should start hidden.\n"
    "    for (int s = 0; s < geometry.series.length; s++) {\n"
    "      _seriesVisible[s] = geometry.series[s].initialIsVisible;\n"
    "    }\n"
    "    _paintPlotBands(canvas);",
    "  @override\n"
    "  void paint(Canvas canvas, Size size) {\n"
    "    for (int s = 0; s < geometry.series.length; s++) {\n"
    "      _seriesVisible[s] = geometry.series[s].initialIsVisible;\n"
    "    }\n"
    "    _paintPlotBands(canvas);",
    1,
)

# add the field at the top
if '_seriesVisible' not in p:
    p = p.replace(
        "  final VarietyCartesianGeometry geometry;",
        "  final VarietyCartesianGeometry geometry;\n"
        "  /// Toggle from the chart widget to honour [VarietySeries.initialIsVisible].\n"
        "  final Map<int, bool> _seriesVisible = <int, bool>{};",
        1,
    )

# gate rendering by visibility
p = p.replace(
    "      _renderer.paintAll(canvas, geometry.elements);",
    "      for (final VarietyElement el in geometry.elements) {\n"
    "        if (_seriesVisible[el.seriesIndex] == false) {\n"
    "          continue;\n"
    "        }\n"
    "        el.renderer.paint(canvas, el);\n"
    "      }",
    1,
)

# apply initialSelection: pre-tick the marker colour getter for those indexes
p = p.replace(
    "  Color markerFillFor(int seriesIndex, int pointIndex, [Color? override]) {",
    "  bool isInitiallySelected(int seriesIndex, int pointIndex) {\n"
    "    final List<int> selection = geometry.series[seriesIndex].initialSelectedDataIndexes;\n"
    "    return selection.contains(pointIndex);\n"
    "  }\n"
    "\n"
    "  Color markerFillFor(int seriesIndex, int pointIndex, [Color? override]) {",
    1,
)

# gate trackball nearestPoint by enableTrackball
p = p.replace(
    "  VarietyChartPoint? nearestPoint(Offset position, {int? seriesHint}) {\n"
    "    if (geometry.series[seriesHint].enableTrackball == false && seriesHint != null) {\n"
    "      return null;\n"
    "    }",
    "  VarietyChartPoint? nearestPoint(Offset position, {int? seriesHint}) {\n"
    "    if (seriesHint != null && geometry.series[seriesHint].enableTrackball == false) {\n"
    "      return null;\n"
    "    }",
    1,
)

io.open(P, 'w', encoding='utf-8').write(p)
print('painter fixed')

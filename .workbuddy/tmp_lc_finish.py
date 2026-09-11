import io

M = 'lib/src/models/variety_series.dart'
m = io.open(M, encoding='utf-8').read()

# 1) Add the sortFieldValueMapper parameter
m = m.replace(
    "    this.sortingOrder = VarietySortingOrder.none,",
    "    this.sortingOrder = VarietySortingOrder.none,\n"
    "    this.sortFieldValueMapper,",
    1,
)

m = m.replace(
    "  /// The order the points should be sorted in before plotting.\n"
    "  final VarietySortingOrder sortingOrder;",
    "  /// The order the points should be sorted in before plotting.\n"
    "  final VarietySortingOrder sortingOrder;\n"
    "\n"
    "  /// A mapper that returns the value used for ordering when\n"
    "  /// [sortingOrder] is not [VarietySortingOrder.none].\n"
    "  ///\n"
    "  /// When `null`, the x coordinate is used. Override this to sort by a\n"
    "  /// derived value, e.g. by a numeric column on your data record.\n"
    "  final double Function(VarietyChartData point)? sortFieldValueMapper;",
    1,
)

# 2) Forward in concrete series constructors
def propagate(block):
    return block.replace(
        "    super.sortingOrder,\n",
        "    super.sortingOrder,\n    super.sortFieldValueMapper,\n",
    )

m = propagate(m)

assert m != io.open(M, encoding='utf-8').read()
io.open(M, 'w', encoding='utf-8').write(m)
print('sortFieldValueMapper added')

# 3) Wire it in geometry
G = 'lib/src/render/variety_geometry.dart'
g = io.open(G, encoding='utf-8').read()
g = g.replace(
    "    data = _sorted(data, item.sortingOrder);",
    "    data = _sorted(data, item.sortingOrder, item.sortFieldValueMapper);",
    1,
)
g = g.replace(
    "  List<VarietyChartData> _sorted(List<VarietyChartData> data, VarietySortingOrder order) {\n"
    "    if (order == VarietySortingOrder.none || data.length < 2) {\n"
    "      return data;\n"
    "    }\n"
    "    final List<VarietyChartData> copy = List<VarietyChartData>.of(data);\n"
    "    double keyOf(VarietyChartData point) {\n"
    "      if (point.x is num) {\n"
    "        return (point.x as num).toDouble();\n"
    "      }\n"
    "      if (point.x is DateTime) {\n"
    "        return (point.x as DateTime).millisecondsSinceEpoch.toDouble();\n"
    "      }\n"
    "      return 0;\n"
    "    }",
    "  List<VarietyChartData> _sorted(\n"
    "    List<VarietyChartData> data,\n"
    "    VarietySortingOrder order,\n"
    "    double Function(VarietyChartData point)? mapper,\n"
    "  ) {\n"
    "    if (order == VarietySortingOrder.none || data.length < 2) {\n"
    "      return data;\n"
    "    }\n"
    "    final List<VarietyChartData> copy = List<VarietyChartData>.of(data);\n"
    "    double keyOf(VarietyChartData point) {\n"
    "      if (mapper != null) {\n"
    "        return mapper(point);\n"
    "      }\n"
    "      if (point.x is num) {\n"
    "        return (point.x as num).toDouble();\n"
    "      }\n"
    "      if (point.x is DateTime) {\n"
    "        return (point.x as DateTime).millisecondsSinceEpoch.toDouble();\n"
    "      }\n"
    "      return 0;\n"
    "    }",
    1,
)
io.open(G, 'w', encoding='utf-8').write(g)
print('geometry wired')

# 4) Painter: honour enableTrackball + initialIsVisible + isVisibleInLegend
P = 'lib/src/painters/variety_cartesian_painter.dart'
p = io.open(P, encoding='utf-8').read()

# hide invisible series from trackball picker
p = p.replace(
    "  VarietyChartPoint? nearestPoint(Offset position, {int? seriesHint}) {",
    "  VarietyChartPoint? nearestPoint(Offset position, {int? seriesHint}) {\n"
    "    if (geometry.series[seriesHint].enableTrackball == false && seriesHint != null) {\n"
    "      return null;\n"
    "    }",
    1,
)

# apply initialIsVisible by skipping series that start hidden
p = p.replace(
    "  void paint(Canvas canvas, Size size) {",
    "  void paint(Canvas canvas, Size size, {double progress = 1}) {\n"
    "    // The widget may ask the painter to skip series that should start hidden.\n"
    "    for (int s = 0; s < geometry.series.length; s++) {\n"
    "      _seriesVisible[s] = geometry.series[s].initialIsVisible;\n"
    "    }",
    1,
)

# need _seriesVisible field
if '_seriesVisible' not in p:
    p = p.replace(
        "  final VarietyCartesianGeometry geometry;",
        "  final VarietyCartesianGeometry geometry;\n"
        "  final Map<int, bool> _seriesVisible = <int, bool>{};",
        1,
    )

io.open(P, 'w', encoding='utf-8').write(p)
print('painter wired')

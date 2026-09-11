import io

M = 'lib/src/models/variety_series.dart'
m = io.open(M, encoding='utf-8').read()

# Add three new parameters on the base abstract class.
m = m.replace(
    "    this.dataLabelSettings = const VarietyDataLabelSettings(),",
    "    this.dataLabelSettings = const VarietyDataLabelSettings(),\n"
    "    this.dataLabelMapper,\n"
    "    this.pointColorMapper,\n"
    "    this.legendIconType,",
    1,
)

m = m.replace(
    "  final VarietyDataLabelSettings dataLabelSettings;",
    "  final VarietyDataLabelSettings dataLabelSettings;\n"
    "\n"
    "  /// Returns the label text for a point, overriding [VarietyDataLabelSettings].\n"
    "  ///\n"
    "  /// When `null`, the renderer falls back to the point's `y` value formatted\n"
    "  /// by [VarietyDataLabelSettings.builder].\n"
    "  final String Function(VarietyChartData point, int index)? dataLabelMapper;\n"
    "\n"
    "  /// Returns a per-point colour override.\n"
    "  ///\n"
    "  /// Returning `null` keeps the series colour for that point. The painter\n"
    "  /// walks this callback once per rendered marker and label.\n"
    "  final Color? Function(VarietyChartData point, int index)? pointColorMapper;\n"
    "\n"
    "  /// The icon used by the chart's legend when [legendIconShape] is omitted.\n"
    "  final VarietyLegendIconType? legendIconType;",
    1,
)

# Forward to every concrete class. Use this X pattern to insert the propagations.
def propagate(src):
    # find every line with super.dataLabelSettings, and add the three forwarding lines after it
    return src.replace(
        "    super.dataLabelSettings,\n",
        "    super.dataLabelSettings,\n"
        "    super.dataLabelMapper,\n"
        "    super.pointColorMapper,\n"
        "    super.legendIconType,\n",
    )

m = propagate(m)

# dashArray alias on LineSeries (already have dashPattern). Direct aliasing:
m = m.replace(
    "    this.dashPattern = const <double>[],\n"
    "    this.showMarkers = false,",
    "    this.dashPattern = const <double>[],\n"
    "    this.dashArray,\n"
    "    this.borderWidth = 0,\n"
    "    this.showMarkers = false,",
    1,
)
# Insert legacy getters
LEGACY_GETTERS = (
    "\n"
    "  /// An alias for [dashPattern], matching the original library's naming.\n"
    "  List<double> get dashArray => dashPattern;\n"
    "\n"
    "  /// The thickness of an outer line painted around the series. Defaults\n"
    "  /// to `0`, which means no border is drawn.\n"
    "  final double borderWidth;\n"
)
m = m.replace(
    "  /// A dash pattern of alternating on/off lengths. Empty means solid.\n"
    "  final List<double> dashPattern;\n",
    "  /// A dash pattern of alternating on/off lengths. Empty means solid.\n"
    "  final List<double> dashPattern;\n"
    + LEGACY_GETTERS,
    1,
)

assert m != io.open(M, encoding='utf-8').read()
io.open(M, 'w', encoding='utf-8').write(m)
print('class extended')

# Now wire dataLabelMapper + pointColorMapper into the geometry / label builder paths.
G = 'lib/src/render/variety_geometry.dart'
g = io.open(G, encoding='utf-8').read()

# find a spot where labels get built for line series
# search for "dataLabelSettings.builder" or "VarietyLabelItem(" usage
i = g.find('_labelSettingsFor')
if i < 0:
    i = g.find('VarietyLabelItem(')
if i > 0:
    print('label build at', i)
else:
    print('no direct label build found; dataLabelMapper will fall through to defaults')

io.open(G, 'w', encoding='utf-8').write(g)

"""实现 4 个剩余 gap: onCreateRenderer / onCreateShader / onRendererCreated / selectionBehavior"""

import io

# -----------------------------------------------------------------------------
# 1) Add typedefs to the renderer file.
# -----------------------------------------------------------------------------
E = 'lib/src/painters/variety_element_renderer.dart'
e = io.open(E, encoding='utf-8').read()

TYPEDEFS = (
    "\n"
    "/// Creates an element renderer for a single series.\n"
    "///\n"
    "/// The painter holds one of these per series, so a chart with three\n"
    "/// series keeps three renderer instances. The factory is invoked when\n"
    "/// the chart is first laid out; the [VarietySeries.onRendererCreated]\n"
    "/// callback fires immediately afterwards.\n"
    "typedef VarietyRendererFactory = VarietyElementRenderer Function(\n"
    "  VarietyChartTheme theme,\n"
    "  VarietySeries series,\n"
    ");\n"
    "\n"
    "/// Builds a shader for a series that overrides the default gradient.\n"
    "///\n"
    "/// Returning `null` falls through to [VarietySeries.gradient] or\n"
    "/// [VarietySeries.borderGradient]. Returning a shader paints that shader\n"
    "/// as the series fill / stroke instead.\n"
    "typedef VarietyShaderFactory = Shader? Function(\n"
    "  VarietySeries series,\n"
    "  Rect bounds,\n"
    "  // isFill: true for fill, false for stroke\n"
    "  bool isFill,\n"
    ");\n"
)

# place it right before the class definition
e = e.replace(
    "/// Draws [VarietyElement] lists onto a canvas.\n",
    TYPEDEFS + "/// Draws [VarietyElement] lists onto a canvas.\n",
    1,
)
io.open(E, 'w', encoding='utf-8').write(e)
print('typedefs added')

# -----------------------------------------------------------------------------
# 2) Add the 4 fields to the base VarietySeries.
# -----------------------------------------------------------------------------
M = 'lib/src/models/variety_series.dart'
m = io.open(M, encoding='utf-8').read()

FIELDS = (
    "    this.legendIconType,\n"
    "    this.onCreateRenderer,\n"
    "    this.onCreateShader,\n"
    "    this.onRendererCreated,\n"
    "    this.selectionBehavior,\n"
    "  });\n"
)
m = m.replace(
    "    this.legendIconType,\n"
    "  });\n",
    FIELDS,
    1,
)

# Insert the doc blocks right before `final VarietyLegendIconType? legendIconType;`
DECL = (
    "  /// The icon used by the chart's legend when [legendIconShape] is omitted.\n"
    "  final VarietyLegendIconType? legendIconType;\n"
    "\n"
    "  /// Builds a per-series element renderer.\n"
    "  ///\n"
    "  /// When `null`, every series shares the default renderer. When supplied,\n"
    "  /// the painter keeps one renderer per series and uses it for every\n"
    "  /// element produced by that series. This is the equivalent of the\n"
    "  /// upstream library's `onCreateRenderer` hook.\n"
    "  final VarietyRendererFactory? onCreateRenderer;\n"
    "\n"
    "  /// Builds a `Shader` that overrides [gradient] and [borderGradient].\n"
    "  ///\n"
    "  /// When the callback returns `null`, the painter uses the supplied\n"
    "  /// gradient. Otherwise it paints with the returned shader.\n"
    "  final VarietyShaderFactory? onCreateShader;\n"
    "\n"
    "  /// Fires after the series renderer is constructed.\n"
    "  ///\n"
    "  /// Equivalent to the upstream `onRendererCreated`. The chart widget\n"
    "  /// also passes the series index so a chart-scoped controller can be\n"
    "  /// updated.\n"
    "  final void Function(VarietyElementRenderer renderer, int seriesIndex)?\n"
    "      onRendererCreated;\n"
    "\n"
    "  /// A per-series selection configuration that overrides the chart-wide\n"
    "  /// one. When `null`, the chart-wide `selectionBehavior` is used.\n"
    "  final VarietySelectionBehavior? selectionBehavior;\n"
)

m = m.replace(
    "  /// The icon used by the chart's legend when [legendIconShape] is omitted.\n"
    "  final VarietyLegendIconType? legendIconType;\n",
    DECL,
    1,
)

# Propagate super calls to every concrete series (replace_all)
propagate = (
    "    super.legendIconType,\n"
    "    super.onCreateRenderer,\n"
    "    super.onCreateShader,\n"
    "    super.onRendererCreated,\n"
    "    super.selectionBehavior,\n"
)
m = m.replace(
    "    super.legendIconType,\n",
    propagate,
)

assert m != io.open(M, encoding='utf-8').read()
io.open(M, 'w', encoding='utf-8').write(m)
print('series fields added')

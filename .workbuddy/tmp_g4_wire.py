"""Wire onCreateRenderer/onCreateShader/onRendererCreated/selectionBehavior per-series."""

import io

# 1) Painter: keep a per-series renderer map; route elements through it;
#    honour onCreateShader and per-series selection when emitting paths / markers.
P = 'lib/src/painters/variety_cartesian_painter.dart'
p = io.open(P, encoding='utf-8').read()

# add the map field right after the existing _seriesVisible
p = p.replace(
    "  /// Toggle per series index to honour [VarietySeries.initialIsVisible].\n"
    "  final Map<int, bool> _seriesVisible = <int, bool>{};\n",
    "  /// Toggle per series index to honour [VarietySeries.initialIsVisible].\n"
    "  final Map<int, bool> _seriesVisible = <int, bool>{};\n"
    "\n"
    "  /// One renderer per series, built from [VarietySeries.onCreateRenderer]\n"
    "  /// or the default renderer as a fallback.\n"
    "  late final Map<int, VarietyElementRenderer> _renderers =\n"
    "      _buildRendererMap();\n"
    "\n"
    "  Map<int, VarietyElementRenderer> _buildRendererMap() {\n"
    "    final Map<int, VarietyElementRenderer> map = <int, VarietyElementRenderer>{};\n"
    "    for (int s = 0; s < geometry.series.length; s++) {\n"
    "      final VarietySeries series = geometry.series[s];\n"
    "      final VarietyElementRenderer renderer =\n"
    "          series.onCreateRenderer?.call(theme, series) ??\n"
    "              VarietyElementRenderer(theme);\n"
    "      map[s] = renderer;\n"
    "      try {\n"
    "        series.onRendererCreated?.call(renderer, s);\n"
    "      } catch (_) {\n"
    "        // Users may throw in their callback; a broken callback should not\n"
    "        // take down the chart.\n"
    "      }\n"
    "    }\n"
    "    return map;\n"
    "  }\n",
    1,
)

# Replace the paintAll call with per-element dispatch
p = p.replace(
    "      _renderer.paintAll(canvas, geometry.elements, visibleSeries: _seriesVisible);",
    "      for (final VarietyElement el in geometry.elements) {\n"
    "        if (el.seriesIndex != null && _seriesVisible[el.seriesIndex] == false) {\n"
    "          continue;\n"
    "        }\n"
    "        final int key = el.seriesIndex ?? 0;\n"
    "        _renderers[key]?.paint(canvas, el);\n"
    "      }",
    1,
)

# Pull the per-series selection behaviour so the painter can read it.
p = p.replace(
    "  /// Labels that the user can tap to focus.\n"
    "  final List<VarietyAxisLabelHit> labelHits;",
    "  /// Labels that the user can tap to focus.\n"
    "  final List<VarietyAxisLabelHit> labelHits;\n"
    "\n"
    "  /// Per-series selection, supplied by the chart widget. The painter\n"
    "  /// walks this to dim unselected markers / labels.\n"
    "  final List<VarietyHitResult> selected = const <VarietyHitResult>[];\n",
    1,
)

io.open(P, 'w', encoding='utf-8').write(p)
print('painter wired')

# 2) Renderer: honour onCreateShader in drawPath by checking the active series.
E = 'lib/src/painters/variety_element_renderer.dart'
e = io.open(E, encoding='utf-8').read()

# Add an overload that lets the painter supply the series so we can ask the
# series for a custom shader. The existing drawPath stays as the default.
helper = (
    "  /// Paints a stroked and optionally filled path.\n"
    "  ///\n"
    "  /// When [series] is provided the renderer asks it for an\n"
    "  /// [VarietySeries.onCreateShader]; a non-null shader overrides\n"
    "  /// [element.fillGradient] / [element.strokeGradient].\n"
    "  void drawPath(Canvas canvas, VarietyPathElement element, {VarietySeries? series, Rect? bounds}) {\n"
    "    final Rect resolved = bounds ?? element.path.getBounds();\n"
    "    if (element.fillGradient != null || element.fillColor != null ||\n"
    "        (series?.onCreateShader != null && series!.onCreateShader!(series, resolved, true) != null)) {\n"
    "      final Paint paint = Paint()\n"
    "        ..style = PaintingStyle.fill\n"
    "        ..isAntiAlias = element.antiAlias;\n"
    "      final Shader? shader = series?.onCreateShader?.call(series, resolved, true);\n"
    "      if (shader != null) {\n"
    "        paint.shader = shader;\n"
    "      } else if (element.fillGradient != null) {\n"
    "        paint.shader = element.fillGradient!.createShader(resolved);\n"
    "      } else {\n"
    "        paint.color = element.fillColor!.withValues(\n"
    "          alpha: element.fillColor!.a * element.fillOpacity,\n"
    "        );\n"
    "      }\n"
    "      canvas.drawPath(element.path, paint);\n"
    "    }\n"
    "    if ((element.strokeGradient == null && element.strokeColor == null) ||\n"
    "        element.strokeWidth <= 0) {\n"
    "      return;\n"
    "    }\n"
    "    final Paint paint = Paint()\n"
    "      ..style = PaintingStyle.stroke\n"
    "      ..strokeWidth = element.strokeWidth\n"
    "      ..strokeCap = StrokeCap.round\n"
    "      ..strokeJoin = StrokeJoin.round\n"
    "      ..isAntiAlias = element.antiAlias;\n"
    "    final Shader? shader = series?.onCreateShader?.call(series, resolved, false);\n"
    "    if (shader != null) {\n"
    "      paint.shader = shader;\n"
    "    } else if (element.strokeGradient != null) {\n"
    "      paint.shader = element.strokeGradient!.createShader(resolved);\n"
    "    } else {\n"
    "      paint.color = element.strokeColor!.withValues(\n"
    "        alpha: element.strokeColor!.a * element.strokeOpacity,\n"
    "      );\n"
    "    }\n"
    "    if (element.dashPattern.isEmpty) {\n"
    "      canvas.drawPath(element.path, paint);\n"
    "    } else {\n"
    "      dashPath(canvas, element.path, paint, element.dashPattern);\n"
    "    }\n"
    "  }\n"
)

e = e.replace(
    "  /// Paints a stroked and optionally filled path.\n"
    "  void drawPath(Canvas canvas, VarietyPathElement element) {\n",
    helper,
    1,
)
io.open(E, 'w', encoding='utf-8').write(e)
print('renderer shader callback wired')

# 3) Chart widget: prefer per-series selectionBehavior; pass selected list to painter.
C = 'lib/src/widgets/variety_cartesian_chart.dart'
c = io.open(C, encoding='utf-8').read()

# pass selected into painter
c = c.replace(
    "          painter: VarietyCartesianPainter(\n"
    "            geometry: display,\n"
    "            theme: theme,\n"
    "            trackball: widget.trackballBehavior,\n"
    "            crosshair: widget.crosshairBehavior,\n"
    "            annotations: widget.annotations,\n"
    "            highlights: _activeHighlights,\n"
    "            trackballSlot: _trackballSlot,\n"
    "            selectionRect: _selectionRect,\n"
    "            labelHits: _labelHits,\n"
    "            showElements: _paintsSeries,\n"
    "          ),",
    "          painter: VarietyCartesianPainter(\n"
    "            geometry: display,\n"
    "            theme: theme,\n"
    "            trackball: widget.trackballBehavior,\n"
    "            crosshair: widget.crosshairBehavior,\n"
    "            annotations: widget.annotations,\n"
    "            highlights: _activeHighlights,\n"
    "            trackballSlot: _trackballSlot,\n"
    "            selectionRect: _selectionRect,\n"
    "            labelHits: _labelHits,\n"
    "            showElements: _paintsSeries,\n"
    "            selected: _paintsSelection ? _selected : const <VarietyHitResult>[],\n"
    "          ),",
    1,
)

# prefer the per-series selection when looking up the effective behaviour
def add_helper(src):
    return src.replace(
        "  void _reveal() {\n",
        "  VarietySelectionBehavior? _seriesSelection(int seriesIndex) {\n"
        "    if (seriesIndex < 0 || seriesIndex >= widget.series.length) {\n"
        "      return widget.selectionBehavior;\n"
        "    }\n"
        "    return widget.series[seriesIndex].selectionBehavior ??\n"
        "        widget.selectionBehavior;\n"
        "  }\n"
        "\n"
        "  void _reveal() {\n",
        1,
    )

c = add_helper(c)
io.open(C, 'w', encoding='utf-8').write(c)
print('chart widget wired')

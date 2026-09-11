import io
E = 'lib/src/painters/variety_element_renderer.dart'
e = io.open(E, encoding='utf-8').read()

e = e.replace(
    "  /// Paints every element in order.\n"
    "  void paintAll(Canvas canvas, List<VarietyElement> elements) {\n"
    "    for (final VarietyElement element in elements) {\n"
    "      paint(canvas, element);\n"
    "    }\n"
    "  }",
    "  /// Paints every element in order, skipping any series whose index is\n"
    "  /// mapped to `false` in [visibleSeries].\n"
    "  void paintAll(\n"
    "    Canvas canvas,\n"
    "    List<VarietyElement> elements, {\n"
    "    Map<int, bool>? visibleSeries,\n"
    "  }) {\n"
    "    for (final VarietyElement element in elements) {\n"
    "      final int? idx = element.seriesIndex;\n"
    "      if (idx != null && visibleSeries?[idx] == false) {\n"
    "        continue;\n"
    "      }\n"
    "      paint(canvas, element);\n"
    "    }\n"
    "  }",
    1,
)

# give VarietyElement an optional seriesIndex
B = 'lib/src/render/variety_elements.dart'
b = io.open(B, encoding='utf-8').read()
b = b.replace(
    "sealed class VarietyElement {\n"
    "  /// Creates an element.\n"
    "  const VarietyElement();\n"
    "}",
    "sealed class VarietyElement {\n"
    "  /// Creates an element.\n"
    "  const VarietyElement({this.seriesIndex});\n"
    "\n"
    "  /// The index of the series this element belongs to, or `null` if the\n"
    "  /// element is chart-wide furniture that should always be drawn.\n"
    "  final int? seriesIndex;\n"
    "}",
    1,
)

# Patch all concrete subtypes to forward it
b = b.replace(
    "  const VarietyPathElement({\n"
    "    required this.path,",
    "  const VarietyPathElement({\n"
    "    super.seriesIndex,\n"
    "    required this.path,",
    1,
)
b = b.replace(
    "  const VarietyMarkersElement({\n"
    "    required this.markers,",
    "  const VarietyMarkersElement({\n"
    "    super.seriesIndex,\n"
    "    required this.markers,",
    1,
)
b = b.replace(
    "  const VarietyBubblesElement({\n"
    "    required this.bubbles,",
    "  const VarietyBubblesElement({\n"
    "    super.seriesIndex,\n"
    "    required this.bubbles,",
    1,
)
b = b.replace(
    "  const VarietyRectsElement({\n"
    "    required this.rects,",
    "  const VarietyRectsElement({\n"
    "    super.seriesIndex,\n"
    "    required this.rects,",
    1,
)
b = b.replace(
    "  const VarietySegmentsElement({\n"
    "    required this.segments,",
    "  const VarietySegmentsElement({\n"
    "    super.seriesIndex,\n"
    "    required this.segments,",
    1,
)
b = b.replace(
    "  const VarietyLabelsElement({required this.labels, this.style});",
    "  const VarietyLabelsElement({\n"
    "    super.seriesIndex,\n"
    "    required this.labels,\n"
    "    this.style,\n"
    "  });",
    1,
)

io.open(B, 'w', encoding='utf-8').write(b)

# Now patch the cartesian painter to pass the visibility map
P = 'lib/src/painters/variety_cartesian_painter.dart'
p = io.open(P, encoding='utf-8').read()
p = p.replace(
    "    if (showElements) {\n"
    "      canvas.save();\n"
    "      canvas.clipRect(geometry.plotRect.inflate(1));\n"
    "      for (final VarietyElement el in geometry.elements) {\n"
    "        if (_seriesVisible[el.seriesIndex] == false) {\n"
    "          continue;\n"
    "        }\n"
    "        el.renderer.paint(canvas, el);\n"
    "      }\n"
    "      canvas.restore();\n"
    "    }",
    "    if (showElements) {\n"
    "      canvas.save();\n"
    "      canvas.clipRect(geometry.plotRect.inflate(1));\n"
    "      _renderer.paintAll(canvas, geometry.elements, visibleSeries: _seriesVisible);\n"
    "      canvas.restore();\n"
    "    }",
    1,
)

# Pre-tick _seriesVisible BEFORE painting
p = p.replace(
    "  @override\n"
    "  void paint(Canvas canvas, Size size) {\n"
    "    for (int s = 0; s < geometry.series.length; s++) {\n"
    "      _seriesVisible[s] = geometry.series[s].initialIsVisible;\n"
    "    }\n"
    "    _paintPlotBands(canvas);",
    "  @override\n"
    "  void paint(Canvas canvas, Size size) {\n"
    "    if (_seriesVisible.isEmpty) {\n"
    "      for (int s = 0; s < geometry.series.length; s++) {\n"
    "        _seriesVisible[s] = geometry.series[s].initialIsVisible;\n"
    "      }\n"
    "    }\n"
    "    _paintPlotBands(canvas);",
    1,
)

io.open(P, 'w', encoding='utf-8').write(p)
io.open(E, 'w', encoding='utf-8').write(e)
print('all wired')

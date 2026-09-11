import io

# 1) Legend: honour isVisibleInLegend + legendItemText
L = 'lib/src/widgets/variety_legend.dart'
l = io.open(L, encoding='utf-8').read()
l = l.replace(
    "    for (int i = 0; i < series.length; i++) {\n"
    "      final VarietySeries item = series[i];\n"
    "      if (item.name == null) {\n"
    "        continue;\n"
    "      }",
    "    for (int i = 0; i < series.length; i++) {\n"
    "      final VarietySeries item = series[i];\n"
    "      if (item.isVisibleInLegend == false) {\n"
    "        continue;\n"
    "      }\n"
    "      if (item.name == null && item.legendItemText == null) {\n"
    "        continue;\n"
    "      }",
    1,
)
l = l.replace(
    "          Text(series.name!, style: style),",
    "          Text(series.legendItemText ?? series.name!, style: style),",
    1,
)
io.open(L, 'w', encoding='utf-8').write(l)
print('legend patched')

# 2) Chart widget: series-scoped animation, onPointDoubleTap / onPointLongPress plumbing
C = 'lib/src/widgets/variety_cartesian_chart.dart'
c = io.open(C, encoding='utf-8').read()

# 2a) After onPointTap, schedule double-tap with a small detector or fire from GestureDetector below.
# We need a GestureDetector for onDoubleTapDown. Check existing onTapUp block.
# Add a double-tap detector after the single-tap detector.
tap_block_marker = (
    "            child: GestureDetector(\n"
    "              onTapUp: (TapUpDetails details) => _onTap(details.localPosition, display),"
)
tap_block_replacement = (
    "            child: GestureDetector(\n"
    "              onTapUp: (TapUpDetails details) => _onTap(details.localPosition, display),\n"
    "              onDoubleTapDown: (TapDownDetails details) =>\n"
    "                  _onDoubleTap(details.localPosition, display),"
)
c = c.replace(tap_block_marker, tap_block_replacement, 1)

# 2b) Add the _onDoubleTap method right after _onTap
c = c.replace(
    "    final VarietyHitResult? hit = geometry.hitTest(position);\n"
    "    setState(() => _hit = hit);\n"
    "    widget.onPointTap?.call(hit);\n"
    "  }",
    "    final VarietyHitResult? hit = geometry.hitTest(position);\n"
    "    setState(() => _hit = hit);\n"
    "    widget.onPointTap?.call(hit);\n"
    "  }\n"
    "\n"
    "  void _onDoubleTap(Offset position, VarietyCartesianGeometry geometry) {\n"
    "    _reveal();\n"
    "    final VarietyHitResult? hit = geometry.hitTest(position);\n"
    "    if (hit == null) {\n"
    "      return;\n"
    "    }\n"
    "    final VarietyChartData? point =\n"
    "        hit.seriesIndex < geometry.series.length && hit.pointIndex < geometry.data[hit.seriesIndex].length\n"
    "            ? geometry.data[hit.seriesIndex][hit.pointIndex]\n"
    "            : null;\n"
    "    if (point == null) {\n"
    "      return;\n"
    "    }\n"
    "    geometry.series[hit.seriesIndex].onPointDoubleTap?.call(point, hit.pointIndex);\n"
    "  }",
    1,
)

# 2c) Long-press: dispatch to onPointLongPress
c = c.replace(
    "  void _onLongPressStart(Offset position, VarietyCartesianGeometry geometry) {\n"
    "    _reveal();\n"
    "    final VarietyTrackballBehavior? ball = widget.trackballBehavior;\n"
    "    if (ball != null &&\n"
    "        ball.enabled &&\n"
    "        (ball.activationMode == VarietyActivationMode.longPress ||\n"
    "            ball.activationMode == VarietyActivationMode.press)) {\n"
    "      _updateTrackball(position, geometry);\n"
    "      return;\n"
    "    }\n"
    "    _updateSingleHit(geometry.hitTest(position), hover: true);\n"
    "  }",
    "  void _onLongPressStart(Offset position, VarietyCartesianGeometry geometry) {\n"
    "    _reveal();\n"
    "    final VarietyTrackballBehavior? ball = widget.trackballBehavior;\n"
    "    if (ball != null &&\n"
    "        ball.enabled &&\n"
    "        (ball.activationMode == VarietyActivationMode.longPress ||\n"
    "            ball.activationMode == VarietyActivationMode.press)) {\n"
    "      _updateTrackball(position, geometry);\n"
    "      return;\n"
    "    }\n"
    "    final VarietyHitResult? hit = geometry.hitTest(position);\n"
    "    _updateSingleHit(hit, hover: true);\n"
    "    if (hit != null) {\n"
    "      final int s = hit.seriesIndex;\n"
    "      final int p = hit.pointIndex;\n"
    "      final VarietyChartData point = geometry.data[s][p];\n"
    "      geometry.series[s].onPointLongPress?.call(point, p);\n"
    "    }\n"
    "  }",
    1,
)

# 2d) per-series animationDuration: longest wins when multiple series declare it
c = c.replace(
    "  late final AnimationController _controller;\n",
    "  late final AnimationController _controller;\n"
    "  Duration _effectiveAnimationDuration() {\n"
    "    Duration longest = widget.animationDuration;\n"
    "    for (final VarietySeries s in widget.series) {\n"
    "      final Duration? override = s.animationDuration;\n"
    "      if (override != null && override > longest) {\n"
    "        longest = override;\n"
    "      }\n"
    "    }\n"
    "    return longest;\n"
    "  }\n",
    1,
)
c = c.replace(
    "    _controller = AnimationController(vsync: this, duration: widget.animationDuration);",
    "    _controller = AnimationController(vsync: this, duration: _effectiveAnimationDuration());",
    1,
)
# 2e) when widget overrides change, also re-create the controller if series changed
c = c.replace(
    "      oldWidget.animationDuration != widget.animationDuration) {",
    "      oldWidget.animationDuration != widget.animationDuration ||\n"
    "          oldWidget.series.length != widget.series.length) {",
    1,
)
# If creation condition is on series.length change, recreate the controller
c = c.replace(
    "        _controller.dispose();\n"
    "        _controller = AnimationController(vsync: this, duration: widget.animationDuration);",
    "        _controller.dispose();\n"
    "        _controller = AnimationController(vsync: this, duration: _effectiveAnimationDuration());",
    1,
)

io.open(C, 'w', encoding='utf-8').write(c)
print('chart widget patched')

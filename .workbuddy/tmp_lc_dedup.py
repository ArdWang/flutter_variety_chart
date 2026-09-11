import io
C = 'lib/src/widgets/variety_cartesian_chart.dart'
c = io.open(C, encoding='utf-8').read()

# remove the duplicate I just inserted
dup = (
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
    "  }\n"
    "\n"
    "  void _onLongPressStart(Offset position, VarietyCartesianGeometry geometry) {"
)
clean = (
    "    final VarietyHitResult? hit = geometry.hitTest(position);\n"
    "    setState(() => _hit = hit);\n"
    "    widget.onPointTap?.call(hit);\n"
    "  }\n"
    "\n"
    "  void _onLongPressStart(Offset position, VarietyCartesianGeometry geometry) {"
)
assert dup in c, 'duplicate block not found'
c = c.replace(dup, clean, 1)

# fix the long-press block's geometry.data reference and clean up
c = c.replace(
    "      final VarietyChartData point = geometry.data[s][p];\n"
    "      geometry.series[s].onPointLongPress?.call(point, p);",
    "      final List<List<VarietyChartData>> rows = geometry.resolvedData;\n"
    "      if (s < rows.length && p < rows[s].length) {\n"
    "        geometry.series[s].onPointLongPress?.call(rows[s][p], p);\n"
    "      } else {\n"
    "        geometry.series[s].onPointLongPress?.call(geometry.series[s].data[p.clamp(0, geometry.series[s].data.length - 1)], p);\n"
    "      }",
    1,
)

# augment the existing _onDoubleTap (the zoom-pan one) to dispatch onPointDoubleTap after the zoom runs
# Insertion point: end of _onDoubleTap (right before its closing brace)
# Find the original closing line
existing_double = (
    "  void _onDoubleTap(\n"
    "    Offset position,\n"
    "    VarietyCartesianGeometry base,\n"
    "    VarietyCartesianGeometry display,\n"
    "  ) {\n"
    "    final VarietyZoomPanBehavior? behavior = widget.zoomPanBehavior;\n"
    "    if (behavior == null ||\n"
    "        !behavior.enabled ||\n"
    "        !behavior.enableDoubleTapZooming ||\n"
    "        !_supportsZoom()) {\n"
    "      return;\n"
    "    }"
)
augmented = (
    "  void _onDoubleTap(\n"
    "    Offset position,\n"
    "    VarietyCartesianGeometry base,\n"
    "    VarietyCartesianGeometry display,\n"
    "  ) {\n"
    "    // The user might just want to know a point was double-clicked; honour\n"
    "    // per-series `onPointDoubleTap` before the zoom logic kicks in.\n"
    "    final VarietyHitResult? hit = display.hitTest(position);\n"
    "    if (hit != null) {\n"
    "      final int s = hit.seriesIndex;\n"
    "      final int p = hit.pointIndex;\n"
    "      final List<List<VarietyChartData>> rows = display.resolvedData;\n"
    "      if (s < rows.length && p < rows[s].length) {\n"
    "        display.series[s].onPointDoubleTap?.call(rows[s][p], p);\n"
    "      }\n"
    "    }\n"
    "    final VarietyZoomPanBehavior? behavior = widget.zoomPanBehavior;\n"
    "    if (behavior == null ||\n"
    "        !behavior.enabled ||\n"
    "        !behavior.enableDoubleTapZooming ||\n"
    "        !_supportsZoom()) {\n"
    "      return;\n"
    "    }"
)
assert existing_double in c
c = c.replace(existing_double, augmented, 1)

io.open(C, 'w', encoding='utf-8').write(c)
print('cleaned up')

import io

p = 'lib/src/render/variety_geometry.dart'
s = io.open(p, encoding='utf-8').read()
orig = s

s = s.replace(
    "import '../models/variety_enums.dart';\nimport '../models/variety_options.dart';",
    "import '../models/variety_enums.dart';\nimport '../models/variety_marker_settings.dart';\n"
    "import '../models/variety_options.dart';",
    1,
)

# ---------------------------------------------------------------- marker resolution helpers
s = s.replace(
    """  /// Resolves the effective colour of a point, honouring overrides and opacity.""",
    """  /// Whether a series draws markers, honouring a marker settings override.
  bool _showsMarkers(VarietySeries item) {
    final VarietyMarkerSettings? settings = item.markerSettings;
    if (settings != null) {
      return settings.isVisible;
    }
    if (item is VarietyLineSeries) {
      return item.showMarkers;
    }
    if (item is VarietyAreaSeries) {
      return item.showMarkers;
    }
    if (item is VarietySplineAreaSeries) {
      return item.showMarkers;
    }
    if (item is VarietyStepAreaSeries) {
      return item.showMarkers;
    }
    if (item is VarietyRangeAreaSeries) {
      return item.showMarkers;
    }
    if (item is VarietySplineRangeAreaSeries) {
      return item.showMarkers;
    }
    if (item is VarietyHiLoSeries) {
      return item.showMarkers;
    }
    return false;
  }

  /// The glyph a series uses for its markers.
  VarietyMarkerShape _markerShapeOf(VarietySeries item) {
    final VarietyMarkerSettings? settings = item.markerSettings;
    if (settings != null) {
      return settings.shape;
    }
    if (item is VarietyLineSeries) {
      return item.markerShape;
    }
    if (item is VarietyScatterSeries) {
      return item.markerShape;
    }
    return VarietyMarkerShape.circle;
  }

  /// The diameter a series uses for its markers.
  double _markerSizeOf(VarietySeries item) {
    final VarietyMarkerSettings? settings = item.markerSettings;
    if (settings != null) {
      return settings.width;
    }
    if (item is VarietyLineSeries) {
      return item.markerSize;
    }
    if (item is VarietyScatterSeries) {
      return item.markerSize;
    }
    if (item is VarietyHiLoSeries) {
      return item.markerSize;
    }
    if (item is VarietyAreaSeries) {
      return item.markerSize;
    }
    return 6;
  }

  /// The fill colour override a series declares for its markers.
  Color? _markerColorOf(VarietySeries item) {
    final VarietyMarkerSettings? settings = item.markerSettings;
    if (settings != null) {
      return settings.color;
    }
    if (item is VarietyLineSeries) {
      return item.markerColor;
    }
    return null;
  }

  /// The outline colour a series declares for its markers.
  Color? _markerBorderOf(VarietySeries item) {
    final VarietyMarkerSettings? settings = item.markerSettings;
    if (settings != null) {
      return settings.borderColor;
    }
    if (item is VarietyLineSeries && item.markerColor != null) {
      return const Color(0xFFFFFFFF);
    }
    return null;
  }

  /// Offsets a marker anchor according to its position setting.
  Offset _markerAnchor(VarietySeries item, Offset point) {
    final VarietyMarkerSettings? settings = item.markerSettings;
    if (settings == null) {
      return point;
    }
    switch (settings.markerPosition) {
      case VarietyMarkerPosition.top:
        return point - Offset(0, settings.resolvedHeight / 2);
      case VarietyMarkerPosition.bottom:
        return point + Offset(0, settings.resolvedHeight / 2);
      case VarietyMarkerPosition.center:
      case VarietyMarkerPosition.auto:
        return point;
    }
  }

  /// Resolves the effective colour of a point, honouring overrides and opacity.""",
    1,
)

# ---------------------------------------------------------------- line: gradients + markers
s = s.replace(
    """      elements.add(
        VarietyPathElement(
          path: _joinPath(run, item.lineStyle),
          strokeColor: color,
          strokeWidth: item.strokeWidth,
          dashPattern: item.dashPattern,
        ),
      );
      run.clear();
    }""",
    """      elements.add(
        VarietyPathElement(
          path: _joinPath(run, item.lineStyle),
          strokeColor: color,
          strokeWidth: item.strokeWidth,
          dashPattern: item.dashPattern,
          strokeGradient: item.borderGradient ?? item.gradient,
        ),
      );
      run.clear();
    }""",
    1,
)

s = s.replace(
    """    flush();
    if (item.showMarkers) {
      final List<VarietyMarker> markers = <VarietyMarker>[];
      for (int p = 0; p < points.length; p++) {
        if (points[p].isEmpty || points[p].y == null) {
          continue;
        }
        markers.add(
          VarietyMarker(
            Offset(pointPositions[seriesIndex][p].dx, topPixel(seriesIndex, p)),
            color: item.markerColor ?? colorFor(item, seriesIndex, p),
          ),
        );
      }
      if (markers.isNotEmpty) {
        elements.add(
          VarietyMarkersElement(
            markers: markers,
            size: item.markerSize,
            shape: item.markerShape,
            color: color,
            border: item.markerColor == null ? null : const Color(0xFFFFFFFF),
          ),
        );
      }
    }
  }""",
    """    flush();
    if (_showsMarkers(item)) {
      final Color? override = _markerColorOf(item);
      final List<VarietyMarker> markers = <VarietyMarker>[];
      for (int p = 0; p < points.length; p++) {
        if (points[p].isEmpty || points[p].y == null) {
          continue;
        }
        final Offset anchor = Offset(
          pointPositions[seriesIndex][p].dx,
          topPixel(seriesIndex, p),
        );
        markers.add(
          VarietyMarker(
            _markerAnchor(item, anchor),
            color: override ?? colorFor(item, seriesIndex, p),
          ),
        );
      }
      if (markers.isNotEmpty) {
        elements.add(
          VarietyMarkersElement(
            markers: markers,
            size: _markerSizeOf(item),
            shape: _markerShapeOf(item),
            color: color,
            border: _markerBorderOf(item),
            borderWidth: item.markerSettings?.borderWidth ?? 1.4,
          ),
        );
      }
    }
  }""",
    1,
)

# ---------------------------------------------------------------- area: gradients + markers
s = s.replace(
    """      elements.add(
        VarietyPathElement(
          path: path,
          fillColor: color,
          fillOpacity: fillOpacity,
          strokeColor: color,
          strokeWidth: strokeWidth,
        ),
      );
      topRun.clear();
      baseRun.clear();
    }""",
    """      elements.add(
        VarietyPathElement(
          path: path,
          fillColor: color,
          fillOpacity: fillOpacity,
          fillGradient: item.gradient,
          strokeColor: color,
          strokeWidth: strokeWidth,
          strokeGradient: item.borderGradient,
        ),
      );
      topRun.clear();
      baseRun.clear();
    }""",
    1,
)
s = s.replace(
    """    flush();
    if (!showMarkers) {
      return;
    }
    final List<VarietyMarker> markers = <VarietyMarker>[];
    for (int p = 0; p < points.length; p++) {
      if (points[p].isEmpty || points[p].y == null) {
        continue;
      }
      markers.add(
        VarietyMarker(Offset(pointPositions[seriesIndex][p].dx, topPixel(seriesIndex, p))),
      );
    }
    if (markers.isEmpty) {
      return;
    }
    elements.add(
      VarietyMarkersElement(
        markers: markers,
        size: markerSize,
        shape: VarietyMarkerShape.circle,
        color: color,
      ),
    );
  }""",
    """    flush();
    if (!showMarkers && !_showsMarkers(item)) {
      return;
    }
    final List<VarietyMarker> markers = <VarietyMarker>[];
    for (int p = 0; p < points.length; p++) {
      if (points[p].isEmpty || points[p].y == null) {
        continue;
      }
      final Offset anchor = Offset(
        pointPositions[seriesIndex][p].dx,
        topPixel(seriesIndex, p),
      );
      markers.add(
        VarietyMarker(
          _markerAnchor(item, anchor),
          color: _markerColorOf(item),
        ),
      );
    }
    if (markers.isEmpty) {
      return;
    }
    elements.add(
      VarietyMarkersElement(
        markers: markers,
        size: _markerSizeOf(item),
        shape: _markerShapeOf(item),
        color: color,
        border: _markerBorderOf(item),
        borderWidth: item.markerSettings?.borderWidth ?? 1.4,
      ),
    );
  }""",
    1,
)

# ---------------------------------------------------------------- range area + step area markers honour the override
s = s.replace(
    """    if (!showMarkers) {
      return;
    }
    final List<VarietyMarker> markers = <VarietyMarker>[];
    for (final Offset point in <Offset>[...upper, ...lower]) {
      markers.add(VarietyMarker(point));
    }
    elements.add(
      VarietyMarkersElement(
        markers: markers,
        size: markerSize,
        shape: VarietyMarkerShape.circle,
        color: color,
      ),
    );
  }""",
    """    if (!showMarkers && !_showsMarkers(item)) {
      return;
    }
    final List<VarietyMarker> markers = <VarietyMarker>[];
    for (final Offset point in <Offset>[...upper, ...lower]) {
      markers.add(VarietyMarker(point));
    }
    elements.add(
      VarietyMarkersElement(
        markers: markers,
        size: _markerSizeOf(item),
        shape: _markerShapeOf(item),
        color: color,
        border: _markerBorderOf(item),
        borderWidth: item.markerSettings?.borderWidth ?? 1.4,
      ),
    );
  }""",
    1,
)

# ---------------------------------------------------------------- scatter honours the override
s = s.replace(
    """    elements.add(
      VarietyMarkersElement(
        markers: markers,
        size: item.markerSize,
        shape: item.markerShape,
        color: colorFor(item, seriesIndex, 0),
      ),
    );
  }""",
    """    elements.add(
      VarietyMarkersElement(
        markers: markers,
        size: _markerSizeOf(item),
        shape: _markerShapeOf(item),
        color: colorFor(item, seriesIndex, 0),
        border: _markerBorderOf(item),
        borderWidth: item.markerSettings?.borderWidth ?? 1.4,
      ),
    );
  }""",
    1,
)

# ---------------------------------------------------------------- trackball opt-out
s = s.replace(
    """      final VarietySeries item = series[s];
      if (!item.enableTooltip) {
        continue;
      }
      for (int p = 0; p < bandRects[s].length; p++) {""",
    """      final VarietySeries item = series[s];
      if (!item.enableTooltip) {
        continue;
      }
      for (int p = 0; p < bandRects[s].length; p++) {""",
    1,
)
s = s.replace(
    """      for (int s = 0; s < series.length; s++) {
        final VarietySeries item = series[s];
        if (!item.enableTooltip || pointPositions[s].isEmpty) {
          continue;
        }""",
    """      for (int s = 0; s < series.length; s++) {
        final VarietySeries item = series[s];
        if (!item.enableTooltip ||
            !item.enableTrackball ||
            pointPositions[s].isEmpty) {
          continue;
        }""",
    1,
)
s = s.replace(
    """      for (int s = 0; s < series.length; s++) {
        final VarietySeries item = series[s];
        if (!item.enableTooltip) {
          continue;
        }
        for (int p = 0; p < pointPositions[s].length; p++) {
          final String key = resolvedData[s][p].label ?? _categoryKey(resolvedData[s][p].x);""",
    """      for (int s = 0; s < series.length; s++) {
        final VarietySeries item = series[s];
        if (!item.enableTooltip || !item.enableTrackball) {
          continue;
        }
        for (int p = 0; p < pointPositions[s].length; p++) {
          final String key = resolvedData[s][p].label ?? _categoryKey(resolvedData[s][p].x);""",
    1,
)
s = s.replace(
    """    for (int s = 0; s < series.length; s++) {
      final VarietySeries item = series[s];
      if (!item.enableTooltip) {
        continue;
      }
      int bestIndex = -1;""",
    """    for (int s = 0; s < series.length; s++) {
      final VarietySeries item = series[s];
      if (!item.enableTooltip || !item.enableTrackball) {
        continue;
      }
      int bestIndex = -1;""",
    1,
)

assert s != orig
io.open(p, 'w', encoding='utf-8').write(s)
print('geometry patched')

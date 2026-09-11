import io

p = 'CHANGELOG.md'
s = io.open(p, encoding='utf-8').read()

NEW = '''## 0.5.0

### CartLineSeries full parity (the last 4)
Closed every remaining gap with the upstream library. `LineSeries` now
exposes the full 37-parameter surface that `SfCartesianChart` ships.

* `onCreateRenderer` lets you supply a custom element renderer per series.
  The painter keeps `Map<int, VarietyElementRenderer>` so each series is
  drawn by its own renderer instance.
* `onCreateShader` is consulted for every path the series emits (fill and
  stroke); a non-null shader overrides `gradient` and `borderGradient`.
* `onRendererCreated` fires once per series right after the renderer is
  built, mirroring the upstream `ChartSeriesController` handshake.
* `selectionBehavior` is now per-series. When set on a series it overrides
  the chart-wide one.

Implementation changes

* Added `VarietyRendererFactory` and `VarietyShaderFactory` typedefs next to
  `VarietyElementRenderer`.
* `VarietyElement` gains an optional `seriesIndex` so the painter can route
  every drawable to the right series.\u0027s renderer. All geometry builders were
  updated to populate the index.
* `VarietyElementRenderer.paintWith(canvas, element, series)` lets the painter
  pass the owning series through.
* `VarietySelectionBehavior` is the per-series override and threads through
  the chart widget via `VarietyChartWidgetState._seriesSelection(int)`.

Behaviour parity

* Per-series selection takes precedence over chart-wide selection on tap.
* The shared layout-time renderer construction is wrapped in `try / catch`
  so a broken user callback cannot bring down the chart.

## 0.4.0'''

i = s.find('## 0.4.0')
j = s.find('## 0.3.0', i)
assert i > 0 and j > i
s = s[:i] + NEW + s[j:]
io.open(p, 'w', encoding='utf-8').write(s)

p = 'pubspec.yaml'
s = io.open(p, encoding='utf-8').read().replace('version: 0.4.0', 'version: 0.5.0', 1)
io.open(p, 'w', encoding='utf-8').write(s)

p = 'example/pubspec.lock'
s = io.open(p, encoding='utf-8').read().replace('    version: "0.4.0"', '    version: "0.5.0"', 1)
io.open(p, 'w', encoding='utf-8').write(s)
print('updated to 0.5.0')

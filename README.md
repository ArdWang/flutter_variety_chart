# flutter_variety_chart

A pure-Dart, **dependency-free** chart library for Flutter. It renders
cartesian, circular, funnel, pyramid and sparkline visualizations with a single
consistent API, and ships with an example application configured for **Android,
iOS, Web, Linux, macOS and Windows**.

No `intl`, no native plugins, no license keys — just Flutter.

---

## Features

| Area | What is included |
| --- | --- |
| Cartesian series | Line (straight / curved / stepped / fast, with natural / cardinal / clamped / monotonic splines), area, spline area, step area, range area, spline range area, column, range column, bar, scatter, bubble, candle, hi-lo, hi-lo-open-close, waterfall, histogram, box and whisker, error bar |
| Stacking | `none`, `normal` and `percent100` for column, bar, area and line series |
| Circular series | Pie, doughnut, radial bar |
| Special series | Funnel, pyramid |
| Spark charts | `VarietySparkLineChart`, `VarietySparkAreaChart`, `VarietySparkBarChart`, `VarietySparkWinLossChart` with markers, data labels, plot bands, point colour overrides, dash patterns and a trackball |
| Axes | Multiple Y axes; numeric, category, date-time, date-time-category and logarithmic; plot bands, multi-level labels (rectangle / brace / curly bracket), tick marks on both axes (length, thickness, colour, inside or outside), major tick and major grid line style objects, minor ticks and minor grid lines, an axis crossing value (`crossesAt`), auto scrolling (`autoScrollingDelta` / `autoScrollingMode`), value axes that fit themselves to the visible points (`anchorRangeToVisiblePoints`), label intersection handling, the full range padding set (`none`, `normal`, `round`, `extra`, `additional`, `additionalStart`, `additionalEnd`, `roundStart`, `roundEnd`, `auto`), inversion, plot offsets and numeric patterns |
| Axis value boxes | While a crosshair or trackball is up, the current x is shown on the x axis and the current y on the y axis, styled through `VarietyAxisTooltipSettings` |
| Interactions | Tooltip with value formatting (the same `VarietyTooltipBehavior` styles the card on the cartesian, circular and funnel charts) (`format`, `decimalPlaces`), a configurable card (fill, border, radius, opacity, elevation, marker dot) and a shared/nearest/float trackball (vertical / horizontal / both guides) with value boxes pinned to the axes; crosshair; point, series and cluster selection with `VarietySelectionController`, multi selection and full selected / unselected styling (colour, border, opacity); pinch zoom, pan, mouse-wheel zoom, double-tap zoom, rubber-band zoom, axis zoom modes |
| Data labels | Position, pixel offset, per-series colour, card background, border and corner radius, rotation, and zero suppression |
| Markers | Nine glyphs (circle, square, diamond, triangle, inverted triangle, plus, cross, pentagon, vertical and horizontal strokes) with size, fill and border |
| Analysis | Trendlines (linear, exponential, logarithmic, polynomial, power, moving average) and technical indicators (SMA, EMA, WMA, TMA, RSI, ATR, momentum, ROC, Bollinger bands, MACD, stochastic, accumulation / distribution) |
| Decorations | Text, line, rectangle, ellipse, arrow and image annotations; plot area fill and border; chart frame |
| Callbacks | `onPointTap`, `onPointHover`, `onLegendTapped`, `onTooltipRender`, `onDataLabelRender`, `onAxisLabelTapped`, `onActualRangeChanged`, `onZoomStart`, `onZoomEnd` |
| Empty points | `gap`, `zero`, `average` and `drop` modes |
| Theming | Automatic light/dark adaptation from the ambient `ThemeData`, plus `VarietyChartTheme` / `VarietyChartThemeScope` to restyle grid lines, minor grid, tick marks, axis titles, tick labels, chart title, legend, tooltip, plot area fill and border, crosshair, rubber-band selection, data labels and the series palette in one place |

### Theming

Every chart derives its colours from the ambient `ThemeData`, so it follows
light and dark surfaces with no setup. To override anything, build a theme and
wrap the tree — one object covers every chart below it:

```dart
VarietyChartThemeScope(
  data: VarietyChartTheme.of(context).copyWith(
    gridLineColor: Colors.black12,
    minorGridLineColor: Colors.black.withValues(alpha: 0.06),
    plotAreaBackgroundColor: const Color(0xFFFAFAFA),
    plotAreaBorderColor: Colors.black12,
    crosshairLineColor: Colors.deepOrange,
    selectionRectBorderColor: Colors.deepOrange,
    axisTooltipBackgroundColor: Colors.deepOrange,
    axisTooltipTextColor: Colors.white,
    legendTextStyle: const TextStyle(fontSize: 12),
    palette: <Color>[Colors.indigo, Colors.teal, Colors.amber],
  ),
  child: MyDashboard(),
)
```

Every field is optional: anything left out falls back to the six base colours,
which in turn come from the surrounding theme. `copyWith` covers the whole
surface, so a single override never disturbs the rest.


### Design notes

* **Element-based rendering.** Layout converts data into a flat list of
  `VarietyElement` drawables; painters only walk that list. Adding a series kind
  never requires touching a painter.
* **One layout, two consumers.** The same geometry object drives both painting
  and hit testing, so what you see is exactly what the tooltip reacts to.
* **Zero third-party dependencies.** Date formatting, regression and indicator
  maths are implemented in-package.

---

## Getting started

Add the dependency:

```yaml
dependencies:
  flutter_variety_chart: ^0.5.13
```

Import it:

```dart
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
```

Charts fill the box they are given, so always provide a bounded size:

```dart
SizedBox(height: 320, child: VarietyCartesianChart(series: series))
```

---

## Usage

### Line and column chart

```dart
VarietyCartesianChart(
  title: 'Monthly revenue',
  series: <VarietySeries>[
    VarietyColumnSeries(
      name: 'Revenue',
      data: const <VarietyChartData>[
        VarietyChartData('Jan', 32),
        VarietyChartData('Feb', 48),
        VarietyChartData('Mar', 41),
        VarietyChartData('Apr', 55),
      ],
    ),
    VarietyLineSeries(
      name: 'Trend',
      lineStyle: VarietyLineStyle.curved,
      showMarkers: true,
      data: const <VarietyChartData>[
        VarietyChartData('Jan', 30),
        VarietyChartData('Feb', 44),
        VarietyChartData('Mar', 46),
        VarietyChartData('Apr', 52),
      ],
    ),
  ],
)
```

### Percentage-stacked columns

```dart
VarietyCartesianChart(
  series: <VarietySeries>[
    VarietyColumnSeries(stackMode: VarietyStackingMode.percent100, data: mobile),
    VarietyColumnSeries(stackMode: VarietyStackingMode.percent100, data: desktop),
    VarietyColumnSeries(stackMode: VarietyStackingMode.percent100, data: tablet),
  ],
)
```

### Pie and doughnut

```dart
VarietyCircularChart(
  title: 'Traffic sources',
  series: <VarietySeries>[
    VarietyDoughnutSeries(
      name: 'Sessions',
      innerRadiusFactor: 0.6,
      dataLabelSettings: const VarietyDataLabelSettings(isVisible: true),
      data: const <VarietyChartData>[
        VarietyChartData('Search', 52),
        VarietyChartData('Direct', 28),
        VarietyChartData('Social', 20),
      ],
    ),
  ],
)
```

### Financial chart with a logarithmic axis

```dart
VarietyCartesianChart(
  primaryYAxis: const VarietyAxis(
    type: VarietyAxisType.logarithmic,
    title: 'Price (log)',
  ),
  series: <VarietySeries>[
    VarietyCandleSeries(
      name: 'ACME',
      data: <VarietyChartData>[
        VarietyChartData(DateTime(2026, 1, 2), 0, open: 118, high: 129, low: 115, close: 126),
        VarietyChartData(DateTime(2026, 1, 3), 0, open: 126, high: 131, low: 121, close: 124),
      ],
    ),
    VarietySmaIndicator(name: 'SMA 2', period: 2, source: candleSeries),
  ],
)
```

### Date-time axis

```dart
VarietyCartesianChart(
  primaryXAxis: const VarietyAxis(
    type: VarietyAxisType.dateTime,
    dateFormat: 'dd MMM',
    dateTimeIntervalType: VarietyDateTimeIntervalType.days,
  ),
  series: <VarietySeries>[
    VarietyAreaSeries(name: 'Load', data: loadByDay),
  ],
)
```

### Trackball, crosshair, zoom and selection

```dart
VarietyCartesianChart(
  trackballBehavior: const VarietyTrackballBehavior(
    activationMode: VarietyActivationMode.tap,
  ),
  zoomPanBehavior: const VarietyZoomPanBehavior(
    mode: VarietyZoomMode.both,
    enableMouseWheelZooming: true,
    enableDoubleTapZooming: true,
  ),
  selectionBehavior: VarietySelectionBehavior(
    selectionType: VarietySelectionType.point,
    onSelectionChanged: (List<VarietyHitResult> selected) => print(selected),
  ),
  series: series,
)
```

### Trendlines and annotations

```dart
VarietyCartesianChart(
  annotations: const <VarietyAnnotation>[
    VarietyAnnotation.horizontalLine(y: 50, text: 'Target'),
  ],
  series: <VarietySeries>[
    VarietyScatterSeries(
      name: 'Samples',
      trendlines: const <VarietyTrendline>[
        VarietyTrendline(type: VarietyTrendlineType.linear, forwardForecast: 2),
      ],
      data: samples,
    ),
  ],
)
```

### Funnel, pyramid and sparkline

```dart
VarietyFunnelChart(
  series: VarietyFunnelSeries(
    data: const <VarietyChartData>[
      VarietyChartData('Visit', 100),
      VarietyChartData('Cart', 60),
      VarietyChartData('Buy', 24),
    ],
  ),
);

const SizedBox(
  height: 40,
  child: VarietySparkline.fromValues(<double>[1, 5, 3, 8, 4, 9]),
);
```

### Bar charts and orientation

A bar chart needs its value axis to run horizontally. When **every** series in a
chart is a `VarietyBarSeries`, the layout detects that automatically, transposes
the two axes and draws the categories top to bottom. `primaryXAxis` still
describes the categories and `primaryYAxis` still describes the values — no
extra configuration is required:

```dart
VarietyCartesianChart(
  series: <VarietySeries>[
    VarietyBarSeries(
      name: 'Revenue',
      cornerRadius: 6,
      data: const <VarietyChartData>[
        VarietyChartData('Jan', 32),
        VarietyChartData('Feb', 48),
      ],
    ),
  ],
)
```

Mixing a bar series with another series kind disables the transposition so that
all series share one coordinate system.


### Spark charts

Four dedicated widgets cover the whole spark chart family. Each fills its box,
so give it a height:

```dart
const SizedBox(
  height: 60,
  child: VarietySparkLineChart(
    data: <double>[4, 6, 5, 8, 7, 11, 9, 12],
    strokeWidth: 3,
    dashArray: <double>[6, 3],
  ),
);

const SizedBox(
  height: 60,
  child: VarietySparkBarChart(
    data: <double>[12, 18, 15, 24, 21, 30],
    labelDisplayMode: VarietySparkLabelDisplayMode.all,
    plotBand: VarietySparkPlotBand(start: 18, end: 26),
  ),
);

const SizedBox(
  height: 60,
  child: VarietySparkWinLossChart(
    data: <double>[1, -1, 1, 1, -1, 0, 1],
    negativePointColor: Color(0xFFE0603F),
    tiePointColor: Color(0xFF9AA0A6),
  ),
);
```

A marker and a trackball are configured the same way:

```dart
VarietySparkAreaChart(
  data: values,
  marker: const VarietySparkMarker(
    displayMode: VarietySparkMarkerDisplayMode.high,
    shape: VarietySparkMarkerShape.diamond,
  ),
  trackball: VarietySparkTrackball(
    activationMode: VarietySparkActivationMode.tap,
    tooltipFormatter: (VarietySparkTooltipFormatterDetails details) =>
        'Day ${details.index}: ${details.y}',
    hideDelay: 2000,
  ),
)
```

### Multiple Y axes

Give an extra axis a name and point a series at it:

```dart
VarietyCartesianChart(
  primaryYAxis: const VarietyAxis(type: VarietyAxisType.numeric, title: 'Revenue'),
  secondaryYAxes: const <VarietyAxis>[
    VarietyAxis(
      type: VarietyAxisType.numeric,
      name: 'rate',
      title: 'Rate (%)',
      opposedPosition: true,
    ),
  ],
  series: <VarietySeries>[
    VarietyColumnSeries(name: 'Revenue', data: revenue),
    VarietyLineSeries(name: 'Rate', yAxisName: 'rate', data: rate),
  ],
)
```

---

## Custom rendering

Every public series and element type is exported, so you can build your own
chart by assembling `VarietyElement`s and feeding them to a painter, or by
adding a custom `VarietyChartData` colour per point.

## Example

The [`example/`](example) directory contains a runnable application that
demonstrates every series kind. It is configured for all six Flutter platforms:

```bash
cd example
flutter run -d chrome    # web
flutter run -d macos     # macOS
flutter run -d windows   # Windows
flutter run -d linux     # Linux
flutter run              # Android or iOS device / emulator
```

## Additional information

* Issues and feature requests: please open an issue on the repository.
* Contributions are welcome. Before opening a pull request run:

  ```bash
  dart analyze lib test
  flutter test
  ```

* The package has no third-party dependencies, so `dart analyze` is the fastest
  way to check the library while iterating.
* Licensed under the MIT License — see [LICENSE](LICENSE).

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
| Cartesian series | Line (straight / curved / stepped / fast, with natural / cardinal / clamped / monotonic splines), area, spline area, step area, range area, spline range area, column, range column, bar, scatter, bubble, candle, hi-lo, hi-lo-open-close, waterfall, histogram, box and whisker, error bar; column and bar rectangles take a `spacing` gap, and candles can be drawn hollow (`enableSolidCandles`) or marked when all four prices are equal (`showIndicationForSameValues`) |
| Stacking | `none`, `normal` and `percent100` for column, bar, area and line series |
| Circular series | Pie, doughnut, radial bar |
| Special series | Funnel, pyramid |
| Spark charts | `VarietySparkLineChart`, `VarietySparkAreaChart`, `VarietySparkBarChart`, `VarietySparkWinLossChart` with markers, data labels, plot bands, point colour overrides, dash patterns and a trackball |
| Axes | Multiple Y axes and multiple X axes (`secondaryYAxes` / `secondaryXAxes`, bound from a series through `yAxisName` / `xAxisName`), each resolving its own range, ticks, captions and column slot width; numeric, category, date-time, date-time-category and logarithmic; cross-axis plot bands with gradients and dashed outlines, multi-level labels with merging and a configurable row height, tick marks on both axes (length, thickness, colour, inside or outside), major tick and major grid line style objects, minor ticks and minor grid lines (each with its own style), a caption cap (`maximumLabels`), caption alignment (`labelAlignment`), `trim` as a label intersection action, an axis crossing value (`crossesAt`), auto scrolling (`autoScrollingDelta` / `autoScrollingMode`), value axes that fit themselves to the visible points (`anchorRangeToVisiblePoints`), label intersection handling, the full range padding set (`none`, `normal`, `round`, `extra`, `additional`, `additionalStart`, `additionalEnd`, `roundStart`, `roundEnd`, `auto`), an initial zoom window (`initialZoomFactor` / `initialZoomPosition`), inversion, plot offsets, legend placement that resolves itself (`VarietyLegendPosition.auto`) and numeric patterns |
| Axis value boxes | While a crosshair or trackball is up, the current x is shown on the x axis and the current y on the y axis, styled through `VarietyAxisTooltipSettings` |
| Interactions | Tooltip with value formatting (the same `VarietyTooltipBehavior` styles the card on the cartesian, circular and funnel charts) (`format`, `decimalPlaces`), a configurable card (fill, border, radius, opacity, elevation, marker dot) and a shared/nearest/float trackball (vertical / horizontal / both / no guide) with value boxes pinned to the axes; a tooltip that follows the pointer instead of the point (`tooltipPosition`) and a `header` caption; crosshair; point, series and cluster selection with `VarietySelectionController`, multi selection and full selected / unselected styling (colour, border, opacity); pinch zoom, pan, mouse-wheel zoom, double-tap zoom, rubber-band zoom, axis zoom modes, a chart wide colour cycle (`palette`), an optional delay before a hovered tooltip appears (`showDuration`), an option to defer the repaint of a pinch until the fingers are off (`enableDeferredZooming: false`) and a legend that takes a series on and off the plot when an entry is tapped (`toggleSeriesVisibility`), striking the hidden entry through |
| Data labels | Position, pixel offset, per-series colour, card background, border and corner radius, rotation, zero suppression, opacity, connector lines back to the point, and running totals on stacked series |
| Markers | Nine glyphs (circle, square, diamond, triangle, inverted triangle, plus, cross, pentagon, vertical and horizontal strokes) plus `none` to draw nothing, with size, fill and border |
| Analysis | Trendlines (linear, exponential, logarithmic, polynomial, power, moving average) and technical indicators (SMA, EMA, WMA, TMA, RSI, ATR, momentum, ROC, Bollinger bands, MACD, stochastic, accumulation / distribution) |
| Decorations | Text, line, rectangle, ellipse, arrow and image annotations; plot area fill and border; chart frame |
| Callbacks | `onPointTap`, `onPointHover`, `onLegendTapped`, `onTooltipRender`, `onDataLabelRender`, `onAxisLabelTapped`, `onActualRangeChanged`, `onZoomStart`, `onZooming`, `onZoomEnd`, `onZoomReset`, `onChartTouchInteractionDown` / `Move` / `Up`, `onPlotAreaSwipe` |
| Export and incremental loading | `toImage({pixelRatio})` on the chart state, plus `onPlotAreaSwipe` / `loadMoreIndicatorBuilder` for an infinite scroll |
| Empty points | `gap`, `zero`, `average` and `drop` modes, plus `showMarker` to decide whether a substituted reading is marked |
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
  flutter_variety_chart: ^0.5.19
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

### Multiple axes

The vertical family is addressed with `secondaryYAxes` and `yAxisName`. Give an
extra axis a name and point a series at it:

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

The horizontal family works the same way through `secondaryXAxes` and
`xAxisName`. Every extra axis resolves its own range from its own series, prints
its own ticks in a row of its own under the plot area, and gives its columns a
slot width of its own — so two series measured in different units share one plot
area without either being squeezed into the other's scale:

```dart
VarietyCartesianChart(
  primaryXAxis: VarietyAxis(
    type: VarietyAxisType.numeric,
    name: 'rpm',
    title: 'Engine speed (rpm)',
    minimum: 0,
    maximum: 7000,
  ),
  secondaryXAxes: <VarietyAxis>[
    VarietyAxis(
      type: VarietyAxisType.numeric,
      name: 'road',
      title: 'Road speed (km/h)',
      minimum: 0,
      maximum: 220,
    ),
  ],
  primaryYAxis: const VarietyAxis(type: VarietyAxisType.numeric),
  series: <VarietySeries>[
    VarietyLineSeries(name: 'Torque vs rpm', data: torque),
    VarietyLineSeries(name: 'Power vs road speed', xAxisName: 'road', data: power),
  ],
)
```

Two things stay with the primary axis, matching how secondary Y axes behave:
grid lines and plot bands. The zoom window does too — pinching zooms the primary
axis only, because a window expressed in its units means nothing on another
scale. In a bar chart the layouts transpose, so the horizontal family carries the
values and a second horizontal axis is a second value axis.

---

## Export, swipe and incremental loading

`toImage` renders the chart through its own repaint boundary, so the picture is
the chart and nothing that happens to sit behind it:

```dart
final GlobalKey<VarietyCartesianChartState> key =
    GlobalKey<VarietyCartesianChartState>();

VarietyCartesianChart(key: key, series: series);

final ui.Image image = await key.currentState!.toImage(pixelRatio: 3);
```

`onPlotAreaSwipe` reports a pan that ran out of data at one end of the axis, and
`loadMoreIndicatorBuilder` shows a widget over the bottom of the plot while the
reader is sitting there. Together they are what a chart that pages its data
needs:

```dart
VarietyCartesianChart(
  series: <VarietySeries>[VarietyLineSeries(data: readings)],
  primaryXAxis: const VarietyAxis(
    type: VarietyAxisType.category,
    initialZoomFactor: 0.25, // open on a window, not the whole range
  ),
  zoomPanBehavior: const VarietyZoomPanBehavior(),
  onPlotAreaSwipe: (VarietySwipeDirection direction) => _fetchMore(direction),
  loadMoreIndicatorBuilder: (BuildContext context) =>
      const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
)
```

## Upgrading from 0.5.14

Three names changed in this release, all in the name of consistency:

| Was | Now |
| --- | --- |
| `VarietyAxis.labelAlignment: VarietyLabelPosition.outside` | `VarietyAxis.labelAlignment: VarietyLabelAlignment.start` (a `VarietyLabelPosition` no longer fits this field) |
| `VarietyTrackballVisibilityMode.always` | `VarietyTrackballVisibilityMode.visible` |
| `VarietyMultiLevelBorderType.curlyBracket` / `.brace` | `VarietyMultiLevelBorderType.curlyBrace` / `.squareBrace` |

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

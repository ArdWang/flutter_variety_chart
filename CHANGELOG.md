## 0.5.6

### Rounds out the option surface

A pass over the reference library turned up a set of options that were either
missing or declared and then never read. Everything here is wired through to
the renderer and covered by tests.

Added

* `VarietyRangePadding` gains `normal`, `additionalStart`, `additionalEnd`,
  `roundStart` and `roundEnd`, so an axis can be padded at one end only.
  `additional` now buys half an interval past the rounded ends, which it needs
  to be visible at all.
* `VarietyMarkerShape` gains `pentagon`, `verticalLine` and `horizontalLine`.
* `VarietySelectionType.cluster` selects one point per series at the tapped
  slot.
* `VarietyDataLabelSettings` gains `offset`, `useSeriesColor`,
  `backgroundColor`, `borderColor`, `borderWidth`, `borderRadius`, `angle` and
  `showZeroValue`.
* `VarietyTooltipBehavior` gains `format`, `decimalPlaces`, `canShowMarker`,
  `borderColor`, `borderWidth`, `opacity` and `elevation`. `format` wraps the
  value with `{value}`, so `'{value} kg'` prints `12 kg`. Both tooltip cards --
  the single point one and the shared trackball one -- now read the same
  behaviour, so a fill, border or opacity applies to every tooltip the chart
  shows. A `textStyle` colour also drives the card's heading and caption.
* `VarietyCartesianChart` gains `plotAreaBackgroundColor`,
  `plotAreaBorderColor`, `plotAreaBorderWidth`, `borderColor` and
  `borderWidth`.

Fixed

* `VarietySelectionBehavior.selectedColor` and `unselectedOpacity` were
  declared but never applied, so a selection changed nothing on screen.
  Selected points now take the configured colour and border, and series that
  hold nothing selected fade back by `unselectedOpacity`.

## 0.5.5

### A numeric x axis honours `interval`, and keeps it through a zoom

`VarietyAxis.interval` was read into the geometry and then never used: a numeric
x axis split `[minimum, maximum]` into `desiredIntervals` equal parts instead. A
caller whose x values are whole numbers — a point index, a slot number, anything
counted — therefore got grid lines and captions *between* its points, and
rounding a caption to the nearest point only hid part of the mismatch.

Zooming made it worse. A gesture overwrites `xMinimum`/`xMaximum` with the
visible window (`_resolvePrimaryRange`), and the ticks were then recomputed from
that window, whose bounds are never whole. Measured on a 1400px plot, every grid
line sat **22px** away from the point it was meant to mark.

The interval is now honoured the way the secondary axis has always honoured its
own in `yTicks`.

Fixed

* A numeric x axis lays its ticks on a fixed grid, `xTickOrigin + k * interval`,
  and clips that grid to the visible window. The origin is the axis minimum
  *before* the window is applied, so zooming and panning leave every tick on the
  same value instead of recomputing it from the window.
* Grid lines, captions and the measured label band all come from that one list
  (`VarietyCartesianGeometry.xNumericTicks`), so a caption can no longer
  describe a different value than the line it sits on — or than the band it
  reserved space for.
* When the visible window is narrower than a step and a half the whole grid
  would vanish, so the step subdivides — halving, or dropping to `1` — which
  keeps every tick a whole multiple of the caller's interval.
* Without an interval a numeric axis still splits the visible span into
  `desiredIntervals` equal parts, unchanged.

## 0.5.4

### Category axes no longer fold a day of readings into one slot

A category axis keyed each slot on the *caption* it would print, and a date
time caption defaults to a date only pattern. Every point of a day therefore
landed on the same slot: three readings a few seconds apart were drawn on top
of each other, and the line had nothing to spread across, so the points did
not line up with the times on the axis.

Fixed

* Categories key on the instant a point carries, not on its caption, which is
  what upstream's `DateTimeCategoryAxis` does when it keys on
  `millisecondsSinceEpoch`.
* Captions are derived separately, and a pattern is chosen fine enough to give
  every category a caption of its own, so a minute of readings is labelled
  `11:30:01`, `11:30:11`, `11:30:31` rather than one repeated `15 Sep`.
* Slots and captions are now kept apart, so a caller who pins a coarse
  `dateFormat` gets the repeated captions they asked for while every point
  still keeps its own slot.

## 0.5.3

### Trackball guide follows the point you tapped

The guide used to be anchored on the first series' nearest point, whatever the
touch was actually near. Series carry their own x values -- time stamped data
almost always does -- so a tap on a point of the second series could put the
guide more than a hundred pixels away, and every marker in the shared tooltip
sat beside it rather than on it.

Fixed

* The guide is anchored on the point closest to the touch across all series,
  which is what upstream's `leastX` does.
* `VarietyTrackballBehavior.displayMode` is now honoured. It was declared but
  never read, so every mode behaved like `groupAllPoints`:
  * `groupAllPoints` pulls every series onto the guide, so the markers line up
    with the guide and the tooltip.
  * `floatAllPoints` leaves each point on its own x.
  * `nearestPoint` reports the single closest point.
  * `none` reports nothing.

## 0.5.2

### Date time axis captions stay unique

A date time axis could print the same caption more than once, which made a
chart driven by very little data look like it had duplicate points. The
caption pattern used to be derived from the span alone, so it could be coarser
than the tick interval: milliseconds across half a minute were all captioned
`10:28:01`, ten days carved into hours repeated each `dd MMM` twenty-four
times, and a range crossing midnight repeated `10:00`.

Fixed

* The caption pattern is now resolved against the ticks that were actually
  generated, walking from the shortest pattern that reads naturally to one
  that keeps every caption distinct.
* Two ticks can no longer be captioned the same way, even when the axis pins a
  `dateFormat` or a `labelFormatter` that cannot tell them apart: the painter
  keeps the first caption and drops the rest.
* Automatic intervals are no longer taken at face value. The step is sized so
  the axis lands near eight ticks, which also stops a ten day range from being
  carved into two hundred and forty hourly ones. Ranges under two seconds now
  get millisecond ticks instead of a single label.

## 0.5.1

### Gesture zoom and pan aligned with Syncfusion

Pinch, wheel, double-tap, pan and selection zooming now use the normalised
`(zoomFactor, zoomPosition)` window model that `Syncfusion_flutter_charts`'
`ZoomPanBehavior` uses, instead of raw data-space minimum/maximum pairs. Each
axis keeps the visible fraction of the full range plus where that window
starts, so a gesture only ever touches two numbers and the focal point stays
pinned while it is applied.

Fixed

* The mouse wheel could zoom in but never back out: the target window was
  clamped against the already-zoomed window instead of the full range.
* A pinch anchored the vertical axis at the mirrored position, because the
  pixel-to-value helper treated the top of the plot as the axis minimum.
* Dragging vertically panned the plot against the finger. Both axes now move
  with the content.

Changed

* Selection zooming is driven by a long press, matching upstream's
  "long-press and drag to select a region". `VarietyZoomMode.both` now really
  does enable pinch, pan and selection at the same time, and
  `VarietyZoomMode.selection` keeps drag-to-pan.
* `VarietyZoomMode.none` now disables every zoom and pan gesture. It was
  previously ignored, so `mode: none` still zoomed.
* While selection zooming is active a long press draws the zoom region rather
  than activating a long-press trackball.

Removed a redundant null assertion in the trackball hit path that tripped
`unnecessary_non_null_assertion`.

## 0.5.0

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
  every drawable to the right series. All geometry builders were
  updated to populate the index.
* `VarietyElementRenderer.paintWith(canvas, element, series)` lets the painter
  pass the owning series through.
* `VarietySelectionBehavior` is the per-series override and threads through
  the chart widget via `VarietyChartWidgetState._seriesSelection(int)`.

Behaviour parity

* Per-series selection takes precedence over chart-wide selection on tap.
* The shared layout-time renderer construction is wrapped in `try / catch`
  so a broken user callback cannot bring down the chart.

## 0.4.0

### Line series parameter parity
* Added series-scoped parameters that bring `LineSeries` (and every other
  cartesian series) to functional parity with the upstream library:
  `markerSettings`, `gradient`, `borderGradient`, `enableTrackball`,
  `initialIsVisible`, `initialSelectedDataIndexes`, `isVisibleInLegend`,
  `legendItemText`, `legendIconType`, `pointColorMapper`, `dataLabelMapper`,
  `onPointDoubleTap`, `onPointLongPress`, `animationDuration`,
  `sortFieldValueMapper` and `borderWidth`.
* `VarietyMarkerSettings` is now exported and shared by every series.
* `dashArray` is accepted as an alias for `dashPattern`.
* Per-series `animationDuration` overrides the chart-level one when it is
  longer. The controller is rebuilt when the series list changes.
* Honour `initialIsVisible` at paint time and `enableTrackball` at hit-test
  time so hidden series do not appear in the trackball picker.

### Behaviour parity
* The double-tap gesture now dispatches the series-scoped `onPointDoubleTap`
  callback before the zoom-pan logic kicks in.
* Long-pressing a point dispatches the series-scoped `onPointLongPress`.
* The legend widget now honours `isVisibleInLegend` (defaulting the existing
  filter) and renders `legendItemText` instead of `name` when supplied.

### Fixed
* Series-scoped `onPointDoubleTap` was declared but never wired.
* A blank `geometry.data` lookup made the double-tap callback crash when the
  click fell on the chart edge.

## 0.3.0

### Spark charts
* Added four dedicated widgets: `VarietySparkLineChart`,
  `VarietySparkAreaChart`, `VarietySparkBarChart` and
  `VarietySparkWinLossChart`. Each one carries the full option set:
  `plotBand`, `color`, `isInversed`, `axisCrossesAt`, `axisLineColor`,
  `axisLineWidth`, `axisLineDashArray`, `highPointColor`, `lowPointColor`,
  `negativePointColor`, `firstPointColor`, `lastPointColor`,
  `labelDisplayMode`, `labelStyle` and `trackball`.
* Line charts add `strokeWidth` and `dashArray`; area charts add
  `borderWidth` and `borderColor`; bar charts add `borderWidth` and
  `borderColor`; win/loss charts add `tiePointColor` as well.
* Added `VarietySparkMarker` with `none`, `all`, `high`, `low`, `first`
  and `last` display modes, five shapes, a fill colour, an outline and a size.
* Added `VarietySparkLabelDisplayMode` with the same six modes for data labels.
* Added `VarietySparkPlotBand` to shade a value range with an optional border.
* Added `VarietySparkTrackball` with tap, double tap and long press activation,
  a line colour, width and dash pattern, a customisable tooltip card, a
  `tooltipFormatter` callback, `shouldAlwaysShow` and `hideDelay`.
* `VarietySparkline` is now a thin adapter over the four widgets, so the
  original API keeps working.

The four widgets, `VarietySparkMarker`, `VarietySparkPlotBand`,
`VarietySparkTrackball` and all four enumerations were verified parameter by
parameter against the reference implementation and have full coverage.

#### Behaviour parity

* The drawing area has **no padding**, so the first and last points sit on the
  edges and the highest value touches the top.
* The value scale follows the **data only**. `axisCrossesAt` moves the axis
  line and is clamped into the drawing area; it never stretches the scale.
* A flat series, or a series with a single point, is drawn on the top edge, and
  a single point is centred horizontally.
* `isInversed` **mirrors the series horizontally**, which is what the
  reference widget does, rather than flipping the value axis.
* Marker colour resolution follows the reference priority:
  first, last, high, low, then negative.
* A data label is placed above a positive value and below a negative one, is
  pushed clear of the marker, and is clamped inside the drawing area.
* The widget sizes itself when its constraints are unbounded: a 16:9 box, or
  480 x 270 when both axes are unbounded.

### Multiple axes
* Added `VarietyCartesianChart.secondaryYAxes` so a chart can plot series
  against more than one value axis.
* Added `VarietySeries.yAxisName` and `VarietySeries.xAxisName` to bind a
  series to a named axis.
* The layout resolves an independent range, tick interval and label format per
  axis, and the painter stacks the extra axes to the right of the plot area.

### Fixed
* `hideDelay` on a spark chart trackball now starts counting from the gesture,
  not only from a pointer exit.

## 0.2.0


Expanded the library from a core skeleton to a broad feature set.

### Series
* Added `VarietySplineAreaSeries`, `VarietyStepAreaSeries`,
  `VarietySplineRangeAreaSeries` and `VarietyFastLineSeries`.
* Added `VarietyBoxAndWhiskerSeries` with exclusive, inclusive and normal
  quartile modes, outliers, mean markers and inner point overlays.
* Added `VarietyErrorBarSeries` with fixed, percentage, standard deviation,
  standard error and custom magnitudes, usable standalone or attached to any
  cartesian series through `VarietySeries.errorBar`.
* Added `VarietySplineType` so splines can be cardinal, natural, clamped or
  monotonic.
* Added `VarietySortingOrder` to every series.

### Empty points
* Added `VarietyEmptyPointSettings` with the `gap`, `zero`, `average` and
  `drop` modes.

### Axes
* Added `VarietyLabelIntersectAction` with `none`, `hide`, `rotate45`,
  `rotate90`, `wrap` and `multipleRows`.
* Added `VarietyRangePadding`, `VarietyEdgeLabelPlacement`,
  `VarietyLabelPlacement`, `VarietyTickPosition`, `VarietyAxisBorderType`.
* Added `isInversed`, `plotOffset`, `plotOffsetStart`, `plotOffsetEnd`,
  `maximumLabels`, `numberFormat` and axis names.
* Added minor ticks and minor grid lines through `minorTicksPerInterval`,
  `VarietyMinorTickLines`, `VarietyMinorGridLines`, `VarietyMajorTickLines`
  and `VarietyMajorGridLines`.
* Added `VarietyMultiLevelBorderType` so group brackets can be rectangles,
  braces or curly brackets.

### Interactions
* Added a full callback surface: `onLegendTapped`, `onTooltipRender`,
  `onDataLabelRender`, `onAxisLabelTapped`, `onActualRangeChanged`,
  `onZoomStart` and `onZoomEnd`.
* Added `VarietySelectionController`, `enableMultiSelection` and
  `toggleSelection`.
* Added `VarietyZoomAxisMode` so a gesture can zoom the primary axis, the
  secondary axis or both.
* Added trackball `lineType`, `displayMode`, `visibilityMode`,
  `markerSettings`, `hideDelay` and `shouldAlwaysShow`.
* Added `VarietyRenderingMode` with an optional loading placeholder.

### Legend
* Added `VarietyLegendSettings`: icon type, icon size, item orientation,
  overflow mode, alignment, title, per-item padding, responsiveness and
  `toggleSeriesVisibility`. Icons are now painted per series kind.

### Analysis
* Added the accumulation / distribution indicator (`VarietyAdIndicator`).

### Tooling
* Split the test suite into 14 files covering geometry, indicators,
  regression, formatting and widgets; 163 cases in total.

## 0.1.0

Initial release.

* Added `VarietyCartesianChart` supporting line, area, column, bar and scatter
  series, numeric and category axes, grid lines, data labels, legend and tooltip.
* Added `VarietyCircularChart` supporting pie and doughnut series with slice
  exploding and centre widgets.
* Added an entrance animation, hover/tap hit testing and custom tooltip builders.
* Added a full multi-platform example application.

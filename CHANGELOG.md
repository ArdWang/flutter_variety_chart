## 0.5.16

### A cheaper frame, and one list that stopped growing

Nothing here changes what a chart looks like. It changes how much work each
frame costs, and it fixes a list that never stopped growing.

Fixed

* The axis label rectangles the painter hands back were appended to on every
  frame rather than describing the current one. A chart that repainted for a
  second collected hundreds of stale rectangles: memory that grew without
  bound, and a hit test that could match positions no longer on screen. Both
  hit lists are emptied at the start of a paint now. The regression test in
  `test/render/variety_render_hot_paths_test.dart` reports twelve entries
  where four are expected on the previous revision.

Performance

* A category chart looked a point's slot up by scanning the whole category
  list, once per point and again for every element built, which made the layout
  quadratic in the number of categories. Three series of two thousand points
  took 19.6 ms to lay out and now take 3.6 ms. The lookup goes through an index
  built alongside the keys, so what it resolves is unchanged.
* The inset probe that is built on every frame purely to measure the axis
  furniture no longer builds the series elements, which nothing on that path
  reads: 0.9 ms against 3.6 ms for a full build of the same data.
* Markers no longer build a path and two paints apiece. The glyph is built once
  per shape and size, the circle and the square go straight to the canvas, and
  the paints are reused with their colour reassigned. A five thousand point
  scatter went from 14.4 ms a frame to 4.6 ms, and a two thousand point line
  with markers from 7.6 ms to 2.1 ms.
* The dashes of a dashed path are collected into a single path and drawn once,
  instead of a path being cut out and drawn for each dash: a two thousand point
  dashed line went from 5.9 ms a frame to 3.7 ms.

Added

* `VarietyCartesianGeometry.buildElements`. Passing `false` skips the element
  pass for callers that only need the ranges, ticks and captions; `elements` is
  then empty, so nothing that draws should be handed a geometry built that way.

Notes

* A series dense enough to draw several points per pixel still costs
  proportionally more to dash, because there are proportionally more dashes.
  That is what `VarietyFastLineSeries` and its `decimationFactor` are for.

## 0.5.15

### The rest of the dead configuration, and the first export hook

An option that is declared, documented and then never read is worse than no
option at all: the chart silently ignores what the caller asked for. The sweep
that has been clearing that list now comes back empty — every field it found is
read by the renderer — and the options the API was missing are added with
them.

Added

* `VarietyAxis.minorTickLines` is drawn at last, with `size`, `width` and
  `color`, on both axes and on every extra axis. Minor ticks follow
  `minorTicksPerInterval` exactly as before; only their styling was missing.
* `VarietyAxis.maximumLabels` caps the captions at that many per 100 logical
  pixels, which is where the default of three comes from. Captions are dropped
  on a regular stride, and the two ends are always kept.
* `VarietyAxis.labelAlignment` places a caption by its leading edge, its centre
  or its trailing edge.
* `VarietyMultiLevelLabels.merge` folds neighbouring groups that share a caption
  and touch into one bracket, and `rowHeight` sets how far a nested row sits
  below the axis.
* `VarietyPlotBand.associatedAxisStart` / `associatedAxisEnd` bound a band on the
  opposite axis, turning a full-height stripe into a rectangle;
  `VarietyPlotBand.gradient` replaces the flat fill; `dashArray` outlines the
  band.
* `VarietyErrorBarSeries.direction` draws a one-sided whisker, and
  `verticalErrorValue` / `horizontalErrorValue` plus the four per-side
  magnitudes give each direction its own reach (the per-side ones apply to
  `VarietyErrorBarType.custom`).
* `VarietyAxis.initialZoomFactor` / `initialZoomPosition` open the chart on a
  window rather than the whole range, still pan and zoom-able from there.
* `VarietyCartesianChart.palette` overrides the colour cycle for one chart.
* `VarietyCartesianChart.onChartTouchInteractionDown` / `Move` / `Up` report
  every raw pointer position, whether or not it landed on a series.
* `VarietyCartesianChart.onPlotAreaSwipe` fires when a pan runs out of data at
  one end of the axis, and `loadMoreIndicatorBuilder` shows a widget over the
  bottom of the plot while the reader is sitting at that end — the pair an
  infinite scroll needs.
* `toImage({double pixelRatio})` on `VarietyCartesianChartState`,
  `VarietyCircularChartState` and `VarietyFunnelChartState`, reached through a
  `GlobalKey` of the state type. Every chart now owns a `RepaintBoundary`, so the
  export is the chart and nothing behind it.
* `VarietyZoomPanBehavior.onZooming` reports the window on every frame of a
  gesture, and `onZoomReset` reports a return to the full range.
* `VarietyTooltipBehavior.tooltipPosition` pins the card to the point or lets it
  follow the pointer, and `header` captions it.
* `VarietyLegendPosition.auto` picks a side from the shape of the chart: taller
  than wide puts the legend underneath, wider puts it at the right.
* `VarietyMarkerShape.none` draws no glyph at all, which is how one series in a
  chart disables markers for itself.
* `VarietyLegendIconType.pentagon` / `verticalLine` / `horizontalLine`, and a
  series' own `legendIconType` now wins over the chart wide setting.
* `VarietyLabelIntersectAction.trim` shortens a caption that would collide
  instead of dropping it.
* `VarietyAxisBorderType.withoutTopAndBottom` joins the two value axes with
  upright rules and leaves the top and bottom edges out.
* `VarietyTrackballLineType.none` draws no guide, and
  `VarietyActivationMode.doubleTap` lets a trackball or crosshair claim the
  double tap when zoom is not using it.
* `VarietyDataLabelSettings.connectorLineSettings`
  (a `VarietyConnectorLineSettings` with `length`, `width`, `color` and `type`)
  draws a line from a caption back to its point, `opacity` fades the caption and
  its card, and `showCumulativeTotal` captions a stack with its running total.
* `VarietySeries.selectionColor` colours the highlight of a selected point;
  `VarietySeries.legendIconType`, `initialSelectedDataIndexes` and
  `animationDelay` are all consumed now, so a series can pick its own legend
  glyph, open the chart already selected, and be staggered behind the series
  before it.
* `VarietyEmptyPointSettings.showMarker` decides whether a point whose value was
  substituted for an empty one gets a marker. It defaults to `false`, so an
  interpolated reading no longer passes itself off as a measurement.
* `VarietyTooltipBehavior.showDuration` waits that long before a hovered card
  appears, so a pointer crossing the plot no longer flashes one at every point
  it passes.
* `VarietyZoomPanBehavior.enableDeferredZooming: false` keeps the zoom state
  moving during a pinch but holds the repaint back until the fingers are off,
  which is what makes pinching a very large data set cheap.
* New value types: `VarietyLabelAlignment`, `VarietyErrorBarDirection`,
  `VarietyTooltipPosition`, `VarietySwipeDirection`, `VarietyChartTouchArgs`,
  `VarietyConnectorLineSettings`.

Changed

* **Breaking.** `VarietyAxis.labelAlignment` is now a `VarietyLabelAlignment`
  (`start`, `center`, `end`), the axis counterpart of the caption alignment
  the data labels use. It used to be a `VarietyLabelPosition`,
  which described a different idea. The default is `center`, so nothing moves
  for a chart that does not set it.
* **Breaking.** `VarietyTrackballVisibilityMode.always` is now `visible`, the
  spelling used everywhere else in the API.
* **Breaking.** `VarietyMultiLevelBorderType.curlyBracket` and `brace` are now
  `curlyBrace` and `squareBrace`, and `withoutTopAndBottom` was added.

Fixed

* A plain pan reported nothing, so `onZoomEnd` never fired after panning. It
  does now, and a pan that runs out of data reports the end through
  `onPlotAreaSwipe`.
* The room reserved for a multi-level label band was hard coded to 22 pixels a
  row while the painter drew the rows at `rowHeight`. Both now read the same
  value, which is the same half-wired mistake the tick label style used to have.

## 0.5.14

### Multiple horizontal axes

`VarietySeries.xAxisName` was declared, mirrored in every series constructor and
read by nothing. The vertical family already had its counterpart working
(`secondaryYAxes` + `yAxisName`); the horizontal family never went plural. It
does now.

Added

* `VarietyCartesianChart.secondaryXAxes`, bound from a series through
  `VarietySeries.xAxisName` exactly as secondary Y axes are bound through
  `yAxisName`. Every extra axis resolves its own range, its own ticks and its own
  captions, prints them in a row of its own under the plot area, and gives the
  columns on it a slot width of their own. A name that matches no axis falls back
  to the primary one.
* `VarietyCartesianGeometry` gained the per-axis horizontal state its vertical
  counterpart already had: `xAxes`, `seriesXAxis`, `xAxisIndexOf`, `xAxisFor`,
  `axisXTypes`, `axisXMinimums` / `axisXMaximums` / `axisXIntervals` /
  `axisXTickOrigins`, `axisCategories`, `axisCategoryValues`, `axisSlotCenters`,
  `axisSlotWidths`, `axisDateTimeTicks`, `pixelXOn`, `xTickPositionsOn`,
  `xNumericTicksOn`, `xMinorTickPositionsOn`, `xTickLabelOn` and
  `dateTimeTickLabelOn`. The old singular members (`categories`, `slotCenters`,
  `slotWidth`, `xMinimum`, `xMaximum`, `xInterval`, `xTickOrigin`,
  `dateTimeTicks`, `xNumericTicks`, `xAxisType`, `pixelXFor`, `categoryIndexOf`)
  still read and behave exactly as before, now as views onto axis 0, except
  that `pixelXFor` takes a series index instead of a series and
  `categoryIndexOf` takes an optional axis index.

Changed

* **Two horizontal axes can now share one plot area, so a series can leave the
  primary axis' scale.** That is the point of the feature, but it means a series
  that names a second horizontal axis no longer widens the primary axis' range,
  and its points are drawn against the other axis' pixels. Charts that name no
  axis are unaffected down to the pixel.
* Column grouping now looks only at the series standing on the same slot axis.
  Previously the group width was divided by every column-like series on the
  chart and the offset was taken from the series' position in the whole list, so
  a column chart with a line series interleaved between two column series gave
  the later column the wrong offset and a width divided by the wrong count.
* The trackball snaps each series on its own horizontal axis: a category axis to
  the nearest slot, a value axis to the nearest point by pixel. On a single-axis
  chart this is the old behaviour; on a multi-axis chart it is what keeps a
  series on a second axis reachable.
* Grid lines and plot bands stay with the primary horizontal axis, and so does
  the zoom window, matching how secondary Y axes have always been treated. A
  window expressed in the primary axis' units means nothing on another scale, so
  a second axis always shows its whole range.

Fixed

* **`VarietyChartTheme.axisLabelTextStyle` now reaches every tick label it
  claims to.** The primary captions honoured it, but the secondary value axes,
  the extra horizontal axes and the room the widget reserves for all of them
  fell back to a hard-coded 11 px style instead, so a chart that asked for
  larger labels got them on the primary axis only and clipped them everywhere
  else. The three places that have to agree — the caption, the space reserved
  for it and whatever is stacked underneath it — now share one chain
  (`axis.labelStyle`, then the theme, then the built-in default), and the
  multi-level labels measure the primary row with it too.

Covered by test/render/variety_multi_x_axis_test.dart and
test/widgets/variety_axis_label_style_test.dart, and the example app's
Advanced page grew a two-axis dyno chart.

## 0.5.13

### Auto scrolling and the anchored value range

Two more axis fields were declared, documented and never read.

Added

* `autoScrollingDelta` and `autoScrollingMode` now keep a window of the axis in
  view. The delta is a span in axis units, so on a category axis it is the number
  of points: a delta of 20 keeps the last twenty categories visible and leaves
  the rest reachable by panning. `VarietyAutoScrollingMode.start` keeps the
  oldest points instead of the newest, fewer points than the delta shows all of
  them, and an appended point slides the window along. A window the reader has
  moved by hand is left alone, so the delta never fights a gesture.
* `anchorRangeToVisiblePoints` now decides whether a value axis fits itself to
  the points inside the visible window. It is on by default, which is what makes
  panning into a long series rescale the value axis to what is on screen.

Changed

* **Zooming one axis can now rescale another.** With the default
  `anchorRangeToVisiblePoints: true`, narrowing the x window re-fits the value
  axis to the points left in view, so the reading under the pointer is no longer
  fixed on the y axis while x zooms. Set `anchorRangeToVisiblePoints: false` on
  the value axis for the previous behaviour, where its range covers every point.

Covered by test/widgets/variety_auto_scrolling_test.dart and the
`anchorRangeToVisiblePoints` pair in test/widgets/variety_pinch_zoom_test.dart.

## 0.5.12

### The axes can cross where the data says

`VarietyAxis.crossesAt` was declared and never read, so there was no way to run
the x axis through zero -- the line, its marks and its captions all stayed on
the bottom edge. A chart of signed data had to keep a baseline it did not mean.

`crossesAt` on an axis now moves the opposite axis line to that reading: the
line lands on the value, the marks point away from it and the x captions sit on
whichever side of it they have room on, so a line through the middle of the
plot does not print its labels over the series. Readings outside the visible
range clamp to the edge.

An axis that sets no `crossesAt` draws exactly what it drew before, including
`opposedPosition` handling.

Covered by test/render/variety_axis_crossing_test.dart.

## 0.5.11

### Tick marks were half wired and half missing

Each axis carried `majorTickLines` and `majorGridLines` style objects that
nothing read, and `tickPosition` that nothing read either. Worse, the marks
that did get drawn were nested inside the caption loop, so `showLabels: false`
silently took the tick marks with it, and the x axis never drew marks at all
however `showTicks` was set.

Fixed

* `majorTickLines` (size, width, colour) and `majorGridLines` (width, colour,
  dash array) now reach the renderer on both axes. `majorTickLines` wins over
  the plain `tickLength` / axis colour fields, the same relationship
  `minorGridLines` already had with the grid fields.
* `tickPosition` now decides the side a mark is drawn on, on both axes and on
  extra axes, and `VarietyTickPosition.inside` flips it into the plot area.
* Tick marks no longer depend on `showLabels`: the two are separate switches,
  which is what the fields always implied.
* The x axis draws tick marks, which it never did.

### The guides read their lineType

`VarietyTrackballBehavior.lineType` and `VarietyCrosshairBehavior.lineType`
were both declared and never read: the trackball always drew a vertical guide
and the crosshair always fell back to its two booleans. Both now resolve
through the same switch, and the crosshair's `showVerticalLine` /
`showHorizontalLine` pair only decides when no `lineType` was given.

### The trackball reads its visibilityMode

`VarietyTrackballBehavior.visibilityMode` was declared and never read. `always`
keeps the trackball past its hide delay, `hidden` refuses to show it at all and
`auto` is the behaviour that was already there. `shouldAlwaysShow` is kept as
the older spelling of `always`.

Covered by test/render/variety_axis_tick_lines_test.dart and
test/widgets/variety_trackball_visibility_test.dart.

## 0.5.10

### `splineType` now picks the interpolation

`VarietyLineSeries.splineType` (and the four other line-like series that carry
one) was declared, documented and then never read: every curved series was
drawn with the same cardinal spline, so `natural`, `clamped` and `monotonic`
all produced the identical curve.

A curve is a cubic Hermite run, so the four kinds differ only in the tangent
carried at each point, and each axis is interpolated as its own scalar
sequence. That makes the curve a parametric spline rather than a function of
x, which is what the existing shape already assumed.

* `cardinal` -- Catmull-Rom, the previous behaviour and still the default, so
  charts that never set the field are unchanged.
* `natural` -- solves the tridiagonal system with a zero second derivative at
  each end.
* `clamped` -- the same system with a flat tangent pinned at each end.
* `monotonic` -- Fritsch-Carlson, which pulls the tangents back inside the
  monotone cone so the curve cannot overshoot the points it passes through.

`VarietySeries` gains a `splineType` getter defaulting to `cardinal`, so the
renderer can ask any series for one; the non-line series ignore it.

Covered by test/render/variety_spline_type_test.dart, which pins the overshoot
behaviour of `cardinal` against `monotonic` and would have passed trivially
before, since every kind drew the same path.

## 0.5.9

### Tooltip styling reaches the circular and funnel charts

`VarietyCircularChart` and `VarietyFunnelChart` only had an `enableTooltip`
flag and a body builder, so the card they showed was always the default one --
its fill, border, opacity and marker dot could not be changed at all, and
neither could the way a value was captioned.

Added

* `tooltipBehavior` on `VarietyCircularChart` and `VarietyFunnelChart`, the
  same `VarietyTooltipBehavior` the cartesian chart takes. All four chart
  widgets now style and format their tooltips the same way, and the card is
  built from one shared chrome.
* `enableTooltip` remains the on/off switch and is now combined with
  `VarietyTooltipBehavior.enabled`, so either one hides the card.

## 0.5.8

### Value boxes on the axes

While a crosshair or trackball is up the reader has to look down at the axis to
learn which x the guide sits on, and across to it for the y. The guide carried
no such reading, so the axis had to be traced by eye.

Added

* `VarietyAxisTooltipSettings`, and an `axisTooltip` field on both
  `VarietyCrosshairBehavior` and `VarietyTrackballBehavior`. The x box rides on
  the x axis under the guide, the y box on the y axis level with the point.
* The caption comes from the axis, so `labelFormatter`, `numberFormat` and
  `dateFormat` shape the text; the settings cover the fill, text colour,
  outline, corner radius and padding. `VarietyAxisTooltipSettings.hidden` turns
  the boxes off.
* `axisTooltipBackgroundColor`, `axisTooltipTextColor` and
  `axisTooltipBorderColor` on `VarietyChartTheme`, all falling back to the
  tooltip colours.
* `varietyFormatTooltipValue`, the value formatter the tooltip cards used, is
  now shared rather than private to the card.

## 0.5.7

### A chart theme you can actually reach

`VarietyChartTheme` existed but only carried the six colours the painter
happened to need, and there was no way to hand a chart your own. Everything
else -- the minor grid, tick marks, axis titles, chart title, legend, plot
area, crosshair, rubber-band selection, data labels and the series palette --
was either derived from the ambient `ThemeData` or hardcoded.

Added

* Around twenty more fields on `VarietyChartTheme`, covering grid lines (major
  and minor), tick marks, axis titles, chart title and its fill, legend text,
  title and fill, plot area fill and border, data labels, crosshair, the
  rubber-band selection rectangle, the shared tooltip's separator, and seven
  text styles.
* `VarietyChartTheme.copyWith`, so one override never disturbs the rest. Every
  field left out falls back to the six base colours, which in turn come from
  the surrounding theme, so nothing needs configuring for a default look.
* `VarietyChartThemeScope`, which applies a theme to every chart below it.
  `VarietyChartTheme.of` reads the nearest scope first and derives from the
  ambient `ThemeData` when there is none.
* `palette`, which replaces the built-in series colours for the whole chart.

Fixed

* `VarietyZoomPanBehavior.selectionRectColor` and `selectionRectBorderColor`
  were declared but never read: the rubber-band rectangle was painted with a
  hardcoded blue. It now honours the behaviour, then the theme.

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

* Categories key on the instant a point carries, not on its caption, so two
  readings a second apart stay in buckets of their own even when their captions
  happen to match.
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
  so the crosshair lands on the point the reader actually aimed at.
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

### Gesture zoom and pan reworked around a normalised window

Pinch, wheel, double-tap, pan and selection zooming now use a normalised
`(zoomFactor, zoomPosition)` window model instead of raw data-space
minimum/maximum pairs. Each
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

* Selection zooming is driven by a long press: press, drag out a region,
  release. `VarietyZoomMode.both` now really
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
Closed every remaining gap in the series parameter surface.
`VarietyLineSeries` now exposes all 37 parameters the chart API offers.

* `onCreateRenderer` lets you supply a custom element renderer per series.
  The painter keeps `Map<int, VarietyElementRenderer>` so each series is
  drawn by its own renderer instance.
* `onCreateShader` is consulted for every path the series emits (fill and
  stroke); a non-null shader overrides `gradient` and `borderGradient`.
* `onRendererCreated` fires once per series right after the renderer is
  built, which is the hook a renderer-scoped controller attaches to.
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
* Added series-scoped parameters, shared by `VarietyLineSeries` and every
  other cartesian series:
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
parameter and have full coverage.

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

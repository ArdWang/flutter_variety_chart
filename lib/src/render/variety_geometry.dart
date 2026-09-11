import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../analysis/variety_regression.dart';
import '../models/variety_axis.dart';
import '../models/variety_chart_data.dart';
import '../models/variety_empty_points.dart';
import '../models/variety_enums.dart';
import '../models/variety_marker_settings.dart';
import '../models/variety_options.dart';
import '../models/variety_series.dart';
import '../models/variety_trendline.dart';
import '../utils/variety_label_utils.dart';
import 'variety_elements.dart';

/// Identifies the data point that sits under a pointer.
@immutable
class VarietyHitResult {
  /// Creates a hit result.
  const VarietyHitResult({
    required this.series,
    required this.seriesIndex,
    required this.point,
    required this.pointIndex,
    required this.position,
    this.band,
  });

  /// The series that owns the point.
  final VarietySeries series;

  /// The index of the owning series.
  final int seriesIndex;

  /// The matched data point.
  final VarietyChartData point;

  /// The index of the point inside the series.
  final int pointIndex;

  /// The pixel position of the point on screen.
  final Offset position;

  /// The rectangle of the point, when the series draws bands.
  final Rect? band;

  @override
  bool operator ==(Object other) =>
      other is VarietyHitResult &&
      other.seriesIndex == seriesIndex &&
      other.pointIndex == pointIndex;

  @override
  int get hashCode => Object.hash(seriesIndex, pointIndex);
}

/// A single renderable slice of a circular series.
@immutable
class VarietySlice {
  /// Creates a slice description.
  const VarietySlice({
    required this.startAngle,
    required this.sweepAngle,
    required this.outerRadius,
    required this.innerRadius,
    required this.color,
    required this.point,
    required this.seriesIndex,
    required this.pointIndex,
    required this.center,
    this.strokeColor,
    this.strokeWidth = 1.5,
    this.cornerRadius = 0.0,
    this.isTrack = false,
  });

  /// The starting angle in radians.
  final double startAngle;

  /// The angular sweep in radians.
  final double sweepAngle;

  /// The outer radius in logical pixels.
  final double outerRadius;

  /// The inner radius in logical pixels.
  final double innerRadius;

  /// The fill colour of the slice.
  final Color color;

  /// The data point backing the slice.
  final VarietyChartData point;

  /// The index of the owning series.
  final int seriesIndex;

  /// The index of the point inside the series.
  final int pointIndex;

  /// The centre the slice is drawn around.
  final Offset center;

  /// The colour stroked between slices.
  final Color? strokeColor;

  /// The thickness stroked between slices.
  final double strokeWidth;

  /// The corner radius of the ring segment.
  final double cornerRadius;

  /// Whether this slice is the unfilled track behind a radial bar.
  final bool isTrack;
}

/// A single segment of a funnel or pyramid.
@immutable
class VarietyFunnelSegment {
  /// Creates a funnel segment.
  const VarietyFunnelSegment({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    required this.color,
    required this.point,
    required this.pointIndex,
    required this.center,
  });

  /// The top-left corner.
  final Offset topLeft;

  /// The top-right corner.
  final Offset topRight;

  /// The bottom-right corner.
  final Offset bottomRight;

  /// The bottom-left corner.
  final Offset bottomLeft;

  /// The fill colour.
  final Color color;

  /// The data point backing the segment.
  final VarietyChartData point;

  /// The index of the segment.
  final int pointIndex;

  /// The centre used for label anchoring.
  final Offset center;
}

/// Derives the pixel geometry of a cartesian chart from its series and axes.
class VarietyCartesianGeometry {
  /// Builds the geometry for the given [series] inside [plotRect].
  VarietyCartesianGeometry({
    required this.series,
    required VarietyAxis xAxis,
    required VarietyAxis yAxis,
    required Rect plotRect,
    required this.progress,
    this.visibleXRange,
    this.visibleYRange,
    this.dataLabelResolver,
    this.secondaryYAxes = const <VarietyAxis>[],
  })  : _rawPlotRect = plotRect,
        transposed = _shouldTranspose(series),
        xAxis = _shouldTranspose(series) ? yAxis : xAxis,
        yAxis = _shouldTranspose(series) ? xAxis : yAxis {
    yAxes = <VarietyAxis>[yAxis, ...secondaryYAxes];
    _resolveSeriesAxes();
    _resolveAxisTypes();
    _resolveData();
    _collectCategories();
    _resolveRanges();
    _buildPositions();
    _buildElements();
  }

  void _resolveSeriesAxes() {
    seriesYAxis = List<int>.generate(series.length, (int index) {
      final String? name = series[index].yAxisName;
      if (name == null) {
        return 0;
      }
      final int found =
          yAxes.indexWhere((VarietyAxis axis) => axis.name == name);
      return found < 0 ? 0 : found;
    });
    axisMinimums = List<double>.filled(yAxes.length, 0);
    axisMaximums = List<double>.filled(yAxes.length, 1);
    axisIntervals = List<double>.filled(yAxes.length, 1);
  }

  /// The index of the secondary axis a series is plotted against.
  int axisIndexOf(int seriesIndex) =>
      seriesIndex >= 0 && seriesIndex < seriesYAxis.length
          ? seriesYAxis[seriesIndex]
          : 0;

  /// The axis object a series is plotted against.
  VarietyAxis axisFor(int seriesIndex) => yAxes[axisIndexOf(seriesIndex)];

  final Rect _rawPlotRect;

  /// The cartesian series to lay out.
  final List<VarietySeries> series;

  /// Whether the layout is transposed so that values run horizontally.
  ///
  /// A bar chart needs its value axis to be horizontal, so when every series is
  /// a [VarietyBarSeries] the declared primary and secondary axes are swapped
  /// and every point is rewritten as `(value, categoryIndex)`.
  final bool transposed;

  /// The effective horizontal axis configuration.
  final VarietyAxis xAxis;

  /// The effective vertical axis configuration.
  final VarietyAxis yAxis;

  /// The data as authored by the caller, before transposition.
  late final List<List<VarietyChartData>> sourceData;

  /// The rectangle available for plotting, excluding axis captions.
  ///
  /// The value honours the `plotOffset`, `plotOffsetStart` and `plotOffsetEnd`
  /// settings declared on the two axes.
  Rect get plotRect {
    final double left = _rawPlotRect.left + xAxis.plotOffsetStart;
    final double right = _rawPlotRect.right - xAxis.plotOffsetEnd;
    final double top = _rawPlotRect.top + yAxis.plotOffsetEnd;
    final double bottom = _rawPlotRect.bottom - yAxis.plotOffsetStart;
    final double inset = math.min(xAxis.plotOffset, yAxis.plotOffset);
    final Rect adjusted =
        Rect.fromLTRB(left, top + inset, right, bottom - inset);
    if (adjusted.width < 8 || adjusted.height < 8) {
      return _rawPlotRect;
    }
    return adjusted;
  }

  /// The animation progress, from `0` (collapsed) to `1` (fully drawn).
  final double progress;

  /// An optional zoom window expressed in primary-axis units.
  final (double, double)? visibleXRange;

  /// An optional zoom window expressed in secondary-axis units.
  final (double, double)? visibleYRange;

  /// Additional secondary axes, drawn to the right of the plot area.
  ///
  /// A series opts into one of these axes by setting its `yAxisName` to the
  /// matching `VarietyAxis.name`.
  final List<VarietyAxis> secondaryYAxes;

  /// An optional hook that rewrites, or suppresses, a data label caption.
  ///
  /// Returning `null` keeps the default caption and returning an empty string
  /// removes the label.
  final String? Function(
    VarietySeries series,
    int seriesIndex,
    VarietyChartData point,
    int pointIndex,
    String caption,
  )? dataLabelResolver;

  /// The resolved type of the primary axis.
  late final VarietyAxisType xAxisType;

  /// The resolved type of the secondary axis.
  late final VarietyAxisType yAxisType;

  /// The data each series actually plots, after binning, accumulation and
  /// grouping have been applied.
  late final List<List<VarietyChartData>> resolvedData;

  /// The ordered category captions, populated for category axes.
  final List<String> categories = <String>[];

  /// The raw category values, populated for category axes.
  final List<dynamic> categoryValues = <dynamic>[];

  /// The lowest value on the primary axis, in axis units.
  double xMinimum = 0;

  /// The highest value on the primary axis, in axis units.
  double xMaximum = 1;

  /// Every secondary axis in play, the primary one first.
  late final List<VarietyAxis> yAxes;

  /// The index of the secondary axis each series is plotted against.
  late final List<int> seriesYAxis;

  /// The lowest value of each secondary axis.
  late final List<double> axisMinimums;

  /// The highest value of each secondary axis.
  late final List<double> axisMaximums;

  /// The tick interval of each secondary axis.
  late final List<double> axisIntervals;

  /// The lowest value on the primary secondary axis.
  double yMinimum = 0;

  /// The highest value on the secondary axis.
  double yMaximum = 1;

  /// The spacing between secondary axis ticks.
  double yInterval = 1;

  /// The interval between primary axis ticks on a numeric axis.
  double xInterval = 1;

  /// The base of a logarithmic secondary axis.
  double logBase = 10;

  /// The pixel positions of every point, indexed by series then point.
  final List<List<Offset>> pointPositions = <List<Offset>>[];

  /// The rectangles of every banded point, indexed by series then point.
  final List<List<Rect?>> bandRects = <List<Rect?>>[];

  /// The horizontal centre of each category slot.
  final List<double> slotCenters = <double>[];

  /// The width of one slot in logical pixels.
  double slotWidth = 0;

  /// The drawables produced by this layout, in painting order.
  final List<VarietyElement> elements = <VarietyElement>[];

  /// The date time ticks, populated for date time axes.
  final List<DateTime> dateTimeTicks = <DateTime>[];

  double get _xSpan => math.max(xMaximum - xMinimum, 1e-9);

  double get _ySpan => math.max(yMaximum - yMinimum, 1e-9);

  bool get _isLogarithmic => yAxisType == VarietyAxisType.logarithmic;

  bool get _isDateTimePrimary =>
      xAxisType == VarietyAxisType.dateTime ||
      xAxisType == VarietyAxisType.dateTimeCategory;

  /// The Y pixel of the value `0` on the given axis.
  double baselineYOn(int axisIndex) {
    if (axisIndex <= 0) {
      return baselineY;
    }
    final double lo = axisMinimums[axisIndex];
    final double hi = axisMaximums[axisIndex];
    if (lo > 0) {
      return pixelYOn(axisIndex, lo);
    }
    if (hi < 0) {
      return pixelYOn(axisIndex, hi);
    }
    return pixelYOn(axisIndex, 0);
  }

  /// The Y pixel of the value `0`, clamped into the visible range.
  double get baselineY {
    if (yMinimum > 0) {
      return pixelY(yMinimum);
    }
    if (yMaximum < 0) {
      return pixelY(yMaximum);
    }
    if (_isLogarithmic) {
      return pixelY(yMinimum);
    }
    return pixelY(0);
  }

  /// The secondary axis tick values.
  List<double> get yTicks {
    if (yAxisType == VarietyAxisType.category ||
        yAxisType == VarietyAxisType.dateTimeCategory) {
      return List<double>.generate(categories.length, (int i) => i.toDouble());
    }
    if (_isLogarithmic) {
      return _logarithmicTicks();
    }
    final List<double> ticks = <double>[];
    const int guard = 2000;
    double value = yMinimum;
    int count = 0;
    while (value <= yMaximum + yInterval * 1e-6 && count < guard) {
      ticks.add(value);
      value += yInterval;
      count++;
    }
    return ticks;
  }

  // ---------------------------------------------------------------------------
  // Resolution
  // ---------------------------------------------------------------------------

  void _resolveAxisTypes() {
    if (transposed) {
      xAxisType = xAxis.type ?? VarietyAxisType.numeric;
      yAxisType = yAxis.type ?? VarietyAxisType.category;
      logBase = yAxis.logBase <= 1 ? 10 : yAxis.logBase;
      return;
    }
    if (xAxis.type != null) {
      xAxisType = xAxis.type!;
    } else {
      bool allNumeric = true;
      bool allDateTime = true;
      for (final VarietySeries item in series) {
        for (final VarietyChartData point in item.data) {
          if (point.x is! num) {
            allNumeric = false;
          }
          if (point.x is! DateTime) {
            allDateTime = false;
          }
        }
      }
      xAxisType = allDateTime && !allNumeric
          ? VarietyAxisType.dateTime
          : (allNumeric ? VarietyAxisType.numeric : VarietyAxisType.category);
    }
    yAxisType = yAxis.type ?? VarietyAxisType.numeric;
    logBase = yAxis.logBase <= 1 ? 10 : yAxis.logBase;
  }

  void _resolveData() {
    sourceData = series.map(_computeSeriesData).toList(growable: false);
    if (transposed) {
      // fall through to the transposition step below
    }
    if (!transposed) {
      resolvedData = sourceData;
      return;
    }
    final List<String> order = <String>[];
    final Set<String> seen = <String>{};
    for (final List<VarietyChartData> points in sourceData) {
      for (final VarietyChartData point in points) {
        final String key = point.label ?? _categoryKey(point.x);
        if (seen.add(key)) {
          order.add(key);
        }
      }
    }
    categories.addAll(order);
    for (int i = 0; i < sourceData.length; i++) {
      for (final VarietyChartData point in sourceData[i]) {
        final String key = point.label ?? _categoryKey(point.x);
        final int index = order.indexOf(key);
        if (!categoryValues.contains(point.x)) {
          categoryValues.add(point.x);
        }
        if (index < 0) {
          continue;
        }
      }
    }
    resolvedData = List<List<VarietyChartData>>.generate(
      sourceData.length,
      (int s) => List<VarietyChartData>.generate(
        sourceData[s].length,
        (int p) {
          final VarietyChartData point = sourceData[s][p];
          final String key = point.label ?? _categoryKey(point.x);
          final int index = order.indexOf(key);
          return VarietyChartData(
            point.y ?? 0,
            index < 0 ? p.toDouble() : index.toDouble(),
            label: point.label,
            color: point.color,
            isEmpty: point.isEmpty,
          );
        },
      ),
    );
  }

  /// The axis that carries the category captions.
  VarietyAxis get _categoryAxis => transposed ? yAxis : xAxis;

  static bool _shouldTranspose(List<VarietySeries> series) =>
      series.isNotEmpty &&
      series.every((VarietySeries item) => item is VarietyBarSeries);

  List<VarietyChartData> _computeSeriesData(VarietySeries item) {
    List<VarietyChartData> data = item.data;
    if (item is VarietyHistogramSeries) {
      data = _binHistogram(item);
    } else if (item is VarietyWaterfallSeries) {
      data = _accumulateWaterfall(item);
    }
    data = _sorted(data, item.sortingOrder, item.sortFieldValueMapper);
    return _resolveEmptyPoints(data, item.emptyPointSettings);
  }

  /// Sorts a point list according to the requested order.
  List<VarietyChartData> _sorted(
    List<VarietyChartData> data,
    VarietySortingOrder order,
    double Function(VarietyChartData point)? mapper,
  ) {
    if (order == VarietySortingOrder.none || data.length < 2) {
      return data;
    }
    final List<VarietyChartData> copy = List<VarietyChartData>.of(data);
    double keyOf(VarietyChartData point) {
      if (mapper != null) {
        return mapper(point);
      }
      if (point.x is num) {
        return (point.x as num).toDouble();
      }
      if (point.x is DateTime) {
        return (point.x as DateTime).millisecondsSinceEpoch.toDouble();
      }
      return 0;
    }

    copy.sort(
      (VarietyChartData a, VarietyChartData b) =>
          order == VarietySortingOrder.ascending
              ? keyOf(a).compareTo(keyOf(b))
              : keyOf(b).compareTo(keyOf(a)),
    );
    return copy;
  }

  /// Applies the empty point mode declared by a series.
  ///
  /// `gap` keeps the point flagged so the renderer breaks the line, `zero`
  /// substitutes `0`, `average` interpolates from the closest valid
  /// neighbours and `drop` removes the point together with its neighbours.
  List<VarietyChartData> _resolveEmptyPoints(
    List<VarietyChartData> data,
    VarietyEmptyPointSettings settings,
  ) {
    if (settings.mode == VarietyEmptyPointMode.gap) {
      return data;
    }
    bool isEmptyAt(VarietyChartData point) =>
        point.isEmpty ||
        (point.y == null && point.close == null && point.high == null);
    if (!data.any(isEmptyAt)) {
      return data;
    }
    final List<VarietyChartData> result = List<VarietyChartData>.of(data);
    for (int i = 0; i < result.length; i++) {
      if (!isEmptyAt(result[i])) {
        continue;
      }
      switch (settings.mode) {
        case VarietyEmptyPointMode.zero:
          result[i] = result[i].withValue(0).copyWith(isEmpty: false);
        case VarietyEmptyPointMode.average:
          double? before;
          double? after;
          for (int j = i - 1; j >= 0; j--) {
            if (!isEmptyAt(result[j]) && result[j].y != null) {
              before = result[j].y;
              break;
            }
          }
          for (int j = i + 1; j < result.length; j++) {
            if (!isEmptyAt(result[j]) && result[j].y != null) {
              after = result[j].y;
              break;
            }
          }
          final double? filled = switch ((before, after)) {
            (final double a, final double b) => (a + b) / 2,
            (final double a, null) => a,
            (null, final double b) => b,
            _ => null,
          };
          result[i] = filled == null
              ? result[i]
              : result[i].withValue(filled).copyWith(isEmpty: false);
        case VarietyEmptyPointMode.drop:
          if (i > 0) {
            result[i - 1] = result[i - 1].copyWith(isEmpty: true);
          }
          if (i + 1 < result.length) {
            result[i + 1] = result[i + 1].copyWith(isEmpty: true);
          }
          result[i] = result[i].copyWith(isEmpty: true);
        case VarietyEmptyPointMode.gap:
          break;
      }
    }
    return result;
  }

  List<VarietyChartData> _binHistogram(VarietyHistogramSeries item) {
    final List<double> samples = item.data
        .map((VarietyChartData point) => point.y ?? 0)
        .toList(growable: false);
    if (samples.isEmpty) {
      return const <VarietyChartData>[];
    }
    final int bins = math.max(item.binCount, 1);
    final double min = samples.reduce(math.min);
    final double max = samples.reduce(math.max);
    if (max - min < 1e-12) {
      return <VarietyChartData>[
        VarietyChartData(min, samples.length.toDouble())
      ];
    }
    final double width = (max - min) / bins;
    final List<int> counts = List<int>.filled(bins, 0);
    for (final double sample in samples) {
      int index = ((sample - min) / width).floor();
      if (index >= bins) {
        index = bins - 1;
      }
      if (index < 0) {
        index = 0;
      }
      counts[index]++;
    }
    return List<VarietyChartData>.generate(
      bins,
      (int i) => VarietyChartData(
        min + width * (i + 0.5),
        counts[i].toDouble(),
        label: '${varietyFormatNumber(min + width * i)} - '
            '${varietyFormatNumber(min + width * (i + 1))}',
      ),
    );
  }

  List<VarietyChartData> _accumulateWaterfall(VarietyWaterfallSeries item) {
    final List<VarietyChartData> result = <VarietyChartData>[];
    double running = 0;
    for (int i = 0; i < item.data.length; i++) {
      final VarietyChartData point = item.data[i];
      final double delta = point.y ?? 0;
      final bool isSummary = item.summaryIndexes.contains(i);
      if (isSummary) {
        result.add(point.copyWith(secondaryY: 0, close: running));
      } else {
        result.add(point.copyWith(secondaryY: running, close: running + delta));
        running += delta;
      }
    }
    if (item.showTotal && item.data.isNotEmpty) {
      result.add(
        VarietyChartData('Total', running,
            secondaryY: 0, close: running, label: 'Total'),
      );
    }
    return result;
  }

  void _collectCategories() {
    if (transposed) {
      return;
    }
    if (xAxisType != VarietyAxisType.category &&
        xAxisType != VarietyAxisType.dateTimeCategory) {
      return;
    }
    final Set<String> seen = <String>{};
    for (final List<VarietyChartData> points in resolvedData) {
      for (final VarietyChartData point in points) {
        final String key = point.label ?? _categoryKey(point.x);
        if (seen.add(key)) {
          categories.add(key);
          categoryValues.add(point.x);
        }
      }
    }
  }

  String _categoryKey(dynamic x) {
    if (x is DateTime) {
      return varietyFormatDateTime(x, _categoryAxis.dateFormat ?? 'dd MMM');
    }
    return x?.toString() ?? '';
  }

  void _resolveRanges() {
    _resolvePrimaryRange();
    _resolveSecondaryRange();
  }

  void _resolvePrimaryRange() {
    switch (xAxisType) {
      case VarietyAxisType.category:
      case VarietyAxisType.dateTimeCategory:
        final int count = math.max(categories.length, 1);
        xMinimum = 0;
        xMaximum = count.toDouble();
      case VarietyAxisType.dateTime:
        double? min;
        double? max;
        for (final List<VarietyChartData> points in resolvedData) {
          for (final VarietyChartData point in points) {
            if (point.x is! DateTime || point.isEmpty) {
              continue;
            }
            final double ms =
                (point.x as DateTime).millisecondsSinceEpoch.toDouble();
            min = min == null ? ms : math.min(min, ms);
            max = max == null ? ms : math.max(max, ms);
          }
        }
        xMinimum = xAxis.minimum ?? min ?? 0;
        xMaximum = xAxis.maximum ?? max ?? xMinimum + 86400000;
        if (xMaximum - xMinimum < 1) {
          xMaximum = xMinimum + 86400000;
        }
        _buildDateTimeTicks();
      case VarietyAxisType.numeric:
      case VarietyAxisType.logarithmic:
        double? min;
        double? max;
        for (final List<VarietyChartData> points in resolvedData) {
          for (final VarietyChartData point in points) {
            if (point.x is! num || point.isEmpty) {
              continue;
            }
            final double value = (point.x as num).toDouble();
            min = min == null ? value : math.min(min, value);
            max = max == null ? value : math.max(max, value);
          }
        }
        double lo = xAxis.minimum ?? min ?? 0;
        double hi = xAxis.maximum ?? max ?? 1;
        if (transposed) {
          // The primary axis carries the values in a transposed layout, so the
          // bars must start from a zero baseline.
          if (xAxis.minimum == null) {
            lo = math.min(lo, 0);
          }
          if (xAxis.maximum == null) {
            hi = math.max(hi, 0);
          }
        }
        if ((hi - lo).abs() < 1e-9) {
          hi = lo + 1;
        }
        final _NiceRange nice = _niceRange(lo, hi, xAxis.desiredIntervals);
        final (double, double, double) padded =
            _applyRangePadding(lo, hi, xAxis, nice);
        xMinimum = xAxis.minimum ?? padded.$1;
        xMaximum = xAxis.maximum ?? padded.$2;
        xInterval = xAxis.interval ?? padded.$3;
    }
    final (double, double)? zoom = visibleXRange;
    if (zoom != null && zoom.$2 > zoom.$1) {
      xMinimum = zoom.$1;
      xMaximum = zoom.$2;
    }
  }

  void _resolveSecondaryRange() {
    axisMinimums[0] = yMinimum;
    axisMaximums[0] = yMaximum;
    axisIntervals[0] = yInterval;
    if (yAxes.length > 1) {
      _resolvePrimaryRange_();
    }
    if (yAxisType == VarietyAxisType.category ||
        yAxisType == VarietyAxisType.dateTimeCategory) {
      final double count = math.max(categories.length, 1).toDouble();
      yMinimum = -0.5;
      yMaximum = count - 0.5;
      yInterval = 1;
      return;
    }
    final bool percent =
        series.any((VarietySeries item) => item.isPercentStacked);
    if (percent) {
      yMinimum = yAxis.minimum ?? 0;
      yMaximum = yAxis.maximum ?? 100;
      yInterval = yAxis.interval ?? 25;
      return;
    }
    bool includeZero = false;
    double? min;
    double? max;
    for (int s = 0; s < series.length; s++) {
      if (axisIndexOf(s) != 0) {
        continue;
      }
      final VarietySeries item = series[s];
      if (item is VarietyColumnSeries ||
          item is VarietyBarSeries ||
          item is VarietyAreaSeries ||
          item is VarietyWaterfallSeries ||
          item is VarietyHistogramSeries ||
          item is VarietyCandleSeries ||
          item is VarietyHiLoSeries ||
          item is VarietyHiLoOpenCloseSeries) {
        includeZero = true;
      }
      if (item.isStacked) {
        continue;
      }
      for (final VarietyChartData point in resolvedData[s]) {
        if (point.isEmpty) {
          continue;
        }
        final (double, double) bounds = _pointBounds(item, point);
        min = min == null ? bounds.$1 : math.min(min, bounds.$1);
        max = max == null ? bounds.$2 : math.max(max, bounds.$2);
      }
    }
    bool primaryStacked = false;
    for (int s = 0; s < series.length; s++) {
      if (axisIndexOf(s) == 0 && series[s].isStacked) {
        primaryStacked = true;
        break;
      }
    }
    if (primaryStacked) {
      final Map<int, (double, double)> totals = _stackTotals();
      for (final (double, double) bound in totals.values) {
        min = min == null ? bound.$1 : math.min(min, bound.$1);
        max = max == null ? bound.$2 : math.max(max, bound.$2);
      }
    }
    double lo = yAxis.minimum ?? min ?? 0;
    double hi = yAxis.maximum ?? max ?? 1;
    if (includeZero) {
      if (yAxis.minimum == null) {
        lo = math.min(lo, 0);
      }
      if (yAxis.maximum == null) {
        hi = math.max(hi, 0);
      }
    }
    if ((hi - lo).abs() < 1e-9) {
      hi = lo + 1;
    }
    if (_isLogarithmic) {
      final double safeLo = lo <= 0 ? 1 : lo;
      final _LogRange range =
          _logRange(safeLo, hi > safeLo ? hi : safeLo * 10, logBase);
      yMinimum = yAxis.minimum ?? range.minimum;
      yMaximum = yAxis.maximum ?? range.maximum;
      yInterval = range.interval;
      return;
    }
    final _NiceRange nice = _niceRange(lo, hi, yAxis.desiredIntervals);
    final (double, double, double) padded =
        _applyRangePadding(lo, hi, yAxis, nice);
    yMinimum = yAxis.minimum ?? padded.$1;
    yMaximum = yAxis.maximum ?? padded.$2;
    yInterval = yAxis.interval ?? padded.$3;
    if (yInterval <= 0) {
      yInterval = _ySpan / yAxis.desiredIntervals;
    }
    final (double, double)? zoom = visibleYRange;
    if (zoom != null && zoom.$2 > zoom.$1) {
      yMinimum = zoom.$1;
      yMaximum = zoom.$2;
      yInterval = _ySpan / yAxis.desiredIntervals;
    }
    axisMinimums[0] = yMinimum;
    axisMaximums[0] = yMaximum;
    axisIntervals[0] = yInterval;
  }

  /// Resolves the range of every secondary axis declared after the first.
  void _resolvePrimaryRange_() {
    for (int axisIndex = 1; axisIndex < yAxes.length; axisIndex++) {
      final VarietyAxis axis = yAxes[axisIndex];
      double? min;
      double? max;
      for (int s = 0; s < series.length; s++) {
        if (axisIndexOf(s) != axisIndex) {
          continue;
        }
        for (final VarietyChartData point in resolvedData[s]) {
          if (point.isEmpty) {
            continue;
          }
          final (double, double) bounds = _pointBounds(series[s], point);
          min = min == null ? bounds.$1 : math.min(min, bounds.$1);
          max = max == null ? bounds.$2 : math.max(max, bounds.$2);
        }
      }
      final double lo = axis.minimum ?? min ?? 0;
      double hi = axis.maximum ?? max ?? 1;
      if ((hi - lo).abs() < 1e-9) {
        hi = lo + 1;
      }
      final _NiceRange nice = _niceRange(lo, hi, axis.desiredIntervals);
      final (double, double, double) padded =
          _applyRangePadding(lo, hi, axis, nice);
      axisMinimums[axisIndex] = axis.minimum ?? padded.$1;
      axisMaximums[axisIndex] = axis.maximum ?? padded.$2;
      axisIntervals[axisIndex] = axis.interval ?? padded.$3;
    }
  }

  /// Resolves the visible range from the raw data range and the axis'
  /// [VarietyRangePadding] setting.
  (double, double, double) _applyRangePadding(
    double lo,
    double hi,
    VarietyAxis axis,
    _NiceRange nice,
  ) {
    final double span = hi - lo;
    final double fallbackInterval =
        span <= 0 ? 1 : span / math.max(axis.desiredIntervals, 1);
    switch (axis.rangePadding) {
      case VarietyRangePadding.none:
        return (lo, hi, fallbackInterval);
      case VarietyRangePadding.extra:
        final double pad = span <= 0 ? 1 : span * 0.05;
        return (lo - pad, hi + pad, fallbackInterval);
      case VarietyRangePadding.additional:
        final double pad = span <= 0 ? 1 : span * 0.02;
        return (
          math.min(lo - pad, nice.minimum),
          math.max(hi + pad, nice.maximum),
          nice.interval,
        );
      case VarietyRangePadding.round:
      case VarietyRangePadding.auto:
        return (nice.minimum, nice.maximum, nice.interval);
    }
  }

  /// The lowest and highest value a point contributes to the range.
  (double, double) _pointBounds(VarietySeries item, VarietyChartData point) {
    if (item.isRange || item is VarietyCandleSeries) {
      return (
        math.min(point.lowValue, point.highValue),
        math.max(point.lowValue, point.highValue)
      );
    }
    final double value = point.y ?? 0;
    return (value, value);
  }

  Map<int, (double, double)> _stackTotals() {
    final Map<int, (double, double)> totals = <int, (double, double)>{};
    for (int s = 0; s < series.length; s++) {
      final VarietySeries item = series[s];
      if (!item.isStacked || axisIndexOf(s) != 0) {
        continue;
      }
      for (int p = 0; p < resolvedData[s].length; p++) {
        final double value = valueAt(s, p);
        final (double, double) current = totals[p] ?? (0, 0);
        const double positive = 0;
        final double up = current.$1 + math.max(value, positive);
        final double down = current.$2 + math.min(value, positive);
        totals[p] = (up, down);
      }
    }
    return totals;
  }

  /// The value of a resolved point, regardless of the chart orientation.
  double valueAt(int seriesIndex, int pointIndex) {
    if (seriesIndex < 0 ||
        seriesIndex >= resolvedData.length ||
        pointIndex < 0 ||
        pointIndex >= resolvedData[seriesIndex].length) {
      return 0;
    }
    final VarietyChartData point = resolvedData[seriesIndex][pointIndex];
    if (transposed) {
      return (point.x as num?)?.toDouble() ?? 0;
    }
    return point.y ?? 0;
  }

  double _stackedValue(int seriesIndex, int pointIndex) {
    double total = 0;
    final int targetAxis = axisIndexOf(seriesIndex);
    for (int s = 0; s <= seriesIndex; s++) {
      final VarietySeries item = series[s];
      if (!item.isStacked || axisIndexOf(s) != targetAxis) {
        continue;
      }
      if (resolvedData[s].length <= pointIndex) {
        continue;
      }
      total += valueAt(s, pointIndex);
    }
    return total;
  }

  double _stackedBase(int seriesIndex, int pointIndex) {
    double total = 0;
    final int targetAxis = axisIndexOf(seriesIndex);
    for (int s = 0; s < seriesIndex; s++) {
      final VarietySeries item = series[s];
      if (!item.isStacked || axisIndexOf(s) != targetAxis) {
        continue;
      }
      if (resolvedData[s].length <= pointIndex) {
        continue;
      }
      total += valueAt(s, pointIndex);
    }
    return total;
  }

  double _percentTotal(int pointIndex, [int targetAxis = 0]) {
    double total = 0;
    for (int s = 0; s < series.length; s++) {
      final VarietySeries item = series[s];
      if (!item.isPercentStacked ||
          axisIndexOf(s) != targetAxis ||
          resolvedData[s].length <= pointIndex) {
        continue;
      }
      total += math.max(valueAt(s, pointIndex), 0);
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // Positions
  // ---------------------------------------------------------------------------

  void _buildPositions() {
    slotWidth = _slotWidth();
    if (!transposed &&
        (xAxisType == VarietyAxisType.category ||
            xAxisType == VarietyAxisType.dateTimeCategory)) {
      for (int i = 0; i < categories.length; i++) {
        slotCenters.add(
          _mirrorPrimary(plotRect.left + slotWidth * (i - xMinimum + 0.5)),
        );
      }
    }
    for (int s = 0; s < series.length; s++) {
      final VarietySeries item = series[s];
      final List<VarietyChartData> points = resolvedData[s];
      final List<Offset> positions = <Offset>[];
      final List<Rect?> rects = <Rect?>[];
      for (int p = 0; p < points.length; p++) {
        // The horizontal pixel always follows the primary axis. Vertically a
        // transposed layout follows the category index instead of the value.
        final double x = pixelXFor(item, p, points[p]);
        final int axisIndex = axisIndexOf(s);
        final double vertical = transposed
            ? pixelY(points[p].y ?? p.toDouble())
            : pixelYOn(axisIndex, topValue(s, p));
        positions.add(Offset(x, animateY(vertical)));
        rects.add(null);
      }
      pointPositions.add(positions);
      bandRects.add(rects);
    }
  }

  double _slotWidth() {
    final double extent = transposed ? plotRect.height : plotRect.width;
    if (!transposed &&
        (xAxisType == VarietyAxisType.category ||
            xAxisType == VarietyAxisType.dateTimeCategory)) {
      // A zoomed-in window shows fewer slots across the same extent, so the
      // divisor is the visible span rather than the full category count.
      return extent / math.max(xMaximum - xMinimum, 1);
    }
    final int count = _slotCount();
    return extent / math.max(count, 1);
  }

  int _slotCount() {
    if (transposed) {
      return math.max(categories.length, 1);
    }
    if (xAxisType == VarietyAxisType.category ||
        xAxisType == VarietyAxisType.dateTimeCategory) {
      return math.max(categories.length, 1);
    }
    int count = 0;
    for (final List<VarietyChartData> points in resolvedData) {
      count = math.max(count, points.length);
    }
    return math.max(count, 1);
  }

  /// The visual "top" value of a point, honouring stacking and percentages.
  double topValue(int seriesIndex, int pointIndex) {
    final VarietySeries item = series[seriesIndex];
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    if (pointIndex >= points.length) {
      return 0;
    }
    final double raw = valueAt(seriesIndex, pointIndex);
    if (item.isPercentStacked) {
      final double total = _percentTotal(pointIndex, axisIndexOf(seriesIndex));
      if (total <= 0) {
        return 0;
      }
      final double ratio = math.max(raw, 0) / total * 100;
      return _stackedPercentBase(seriesIndex, pointIndex) + ratio;
    }
    if (item.isStacked) {
      return _stackedValue(seriesIndex, pointIndex);
    }
    return raw;
  }

  double _stackedPercentBase(int seriesIndex, int pointIndex) {
    double total = 0;
    final int targetAxis = axisIndexOf(seriesIndex);
    for (int s = 0; s < seriesIndex; s++) {
      final VarietySeries item = series[s];
      if (!item.isPercentStacked || axisIndexOf(s) != targetAxis) {
        continue;
      }
      final double grand = _percentTotal(pointIndex, targetAxis);
      if (grand <= 0) {
        continue;
      }
      total += math.max(valueAt(s, pointIndex), 0) / grand * 100;
    }
    return total;
  }

  /// The visual "base" value of a point, honouring stacking and percentages.
  double baseValue(int seriesIndex, int pointIndex) {
    final VarietySeries item = series[seriesIndex];
    if (item.isPercentStacked) {
      return _stackedPercentBase(seriesIndex, pointIndex);
    }
    if (item.isStacked) {
      return _stackedBase(seriesIndex, pointIndex);
    }
    return 0;
  }

  /// The horizontal pixel of a point.
  double pixelXFor(VarietySeries item, int pointIndex, VarietyChartData point) {
    if (xAxisType == VarietyAxisType.category ||
        xAxisType == VarietyAxisType.dateTimeCategory) {
      final String key = point.label ?? _categoryKey(point.x);
      final int index = categories.indexOf(key);
      final int resolved = index < 0 ? pointIndex : index;
      return _mirrorPrimary(
        plotRect.left + slotWidth * (resolved - xMinimum + 0.5),
      );
    }
    return _mirrorPrimary(
      plotRect.left +
          (numericX(point.x, pointIndex) - xMinimum) / _xSpan * plotRect.width,
    );
  }

  /// The numeric position of a point along the primary axis.
  double numericX(dynamic x, int fallbackIndex) {
    if (x is DateTime) {
      return x.millisecondsSinceEpoch.toDouble();
    }
    if (x is num) {
      return x.toDouble();
    }
    return fallbackIndex.toDouble();
  }

  /// Mirrors a horizontal pixel when the primary axis is inverted.
  double _mirrorPrimary(double x) =>
      xAxis.isInversed ? plotRect.left + plotRect.right - x : x;

  /// Mirrors a vertical pixel when the secondary axis is inverted.
  double _mirrorSecondary(double y) =>
      yAxis.isInversed ? plotRect.top + plotRect.bottom - y : y;

  double _axisSpan(int axisIndex) => math.max(
        axisMaximums[axisIndex] - axisMinimums[axisIndex],
        1e-9,
      );

  /// Converts a value on the given secondary axis into a pixel.
  double pixelYOn(int axisIndex, double value) {
    if (axisIndex <= 0) {
      return pixelY(value);
    }
    final double lo = axisMinimums[axisIndex];
    final double hi = axisMaximums[axisIndex];
    final VarietyAxis axis = yAxes[axisIndex];
    if ((axis.type ?? yAxisType) == VarietyAxisType.logarithmic) {
      final double base = axis.logBase <= 1 ? 10 : axis.logBase;
      final double safe = value <= 0 ? lo : value;
      final double from = math.log(lo) / math.log(base);
      final double to = math.log(hi) / math.log(base);
      final double current = math.log(safe) / math.log(base);
      return _mirrorSecondary(
        plotRect.bottom -
            (current - from) / math.max(to - from, 1e-9) * plotRect.height,
      );
    }
    return _mirrorSecondary(
      plotRect.bottom - (value - lo) / _axisSpan(axisIndex) * plotRect.height,
    );
  }

  /// Converts a secondary-axis value into a pixel.
  double pixelY(double value) {
    if (_isLogarithmic) {
      final double safe = value <= 0 ? yMinimum : value;
      final double lo = math.log(yMinimum) / math.log(logBase);
      final double hi = math.log(yMaximum) / math.log(logBase);
      final double current = math.log(safe) / math.log(logBase);
      return _mirrorSecondary(
        plotRect.bottom -
            (current - lo) / math.max(hi - lo, 1e-9) * plotRect.height,
      );
    }
    return _mirrorSecondary(
      plotRect.bottom - (value - yMinimum) / _ySpan * plotRect.height,
    );
  }

  /// Maps a raw Y pixel into its animated position for the current progress.
  double animateY(double target, [int axisIndex = 0]) {
    if (progress >= 1) {
      return target;
    }
    final double base = baselineYOn(axisIndex);
    return base + (target - base) * progress.clamp(0.0, 1.0);
  }

  /// Converts a data-space pair into a pixel position inside the plot area.
  Offset toPixel(double xValue, double yValue) => Offset(
        _mirrorPrimary(
          plotRect.left + (xValue - xMinimum) / _xSpan * plotRect.width,
        ),
        pixelY(yValue),
      );

  // ---------------------------------------------------------------------------
  // Elements
  // ---------------------------------------------------------------------------

  void _buildElements() {
    for (int s = 0; s < series.length; s++) {
      _buildSeriesElements(s, series[s]);
      _buildTrendlines(s);
    }
  }

  void _buildSeriesElements(int s, VarietySeries item) {
    if (item is VarietyBoxAndWhiskerSeries) {
      _buildBoxPlot(s, item);
      _buildAttachedErrorBar(s, item);
      return;
    }
    if (item is VarietyErrorBarSeries) {
      _buildWhiskers(s, item, item);
      return;
    }
    if (item is VarietySplineAreaSeries) {
      _buildAreaLike(
        s,
        item,
        style: VarietyLineStyle.curved,
        strokeWidth: item.strokeWidth,
        fillOpacity: item.fillOpacity,
        showMarkers: item.showMarkers,
        markerSize: item.markerSize,
      );
      _buildAttachedErrorBar(s, item);
      return;
    }
    if (item is VarietyStepAreaSeries) {
      _buildStepArea(s, item);
      _buildAttachedErrorBar(s, item);
      return;
    }
    if (item is VarietySplineRangeAreaSeries) {
      _buildRangeAreaLike(
        s,
        item,
        style: VarietyLineStyle.curved,
        strokeWidth: item.strokeWidth,
        fillOpacity: item.fillOpacity,
        showMarkers: item.showMarkers,
        markerSize: item.markerSize,
      );
      _buildAttachedErrorBar(s, item);
      return;
    }
    if (item is VarietyFastLineSeries) {
      _buildFastLine(s, item);
      _buildAttachedErrorBar(s, item);
      return;
    }
    if (item is VarietyColumnSeries ||
        item is VarietyBarSeries ||
        item is VarietyRangeColumnSeries ||
        item is VarietyWaterfallSeries ||
        item is VarietyHistogramSeries ||
        item is VarietyCandleSeries) {
      _buildColumnLike(s, item);
      _buildAttachedErrorBar(s, item);
      return;
    }
    if (item is VarietyScatterSeries) {
      _buildMarkers(s, item);
      _buildAttachedErrorBar(s, item);
      return;
    }
    if (item is VarietyBubbleSeries) {
      _buildBubbles(s, item);
      _buildAttachedErrorBar(s, item);
      return;
    }
    if (item is VarietyHiLoSeries || item is VarietyHiLoOpenCloseSeries) {
      _buildHiLo(s, item);
      return;
    }
    if (item is VarietyRangeAreaSeries) {
      _buildRangeArea(s, item);
      _buildAttachedErrorBar(s, item);
      return;
    }
    if (item is VarietyAreaSeries) {
      _buildArea(s, item);
      _buildAttachedErrorBar(s, item);
      return;
    }
    if (item is VarietyLineSeries) {
      _buildLine(s, item);
      _buildAttachedErrorBar(s, item);
    }
  }

  void _buildAttachedErrorBar(int seriesIndex, VarietySeries item) {
    final VarietyErrorBarSeries? bar = item.errorBar;
    if (bar == null) {
      return;
    }
    _buildWhiskers(seriesIndex, item, bar);
  }

  void _buildStepArea(int seriesIndex, VarietyStepAreaSeries item) {
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    final Color color = colorFor(item, seriesIndex, 0);
    final List<Offset> top = <Offset>[];
    final List<Offset> base = <Offset>[];
    for (int p = 0; p < points.length; p++) {
      if (points[p].isEmpty) {
        continue;
      }
      final double x = pointPositions[seriesIndex][p].dx;
      if (item.verticalStep && top.isNotEmpty) {
        top.add(Offset(x, top.last.dy));
      }
      top.add(Offset(x, topPixel(seriesIndex, p)));
      final int stepAxis = axisIndexOf(seriesIndex);
      base.add(
        Offset(
          x,
          item.isStacked
              ? animateY(
                  pixelYOn(stepAxis, baseValue(seriesIndex, p)), stepAxis)
              : baselineYOn(stepAxis),
        ),
      );
      _addDataLabel(item, seriesIndex, p, top.last, null);
    }
    if (top.length >= 2) {
      final Path path = Path()..moveTo(top.first.dx, top.first.dy);
      for (int i = 1; i < top.length; i++) {
        if (item.verticalStep) {
          path.lineTo(top[i].dx, top[i].dy);
        } else {
          final double mid = (top[i - 1].dx + top[i].dx) / 2;
          path.lineTo(mid, top[i - 1].dy);
          path.lineTo(mid, top[i].dy);
          path.lineTo(top[i].dx, top[i].dy);
        }
      }
      for (int i = base.length - 1; i >= 0; i--) {
        path.lineTo(base[i].dx, base[i].dy);
      }
      path.close();
      elements.add(
        VarietyPathElement(
          seriesIndex: seriesIndex,
          path: path,
          fillColor: color,
          fillOpacity: item.fillOpacity,
          strokeColor: color,
          strokeWidth: item.strokeWidth,
        ),
      );
    }
    if (!item.showMarkers) {
      return;
    }
    final List<VarietyMarker> markers = <VarietyMarker>[];
    for (int p = 0; p < points.length; p++) {
      if (points[p].isEmpty || points[p].y == null) {
        continue;
      }
      markers.add(
        VarietyMarker(Offset(
            pointPositions[seriesIndex][p].dx, topPixel(seriesIndex, p))),
      );
    }
    if (markers.isEmpty) {
      return;
    }
    elements.add(
      VarietyMarkersElement(
        seriesIndex: seriesIndex,
        markers: markers,
        size: item.markerSize,
        shape: VarietyMarkerShape.circle,
        color: color,
      ),
    );
  }

  void _buildFastLine(int seriesIndex, VarietyFastLineSeries item) {
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    final int step = math.max(item.decimationFactor, 1);
    final List<Offset> run = <Offset>[];
    final Color color = colorFor(item, seriesIndex, 0);
    void flush() {
      if (run.length < 2) {
        run.clear();
        return;
      }
      elements.add(
        VarietyPathElement(
          seriesIndex: seriesIndex,
          path: _joinPath(run, VarietyLineStyle.straight),
          strokeColor: color,
          strokeWidth: item.strokeWidth,
          dashPattern: item.dashPattern,
          antiAlias: item.enableAntiAlias,
        ),
      );
      run.clear();
    }

    for (int p = 0; p < points.length; p++) {
      if (points[p].isEmpty) {
        flush();
        continue;
      }
      if (p % step != 0 && p != points.length - 1) {
        continue;
      }
      run.add(
        Offset(pointPositions[seriesIndex][p].dx, topPixel(seriesIndex, p)),
      );
    }
    flush();
  }

  void _buildWhiskers(
      int seriesIndex, VarietySeries owner, VarietyErrorBarSeries bar) {
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    if (points.isEmpty) {
      return;
    }
    final List<double> values = points
        .where((VarietyChartData point) => !point.isEmpty && point.y != null)
        .map((VarietyChartData point) => point.y!)
        .toList(growable: false);
    if (values.isEmpty) {
      return;
    }
    final double deviation = _standardDeviation(values);
    final double standardError =
        values.isEmpty ? 0 : deviation / math.sqrt(values.length.toDouble());

    double magnitudeOf(VarietyChartData point) {
      final double value = point.y ?? 0;
      switch (bar.type) {
        case VarietyErrorBarType.fixed:
          return bar.errorValue;
        case VarietyErrorBarType.percentage:
          return value.abs() * bar.errorValue / 100;
        case VarietyErrorBarType.standardDeviation:
          return deviation * bar.errorValue;
        case VarietyErrorBarType.standardError:
          return standardError * bar.errorValue;
        case VarietyErrorBarType.custom:
          return point.secondaryY ?? 0;
      }
    }

    final Color color = bar.color ?? colorFor(owner, seriesIndex, 0);
    final List<VarietySegment> stems = <VarietySegment>[];
    final List<VarietySegment> caps = <VarietySegment>[];
    for (int p = 0; p < points.length; p++) {
      if (points[p].isEmpty) {
        continue;
      }
      final Offset position = pointPositions[seriesIndex][p];
      final double value = points[p].y ?? 0;
      final double magnitude = magnitudeOf(points[p]);
      if (magnitude <= 0) {
        continue;
      }
      final int axisIndex = axisIndexOf(seriesIndex);
      if (bar.mode == VarietyErrorBarMode.vertical ||
          bar.mode == VarietyErrorBarMode.both) {
        final double top =
            animateY(pixelYOn(axisIndex, value + magnitude), axisIndex);
        final double bottom =
            animateY(pixelYOn(axisIndex, value - magnitude), axisIndex);
        stems.add(VarietySegment(
            Offset(position.dx, top), Offset(position.dx, bottom)));
        if (bar.showCap) {
          caps.add(
            VarietySegment(
              Offset(position.dx - bar.capLength / 2, top),
              Offset(position.dx + bar.capLength / 2, top),
            ),
          );
          caps.add(
            VarietySegment(
              Offset(position.dx - bar.capLength / 2, bottom),
              Offset(position.dx + bar.capLength / 2, bottom),
            ),
          );
        }
      }
      if (bar.mode == VarietyErrorBarMode.horizontal ||
          bar.mode == VarietyErrorBarMode.both) {
        final double dx = _horizontalOffset(value, magnitude);
        stems.add(
          VarietySegment(
            Offset(position.dx - dx, position.dy),
            Offset(position.dx + dx, position.dy),
          ),
        );
        if (bar.showCap) {
          caps.add(
            VarietySegment(
              Offset(position.dx - dx, position.dy - bar.capLength / 2),
              Offset(position.dx - dx, position.dy + bar.capLength / 2),
            ),
          );
          caps.add(
            VarietySegment(
              Offset(position.dx + dx, position.dy - bar.capLength / 2),
              Offset(position.dx + dx, position.dy + bar.capLength / 2),
            ),
          );
        }
      }
    }
    if (stems.isEmpty) {
      return;
    }
    elements.add(
      VarietySegmentsElement(
          segments: stems, color: color, width: bar.strokeWidth),
    );
    if (caps.isNotEmpty) {
      elements.add(
        VarietySegmentsElement(
            segments: caps, color: color, width: bar.strokeWidth),
      );
    }
  }

  /// Converts a magnitude into a horizontal pixel offset.
  ///
  /// On a numeric primary axis the offset is measured on that axis; otherwise
  /// the vertical scale is reused so the whisker keeps a sensible size.
  double _horizontalOffset(double value, double magnitude) {
    if (xAxisType == VarietyAxisType.numeric ||
        xAxisType == VarietyAxisType.logarithmic) {
      return (toPixel(value + magnitude, 0).dx - toPixel(value, 0).dx).abs();
    }
    return (pixelY(value + magnitude) - pixelY(value)).abs();
  }

  double _standardDeviation(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }
    final double mean =
        values.reduce((double a, double b) => a + b) / values.length;
    double sum = 0;
    for (final double value in values) {
      sum += math.pow(value - mean, 2).toDouble();
    }
    return math.sqrt(sum / values.length);
  }

  void _buildBoxPlot(int seriesIndex, VarietyBoxAndWhiskerSeries item) {
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    if (points.isEmpty) {
      return;
    }
    final Map<String, List<double>> groups = <String, List<double>>{};
    final Map<String, List<int>> members = <String, List<int>>{};
    for (int p = 0; p < points.length; p++) {
      if (points[p].isEmpty) {
        continue;
      }
      final String key = points[p].label ?? _categoryKey(points[p].x);
      groups.putIfAbsent(key, () => <double>[]).add(points[p].y ?? 0);
      members.putIfAbsent(key, () => <int>[]).add(p);
    }
    final Color color = colorFor(item, seriesIndex, 0);
    final double band =
        (slotWidth > 0 ? slotWidth : plotRect.width) * item.widthFactor;
    groups.forEach((String key, List<double> raw) {
      final List<int> indexes = members[key] ?? const <int>[];
      if (indexes.isEmpty) {
        return;
      }
      double center = 0;
      for (final int index in indexes) {
        center += pointPositions[seriesIndex][index].dx;
      }
      center /= indexes.length;
      final _BoxStats stats = _boxStats(raw, item.boxPlotMode);
      final int axisIndex = axisIndexOf(seriesIndex);
      final double q1 = pixelYOn(axisIndex, stats.q1);
      final double q3 = pixelYOn(axisIndex, stats.q3);
      final double median = pixelYOn(axisIndex, stats.median);
      final double lowFence = pixelYOn(axisIndex, stats.lowerFence);
      final double highFence = pixelYOn(axisIndex, stats.upperFence);
      final Rect box = Rect.fromLTRB(
        center - band / 2,
        math.min(q1, q3),
        center + band / 2,
        math.max(q1, q3),
      );
      for (final int index in indexes) {
        bandRects[seriesIndex][index] = box;
      }
      elements.add(
        VarietyRectsElement(
          seriesIndex: seriesIndex,
          rects: <Rect>[box],
          color: item.color?.withValues(alpha: 0.25) ??
              color.withValues(alpha: 0.25),
          radius: item.cornerRadius,
          border: item.whiskerColor ?? color,
          borderWidth: item.strokeWidth,
        ),
      );
      elements.add(
        VarietySegmentsElement(
          seriesIndex: seriesIndex,
          segments: <VarietySegment>[
            VarietySegment(
                Offset(center, math.min(q1, q3)), Offset(center, highFence)),
            VarietySegment(
                Offset(center, math.max(q1, q3)), Offset(center, lowFence)),
            VarietySegment(
              Offset(center - band / 4, lowFence),
              Offset(center + band / 4, lowFence),
            ),
            VarietySegment(
              Offset(center - band / 4, highFence),
              Offset(center + band / 4, highFence),
            ),
          ],
          color: item.whiskerColor ?? color,
          width: item.strokeWidth,
        ),
      );
      elements.add(
        VarietySegmentsElement(
          seriesIndex: seriesIndex,
          segments: <VarietySegment>[
            VarietySegment(
              Offset(box.left, median),
              Offset(box.right, median),
            ),
          ],
          color: item.medianColor ?? color,
          width: item.strokeWidth + 0.6,
        ),
      );
      if (item.showMean) {
        elements.add(
          VarietyMarkersElement(
            seriesIndex: seriesIndex,
            markers: <VarietyMarker>[
              VarietyMarker(Offset(
                  center, pixelYOn(axisIndexOf(seriesIndex), stats.mean))),
            ],
            size: 8,
            shape: VarietyMarkerShape.diamond,
            color: item.meanColor ?? color,
          ),
        );
      }
      if (item.showInnerPoints) {
        final List<VarietyMarker> inner = <VarietyMarker>[];
        for (final int index in indexes) {
          inner.add(
            VarietyMarker(
              Offset(center,
                  pixelYOn(axisIndexOf(seriesIndex), points[index].y ?? 0)),
            ),
          );
        }
        elements.add(
          VarietyMarkersElement(
            seriesIndex: seriesIndex,
            markers: inner,
            size: 5,
            shape: VarietyMarkerShape.circle,
            color: color,
          ),
        );
      }
      if (item.showOutliers && stats.outliers.isNotEmpty) {
        elements.add(
          VarietyMarkersElement(
            seriesIndex: seriesIndex,
            markers: stats.outliers
                .map(
                  (double value) => VarietyMarker(
                    Offset(center, pixelYOn(axisIndexOf(seriesIndex), value)),
                  ),
                )
                .toList(growable: false),
            size: item.outlierSize,
            shape: item.outlierShape,
            color: item.whiskerColor ?? color,
          ),
        );
      }
      _addDataLabel(item, seriesIndex, indexes.first,
          Offset(center, math.min(q1, q3)), null);
    });
  }

  _BoxStats _boxStats(List<double> raw, VarietyBoxPlotMode mode) {
    final List<double> values = List<double>.of(raw)..sort();
    final int n = values.length;
    if (n == 0) {
      return const _BoxStats(0, 0, 0, 0, 0, 0, 0, <double>[]);
    }
    double medianOf(List<double> slice) {
      if (slice.isEmpty) {
        return values.first;
      }
      final int mid = slice.length ~/ 2;
      return slice.length.isOdd
          ? slice[mid]
          : (slice[mid - 1] + slice[mid]) / 2;
    }

    final double median = medianOf(values);
    double q1;
    double q3;
    if (mode == VarietyBoxPlotMode.normal) {
      q1 = values[(n * 0.25).floor().clamp(0, n - 1)];
      q3 = values[(n * 0.75).floor().clamp(0, n - 1)];
    } else {
      final bool excludeMedian =
          mode == VarietyBoxPlotMode.exclusive && n.isOdd;
      final int lowerEnd = excludeMedian ? n ~/ 2 : (n + 1) ~/ 2;
      final int upperStart = excludeMedian ? n ~/ 2 + 1 : n ~/ 2;
      q1 = medianOf(values.sublist(0, lowerEnd));
      q3 = medianOf(values.sublist(upperStart.clamp(0, n)));
    }
    final double iqr = q3 - q1;
    final double lowFence = q1 - 1.5 * iqr;
    final double highFence = q3 + 1.5 * iqr;
    final List<double> outliers = values
        .where((double value) => value < lowFence || value > highFence)
        .toList(growable: false);
    final List<double> inside = values
        .where((double value) => value >= lowFence && value <= highFence)
        .toList(growable: false);
    final double min = inside.isEmpty ? values.first : inside.first;
    final double max = inside.isEmpty ? values.last : inside.last;
    final double mean = values.reduce((double a, double b) => a + b) / n;
    return _BoxStats(
        min, q1, median, q3, max, lowFence, highFence, outliers, mean);
  }

  /// Fits and draws every trendline declared by a series.
  ///
  /// Trendlines are fitted in pixel space, which keeps the maths identical for
  /// numeric, category and date time primary axes.
  void _buildTrendlines(int seriesIndex) {
    final VarietySeries item = series[seriesIndex];
    if (item.trendlines.isEmpty) {
      return;
    }
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    final List<(double, double)> samples = <(double, double)>[];
    for (int p = 0; p < points.length; p++) {
      if (points[p].isEmpty || points[p].y == null) {
        continue;
      }
      samples.add((
        pointPositions[seriesIndex][p].dx,
        item.isStacked ? topValue(seriesIndex, p) : (points[p].y ?? 0),
      ));
    }
    if (samples.length < 2) {
      return;
    }
    final double step = samples.length < 2
        ? 1
        : (samples.last.$1 - samples.first.$1) / (samples.length - 1);
    for (final VarietyTrendline trendline in item.trendlines) {
      if (!trendline.isVisible) {
        continue;
      }
      final double Function(double x)? fit =
          trendline.type == VarietyTrendlineType.movingAverage
              ? varietyMovingAverageTrendline(samples, trendline.period)
              : varietyFitTrendline(samples, trendline);
      if (fit == null) {
        continue;
      }
      final double startX =
          samples.first.$1 - trendline.backwardForecast * step;
      final double endX = samples.last.$1 + trendline.forwardForecast * step;
      final List<Offset> fitted = <Offset>[];
      const int steps = 64;
      for (int i = 0; i <= steps; i++) {
        final double x = startX + (endX - startX) * i / steps;
        final double y = fit(x);
        if (!y.isFinite) {
          continue;
        }
        fitted.add(Offset(
            x,
            animateY(pixelYOn(axisIndexOf(seriesIndex), y),
                axisIndexOf(seriesIndex))));
      }
      if (fitted.length < 2) {
        continue;
      }
      elements.add(
        VarietyPathElement(
          seriesIndex: seriesIndex,
          path: _joinPath(fitted, VarietyLineStyle.straight),
          strokeColor: trendline.color ?? colorFor(item, seriesIndex, 0),
          strokeWidth: trendline.width,
          dashPattern: trendline.dashArray,
        ),
      );
    }
  }

  /// Whether a series draws markers, honouring a marker settings override.
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

  /// Resolves the effective colour of a point, honouring overrides and opacity.
  Color colorFor(VarietySeries item, int seriesIndex, int pointIndex) {
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    final Color base =
        (pointIndex < points.length ? points[pointIndex].color : null) ??
            item.color ??
            varietyDefaultPalette[seriesIndex % varietyDefaultPalette.length];
    return item.opacity >= 1
        ? base
        : base.withValues(alpha: base.a * item.opacity);
  }

  double _cornerRadiusOf(VarietySeries item) {
    if (item is VarietyColumnSeries) {
      return item.cornerRadius;
    }
    if (item is VarietyRangeColumnSeries) {
      return item.cornerRadius;
    }
    if (item is VarietyWaterfallSeries) {
      return item.cornerRadius;
    }
    if (item is VarietyHistogramSeries) {
      return item.cornerRadius;
    }
    return 0;
  }

  double _bandFactor(VarietySeries item) {
    if (item is VarietyColumnSeries) {
      return item.widthFactor;
    }
    if (item is VarietyBarSeries) {
      return item.widthFactor;
    }
    if (item is VarietyRangeColumnSeries) {
      return item.widthFactor;
    }
    if (item is VarietyWaterfallSeries) {
      return item.widthFactor;
    }
    if (item is VarietyHistogramSeries) {
      return item.widthFactor;
    }
    if (item is VarietyCandleSeries) {
      return item.widthFactor;
    }
    return 0.7;
  }

  void _buildColumnLike(int seriesIndex, VarietySeries item) {
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    final List<Rect?> rects = bandRects[seriesIndex];
    final int bandCount = series
        .where((VarietySeries s) =>
            s is VarietyColumnSeries ||
            s is VarietyBarSeries ||
            s is VarietyRangeColumnSeries)
        .length;
    final double band = slotWidth;
    final double width = band * _bandFactor(item) / math.max(bandCount, 1);
    final double shift =
        bandCount > 1 ? (seriesIndex - (bandCount - 1) / 2) * width : 0;
    for (int p = 0; p < points.length; p++) {
      final VarietyChartData point = points[p];
      if (point.isEmpty) {
        continue;
      }
      // In a transposed layout the value runs horizontally and the category
      // index runs vertically, so the two axes swap roles here.
      final Offset position = pointPositions[seriesIndex][p];
      final double center = (transposed ? position.dy : position.dx) + shift;
      final Color color = colorFor(item, seriesIndex, p);
      final double radius = _cornerRadiusOf(item);
      if (item is VarietyCandleSeries) {
        _buildCandle(seriesIndex, item, p, center, width);
        continue;
      }
      double top;
      double bottom;
      if (item is VarietyRangeColumnSeries) {
        top = point.highValue;
        bottom = point.lowValue;
      } else if (item is VarietyWaterfallSeries) {
        top = point.closeValue;
        bottom = point.secondaryY ?? 0;
      } else {
        top = topValue(seriesIndex, p);
        bottom = baseValue(seriesIndex, p);
      }
      final int axisIndex = axisIndexOf(seriesIndex);
      if (transposed) {
        final double v0 = toPixel(bottom, 0).dx;
        final double v1 = toPixel(top, 0).dx;
        final double animated0 = math.min(v0, v1) +
            (math.max(v0, v1) - math.min(v0, v1)) * progress.clamp(0.0, 1.0);
        top = math.min(v0, v1);
        bottom = math.max(animated0, math.min(v0, v1));
      } else {
        top = animateY(pixelYOn(axisIndex, top), axisIndex);
        bottom = animateY(pixelYOn(axisIndex, bottom), axisIndex);
      }
      final Rect rect = transposed
          ? Rect.fromLTRB(
              math.min(top, bottom),
              center - width / 2,
              math.max(top, bottom),
              center + width / 2,
            )
          : Rect.fromLTRB(
              center - width / 2,
              math.min(top, bottom),
              center + width / 2,
              math.max(top, bottom),
            );
      final Rect normalized = Rect.fromLTRB(
        rect.left,
        math.min(rect.top, rect.bottom),
        rect.right,
        math.max(rect.top, rect.bottom),
      );
      rects[p] = normalized;
      Color fill = color;
      if (item is VarietyWaterfallSeries) {
        final double delta = point.closeValue - (point.secondaryY ?? 0);
        if (point.label == 'Total') {
          fill = item.totalColor ?? item.color ?? color;
        } else if (delta >= 0) {
          fill = point.color ??
              item.positiveColor ??
              item.color ??
              const Color(0xFF2FA37A);
        } else {
          fill = point.color ?? item.negativeColor ?? const Color(0xFFE0603F);
        }
      }
      elements.add(
        VarietyRectsElement(
          seriesIndex: seriesIndex,
          rects: <Rect>[normalized],
          color: fill,
          radius: radius,
          border: item is VarietyColumnSeries ? item.borderColor : null,
          borderWidth: item is VarietyColumnSeries ? item.borderWidth : 0,
        ),
      );
      _addDataLabel(item, seriesIndex, p, normalized.center, normalized.top);
    }
    if (item is VarietyWaterfallSeries && item.showConnectorLines) {
      _buildWaterfallConnectors(seriesIndex, item, width);
    }
    if (item is VarietyHistogramSeries && item.showNormalDistribution) {
      _buildNormalCurve(seriesIndex, item);
    }
    if (item is VarietyColumnSeries && item.showTrack) {
      final Color track = item.trackColor ??
          colorFor(item, seriesIndex, 0).withValues(alpha: 0.15);
      for (final Rect? rect in rects) {
        if (rect == null) {
          continue;
        }
        elements.add(
          VarietyRectsElement(
            seriesIndex: seriesIndex,
            rects: <Rect>[
              Rect.fromLTRB(
                  rect.left, plotRect.top, rect.right, plotRect.bottom),
            ],
            color: track,
          ),
        );
      }
    }
  }

  void _buildWaterfallConnectors(
      int seriesIndex, VarietyWaterfallSeries item, double width) {
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    final List<VarietySegment> segments = <VarietySegment>[];
    for (int p = 0; p < points.length - 1; p++) {
      final double x1 = pointPositions[seriesIndex][p].dx + width / 2;
      final double x2 = pointPositions[seriesIndex][p + 1].dx - width / 2;
      final double y = animateY(pixelY(points[p].closeValue));
      segments.add(VarietySegment(Offset(x1, y), Offset(x2, y)));
    }
    if (segments.isEmpty) {
      return;
    }
    elements.add(
      VarietySegmentsElement(
        seriesIndex: seriesIndex,
        segments: segments,
        color: item.connectorLineColor ?? const Color(0xFF9AA0A6),
        width: item.connectorLineWidth,
        dashPattern: const <double>[4, 4],
      ),
    );
  }

  void _buildNormalCurve(int seriesIndex, VarietyHistogramSeries item) {
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    if (points.length < 3) {
      return;
    }
    double mean = 0;
    double count = 0;
    double sumSquares = 0;
    for (final VarietyChartData point in points) {
      final double value = point.y ?? 0;
      mean += value;
      count += 1;
    }
    if (count == 0) {
      return;
    }
    mean /= count;
    for (final VarietyChartData point in points) {
      sumSquares += math.pow((point.y ?? 0) - mean, 2).toDouble();
    }
    final double sd = math.sqrt(sumSquares / count);
    if (sd <= 0) {
      return;
    }
    final Path path = Path();
    const int steps = 96;
    for (int i = 0; i <= steps; i++) {
      final double t = i / steps;
      final double value = mean - 3 * sd + 6 * sd * t;
      final double density =
          math.exp(-0.5 * math.pow((value - mean) / sd, 2).toDouble()) /
              (sd * math.sqrt(2 * math.pi));
      final double x = pointPositions[seriesIndex].first.dx +
          (pointPositions[seriesIndex].last.dx -
                  pointPositions[seriesIndex].first.dx) *
              t;
      final double y =
          animateY(pixelY(density * count * _binWidth(seriesIndex)));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    elements.add(
      VarietyPathElement(
        seriesIndex: seriesIndex,
        path: path,
        strokeColor:
            item.normalDistributionColor ?? colorFor(item, seriesIndex, 0),
        strokeWidth: item.normalDistributionWidth,
      ),
    );
  }

  double _binWidth(int seriesIndex) {
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    if (points.length < 2) {
      return 1;
    }
    return (points[1].x as num).toDouble() - (points[0].x as num).toDouble();
  }

  void _buildCandle(int seriesIndex, VarietyCandleSeries item, int p,
      double center, double width) {
    final VarietyChartData point = resolvedData[seriesIndex][p];
    final bool rising = point.closeValue >= point.openValue;
    final Color color = point.color ??
        (rising
            ? (item.bullFillColor ?? const Color(0xFF2FA37A))
            : (item.bearFillColor ?? const Color(0xFFE0603F)));
    final int axisIndex = axisIndexOf(seriesIndex);
    final double high =
        animateY(pixelYOn(axisIndex, point.highValue), axisIndex);
    final double low = animateY(pixelYOn(axisIndex, point.lowValue), axisIndex);
    final double open =
        animateY(pixelYOn(axisIndex, point.openValue), axisIndex);
    final double close =
        animateY(pixelYOn(axisIndex, point.closeValue), axisIndex);
    if (item.showWicks) {
      elements.add(
        VarietySegmentsElement(
          seriesIndex: seriesIndex,
          segments: <VarietySegment>[
            VarietySegment(Offset(center, high), Offset(center, low)),
          ],
          color: item.borderColor ?? color,
          width: 1.4,
        ),
      );
    }
    final Rect body = Rect.fromLTRB(
      center - width / 2,
      math.min(open, close),
      center + width / 2,
      math.max(open, close),
    );
    bandRects[seriesIndex][p] = body;
    elements.add(
      VarietyRectsElement(
        seriesIndex: seriesIndex,
        rects: <Rect>[body],
        color: color,
        border: item.borderColor ?? color,
        borderWidth: 1,
      ),
    );
  }

  void _buildMarkers(int seriesIndex, VarietyScatterSeries item) {
    final List<VarietyMarker> markers = <VarietyMarker>[];
    for (int p = 0; p < resolvedData[seriesIndex].length; p++) {
      final VarietyChartData point = resolvedData[seriesIndex][p];
      if (point.isEmpty || point.y == null) {
        continue;
      }
      markers.add(
        VarietyMarker(pointPositions[seriesIndex][p],
            color: colorFor(item, seriesIndex, p)),
      );
      _addDataLabel(item, seriesIndex, p, pointPositions[seriesIndex][p], null);
    }
    if (markers.isEmpty) {
      return;
    }
    elements.add(
      VarietyMarkersElement(
        seriesIndex: seriesIndex,
        markers: markers,
        size: _markerSizeOf(item),
        shape: _markerShapeOf(item),
        color: colorFor(item, seriesIndex, 0),
        border: _markerBorderOf(item),
        borderWidth: item.markerSettings?.borderWidth ?? 1.4,
      ),
    );
  }

  void _buildBubbles(int seriesIndex, VarietyBubbleSeries item) {
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    double minSize = double.infinity;
    double maxSize = double.negativeInfinity;
    for (final VarietyChartData point in points) {
      if (point.isEmpty) {
        continue;
      }
      minSize = math.min(minSize, point.magnitude);
      maxSize = math.max(maxSize, point.magnitude);
    }
    if (minSize.isInfinite) {
      return;
    }
    final double span = math.max(maxSize - minSize, 1e-9);
    final List<VarietyBubble> bubbles = <VarietyBubble>[];
    for (int p = 0; p < points.length; p++) {
      final VarietyChartData point = points[p];
      if (point.isEmpty) {
        continue;
      }
      final double ratio =
          maxSize == minSize ? 1 : (point.magnitude - minSize) / span;
      final double radius = item.minimumRadius +
          (item.maximumRadius - item.minimumRadius) * ratio;
      bubbles.add(
        VarietyBubble(
          pointPositions[seriesIndex][p],
          radius * progress.clamp(0.0, 1.0),
          color: colorFor(item, seriesIndex, p),
        ),
      );
      _addDataLabel(item, seriesIndex, p, pointPositions[seriesIndex][p], null);
    }
    if (bubbles.isEmpty) {
      return;
    }
    elements.add(
      VarietyBubblesElement(
        seriesIndex: seriesIndex,
        bubbles: bubbles,
        color: colorFor(item, seriesIndex, 0),
        border: item.borderColor,
        borderWidth: item.borderWidth,
        fillOpacity: item.fillOpacity,
      ),
    );
  }

  void _buildHiLo(int seriesIndex, VarietySeries item) {
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    final List<VarietySegment> stems = <VarietySegment>[];
    final List<VarietySegment> ticks = <VarietySegment>[];
    final List<VarietyMarker> markers = <VarietyMarker>[];
    final Color color = colorFor(item, seriesIndex, 0);
    for (int p = 0; p < points.length; p++) {
      final VarietyChartData point = points[p];
      if (point.isEmpty) {
        continue;
      }
      final int axisIndex = axisIndexOf(seriesIndex);
      final double x = pointPositions[seriesIndex][p].dx;
      final double high =
          animateY(pixelYOn(axisIndex, point.highValue), axisIndex);
      final double low =
          animateY(pixelYOn(axisIndex, point.lowValue), axisIndex);
      stems.add(VarietySegment(Offset(x, high), Offset(x, low)));
      if (item is VarietyHiLoOpenCloseSeries) {
        final double open =
            animateY(pixelYOn(axisIndex, point.openValue), axisIndex);
        final double close =
            animateY(pixelYOn(axisIndex, point.closeValue), axisIndex);
        ticks.add(VarietySegment(
          Offset(x - item.tickWidth / 2, open),
          Offset(x + item.tickWidth / 2, open),
        ));
        ticks.add(VarietySegment(
          Offset(x - item.tickWidth / 2, close),
          Offset(x + item.tickWidth / 2, close),
        ));
      } else if (item is VarietyHiLoSeries && item.showMarkers) {
        markers.add(VarietyMarker(Offset(x, high)));
        markers.add(VarietyMarker(Offset(x, low)));
      }
      _addDataLabel(item, seriesIndex, p, Offset(x, high), null);
    }
    elements.add(
      VarietySegmentsElement(
        seriesIndex: seriesIndex,
        segments: stems,
        color: color,
        width: item is VarietyHiLoOpenCloseSeries
            ? item.strokeWidth
            : (item as VarietyHiLoSeries).strokeWidth,
      ),
    );
    if (ticks.isNotEmpty) {
      elements.add(
          VarietySegmentsElement(segments: ticks, color: color, width: 1.6));
    }
    if (markers.isNotEmpty) {
      elements.add(
        VarietyMarkersElement(
          seriesIndex: seriesIndex,
          markers: markers,
          size: (item as VarietyHiLoSeries).markerSize,
          shape: VarietyMarkerShape.circle,
          color: color,
        ),
      );
    }
  }

  void _buildRangeArea(int seriesIndex, VarietyRangeAreaSeries item) {
    _buildRangeAreaLike(
      seriesIndex,
      item,
      style: item.lineStyle,
      strokeWidth: item.strokeWidth,
      fillOpacity: item.fillOpacity,
      showMarkers: item.showMarkers,
      markerSize: item.markerSize,
    );
  }

  /// Fills the band between a high and a low bound.
  void _buildRangeAreaLike(
    int seriesIndex,
    VarietySeries item, {
    required VarietyLineStyle style,
    required double strokeWidth,
    required double fillOpacity,
    required bool showMarkers,
    required double markerSize,
  }) {
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    final int axisIndex = axisIndexOf(seriesIndex);
    final List<Offset> upper = <Offset>[];
    final List<Offset> lower = <Offset>[];
    for (int p = 0; p < points.length; p++) {
      if (points[p].isEmpty) {
        continue;
      }
      final double x = pointPositions[seriesIndex][p].dx;
      final double high =
          animateY(pixelYOn(axisIndex, points[p].highValue), axisIndex);
      final double low =
          animateY(pixelYOn(axisIndex, points[p].lowValue), axisIndex);
      upper.add(Offset(x, high));
      lower.add(Offset(x, low));
      _addDataLabel(item, seriesIndex, p, Offset(x, high), null);
    }
    if (upper.length < 2) {
      return;
    }
    final Color color = colorFor(item, seriesIndex, 0);
    final Path path = _joinPath(upper, style);
    for (int i = lower.length - 1; i >= 0; i--) {
      path.lineTo(lower[i].dx, lower[i].dy);
    }
    path.close();
    elements.add(
      VarietyPathElement(
        seriesIndex: seriesIndex,
        path: path,
        fillColor: color,
        fillOpacity: fillOpacity,
        strokeColor: color,
        strokeWidth: strokeWidth,
      ),
    );
    if (!showMarkers && !_showsMarkers(item)) {
      return;
    }
    final List<VarietyMarker> markers = <VarietyMarker>[];
    for (final Offset point in <Offset>[...upper, ...lower]) {
      markers.add(VarietyMarker(point));
    }
    elements.add(
      VarietyMarkersElement(
        seriesIndex: seriesIndex,
        markers: markers,
        size: _markerSizeOf(item),
        shape: _markerShapeOf(item),
        color: color,
        border: _markerBorderOf(item),
        borderWidth: item.markerSettings?.borderWidth ?? 1.4,
      ),
    );
  }

  void _buildArea(int seriesIndex, VarietyAreaSeries item) {
    _buildAreaLike(
      seriesIndex,
      item,
      style: item.lineStyle,
      strokeWidth: item.strokeWidth,
      fillOpacity: item.fillOpacity,
      showMarkers: item.showMarkers,
      markerSize: item.markerSize,
    );
  }

  /// Fills the region under a line, shared by the area, spline area and step
  /// area series.
  void _buildAreaLike(
    int seriesIndex,
    VarietySeries item, {
    required VarietyLineStyle style,
    required double strokeWidth,
    required double fillOpacity,
    required bool showMarkers,
    required double markerSize,
  }) {
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    final Color color = colorFor(item, seriesIndex, 0);
    final List<Offset> topRun = <Offset>[];
    final List<Offset> baseRun = <Offset>[];
    void flush() {
      if (topRun.length < 2) {
        topRun.clear();
        baseRun.clear();
        return;
      }
      final Path path = _joinPath(topRun, style);
      for (int i = baseRun.length - 1; i >= 0; i--) {
        path.lineTo(baseRun[i].dx, baseRun[i].dy);
      }
      path.close();
      elements.add(
        VarietyPathElement(
          seriesIndex: seriesIndex,
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
    }

    for (int p = 0; p < points.length; p++) {
      if (points[p].isEmpty) {
        flush();
        continue;
      }
      final double x = pointPositions[seriesIndex][p].dx;
      final Offset top = Offset(x, topPixel(seriesIndex, p));
      topRun.add(top);
      final int areaAxis = axisIndexOf(seriesIndex);
      baseRun.add(
        Offset(
          x,
          item.isStacked
              ? animateY(
                  pixelYOn(areaAxis, baseValue(seriesIndex, p)), areaAxis)
              : baselineYOn(areaAxis),
        ),
      );
      _addDataLabel(item, seriesIndex, p, top, null);
    }
    flush();
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
        seriesIndex: seriesIndex,
        markers: markers,
        size: _markerSizeOf(item),
        shape: _markerShapeOf(item),
        color: color,
        border: _markerBorderOf(item),
        borderWidth: item.markerSettings?.borderWidth ?? 1.4,
      ),
    );
  }

  void _buildLine(int seriesIndex, VarietyLineSeries item) {
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    final List<Offset> run = <Offset>[];
    final Color color = colorFor(item, seriesIndex, 0);
    void flush() {
      if (run.length < 2) {
        run.clear();
        return;
      }
      elements.add(
        VarietyPathElement(
          seriesIndex: seriesIndex,
          path: _joinPath(run, item.lineStyle),
          strokeColor: color,
          strokeWidth: item.strokeWidth,
          dashPattern: item.dashPattern,
          strokeGradient: item.borderGradient ?? item.gradient,
        ),
      );
      run.clear();
    }

    for (int p = 0; p < points.length; p++) {
      if (points[p].isEmpty) {
        flush();
        continue;
      }
      final Offset point =
          Offset(pointPositions[seriesIndex][p].dx, topPixel(seriesIndex, p));
      run.add(point);
      _addDataLabel(item, seriesIndex, p, point, null);
    }
    flush();
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
            seriesIndex: seriesIndex,
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
  }

  /// The animated pixel of the visual top of a point.
  double topPixel(int seriesIndex, int pointIndex) {
    final VarietySeries item = series[seriesIndex];
    final List<VarietyChartData> points = resolvedData[seriesIndex];
    final VarietyChartData point = points[pointIndex];
    final int axisIndex = axisIndexOf(seriesIndex);
    if (item is VarietyLineSeries && item.fillOpacity > 0 && item.isStacked) {
      return animateY(
          pixelYOn(axisIndex, topValue(seriesIndex, pointIndex)), axisIndex);
    }
    if (item.isRange || item is VarietyCandleSeries) {
      return animateY(pixelYOn(axisIndex, point.highValue), axisIndex);
    }
    return animateY(
        pixelYOn(axisIndex, topValue(seriesIndex, pointIndex)), axisIndex);
  }

  Path _joinPath(List<Offset> points, VarietyLineStyle style) {
    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    if (style == VarietyLineStyle.stepped) {
      for (int i = 1; i < points.length; i++) {
        final Offset previous = points[i - 1];
        final Offset current = points[i];
        final double mid = (previous.dx + current.dx) / 2;
        path.lineTo(mid, previous.dy);
        path.lineTo(mid, current.dy);
        path.lineTo(current.dx, current.dy);
      }
      return path;
    }
    if (style != VarietyLineStyle.curved || points.length < 3) {
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      return path;
    }
    for (int i = 0; i < points.length - 1; i++) {
      final Offset p0 = i == 0 ? points[i] : points[i - 1];
      final Offset p1 = points[i];
      final Offset p2 = points[i + 1];
      final Offset p3 = i + 2 < points.length ? points[i + 2] : p2;
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }
    return path;
  }

  void _addDataLabel(
    VarietySeries item,
    int seriesIndex,
    int pointIndex,
    Offset anchor,
    double? bandTop,
  ) {
    final VarietyDataLabelSettings settings = item.dataLabelSettings;
    if (!settings.isVisible) {
      return;
    }
    final List<VarietyChartData> points = sourceData[seriesIndex];
    if (pointIndex >= points.length) {
      return;
    }
    final VarietyChartData point = points[pointIndex];
    String caption =
        settings.builder?.call(point) ?? varietyFormatNumber(point.y ?? 0);
    final String? overridden =
        dataLabelResolver?.call(item, seriesIndex, point, pointIndex, caption);
    if (overridden != null) {
      caption = overridden;
    }
    if (caption.isEmpty) {
      return;
    }
    elements.add(
      VarietyLabelsElement(
        seriesIndex: seriesIndex,
        labels: <VarietyLabelItem>[
          VarietyLabelItem(
            anchor: anchor,
            text: caption,
            position: settings.position,
            offset: settings.labelOffset,
            color: settings.color,
          ),
        ],
        style: settings.textStyle,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Date time ticks
  // ---------------------------------------------------------------------------

  void _buildDateTimeTicks() {
    if (!_isDateTimePrimary) {
      return;
    }
    final DateTime start =
        DateTime.fromMillisecondsSinceEpoch(xMinimum.round());
    final DateTime end = DateTime.fromMillisecondsSinceEpoch(xMaximum.round());
    VarietyDateTimeIntervalType type = xAxis.dateTimeIntervalType;
    if (type == VarietyDateTimeIntervalType.auto) {
      type = _autoIntervalType(end.difference(start));
    }
    final int step = math.max((xAxis.dateTimeInterval ?? 1).round(), 1);
    DateTime cursor = _floorTo(start, type);
    int guard = 0;
    while (cursor.millisecondsSinceEpoch <= xMaximum && guard < 500) {
      dateTimeTicks.add(cursor);
      cursor = _advance(cursor, type, step);
      guard++;
    }
  }

  static VarietyDateTimeIntervalType _autoIntervalType(Duration span) {
    if (span.inDays > 365 * 5) {
      return VarietyDateTimeIntervalType.years;
    }
    if (span.inDays > 180) {
      return VarietyDateTimeIntervalType.months;
    }
    if (span.inDays > 10) {
      return VarietyDateTimeIntervalType.days;
    }
    if (span.inHours > 6) {
      return VarietyDateTimeIntervalType.hours;
    }
    if (span.inMinutes > 5) {
      return VarietyDateTimeIntervalType.minutes;
    }
    return VarietyDateTimeIntervalType.seconds;
  }

  static DateTime _floorTo(DateTime value, VarietyDateTimeIntervalType type) {
    switch (type) {
      case VarietyDateTimeIntervalType.years:
        return DateTime(value.year);
      case VarietyDateTimeIntervalType.months:
        return DateTime(value.year, value.month);
      case VarietyDateTimeIntervalType.days:
        return DateTime(value.year, value.month, value.day);
      case VarietyDateTimeIntervalType.hours:
        return DateTime(value.year, value.month, value.day, value.hour);
      case VarietyDateTimeIntervalType.minutes:
        return DateTime(
            value.year, value.month, value.day, value.hour, value.minute);
      case VarietyDateTimeIntervalType.seconds:
        return DateTime(
          value.year,
          value.month,
          value.day,
          value.hour,
          value.minute,
          value.second,
        );
      case VarietyDateTimeIntervalType.milliseconds:
        return value;
      case VarietyDateTimeIntervalType.auto:
        return DateTime(value.year, value.month, value.day);
    }
  }

  static DateTime _advance(
      DateTime value, VarietyDateTimeIntervalType type, int step) {
    switch (type) {
      case VarietyDateTimeIntervalType.years:
        return DateTime(value.year + step, value.month, value.day);
      case VarietyDateTimeIntervalType.months:
        final int monthIndex = value.year * 12 + (value.month - 1) + step;
        return DateTime(monthIndex ~/ 12, monthIndex % 12 + 1);
      case VarietyDateTimeIntervalType.days:
        return value.add(Duration(days: step));
      case VarietyDateTimeIntervalType.hours:
        return value.add(Duration(hours: step));
      case VarietyDateTimeIntervalType.minutes:
        return value.add(Duration(minutes: step));
      case VarietyDateTimeIntervalType.seconds:
        return value.add(Duration(seconds: step));
      case VarietyDateTimeIntervalType.milliseconds:
        return value.add(Duration(milliseconds: step));
      case VarietyDateTimeIntervalType.auto:
        return value.add(Duration(days: step));
    }
  }

  /// The minor tick values of the secondary axis.
  List<double> get yMinorTicks {
    final int parts = yAxis.minorTicksPerInterval;
    if (parts <= 0 || yInterval <= 0) {
      return const <double>[];
    }
    final List<double> ticks = <double>[];
    final List<double> majors = yTicks;
    final double step = yInterval / (parts + 1);
    for (int i = 0; i < majors.length - 1; i++) {
      for (int part = 1; part <= parts; part++) {
        ticks.add(majors[i] + step * part);
      }
    }
    return ticks;
  }

  /// The minor tick positions of the primary axis, in logical pixels.
  List<double> get xMinorTickPositions {
    final int parts = xAxis.minorTicksPerInterval;
    if (parts <= 0) {
      return const <double>[];
    }
    final List<double> majors = _primaryTickPositions();
    if (majors.length < 2) {
      return const <double>[];
    }
    final List<double> positions = <double>[];
    for (int i = 0; i < majors.length - 1; i++) {
      final double step = (majors[i + 1] - majors[i]) / (parts + 1);
      for (int part = 1; part <= parts; part++) {
        positions.add(majors[i] + step * part);
      }
    }
    return positions;
  }

  /// The primary axis tick positions, in logical pixels.
  List<double> _primaryTickPositions() {
    switch (xAxisType) {
      case VarietyAxisType.category:
      case VarietyAxisType.dateTimeCategory:
        return slotCenters;
      case VarietyAxisType.dateTime:
        return dateTimeTicks
            .map(
              (DateTime tick) => toPixel(
                tick.millisecondsSinceEpoch.toDouble(),
                yMinimum,
              ).dx,
            )
            .toList(growable: false);
      case VarietyAxisType.numeric:
      case VarietyAxisType.logarithmic:
        final double span = xMaximum - xMinimum;
        final int steps = math.max(xAxis.desiredIntervals, 1);
        return List<double>.generate(
          steps + 1,
          (int i) => toPixel(xMinimum + span * i / steps, yMinimum).dx,
        );
    }
  }

  /// The tick values of the given secondary axis.
  List<double> yTicksOn(int axisIndex) {
    if (axisIndex <= 0) {
      return yTicks;
    }
    final double interval = axisIntervals[axisIndex];
    if (interval <= 0) {
      return <double>[
        axisMinimums[axisIndex],
        axisMaximums[axisIndex],
      ];
    }
    final List<double> ticks = <double>[];
    const int guard = 2000;
    double value = axisMinimums[axisIndex];
    int count = 0;
    while (
        value <= axisMaximums[axisIndex] + interval * 1e-6 && count < guard) {
      ticks.add(value);
      value += interval;
      count++;
    }
    if (ticks.isEmpty) {
      ticks.add(axisMinimums[axisIndex]);
    }
    return ticks;
  }

  /// The caption for a tick on the given secondary axis.
  String secondaryTickLabelOn(int axisIndex, double tick) {
    if (axisIndex <= 0) {
      return secondaryTickLabel(tick);
    }
    final VarietyAxis axis = yAxes[axisIndex];
    if (axis.labelFormatter != null) {
      return axis.labelFormatter!(tick);
    }
    if (axis.numberFormat != null) {
      return varietyFormatPattern(tick, axis.numberFormat!);
    }
    return varietyFormatNumber(tick);
  }

  /// The caption for a secondary axis tick, handling category axes.
  String secondaryTickLabel(double tick) {
    if (yAxisType == VarietyAxisType.category ||
        yAxisType == VarietyAxisType.dateTimeCategory) {
      final int index = tick.round();
      if (index >= 0 && index < categories.length) {
        return categories[index];
      }
      return '';
    }
    if (yAxis.labelFormatter != null) {
      return yAxis.labelFormatter!(tick);
    }
    if (yAxis.numberFormat != null) {
      return varietyFormatPattern(tick, yAxis.numberFormat!);
    }
    return varietyFormatNumber(tick);
  }

  /// The caption for a primary axis tick on a numeric axis.
  String primaryTickLabel(double value) {
    if (xAxis.labelFormatter != null) {
      return xAxis.labelFormatter!(value);
    }
    if (xAxis.numberFormat != null) {
      return varietyFormatPattern(value, xAxis.numberFormat!);
    }
    return varietyFormatNumber(value);
  }

  /// The caption for a date time tick.
  String dateTimeTickLabel(DateTime tick) {
    if (xAxis.labelFormatter != null) {
      return xAxis.labelFormatter!(tick);
    }
    final String pattern = xAxis.dateFormat ??
        varietyAutoDateFormat(
          Duration(milliseconds: (xMaximum - xMinimum).round()),
        );
    return varietyFormatDateTime(tick, pattern);
  }

  List<double> _logarithmicTicks() {
    final List<double> ticks = <double>[];
    final double lo = math.log(yMinimum) / math.log(logBase);
    final double hi = math.log(yMaximum) / math.log(logBase);
    const int guard = 200;
    int count = 0;
    for (double exponent = lo.floorToDouble();
        exponent <= hi.ceilToDouble();
        exponent++) {
      ticks.add(math.pow(logBase, exponent).toDouble());
      if (++count > guard) {
        break;
      }
    }
    return ticks.isEmpty ? <double>[yMinimum, yMaximum] : ticks;
  }

  // ---------------------------------------------------------------------------
  // Hit testing
  // ---------------------------------------------------------------------------

  /// Finds the data point closest to [position], if any lies within [tolerance].
  VarietyHitResult? hitTest(Offset position, {double tolerance = 30}) {
    VarietyHitResult? best;
    double bestDistance = double.infinity;
    for (int s = 0; s < series.length; s++) {
      final VarietySeries item = series[s];
      if (!item.enableTooltip) {
        continue;
      }
      for (int p = 0; p < bandRects[s].length; p++) {
        final Rect? rect = bandRects[s][p];
        if (rect != null && rect.inflate(2).contains(position)) {
          return VarietyHitResult(
            series: item,
            seriesIndex: s,
            point: sourceData[s][p],
            pointIndex: p,
            position: rect.center,
            band: rect,
          );
        }
      }
      for (int p = 0; p < pointPositions[s].length; p++) {
        final Offset candidate = Offset(
          pointPositions[s][p].dx,
          topPixel(s, p),
        );
        final double distance = (candidate - position).distance;
        if (distance < bestDistance && distance <= tolerance) {
          bestDistance = distance;
          best = VarietyHitResult(
            series: item,
            seriesIndex: s,
            point: sourceData[s][p],
            pointIndex: p,
            position: candidate,
          );
        }
      }
    }
    return best;
  }

  /// Returns one hit per series at the slot closest to [position].
  ///
  /// This is what a trackball uses: a single vertical guide plus one entry for
  /// every series sharing the same primary-axis index.
  List<VarietyHitResult> hitsAtSlot(Offset position) {
    final List<VarietyHitResult> results = <VarietyHitResult>[];
    if (transposed) {
      for (int s = 0; s < series.length; s++) {
        final VarietySeries item = series[s];
        if (!item.enableTooltip ||
            !item.enableTrackball ||
            pointPositions[s].isEmpty) {
          continue;
        }
        int bestIndex = 0;
        double bestDistance = double.infinity;
        for (int p = 0; p < pointPositions[s].length; p++) {
          final double distance = (pointPositions[s][p].dy - position.dy).abs();
          if (distance < bestDistance) {
            bestDistance = distance;
            bestIndex = p;
          }
        }
        results.add(
          VarietyHitResult(
            series: item,
            seriesIndex: s,
            point: sourceData[s][bestIndex],
            pointIndex: bestIndex,
            position: pointPositions[s][bestIndex],
            band: bandRects[s][bestIndex],
          ),
        );
      }
      return results;
    }
    if (xAxisType == VarietyAxisType.category ||
        xAxisType == VarietyAxisType.dateTimeCategory) {
      if (slotCenters.isEmpty) {
        return results;
      }
      int bestIndex = 0;
      double bestDistance = double.infinity;
      for (int i = 0; i < slotCenters.length; i++) {
        final double distance = (slotCenters[i] - position.dx).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          bestIndex = i;
        }
      }
      for (int s = 0; s < series.length; s++) {
        final VarietySeries item = series[s];
        if (!item.enableTooltip || !item.enableTrackball) {
          continue;
        }
        for (int p = 0; p < pointPositions[s].length; p++) {
          final String key =
              resolvedData[s][p].label ?? _categoryKey(resolvedData[s][p].x);
          if (categories.indexOf(key) != bestIndex) {
            continue;
          }
          results.add(
            VarietyHitResult(
              series: item,
              seriesIndex: s,
              point: sourceData[s][p],
              pointIndex: p,
              position: Offset(pointPositions[s][p].dx, topPixel(s, p)),
              band: bandRects[s][p],
            ),
          );
          break;
        }
      }
      return results;
    }
    for (int s = 0; s < series.length; s++) {
      final VarietySeries item = series[s];
      if (!item.enableTooltip || !item.enableTrackball) {
        continue;
      }
      int bestIndex = -1;
      double bestDistance = double.infinity;
      for (int p = 0; p < pointPositions[s].length; p++) {
        final double distance = (pointPositions[s][p].dx - position.dx).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          bestIndex = p;
        }
      }
      if (bestIndex < 0) {
        continue;
      }
      results.add(
        VarietyHitResult(
          series: item,
          seriesIndex: s,
          point: sourceData[s][bestIndex],
          pointIndex: bestIndex,
          position:
              Offset(pointPositions[s][bestIndex].dx, topPixel(s, bestIndex)),
          band: bandRects[s][bestIndex],
        ),
      );
    }
    return results;
  }

  /// The pixel X of a category slot centre, used to anchor a trackball line.
  double slotCenterFor(Offset position) {
    if (transposed) {
      return position.dx;
    }
    if (slotCenters.isEmpty) {
      return position.dx;
    }
    double best = slotCenters.first;
    double bestDistance = double.infinity;
    for (final double center in slotCenters) {
      final double distance = (center - position.dx).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = center;
      }
    }
    return best;
  }

  static _NiceRange _niceRange(double min, double max, int desiredIntervals) {
    final int intervals = desiredIntervals <= 0 ? 5 : desiredIntervals;
    final double rawRange = max - min;
    if (rawRange <= 0) {
      return _NiceRange(min, min + 1, 1);
    }
    final double rawInterval = rawRange / intervals;
    final double magnitude =
        math.pow(10, (math.log(rawInterval) / math.ln10).floor()).toDouble();
    final double residual = rawInterval / magnitude;
    double niceInterval;
    if (residual <= 1) {
      niceInterval = magnitude;
    } else if (residual <= 2) {
      niceInterval = 2 * magnitude;
    } else if (residual <= 2.5) {
      niceInterval = 2.5 * magnitude;
    } else if (residual <= 5) {
      niceInterval = 5 * magnitude;
    } else {
      niceInterval = 10 * magnitude;
    }
    final double niceMin = (min / niceInterval).floor() * niceInterval;
    final double niceMax = (max / niceInterval).ceil() * niceInterval;
    return _NiceRange(niceMin, niceMax, niceInterval);
  }

  static _LogRange _logRange(double min, double max, double base) {
    final double lo = math.log(min) / math.log(base);
    final double hi = math.log(max) / math.log(base);
    return _LogRange(
      math.pow(base, lo.floor()).toDouble(),
      math.pow(base, hi.ceil()).toDouble(),
      1,
    );
  }
}

class _BoxStats {
  const _BoxStats(
    this.minimum,
    this.q1,
    this.median,
    this.q3,
    this.maximum,
    this.lowerFence,
    this.upperFence,
    this.outliers, [
    this.mean = 0,
  ]);

  final double minimum;
  final double q1;
  final double median;
  final double q3;
  final double maximum;
  final double lowerFence;
  final double upperFence;
  final List<double> outliers;
  final double mean;
}

class _NiceRange {
  const _NiceRange(this.minimum, this.maximum, this.interval);

  final double minimum;
  final double maximum;
  final double interval;
}

class _LogRange {
  const _LogRange(this.minimum, this.maximum, this.interval);

  final double minimum;
  final double maximum;
  final double interval;
}

/// Derives the pixel geometry of a circular chart from its series.
class VarietyCircularGeometry {
  /// Builds the slices for the given [series].
  VarietyCircularGeometry({
    required this.series,
    required this.center,
    required this.maxRadius,
    required this.progress,
  }) {
    _buildSlices();
  }

  /// The circular series to lay out.
  final List<VarietySeries> series;

  /// The centre of the circle.
  final Offset center;

  /// The maximum radius available before clipping.
  final double maxRadius;

  /// The animation progress, from `0` (collapsed) to `1` (fully swept).
  final double progress;

  /// Every slice produced by the layout.
  final List<VarietySlice> slices = <VarietySlice>[];

  /// The radius actually used by the outermost slice.
  double radius = 0;

  /// The drawables produced by this layout.
  final List<VarietyElement> elements = <VarietyElement>[];

  /// The radial bar rings, populated when a radial series is present.
  final List<VarietySlice> rings = <VarietySlice>[];

  void _buildSlices() {
    for (int s = 0; s < series.length; s++) {
      final VarietySeries item = series[s];
      if (item is VarietyRadialBarSeries) {
        _buildRadial(s, item);
        continue;
      }
      final List<VarietyChartData> points = _grouped(item);
      final double total = points.fold<double>(
        0,
        (double sum, VarietyChartData point) => sum + math.max(point.y ?? 0, 0),
      );
      if (total <= 0) {
        continue;
      }
      double startAngle = _degreesToRadians(_startAngleOf(item));
      final double endAngle = _degreesToRadians(_endAngleOf(item));
      final double outer = maxRadius * _radiusFactorOf(item);
      radius = math.max(radius, outer);
      final double inner =
          item is VarietyDoughnutSeries ? outer * item.innerRadiusFactor : 0.0;
      final double span = endAngle - startAngle;
      final bool clockwise =
          _directionOf(item) == VarietySliceDirection.clockwise;
      final bool equal = _equalSlicesOf(item);
      final int explodeIndex = _explodeIndexOf(item);
      final double explodeOffset = _explodeOffsetOf(item);
      for (int p = 0; p < points.length; p++) {
        final VarietyChartData point = points[p];
        final double value = math.max(point.y ?? 0, 0);
        if (value <= 0) {
          continue;
        }
        final double ratio = equal ? 1 / points.length : value / total;
        double sweep = span * ratio * progress.clamp(0.0, 1.0);
        if (clockwise == (sweep < 0)) {
          sweep = -sweep;
        }
        Offset sliceCenter = center;
        if (p == explodeIndex && explodeOffset > 0) {
          final double mid = startAngle + sweep / 2;
          sliceCenter = center +
              Offset(math.cos(mid), math.sin(mid)) * explodeOffset * progress;
        }
        final Color color = point.color ??
            item.color ??
            varietyDefaultPalette[(s + p) % varietyDefaultPalette.length];
        final VarietySlice slice = VarietySlice(
          startAngle: startAngle,
          sweepAngle: sweep,
          outerRadius: outer,
          innerRadius: inner,
          color: color,
          point: point,
          seriesIndex: s,
          pointIndex: p,
          center: sliceCenter,
          strokeColor: _strokeColorOf(item),
          strokeWidth: _strokeWidthOf(item),
          cornerRadius: item is VarietyDoughnutSeries ? item.cornerRadius : 0,
        );
        slices.add(slice);
        startAngle += sweep;
      }
    }
  }

  void _buildRadial(int seriesIndex, VarietyRadialBarSeries item) {
    final List<VarietyChartData> points = item.data;
    double max = item.maximum ?? double.negativeInfinity;
    if (item.maximum == null) {
      for (final VarietyChartData point in points) {
        max = math.max(max, point.y ?? 0);
      }
    }
    if (max.isInfinite || max <= 0) {
      max = 1;
    }
    final int count = math.max(points.length, 1);
    final double ringSpan = maxRadius / count;
    final double thickness = ringSpan * (1 - item.gap);
    final double start = _degreesToRadians(item.startAngle);
    final double end = _degreesToRadians(item.endAngle);
    for (int p = 0; p < points.length; p++) {
      final VarietyChartData point = points[p];
      final double outer =
          maxRadius - ringSpan * p - (ringSpan - thickness) / 2;
      final double inner = math.max(outer - thickness, 0);
      final double ratio = ((point.y ?? 0) / max).clamp(0.0, 1.0);
      final Color color = point.color ??
          item.color ??
          varietyDefaultPalette[
              (seriesIndex + p) % varietyDefaultPalette.length];
      rings.add(
        VarietySlice(
          startAngle: start,
          sweepAngle: (end - start) * ratio * progress.clamp(0.0, 1.0),
          outerRadius: outer,
          innerRadius: inner,
          color: color,
          point: point,
          seriesIndex: seriesIndex,
          pointIndex: p,
          center: center,
          cornerRadius: item.cornerRadius,
        ),
      );
      if (item.showTrack) {
        rings.add(
          VarietySlice(
            startAngle: start,
            sweepAngle: end - start,
            outerRadius: outer,
            innerRadius: inner,
            color:
                (item.trackColor ?? color).withValues(alpha: item.trackOpacity),
            point: point,
            seriesIndex: seriesIndex,
            pointIndex: p,
            center: center,
            cornerRadius: item.cornerRadius,
            isTrack: true,
          ),
        );
      }
    }
  }

  List<VarietyChartData> _grouped(VarietySeries item) {
    final bool group = (item is VarietyPieSeries && item.groupSmallSlices) ||
        (item is VarietyDoughnutSeries && item.groupSmallSlices);
    if (!group) {
      return item.data;
    }
    final double threshold = item is VarietyPieSeries
        ? item.groupTo
        : (item as VarietyDoughnutSeries).groupTo;
    final String label = item is VarietyPieSeries
        ? item.groupLabel
        : (item as VarietyDoughnutSeries).groupLabel;
    final double total = item.data.fold<double>(
      0,
      (double sum, VarietyChartData point) => sum + math.max(point.y ?? 0, 0),
    );
    if (total <= 0) {
      return item.data;
    }
    final List<VarietyChartData> kept = <VarietyChartData>[];
    double others = 0;
    for (final VarietyChartData point in item.data) {
      final double percent = math.max(point.y ?? 0, 0) / total * 100;
      if (percent < threshold) {
        others += math.max(point.y ?? 0, 0);
      } else {
        kept.add(point);
      }
    }
    if (others > 0) {
      kept.add(VarietyChartData(label, others, label: label));
    }
    return kept;
  }

  /// Finds the slice that covers [position], if any.
  VarietyHitResult? hitTest(Offset position) {
    for (final VarietySlice slice in <VarietySlice>[...rings, ...slices]) {
      final Offset delta = position - slice.center;
      final double distance = delta.distance;
      if (distance > slice.outerRadius || distance < slice.innerRadius) {
        continue;
      }
      if (slice.isTrack) {
        continue;
      }
      double angle = math.atan2(delta.dy, delta.dx);
      final double start = _normalize(slice.startAngle);
      final double sweep = slice.sweepAngle;
      if (sweep == 0) {
        continue;
      }
      if (sweep > 0) {
        angle = _normalizeTo(angle, start);
        if (angle >= start && angle <= start + sweep) {
          return _result(slice);
        }
      } else {
        final double from = start + sweep;
        angle = _normalizeTo(angle, from);
        if (angle >= from && angle <= start) {
          return _result(slice);
        }
      }
    }
    return null;
  }

  VarietyHitResult _result(VarietySlice slice) {
    final double mid = slice.startAngle + slice.sweepAngle / 2;
    final double midRadius = (slice.outerRadius + slice.innerRadius) / 2;
    return VarietyHitResult(
      series: series[slice.seriesIndex],
      seriesIndex: slice.seriesIndex,
      point: slice.point,
      pointIndex: slice.pointIndex,
      position: slice.center + Offset(math.cos(mid), math.sin(mid)) * midRadius,
    );
  }

  static Color? _strokeColorOf(VarietySeries item) {
    if (item is VarietyPieSeries) {
      return item.strokeColor;
    }
    if (item is VarietyDoughnutSeries) {
      return item.strokeColor;
    }
    return null;
  }

  static double _strokeWidthOf(VarietySeries item) {
    if (item is VarietyPieSeries) {
      return item.strokeWidth;
    }
    if (item is VarietyDoughnutSeries) {
      return item.strokeWidth;
    }
    return 0;
  }

  static bool _equalSlicesOf(VarietySeries item) {
    if (item is VarietyPieSeries) {
      return item.equalSlices;
    }
    if (item is VarietyDoughnutSeries) {
      return item.equalSlices;
    }
    return false;
  }

  static double _normalize(double angle) {
    double result = angle % (2 * math.pi);
    if (result < 0) {
      result += 2 * math.pi;
    }
    return result;
  }

  static double _normalizeTo(double angle, double reference) {
    double result = angle;
    while (result < reference) {
      result += 2 * math.pi;
    }
    while (result > reference + 2 * math.pi) {
      result -= 2 * math.pi;
    }
    return result;
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;

  static double _startAngleOf(VarietySeries item) {
    if (item is VarietyPieSeries) {
      return item.startAngle;
    }
    if (item is VarietyDoughnutSeries) {
      return item.startAngle;
    }
    return -90.0;
  }

  static double _endAngleOf(VarietySeries item) {
    if (item is VarietyPieSeries) {
      return item.endAngle;
    }
    if (item is VarietyDoughnutSeries) {
      return item.endAngle;
    }
    return 270.0;
  }

  static double _radiusFactorOf(VarietySeries item) {
    if (item is VarietyPieSeries) {
      return item.radiusFactor;
    }
    if (item is VarietyDoughnutSeries) {
      return item.radiusFactor;
    }
    return 0.85;
  }

  static VarietySliceDirection _directionOf(VarietySeries item) {
    if (item is VarietyPieSeries) {
      return item.direction;
    }
    if (item is VarietyDoughnutSeries) {
      return item.direction;
    }
    return VarietySliceDirection.clockwise;
  }

  static int _explodeIndexOf(VarietySeries item) {
    if (item is VarietyPieSeries) {
      return item.explodeIndex;
    }
    if (item is VarietyDoughnutSeries) {
      return item.explodeIndex;
    }
    return -1;
  }

  static double _explodeOffsetOf(VarietySeries item) {
    if (item is VarietyPieSeries) {
      return item.explodeOffset;
    }
    if (item is VarietyDoughnutSeries) {
      return item.explodeOffset;
    }
    return 0.0;
  }
}

/// Derives the pixel geometry of a funnel or pyramid chart.
class VarietyFunnelGeometry {
  /// Builds the segments for the given [series].
  VarietyFunnelGeometry({
    required this.series,
    required this.plotRect,
    required this.progress,
    required this.isPyramid,
  }) {
    _build();
  }

  /// The funnel or pyramid series to lay out.
  final VarietySeries series;

  /// The rectangle the funnel occupies.
  final Rect plotRect;

  /// The animation progress, from `0` to `1`.
  final double progress;

  /// Whether the funnel is drawn as a pyramid instead.
  final bool isPyramid;

  /// Every segment produced by the layout.
  final List<VarietyFunnelSegment> segments = <VarietyFunnelSegment>[];

  /// The drawables produced by this layout.
  final List<VarietyElement> elements = <VarietyElement>[];

  void _build() {
    final List<VarietyChartData> points = series.data;
    if (points.isEmpty) {
      return;
    }
    final double maxValue = points.fold<double>(
      0,
      (double best, VarietyChartData point) =>
          math.max(best, math.max(point.y ?? 0, 0)),
    );
    if (maxValue <= 0) {
      return;
    }
    final double gapRatio = series is VarietyFunnelSeries
        ? (series as VarietyFunnelSeries).gapRatio
        : (series as VarietyPyramidSeries).gapRatio;
    final List<int> exploded = series is VarietyFunnelSeries
        ? (series as VarietyFunnelSeries).explodeIndexes
        : (series as VarietyPyramidSeries).explodeIndexes;
    final double explodeOffset = series is VarietyFunnelSeries
        ? (series as VarietyFunnelSeries).explodeOffset
        : (series as VarietyPyramidSeries).explodeOffset;
    final double slot = plotRect.height / points.length;
    final double height = slot * (1 - gapRatio);
    final double centerX = plotRect.center.dx;
    final double maxWidth = plotRect.width / 2;
    final List<double> widths = points.map((VarietyChartData point) {
      final double value = math.max(point.y ?? 0, 0);
      if (isPyramid &&
          series is VarietyPyramidSeries &&
          (series as VarietyPyramidSeries).mode != VarietyPyramidMode.linear) {
        return maxWidth * math.sqrt(value / maxValue);
      }
      return maxWidth * (value / maxValue);
    }).toList(growable: false);
    final double neck = series is VarietyFunnelSeries &&
            (series as VarietyFunnelSeries).showNeck
        ? widths.last * 0.35
        : 0;
    for (int i = 0; i < points.length; i++) {
      final double shift = exploded.contains(i) ? explodeOffset * progress : 0;
      final double top = plotRect.top + slot * i + (slot - height) / 2;
      final double bottom = top + height;
      final double topHalf = _halfWidthAt(widths, neck, i, isTop: true);
      final double bottomHalf = _halfWidthAt(widths, neck, i, isTop: false);
      final Color color = points[i].color ??
          series.color ??
          varietyDefaultPalette[i % varietyDefaultPalette.length];
      final double animatedTopHalf = topHalf * progress.clamp(0.0, 1.0);
      final double animatedBottomHalf = bottomHalf * progress.clamp(0.0, 1.0);
      final VarietyFunnelSegment segment = VarietyFunnelSegment(
        topLeft: Offset(centerX - animatedTopHalf + shift, top),
        topRight: Offset(centerX + animatedTopHalf + shift, top),
        bottomRight: Offset(centerX + animatedBottomHalf + shift, bottom),
        bottomLeft: Offset(centerX - animatedBottomHalf + shift, bottom),
        color: color,
        point: points[i],
        pointIndex: i,
        center: Offset(centerX + shift, (top + bottom) / 2),
      );
      segments.add(segment);
      final Path path = Path()
        ..moveTo(segment.topLeft.dx, segment.topLeft.dy)
        ..lineTo(segment.topRight.dx, segment.topRight.dy)
        ..lineTo(segment.bottomRight.dx, segment.bottomRight.dy)
        ..lineTo(segment.bottomLeft.dx, segment.bottomLeft.dy)
        ..close();
      elements.add(
        VarietyPathElement(
          seriesIndex: 0,
          path: path,
          fillColor: color,
          strokeColor: series is VarietyFunnelSeries
              ? (series as VarietyFunnelSeries).strokeColor
              : (series as VarietyPyramidSeries).strokeColor,
          strokeWidth: series is VarietyFunnelSeries
              ? (series as VarietyFunnelSeries).strokeWidth
              : (series as VarietyPyramidSeries).strokeWidth,
        ),
      );
      if (series.dataLabelSettings.isVisible) {
        elements.add(
          VarietyLabelsElement(
            seriesIndex: 0,
            labels: <VarietyLabelItem>[
              VarietyLabelItem(
                anchor: segment.center,
                text: series.dataLabelSettings.builder?.call(points[i]) ??
                    (points[i].label ?? varietyFormatNumber(points[i].y ?? 0)),
                position: series.dataLabelSettings.position,
                offset: series.dataLabelSettings.labelOffset,
                color: series.dataLabelSettings.color,
              ),
            ],
            style: series.dataLabelSettings.textStyle,
          ),
        );
      }
    }
  }

  double _halfWidthAt(List<double> widths, double neck, int index,
      {required bool isTop}) {
    if (isPyramid) {
      final double current = widths[index];
      final double next = index + 1 < widths.length ? widths[index + 1] : 0;
      return isTop ? current : (current + next) / 2;
    }
    final double current = widths[index];
    final double previous = index > 0 ? widths[index - 1] : current;
    if (isTop) {
      return index == 0 ? current : (previous + current) / 2;
    }
    final double next = index + 1 < widths.length ? widths[index + 1] : neck;
    return (current + next) / 2;
  }

  /// Finds the segment that covers [position], if any.
  VarietyHitResult? hitTest(Offset position) {
    for (final VarietyFunnelSegment segment in segments) {
      final Path path = Path()
        ..moveTo(segment.topLeft.dx, segment.topLeft.dy)
        ..lineTo(segment.topRight.dx, segment.topRight.dy)
        ..lineTo(segment.bottomRight.dx, segment.bottomRight.dy)
        ..lineTo(segment.bottomLeft.dx, segment.bottomLeft.dy)
        ..close();
      if (path.contains(position)) {
        return VarietyHitResult(
          series: series,
          seriesIndex: 0,
          point: segment.point,
          pointIndex: segment.pointIndex,
          position: segment.center,
        );
      }
    }
    return null;
  }
}

import 'dart:math' as math;

import 'variety_chart_data.dart';
import 'variety_enums.dart';
import 'variety_series.dart';

/// The value an indicator reads from a point, or `null` when the point carries
/// a value of neither kind.
///
/// A point that names a closing price is a bar, and the close is what an
/// indicator is defined over; `y` is often left at zero on such a point. A
/// point without one carries its reading in `y`. Decorating the reading with a
/// zero would hide the third case — a point an earlier stage produced — which
/// is what let a warm-up window average a value nothing had ever held.
double? _readingOrNull(VarietyChartData point) => point.close ?? point.y;

/// A point holding [value] as its reading.
///
/// The bar fields of [source] are dropped on purpose: the output of an
/// indicator is a derived reading, not a bar. Leaving the source's `close`
/// behind is what let a later pass mistake it for the original series, so the
/// triangular average, the MACD signal line and the stochastic `%D` were built
/// from prices instead of from the values they had been handed.
VarietyChartData _derived(VarietyChartData source, double? value) =>
    VarietyChartData(
      source.x,
      value,
      label: source.label,
      color: source.color,
      isEmpty: source.isEmpty,
    );

/// A point whose reading is not defined yet, used for a rolling warm-up.
VarietyChartData _undefined(VarietyChartData source) => _derived(source, null);

/// Produces a point list whose values equal the simple moving average.
List<VarietyChartData> simpleMovingAverage(
    List<VarietyChartData> source, int period) {
  return _rolling(source, period, (List<double> window) {
    return window.reduce((double a, double b) => a + b) / window.length;
  });
}

/// Produces a point list whose values equal the exponential moving average.
///
/// A point with no reading of its own leaves the average undefined, and the
/// seed is only taken from a window in which every point has one. Treating a
/// missing reading as zero would drag the first values toward the origin and
/// then, once the window filled up, jump.
List<VarietyChartData> exponentialMovingAverage(
    List<VarietyChartData> source, int period) {
  if (source.isEmpty || period <= 0) {
    return const <VarietyChartData>[];
  }
  final double multiplier = 2 / (period + 1);
  final List<VarietyChartData> result = <VarietyChartData>[];
  double? previous;
  for (int i = 0; i < source.length; i++) {
    if (previous == null) {
      if (i < period - 1) {
        result.add(_undefined(source[i]));
        continue;
      }
      double seed = 0;
      bool complete = true;
      for (int j = i - period + 1; j <= i; j++) {
        final double? entry = _readingOrNull(source[j]);
        if (entry == null) {
          complete = false;
          break;
        }
        seed += entry;
      }
      if (!complete) {
        result.add(_undefined(source[i]));
        continue;
      }
      previous = seed / period;
      result.add(_derived(source[i], previous));
      continue;
    }
    final double? value = _readingOrNull(source[i]);
    if (value == null) {
      result.add(_undefined(source[i]));
      continue;
    }
    previous = (value - previous) * multiplier + previous;
    result.add(_derived(source[i], previous));
  }
  return result;
}

/// Produces a point list whose values equal the weighted moving average.
List<VarietyChartData> weightedMovingAverage(
    List<VarietyChartData> source, int period) {
  final double weightSum = period * (period + 1) / 2;
  return _rolling(source, period, (List<double> window) {
    double total = 0;
    for (int i = 0; i < window.length; i++) {
      total += window[i] * (i + 1);
    }
    return total / weightSum;
  });
}

/// Produces a point list whose values equal the triangular moving average.
List<VarietyChartData> triangularMovingAverage(
    List<VarietyChartData> source, int period) {
  final int half = (period / 2).ceil();
  final List<VarietyChartData> firstPass = simpleMovingAverage(source, half);
  return simpleMovingAverage(firstPass, half);
}

/// Produces a point list whose values equal the relative strength index.
List<VarietyChartData> relativeStrengthIndex(
    List<VarietyChartData> source, int period) {
  if (source.length <= period) {
    return const <VarietyChartData>[];
  }
  final List<VarietyChartData> result = <VarietyChartData>[];
  double gain = 0;
  double loss = 0;
  for (int i = 1; i <= period; i++) {
    final double? current = _readingOrNull(source[i]);
    final double? previous = _readingOrNull(source[i - 1]);
    if (current == null || previous == null) {
      // A window that is not fully defined cannot seed the averages. Returning
      // a reading built from a zero would put the oscillator on a level it was
      // never measured at, so the whole line stays undefined.
      return List<VarietyChartData>.generate(
        source.length,
        (int i) => _undefined(source[i]),
        growable: false,
      );
    }
    final double delta = current - previous;
    if (delta >= 0) {
      gain += delta;
    } else {
      loss -= delta;
    }
  }
  double averageGain = gain / period;
  double averageLoss = loss / period;
  for (int i = 0; i < source.length; i++) {
    if (i < period) {
      result.add(_undefined(source[i]));
      continue;
    }
    final double? current = _readingOrNull(source[i]);
    if (current == null) {
      result.add(_undefined(source[i]));
      continue;
    }
    if (i > period) {
      final double? previous = _readingOrNull(source[i - 1]);
      if (previous == null) {
        result.add(_undefined(source[i]));
        continue;
      }
      final double delta = current - previous;
      final double up = delta > 0 ? delta : 0;
      final double down = delta < 0 ? -delta : 0;
      averageGain = (averageGain * (period - 1) + up) / period;
      averageLoss = (averageLoss * (period - 1) + down) / period;
    }
    final double rs = averageLoss == 0 ? 100 : averageGain / averageLoss;
    result.add(
        _derived(source[i], averageLoss == 0 ? 100 : 100 - 100 / (1 + rs)));
  }
  return result;
}

/// Produces a point list whose values equal the average true range.
List<VarietyChartData> averageTrueRange(
    List<VarietyChartData> source, int period) {
  if (source.isEmpty) {
    return const <VarietyChartData>[];
  }
  final List<double> trueRanges = <double>[];
  for (int i = 0; i < source.length; i++) {
    final VarietyChartData point = source[i];
    if (i == 0) {
      trueRanges.add(point.highValue - point.lowValue);
      continue;
    }
    final double previousClose = source[i - 1].closeValue;
    final double high = point.highValue;
    final double low = point.lowValue;
    final double range = math.max(
      high - low,
      math.max((high - previousClose).abs(), (low - previousClose).abs()),
    );
    trueRanges.add(range);
  }
  return _rollingValues(source, trueRanges, period);
}

/// Produces a point list whose values equal the momentum oscillator.
List<VarietyChartData> momentum(List<VarietyChartData> source, int period) {
  final List<VarietyChartData> result = <VarietyChartData>[];
  for (int i = 0; i < source.length; i++) {
    if (i < period) {
      result.add(_undefined(source[i]));
      continue;
    }
    final double? current = _readingOrNull(source[i]);
    final double? previous = _readingOrNull(source[i - period]);
    result.add(_derived(
      source[i],
      (current == null || previous == null) ? null : current - previous,
    ));
  }
  return result;
}

/// Produces a point list whose values equal the rate of change, in percent.
List<VarietyChartData> rateOfChange(List<VarietyChartData> source, int period) {
  final List<VarietyChartData> result = <VarietyChartData>[];
  for (int i = 0; i < source.length; i++) {
    if (i < period) {
      result.add(_undefined(source[i]));
      continue;
    }
    final double? previous = _readingOrNull(source[i - period]);
    final double? current = _readingOrNull(source[i]);
    result.add(_derived(
      source[i],
      (current == null || previous == null)
          ? null
          : (previous == 0 ? 0 : (current - previous) / previous * 100),
    ));
  }
  return result;
}

/// Produces the accumulation / distribution line.
///
/// The money flow multiplier is derived from each point's high, low and close,
/// and is weighted by the value carried in [VarietyChartData.size], which this
/// indicator treats as volume.
List<VarietyChartData> accumulationDistribution(List<VarietyChartData> source) {
  final List<VarietyChartData> result = <VarietyChartData>[];
  double running = 0;
  for (final VarietyChartData point in source) {
    final double high = point.highValue;
    final double low = point.lowValue;
    final double close = point.closeValue;
    final double span = high - low;
    if (span > 0) {
      final double multiplier = ((close - low) - (high - close)) / span;
      running += multiplier * (point.size ?? 0);
    }
    result.add(_derived(point, running));
  }
  return result;
}

/// An accumulation / distribution overlay, normally plotted on its own axis.
class VarietyAdIndicator extends VarietyLineSeries {
  /// Creates an A/D overlay over [source].
  VarietyAdIndicator({
    required this.source,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  }) : super(
          data: accumulationDistribution(source.data),
          lineStyle: VarietyLineStyle.straight,
        );

  /// The series the indicator is computed from.
  final VarietySeries source;
}

/// The rolling standard deviation of a window, used by Bollinger bands.
List<VarietyChartData> _rollingStdDev(
    List<VarietyChartData> source, int period) {
  return _rolling(source, period, (List<double> window) {
    final double mean =
        window.reduce((double a, double b) => a + b) / window.length;
    double variance = 0;
    for (final double value in window) {
      variance += math.pow(value - mean, 2).toDouble();
    }
    return math.sqrt(variance / window.length);
  });
}

List<VarietyChartData> _rolling(
  List<VarietyChartData> source,
  int period,
  double Function(List<double> window) reduce,
) {
  final List<double?> values =
      source.map(_readingOrNull).toList(growable: false);
  return _rollingValues(source, values, period, reduce);
}

/// Applies [reduce] to every full window of [values].
///
/// A window holding a point with no reading produces a point with no reading
/// either. Counting a gap as a zero would tilt the window towards the origin,
/// which is how the warm-up of a composite indicator used to pick up values
/// its input had never carried.
List<VarietyChartData> _rollingValues(
  List<VarietyChartData> source,
  List<double?> values,
  int period, [
  double Function(List<double> window)? reduce,
]) {
  if (period <= 0) {
    return const <VarietyChartData>[];
  }
  final double Function(List<double>) reducer = reduce ??
      (List<double> window) =>
          window.reduce((double a, double b) => a + b) / window.length;
  final List<VarietyChartData> result = <VarietyChartData>[];
  for (int i = 0; i < source.length; i++) {
    if (i < period - 1) {
      result.add(_undefined(source[i]));
      continue;
    }
    final List<double?> window = values.sublist(i - period + 1, i + 1);
    if (window.any((double? value) => value == null)) {
      result.add(_undefined(source[i]));
      continue;
    }
    result.add(_derived(source[i], reducer(window.cast<double>())));
  }
  return result;
}

/// A simple moving average overlay.
class VarietySmaIndicator extends VarietyLineSeries {
  /// Creates an SMA overlay over [source].
  VarietySmaIndicator({
    required this.source,
    this.period = 14,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  }) : super(
          data: simpleMovingAverage(source.data, period),
          lineStyle: VarietyLineStyle.straight,
        );

  /// The averaging window.
  final int period;

  /// The series the indicator is computed from.
  final VarietySeries source;
}

/// An exponential moving average overlay.
class VarietyEmaIndicator extends VarietyLineSeries {
  /// Creates an EMA overlay over [source].
  VarietyEmaIndicator({
    required this.source,
    this.period = 14,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  }) : super(
          data: exponentialMovingAverage(source.data, period),
          lineStyle: VarietyLineStyle.straight,
        );

  /// The averaging window.
  final int period;

  /// The series the indicator is computed from.
  final VarietySeries source;
}

/// A weighted moving average overlay.
class VarietyWmaIndicator extends VarietyLineSeries {
  /// Creates a WMA overlay over [source].
  VarietyWmaIndicator({
    required this.source,
    this.period = 14,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  }) : super(
          data: weightedMovingAverage(source.data, period),
          lineStyle: VarietyLineStyle.straight,
        );

  /// The averaging window.
  final int period;

  /// The series the indicator is computed from.
  final VarietySeries source;
}

/// A triangular moving average overlay.
class VarietyTmaIndicator extends VarietyLineSeries {
  /// Creates a TMA overlay over [source].
  VarietyTmaIndicator({
    required this.source,
    this.period = 14,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  }) : super(
          data: triangularMovingAverage(source.data, period),
          lineStyle: VarietyLineStyle.straight,
        );

  /// The averaging window.
  final int period;

  /// The series the indicator is computed from.
  final VarietySeries source;
}

/// A relative strength index overlay, normally plotted on its own axis.
class VarietyRsiIndicator extends VarietyLineSeries {
  /// Creates an RSI overlay over [source].
  VarietyRsiIndicator({
    required this.source,
    this.period = 14,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  }) : super(
          data: relativeStrengthIndex(source.data, period),
          lineStyle: VarietyLineStyle.straight,
        );

  /// The averaging window.
  final int period;

  /// The series the indicator is computed from.
  final VarietySeries source;
}

/// An average true range overlay, normally plotted on its own axis.
class VarietyAtrIndicator extends VarietyLineSeries {
  /// Creates an ATR overlay over [source].
  VarietyAtrIndicator({
    required this.source,
    this.period = 14,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  }) : super(
          data: averageTrueRange(source.data, period),
          lineStyle: VarietyLineStyle.straight,
        );

  /// The averaging window.
  final int period;

  /// The series the indicator is computed from.
  final VarietySeries source;
}

/// A momentum oscillator overlay.
class VarietyMomentumIndicator extends VarietyLineSeries {
  /// Creates a momentum overlay over [source].
  VarietyMomentumIndicator({
    required this.source,
    this.period = 10,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  }) : super(
          data: momentum(source.data, period),
          lineStyle: VarietyLineStyle.straight,
        );

  /// The look-back window.
  final int period;

  /// The series the indicator is computed from.
  final VarietySeries source;
}

/// A rate of change oscillator overlay.
class VarietyRocIndicator extends VarietyLineSeries {
  /// Creates a ROC overlay over [source].
  VarietyRocIndicator({
    required this.source,
    this.period = 10,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  }) : super(
          data: rateOfChange(source.data, period),
          lineStyle: VarietyLineStyle.straight,
        );

  /// The look-back window.
  final int period;

  /// The series the indicator is computed from.
  final VarietySeries source;
}

/// A Bollinger band overlay made of an upper band, a middle band and a lower band.
class VarietyBollingerBandsIndicator {
  /// Creates a Bollinger band overlay over [source].
  VarietyBollingerBandsIndicator({
    required this.source,
    this.period = 14,
    this.standardDeviation = 2.0,
    this.name = 'Bollinger',
  });

  /// The series the bands are computed from.
  final VarietySeries source;

  /// The averaging window.
  final int period;

  /// The number of standard deviations the bands are offset by.
  final double standardDeviation;

  /// The caption prefix used by the generated series.
  final String name;

  /// Builds the upper, middle and lower band series.
  List<VarietyLineSeries> build() {
    final List<VarietyChartData> middle =
        simpleMovingAverage(source.data, period);
    final List<VarietyChartData> deviation =
        _rollingStdDev(source.data, period);
    final List<VarietyChartData> upper = <VarietyChartData>[];
    final List<VarietyChartData> lower = <VarietyChartData>[];
    for (int i = 0; i < middle.length; i++) {
      final double? mean = middle[i].y;
      final double? sd = deviation[i].y;
      if (mean == null || sd == null) {
        upper.add(_undefined(middle[i]));
        lower.add(_undefined(middle[i]));
        continue;
      }
      upper.add(_derived(middle[i], mean + sd * standardDeviation));
      lower.add(_derived(middle[i], mean - sd * standardDeviation));
    }
    return <VarietyLineSeries>[
      VarietyLineSeries(
          name: '$name Upper',
          data: upper,
          strokeWidth: 1.4,
          dashPattern: const <double>[5, 4]),
      VarietyLineSeries(name: '$name Middle', data: middle, strokeWidth: 1.6),
      VarietyLineSeries(
          name: '$name Lower',
          data: lower,
          strokeWidth: 1.4,
          dashPattern: const <double>[5, 4]),
    ];
  }
}

/// A moving average convergence divergence overlay.
class VarietyMacdIndicator {
  /// Creates a MACD overlay over [source].
  VarietyMacdIndicator({
    required this.source,
    this.shortPeriod = 12,
    this.longPeriod = 26,
    this.signalPeriod = 9,
  });

  /// The series the indicator is computed from.
  final VarietySeries source;

  /// The fast EMA window.
  final int shortPeriod;

  /// The slow EMA window.
  final int longPeriod;

  /// The signal EMA window.
  final int signalPeriod;

  /// Builds the MACD line, the signal line and the histogram.
  List<VarietySeries> build() {
    final List<VarietyChartData> fast =
        exponentialMovingAverage(source.data, shortPeriod);
    final List<VarietyChartData> slow =
        exponentialMovingAverage(source.data, longPeriod);
    final List<VarietyChartData> macd = <VarietyChartData>[];
    for (int i = 0; i < source.data.length; i++) {
      final double? a = i < fast.length ? fast[i].y : null;
      final double? b = i < slow.length ? slow[i].y : null;
      macd.add(
          _derived(source.data[i], (a == null || b == null) ? null : a - b));
    }
    final List<VarietyChartData> signal =
        exponentialMovingAverage(macd, signalPeriod);
    final List<VarietyChartData> histogram = <VarietyChartData>[];
    for (int i = 0; i < macd.length; i++) {
      final double? a = macd[i].y;
      final double? b = i < signal.length ? signal[i].y : null;
      histogram.add(_derived(macd[i], (a == null || b == null) ? null : a - b));
    }
    return <VarietySeries>[
      VarietyColumnSeries(name: 'MACD', data: histogram, widthFactor: 0.5),
      VarietyLineSeries(name: 'MACD Line', data: macd, strokeWidth: 1.6),
      VarietyLineSeries(name: 'Signal', data: signal, strokeWidth: 1.6),
    ];
  }
}

/// A stochastic oscillator overlay.
class VarietyStochasticIndicator {
  /// Creates a stochastic oscillator over [source].
  VarietyStochasticIndicator({
    required this.source,
    this.period = 14,
    this.signalPeriod = 3,
  });

  /// The series the oscillator is computed from.
  final VarietySeries source;

  /// The look-back window used by %K.
  final int period;

  /// The smoothing window used by %D.
  final int signalPeriod;

  /// Builds the %K and %D series.
  List<VarietyLineSeries> build() {
    final List<VarietyChartData> kValues = <VarietyChartData>[];
    for (int i = 0; i < source.data.length; i++) {
      if (i < period - 1) {
        kValues.add(_undefined(source.data[i]));
        continue;
      }
      double highest = double.negativeInfinity;
      double lowest = double.infinity;
      for (int j = i - period + 1; j <= i; j++) {
        highest = math.max(highest, source.data[j].highValue);
        lowest = math.min(lowest, source.data[j].lowValue);
      }
      final double? close = _readingOrNull(source.data[i]);
      if (close == null) {
        kValues.add(_undefined(source.data[i]));
        continue;
      }
      final double span = highest - lowest;
      kValues.add(_derived(
          source.data[i], span == 0 ? 50 : (close - lowest) / span * 100));
    }
    return <VarietyLineSeries>[
      VarietyLineSeries(name: '%K', data: kValues, strokeWidth: 1.6),
      VarietyLineSeries(
        name: '%D',
        data: simpleMovingAverage(kValues, signalPeriod),
        strokeWidth: 1.6,
        dashPattern: const <double>[5, 4],
      ),
    ];
  }
}

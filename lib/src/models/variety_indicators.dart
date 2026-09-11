import 'dart:math' as math;

import 'variety_chart_data.dart';
import 'variety_enums.dart';
import 'variety_series.dart';

/// The value used by each point when an indicator needs a single reading.
double _reading(VarietyChartData point) => point.closeValue;

/// Produces a point list whose values equal the simple moving average.
List<VarietyChartData> simpleMovingAverage(List<VarietyChartData> source, int period) {
  return _rolling(source, period, (List<double> window) {
    return window.reduce((double a, double b) => a + b) / window.length;
  });
}

/// Produces a point list whose values equal the exponential moving average.
List<VarietyChartData> exponentialMovingAverage(List<VarietyChartData> source, int period) {
  if (source.isEmpty || period <= 0) {
    return const <VarietyChartData>[];
  }
  final double multiplier = 2 / (period + 1);
  final List<VarietyChartData> result = <VarietyChartData>[];
  double? previous;
  for (int i = 0; i < source.length; i++) {
    final double value = _reading(source[i]);
    if (i < period - 1) {
      result.add(source[i].withValue(null));
      continue;
    }
    if (previous == null) {
      double seed = 0;
      for (int j = i - period + 1; j <= i; j++) {
        seed += _reading(source[j]);
      }
      previous = seed / period;
    } else {
      previous = (value - previous) * multiplier + previous;
    }
    result.add(source[i].copyWith(y: previous));
  }
  return result;
}

/// Produces a point list whose values equal the weighted moving average.
List<VarietyChartData> weightedMovingAverage(List<VarietyChartData> source, int period) {
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
List<VarietyChartData> triangularMovingAverage(List<VarietyChartData> source, int period) {
  final int half = (period / 2).ceil();
  final List<VarietyChartData> firstPass = simpleMovingAverage(source, half);
  return simpleMovingAverage(firstPass, half);
}

/// Produces a point list whose values equal the relative strength index.
List<VarietyChartData> relativeStrengthIndex(List<VarietyChartData> source, int period) {
  if (source.length <= period) {
    return const <VarietyChartData>[];
  }
  final List<VarietyChartData> result = <VarietyChartData>[];
  double gain = 0;
  double loss = 0;
  for (int i = 1; i <= period; i++) {
    final double delta = _reading(source[i]) - _reading(source[i - 1]);
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
      result.add(source[i].withValue(null));
      continue;
    }
    if (i > period) {
      final double delta = _reading(source[i]) - _reading(source[i - 1]);
      final double up = delta > 0 ? delta : 0;
      final double down = delta < 0 ? -delta : 0;
      averageGain = (averageGain * (period - 1) + up) / period;
      averageLoss = (averageLoss * (period - 1) + down) / period;
    }
    final double rs = averageLoss == 0 ? 100 : averageGain / averageLoss;
    result.add(source[i].copyWith(y: averageLoss == 0 ? 100 : 100 - 100 / (1 + rs)));
  }
  return result;
}

/// Produces a point list whose values equal the average true range.
List<VarietyChartData> averageTrueRange(List<VarietyChartData> source, int period) {
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
      result.add(source[i].withValue(null));
      continue;
    }
    result.add(source[i].copyWith(y: _reading(source[i]) - _reading(source[i - period])));
  }
  return result;
}

/// Produces a point list whose values equal the rate of change, in percent.
List<VarietyChartData> rateOfChange(List<VarietyChartData> source, int period) {
  final List<VarietyChartData> result = <VarietyChartData>[];
  for (int i = 0; i < source.length; i++) {
    if (i < period) {
      result.add(source[i].withValue(null));
      continue;
    }
    final double previous = _reading(source[i - period]);
    final double current = _reading(source[i]);
    result.add(source[i].copyWith(y: previous == 0 ? 0 : (current - previous) / previous * 100));
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
    result.add(point.withValue(running));
  }
  return result;
}

/// An accumulation / distribution overlay, normally plotted on its own axis.
class VarietyAdIndicator extends VarietyLineSeries {
  /// Creates an A/D overlay over [source].
  VarietyAdIndicator({
    required VarietySeries source,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  })  : source = source,
        super(
          data: accumulationDistribution(source.data),
          lineStyle: VarietyLineStyle.straight,
        );

  /// The series the indicator is computed from.
  final VarietySeries source;
}

/// The rolling standard deviation of a window, used by Bollinger bands.
List<VarietyChartData> _rollingStdDev(List<VarietyChartData> source, int period) {
  return _rolling(source, period, (List<double> window) {
    final double mean = window.reduce((double a, double b) => a + b) / window.length;
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
  final List<double> values = source.map(_reading).toList(growable: false);
  return _rollingValues(source, values, period, reduce);
}

List<VarietyChartData> _rollingValues(
  List<VarietyChartData> source,
  List<double> values,
  int period, [
  double Function(List<double> window)? reduce,
]) {
  if (period <= 0) {
    return const <VarietyChartData>[];
  }
  final double Function(List<double>) reducer = reduce ??
      (List<double> window) => window.reduce((double a, double b) => a + b) / window.length;
  final List<VarietyChartData> result = <VarietyChartData>[];
  for (int i = 0; i < source.length; i++) {
    if (i < period - 1) {
      result.add(source[i].withValue(null));
      continue;
    }
    result.add(source[i].copyWith(y: reducer(values.sublist(i - period + 1, i + 1))));
  }
  return result;
}

/// A simple moving average overlay.
class VarietySmaIndicator extends VarietyLineSeries {
  /// Creates an SMA overlay over [source].
  VarietySmaIndicator({
    required VarietySeries source,
    this.period = 14,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  })  : source = source,
        super(
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
    required VarietySeries source,
    this.period = 14,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  })  : source = source,
        super(
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
    required VarietySeries source,
    this.period = 14,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  })  : source = source,
        super(
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
    required VarietySeries source,
    this.period = 14,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  })  : source = source,
        super(
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
    required VarietySeries source,
    this.period = 14,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  })  : source = source,
        super(
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
    required VarietySeries source,
    this.period = 14,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  })  : source = source,
        super(
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
    required VarietySeries source,
    this.period = 10,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  })  : source = source,
        super(
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
    required VarietySeries source,
    this.period = 10,
    super.name,
    super.color,
    super.strokeWidth,
    super.dashPattern,
    super.dataLabelSettings,
    super.enableTooltip,
    super.legendIconShape,
  })  : source = source,
        super(
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
    final List<VarietyChartData> middle = simpleMovingAverage(source.data, period);
    final List<VarietyChartData> deviation = _rollingStdDev(source.data, period);
    final List<VarietyChartData> upper = <VarietyChartData>[];
    final List<VarietyChartData> lower = <VarietyChartData>[];
    for (int i = 0; i < middle.length; i++) {
      final double? mean = middle[i].y;
      final double? sd = deviation[i].y;
      if (mean == null || sd == null) {
        upper.add(middle[i].withValue(null));
        lower.add(middle[i].withValue(null));
        continue;
      }
      upper.add(middle[i].copyWith(y: mean + sd * standardDeviation));
      lower.add(middle[i].copyWith(y: mean - sd * standardDeviation));
    }
    return <VarietyLineSeries>[
      VarietyLineSeries(name: '$name Upper', data: upper, strokeWidth: 1.4, dashPattern: const <double>[5, 4]),
      VarietyLineSeries(name: '$name Middle', data: middle, strokeWidth: 1.6),
      VarietyLineSeries(name: '$name Lower', data: lower, strokeWidth: 1.4, dashPattern: const <double>[5, 4]),
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
    final List<VarietyChartData> fast = exponentialMovingAverage(source.data, shortPeriod);
    final List<VarietyChartData> slow = exponentialMovingAverage(source.data, longPeriod);
    final List<VarietyChartData> macd = <VarietyChartData>[];
    for (int i = 0; i < source.data.length; i++) {
      final double? a = i < fast.length ? fast[i].y : null;
      final double? b = i < slow.length ? slow[i].y : null;
      macd.add(source.data[i].copyWith(y: (a == null || b == null) ? null : a - b));
    }
    final List<VarietyChartData> signal = exponentialMovingAverage(macd, signalPeriod);
    final List<VarietyChartData> histogram = <VarietyChartData>[];
    for (int i = 0; i < macd.length; i++) {
      final double? a = macd[i].y;
      final double? b = i < signal.length ? signal[i].y : null;
      histogram.add(macd[i].copyWith(y: (a == null || b == null) ? null : a - b));
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
        kValues.add(source.data[i].withValue(null));
        continue;
      }
      double highest = double.negativeInfinity;
      double lowest = double.infinity;
      for (int j = i - period + 1; j <= i; j++) {
        highest = math.max(highest, source.data[j].highValue);
        lowest = math.min(lowest, source.data[j].lowValue);
      }
      final double close = source.data[i].closeValue;
      final double span = highest - lowest;
      kValues.add(source.data[i].copyWith(y: span == 0 ? 50 : (close - lowest) / span * 100));
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

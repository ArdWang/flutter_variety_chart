import 'dart:math' as math;

import '../models/variety_enums.dart';
import '../models/variety_trendline.dart';

/// Fits a trendline to [points] and returns the resulting function.
///
/// The returned function maps an `x` value to the fitted `y` value. It returns
/// `null` when the model cannot be fitted, for example when the input contains
/// non-positive values for a logarithmic or power model, or when the normal
/// equations are singular.
double Function(double x)? varietyFitTrendline(
  List<(double, double)> points,
  VarietyTrendline trendline,
) {
  if (points.length < 2) {
    return null;
  }
  switch (trendline.type) {
    case VarietyTrendlineType.linear:
      return _fitLinear(points);
    case VarietyTrendlineType.exponential:
      return _fitExponential(points);
    case VarietyTrendlineType.logarithmic:
      return _fitLogarithmic(points);
    case VarietyTrendlineType.power:
      return _fitPower(points);
    case VarietyTrendlineType.polynomial:
      return _fitPolynomial(points, trendline.order);
    case VarietyTrendlineType.movingAverage:
      return null;
  }
}

/// Computes the simple moving average of [values] using the given [period].
List<double?> varietyMovingAverage(List<double> values, int period) {
  if (period <= 0) {
    return List<double?>.filled(values.length, null);
  }
  final List<double?> result = List<double?>.filled(values.length, null);
  double running = 0;
  for (int i = 0; i < values.length; i++) {
    running += values[i];
    if (i >= period) {
      running -= values[i - period];
    }
    if (i >= period - 1) {
      result[i] = running / period;
    }
  }
  return result;
}

double Function(double x)? _fitLinear(List<(double, double)> points) {
  final _LinearFit fit = _leastSquares(
    points.map(((double, double) p) => p.$1).toList(growable: false),
    points.map(((double, double) p) => p.$2).toList(growable: false),
  );
  return (double x) => fit.slope * x + fit.intercept;
}

double Function(double x)? _fitExponential(List<(double, double)> points) {
  if (points.any(((double, double) p) => p.$2 <= 0)) {
    return null;
  }
  final _LinearFit fit = _leastSquares(
    points.map(((double, double) p) => p.$1).toList(growable: false),
    points.map(((double, double) p) => math.log(p.$2)).toList(growable: false),
  );
  final double a = math.exp(fit.intercept);
  return (double x) => a * math.exp(fit.slope * x);
}

double Function(double x)? _fitLogarithmic(List<(double, double)> points) {
  if (points.any(((double, double) p) => p.$1 <= 0)) {
    return null;
  }
  final _LinearFit fit = _leastSquares(
    points.map(((double, double) p) => math.log(p.$1)).toList(growable: false),
    points.map(((double, double) p) => p.$2).toList(growable: false),
  );
  return (double x) =>
      x <= 0 ? double.nan : fit.slope * math.log(x) + fit.intercept;
}

double Function(double x)? _fitPower(List<(double, double)> points) {
  if (points.any(((double, double) p) => p.$1 <= 0 || p.$2 <= 0)) {
    return null;
  }
  final _LinearFit fit = _leastSquares(
    points.map(((double, double) p) => math.log(p.$1)).toList(growable: false),
    points.map(((double, double) p) => math.log(p.$2)).toList(growable: false),
  );
  final double a = math.exp(fit.intercept);
  return (double x) =>
      x <= 0 ? double.nan : a * math.pow(x, fit.slope).toDouble();
}

double Function(double x)? _fitPolynomial(
    List<(double, double)> points, int order) {
  final int degree = order.clamp(1, 6);
  final int size = degree + 1;
  final List<List<double>> matrix = List<List<double>>.generate(
      size, (_) => List<double>.filled(size + 1, 0));
  for (int row = 0; row < size; row++) {
    for (int col = 0; col < size; col++) {
      double sum = 0;
      for (final (double, double) point in points) {
        sum += math.pow(point.$1, row + col).toDouble();
      }
      matrix[row][col] = sum;
    }
    double rhs = 0;
    for (final (double, double) point in points) {
      rhs += point.$2 * math.pow(point.$1, row).toDouble();
    }
    matrix[row][size] = rhs;
  }
  final List<double>? coefficients = _solve(matrix, size);
  if (coefficients == null) {
    return null;
  }
  return (double x) {
    double value = 0;
    for (int i = 0; i < coefficients.length; i++) {
      value += coefficients[i] * math.pow(x, i).toDouble();
    }
    return value;
  };
}

double Function(double x)? _movingAverageTrendline(
    List<(double, double)> points, int period) {
  final List<double?> averaged = varietyMovingAverage(
    points.map(((double, double) p) => p.$2).toList(growable: false),
    period,
  );
  return (double x) {
    // Interpolate the moving average by nearest sample index.
    double bestDistance = double.infinity;
    double? bestValue;
    for (int i = 0; i < points.length; i++) {
      final double distance = (points[i].$1 - x).abs();
      if (distance < bestDistance && averaged[i] != null) {
        bestDistance = distance;
        bestValue = averaged[i];
      }
    }
    return bestValue ?? double.nan;
  };
}

/// Builds the sampler used by a moving-average trendline.
double Function(double x)? varietyMovingAverageTrendline(
  List<(double, double)> points,
  int period,
) =>
    _movingAverageTrendline(points, period);

class _LinearFit {
  const _LinearFit(this.slope, this.intercept);

  final double slope;
  final double intercept;
}

_LinearFit _leastSquares(List<double> xs, List<double> ys) {
  final int n = xs.length;
  double sumX = 0;
  double sumY = 0;
  double sumXY = 0;
  double sumXX = 0;
  for (int i = 0; i < n; i++) {
    sumX += xs[i];
    sumY += ys[i];
    sumXY += xs[i] * ys[i];
    sumXX += xs[i] * xs[i];
  }
  final double denominator = n * sumXX - sumX * sumX;
  if (denominator.abs() < 1e-12) {
    return _LinearFit(0, n == 0 ? 0 : sumY / n);
  }
  final double slope = (n * sumXY - sumX * sumY) / denominator;
  final double intercept = (sumY - slope * sumX) / n;
  return _LinearFit(slope, intercept);
}

/// Solves an augmented matrix with Gauss-Jordan elimination.
List<double>? _solve(List<List<double>> matrix, int size) {
  for (int column = 0; column < size; column++) {
    int pivot = column;
    for (int row = column + 1; row < size; row++) {
      if (matrix[row][column].abs() > matrix[pivot][column].abs()) {
        pivot = row;
      }
    }
    if (matrix[pivot][column].abs() < 1e-12) {
      return null;
    }
    final List<double> swap = matrix[column];
    matrix[column] = matrix[pivot];
    matrix[pivot] = swap;
    final double divisor = matrix[column][column];
    for (int col = column; col <= size; col++) {
      matrix[column][col] /= divisor;
    }
    for (int row = 0; row < size; row++) {
      if (row == column) {
        continue;
      }
      final double factor = matrix[row][column];
      if (factor == 0) {
        continue;
      }
      for (int col = column; col <= size; col++) {
        matrix[row][col] -= factor * matrix[column][col];
      }
    }
  }
  return List<double>.generate(size, (int i) => matrix[i][size]);
}

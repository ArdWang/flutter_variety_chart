import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

void main() {
  group('linear', () {
    test('fits a perfect line', () {
      final double Function(double)? fit = varietyFitTrendline(
        const <(double, double)>[(0, 1), (1, 3), (2, 5), (3, 7)],
        const VarietyTrendline(),
      );
      expect(fit, isNotNull);
      expect(fit!(4), closeTo(9, 0.001));
    });

    test('returns null for a single point', () {
      expect(
        varietyFitTrendline(
            const <(double, double)>[(0, 1)], const VarietyTrendline()),
        isNull,
      );
    });

    test('falls back to a flat line when every x is identical', () {
      final double Function(double)? fit = varietyFitTrendline(
        const <(double, double)>[(2, 4), (2, 8)],
        const VarietyTrendline(),
      );
      expect(fit, isNotNull);
      expect(fit!(2), closeTo(6, 0.001));
    });
  });

  group('exponential', () {
    test('recovers a growing exponential', () {
      final double Function(double)? fit = varietyFitTrendline(
        const <(double, double)>[(0, 2), (1, 6), (2, 18), (3, 54)],
        const VarietyTrendline(type: VarietyTrendlineType.exponential),
      );
      expect(fit, isNotNull);
      expect(fit!(4), closeTo(162, 0.5));
    });

    test('rejects non-positive values', () {
      expect(
        varietyFitTrendline(
          const <(double, double)>[(0, 0), (1, 6)],
          const VarietyTrendline(type: VarietyTrendlineType.exponential),
        ),
        isNull,
      );
    });
  });

  group('logarithmic', () {
    test('rejects a non-positive x', () {
      expect(
        varietyFitTrendline(
          const <(double, double)>[(0, 1), (1, 3)],
          const VarietyTrendline(type: VarietyTrendlineType.logarithmic),
        ),
        isNull,
      );
    });

    test('fits a logarithmic curve', () {
      final double Function(double)? fit = varietyFitTrendline(
        const <(double, double)>[
          (1, 0),
          (2.718281828, 1),
          (7.389056099, 2),
          (20.08553692, 3),
        ],
        const VarietyTrendline(type: VarietyTrendlineType.logarithmic),
      );
      expect(fit, isNotNull);
      expect(fit!(1), closeTo(0, 0.01));
    });
  });

  group('polynomial', () {
    test('fits a quadratic', () {
      final double Function(double)? fit = varietyFitTrendline(
        const <(double, double)>[(0, 0), (1, 1), (2, 4), (3, 9), (4, 16)],
        const VarietyTrendline(type: VarietyTrendlineType.polynomial, order: 2),
      );
      expect(fit, isNotNull);
      expect(fit!(5), closeTo(25, 0.01));
    });

    test('clamps the order into the supported range', () {
      final double Function(double)? fit = varietyFitTrendline(
        const <(double, double)>[
          (0, 0),
          (1, 1),
          (2, 4),
          (3, 9),
          (4, 16),
          (5, 25),
          (6, 36),
          (7, 49),
        ],
        const VarietyTrendline(
            type: VarietyTrendlineType.polynomial, order: 99),
      );
      expect(fit, isNotNull);
      expect(fit!(2), closeTo(4, 0.5));
    });
  });

  group('power', () {
    test('recovers a power law', () {
      final double Function(double)? fit = varietyFitTrendline(
        const <(double, double)>[(1, 3), (2, 12), (3, 27), (4, 48)],
        const VarietyTrendline(type: VarietyTrendlineType.power),
      );
      expect(fit, isNotNull);
      expect(fit!(5), closeTo(75, 0.5));
    });
  });

  group('moving average', () {
    test('trails the window', () {
      final List<double?> values =
          varietyMovingAverage(const <double>[1, 2, 3, 4, 5], 3);
      expect(values[0], isNull);
      expect(values[1], isNull);
      expect(values[2], closeTo(2, 0.001));
      expect(values[4], closeTo(4, 0.001));
    });

    test('produces a sampler', () {
      final double Function(double)? fit = varietyMovingAverageTrendline(
        const <(double, double)>[(0, 1), (1, 2), (2, 3), (3, 4)],
        2,
      );
      expect(fit, isNotNull);
      expect(fit!(3), closeTo(3.5, 0.001));
    });

    test('returns null for a non-positive period', () {
      expect(
        varietyMovingAverage(const <double>[1, 2, 3], 0)
            .every((double? v) => v == null),
        isTrue,
      );
    });
  });
}

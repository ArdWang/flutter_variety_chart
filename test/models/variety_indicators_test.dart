import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../test_helpers.dart';

void main() {
  group('simple moving average', () {
    test('trails the window', () {
      final List<VarietyChartData> values = simpleMovingAverage(rising(), 3);
      expect(values[0].y, isNull);
      expect(values[1].y, isNull);
      expect(values[2].y, closeTo(2, 0.001));
      expect(values[9].y, closeTo(9, 0.001));
    });

    test('keeps the original x values', () {
      final List<VarietyChartData> values = simpleMovingAverage(rising(), 3);
      expect(values.last.x, 9);
    });

    test('returns nothing for a non-positive period', () {
      expect(simpleMovingAverage(rising(), 0), isEmpty);
    });
  });

  group('exponential moving average', () {
    test('seeds from the first full window', () {
      final List<VarietyChartData> values =
          exponentialMovingAverage(rising(), 3);
      expect(values[1].y, isNull);
      expect(values[2].y, closeTo(2, 0.001));
      // A linear ramp makes the EMA lag by a constant, so the last reading
      // sits one step behind the source value of 10.
      expect(values[9].y!, closeTo(9, 0.001));
      expect(values[9].y!, lessThan(10));
    });

    test('returns nothing for empty input', () {
      expect(exponentialMovingAverage(const <VarietyChartData>[], 3), isEmpty);
    });
  });

  group('weighted and triangular moving averages', () {
    test('weights the newest sample most', () {
      final List<VarietyChartData> values = weightedMovingAverage(rising(), 3);
      expect(values[2].y, closeTo((1 * 1 + 2 * 2 + 3 * 3) / 6, 0.001));
    });

    test('triangular average is smoother than the simple one', () {
      final List<VarietyChartData> simple = simpleMovingAverage(rising(), 4);
      final List<VarietyChartData> triangular =
          triangularMovingAverage(rising(), 4);
      expect(triangular.last.y, isNotNull);
      expect((triangular.last.y! - simple.last.y!).abs(), lessThan(2));
    });
  });

  group('oscillators', () {
    test('relative strength index saturates on a rising series', () {
      final List<VarietyChartData> values = relativeStrengthIndex(rising(), 5);
      expect(values.last.y, closeTo(100, 0.001));
    });

    test('relative strength index returns nothing when the window is too long',
        () {
      expect(relativeStrengthIndex(rising(), 50), isEmpty);
    });

    test('momentum equals the difference across the window', () {
      final List<VarietyChartData> values = momentum(rising(), 3);
      expect(values[0].y, isNull);
      expect(values[3].y, closeTo(3, 0.001));
    });

    test('rate of change is expressed in percent', () {
      final List<VarietyChartData> values = rateOfChange(rising(), 2);
      expect(values[2].y, closeTo((3 - 1) / 1 * 100, 0.001));
    });
  });

  group('average true range', () {
    test('averages the true range over the window', () {
      final List<VarietyChartData> values = averageTrueRange(
        const <VarietyChartData>[
          VarietyChartData(0, 0, high: 12, low: 8),
          VarietyChartData(1, 0, high: 15, low: 10),
          VarietyChartData(2, 0, high: 16, low: 11),
        ],
        2,
      );
      expect(values.last.y, isNotNull);
      expect(values.last.y!, greaterThan(0));
    });
  });

  group('composite indicators', () {
    test('Bollinger bands bracket the middle band', () {
      final VarietyBollingerBandsIndicator indicator =
          VarietyBollingerBandsIndicator(
        source: VarietyLineSeries(data: rising()),
        period: 5,
      );
      final List<VarietyLineSeries> series = indicator.build();
      expect(series.length, 3);
      expect(series[0].name, 'Bollinger Upper');
      expect(series[0].data.last.y!, greaterThan(series[1].data.last.y!));
      expect(series[2].data.last.y!, lessThan(series[1].data.last.y!));
    });

    test('MACD exposes a histogram, a line and a signal', () {
      final VarietyMacdIndicator indicator =
          VarietyMacdIndicator(source: VarietyLineSeries(data: rising()));
      final List<VarietySeries> series = indicator.build();
      expect(series.length, 3);
      expect(series.first, isA<VarietyColumnSeries>());
      expect(series[1].name, 'MACD Line');
      expect(series[2].name, 'Signal');
    });

    test('stochastic oscillator emits %K and %D', () {
      final VarietyStochasticIndicator indicator = VarietyStochasticIndicator(
        source: VarietyLineSeries(data: rising()),
        period: 3,
      );
      final List<VarietyLineSeries> series = indicator.build();
      expect(series.length, 2);
      expect(series[0].name, '%K');
      expect(series[1].name, '%D');
      expect(series[0].data.last.y, isNotNull);
    });
  });

  group('indicator series', () {
    test('exposes the source series it was built from', () {
      final VarietyLineSeries source = VarietyLineSeries(data: rising());
      final VarietySmaIndicator indicator =
          VarietySmaIndicator(source: source, period: 3);
      expect(indicator.source, same(source));
      expect(indicator.period, 3);
      expect(indicator.data.length, rising().length);
    });
  });

  group('a derived reading is not the bar it came from', () {
    // The candle points this library is given put the price in `close` and
    // leave `y` at zero, which is what the series tests use too.
    List<VarietyChartData> bars() => List<VarietyChartData>.generate(
          30,
          (int i) => VarietyChartData(
            i,
            0,
            close: 100 + i.toDouble(),
            high: 102 + i.toDouble(),
            low: 98 + i.toDouble(),
          ),
        );

    test('an indicator output drops the closing price it read', () {
      final List<VarietyChartData> values = simpleMovingAverage(bars(), 4);
      expect(values.last.y, isNotNull);
      // Keeping the close behind would let the next pass mistake this point
      // for the bar it was computed from.
      expect(values.last.close, isNull);
    });

    test('the triangular average averages its own first pass', () {
      // Alternating closes, because a straight ramp makes an average of
      // averages land almost exactly where a single wider average does, and the
      // two would then be indistinguishable whichever pass read what.
      final List<VarietyChartData> source = <VarietyChartData>[
        for (int i = 0; i < 30; i++)
          VarietyChartData(i, 0, close: i.isEven ? 100 : 200),
      ];
      // Stated as the definition: a simple average of three, then of three
      // again over the result. The first pass is stripped of the close it came
      // from, which is exactly what the library has to be doing internally for
      // the two to agree.
      final List<VarietyChartData> expected = simpleMovingAverage(
        simpleMovingAverage(source, 3)
            .map((VarietyChartData p) => VarietyChartData(p.x, p.y))
            .toList(growable: false),
        3,
      );
      final List<VarietyChartData> actual = triangularMovingAverage(source, 6);
      expect(actual.last.y, isNotNull);
      expect(actual.last.y!, closeTo(expected.last.y!, 0.001));
      // Reading the closes in the second pass turned the result back into the
      // first pass, one window wide instead of two.
      final List<VarietyChartData> firstPass = simpleMovingAverage(source, 3);
      expect((actual.last.y! - firstPass.last.y!).abs(), greaterThan(1));
    });

    test('the stochastic %D stays on the scale of %K', () {
      final VarietyStochasticIndicator indicator = VarietyStochasticIndicator(
        source: VarietyLineSeries(data: bars()),
        period: 5,
      );
      final List<VarietyLineSeries> series = indicator.build();
      final double k = series[0].data.last.y!;
      final double d = series[1].data.last.y!;
      expect(k, inInclusiveRange(0, 100));
      // Built from the closes, %D came out at price level instead — roughly a
      // hundred times the reading it is supposed to smooth.
      expect(d, inInclusiveRange(0, 100));
      expect((d - k).abs(), lessThan(50));
    });

    test('the MACD signal line stays in the range of the MACD line', () {
      final VarietyMacdIndicator indicator =
          VarietyMacdIndicator(source: VarietyLineSeries(data: bars()));
      final List<VarietySeries> series = indicator.build();
      final double macd = series[1].data.last.y!;
      final double signal = series[2].data.last.y!;
      // A linear ramp of prices puts both lines within a few points of zero,
      // nowhere near the hundred the closes themselves sit at.
      expect(macd.abs(), lessThan(20));
      expect(signal.abs(), lessThan(20));
    });

    test('a gap in the input leaves the window undefined', () {
      final List<VarietyChartData> values =
          simpleMovingAverage(triangularMovingAverage(bars(), 6), 3);
      expect(values.first.y, isNull);
      // The warm-up of the inner pass has to travel outwards rather than being
      // counted as a zero, which would bend the start of the line upwards.
      expect(values[4].y, isNull);
      expect(values.last.y, isNotNull);
    });
  });
}

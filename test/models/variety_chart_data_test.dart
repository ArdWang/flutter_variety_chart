import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

void main() {
  group('VarietyChartData', () {
    test('reads the primary value', () {
      const VarietyChartData point = VarietyChartData('Jan', 32);
      expect(point.x, 'Jan');
      expect(point.y, 32);
      expect(point.isEmpty, isFalse);
    });

    test('falls back across the financial accessors', () {
      const VarietyChartData point = VarietyChartData(1, 42);
      expect(point.openValue, 42);
      expect(point.closeValue, 42);
      expect(point.highValue, 42);
      expect(point.lowValue, 42);
      expect(point.magnitude, 42);
    });

    test('prefers explicit financial values', () {
      const VarietyChartData point = VarietyChartData(
        1,
        40,
        open: 38,
        high: 44,
        low: 36,
        close: 42,
        size: 12,
      );
      expect(point.openValue, 38);
      expect(point.highValue, 44);
      expect(point.lowValue, 36);
      expect(point.closeValue, 42);
      expect(point.magnitude, 12);
    });

    test('uses secondaryY as a range bound', () {
      const VarietyChartData point =
          VarietyChartData('Jan', 20, secondaryY: 60);
      expect(point.highValue, 60);
      expect(point.lowValue, 20);
    });

    test('copyWith replaces only the supplied fields', () {
      const VarietyChartData point =
          VarietyChartData('Jan', 32, label: 'January');
      final VarietyChartData copy = point.copyWith(y: 40);
      expect(copy.y, 40);
      expect(copy.x, 'Jan');
      expect(copy.label, 'January');
    });
  });

  group('VarietyAxis', () {
    test('defaults to sensible values', () {
      const VarietyAxis axis = VarietyAxis();
      expect(axis.showGridLines, isTrue);
      expect(axis.showLabels, isTrue);
      expect(axis.type, isNull);
      expect(axis.logBase, 10);
    });

    test('copyWith preserves unspecified fields', () {
      const VarietyAxis axis =
          VarietyAxis(title: 'Value', showGridLines: false);
      final VarietyAxis copy = axis.copyWith(minimum: 5);
      expect(copy.minimum, 5);
      expect(copy.title, 'Value');
      expect(copy.showGridLines, isFalse);
    });
  });

  group('VarietySeries', () {
    test('reports its stacking state', () {
      final VarietyColumnSeries plain =
          VarietyColumnSeries(data: const <VarietyChartData>[]);
      final VarietyColumnSeries stacked = VarietyColumnSeries(
        data: const <VarietyChartData>[],
        stackMode: VarietyStackingMode.normal,
      );
      final VarietyColumnSeries percent = VarietyColumnSeries(
        data: const <VarietyChartData>[],
        stackMode: VarietyStackingMode.percent100,
      );
      expect(plain.isStacked, isFalse);
      expect(stacked.isStacked, isTrue);
      expect(stacked.isPercentStacked, isFalse);
      expect(percent.isPercentStacked, isTrue);
    });

    test('marks circular and banded series', () {
      expect(VarietyPieSeries(data: const <VarietyChartData>[]).isCircular,
          isTrue);
      expect(VarietyDoughnutSeries(data: const <VarietyChartData>[]).isCircular,
          isTrue);
      expect(
          VarietyRadialBarSeries(data: const <VarietyChartData>[]).isCircular,
          isTrue);
      expect(VarietyColumnSeries(data: const <VarietyChartData>[]).isCircular,
          isFalse);
      expect(VarietyColumnSeries(data: const <VarietyChartData>[]).isBanded,
          isTrue);
      expect(VarietyRangeAreaSeries(data: const <VarietyChartData>[]).isRange,
          isTrue);
    });
  });

  group('palette', () {
    test('exposes at least eight distinct colours', () {
      expect(varietyDefaultPalette.length, greaterThanOrEqualTo(8));
      expect(
          varietyDefaultPalette.toSet().length, varietyDefaultPalette.length);
    });
  });

  group('VarietyChartTheme', () {
    testWidgets('adapts to the ambient brightness',
        (WidgetTester tester) async {
      VarietyChartTheme? light;
      VarietyChartTheme? dark;
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              Theme(
                data: ThemeData(brightness: Brightness.light),
                child: Builder(
                  builder: (BuildContext context) {
                    light = VarietyChartTheme.of(context);
                    return const SizedBox();
                  },
                ),
              ),
              Theme(
                data: ThemeData(brightness: Brightness.dark),
                child: Builder(
                  builder: (BuildContext context) {
                    dark = VarietyChartTheme.of(context);
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      );
      expect(
          light!.tooltipBackgroundColor, isNot(dark!.tooltipBackgroundColor));
      expect(light!.gridLineColor, isNot(dark!.gridLineColor));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

void main() {
  group('varietyFormatNumber', () {
    test('trims whole numbers', () {
      expect(varietyFormatNumber(12), '12');
      expect(varietyFormatNumber(-7), '-7');
    });

    test('trims trailing decimals', () {
      expect(varietyFormatNumber(12.5), '12.5');
      expect(varietyFormatNumber(12.25), '12.25');
      expect(varietyFormatNumber(12.0), '12');
    });

    test('applies magnitude suffixes', () {
      expect(varietyFormatNumber(1500), '1.5K');
      expect(varietyFormatNumber(2500000), '2.5M');
      expect(varietyFormatNumber(3000000000), '3B');
    });

    test('handles non-finite input', () {
      expect(varietyFormatNumber(double.nan), '-');
      expect(varietyFormatNumber(double.infinity), '-');
    });

    test('formats a fixed number of decimals', () {
      expect(varietyFormatFixed(3.14159, 2), '3.14');
    });
  });

  group('varietyFormatDateTime', () {
    final DateTime value = DateTime(2026, 3, 9, 14, 5, 7);

    test('formats common patterns', () {
      expect(varietyFormatDateTime(value, 'yyyy-MM-dd'), '2026-03-09');
      expect(varietyFormatDateTime(value, 'dd MMM yyyy'), '09 Mar 2026');
      expect(varietyFormatDateTime(value, 'HH:mm:ss'), '14:05:07');
      expect(varietyFormatDateTime(value, 'MMM'), 'Mar');
      expect(varietyFormatDateTime(value, 'MMMM'), 'March');
    });

    test('supports twelve hour tokens', () {
      expect(varietyFormatDateTime(value, 'hh:mm a'), '02:05 PM');
    });

    test('keeps quoted literals', () {
      expect(varietyFormatDateTime(value, "yyyy'年'MM'月'"), '2026年03月');
    });

    test('picks an auto pattern from the span', () {
      expect(varietyAutoDateFormat(const Duration(days: 3000)), 'yyyy');
      expect(varietyAutoDateFormat(const Duration(days: 400)), 'MMM yyyy');
      expect(varietyAutoDateFormat(const Duration(days: 30)), 'dd MMM');
      expect(varietyAutoDateFormat(const Duration(hours: 2)), 'HH:mm');
    });
  });

  group('varietyFormatValue', () {
    test('dispatches on the runtime type', () {
      expect(varietyFormatValue(1200), '1.2K');
      expect(varietyFormatValue(DateTime(2026, 3, 9), datePattern: 'yyyy'), '2026');
      expect(varietyFormatValue('Jan'), 'Jan');
    });
  });
}

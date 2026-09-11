/// Formatting helpers used by axis ticks, data labels and tooltips.
///
/// The package deliberately avoids a dependency on `intl`; the pattern based
/// formatter below covers the tokens that chart axes actually need.
library;

const List<String> _monthShort = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _monthLong = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _dayShort = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun'
];

const List<String> _dayLong = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Formats a numeric value into a compact caption.
///
/// Whole numbers lose their decimal part, fractions keep at most two decimals
/// with trailing zeros removed, and large magnitudes use a `K`/`M`/`B` suffix.
String varietyFormatNumber(double value) {
  if (value.isNaN || value.isInfinite) {
    return '-';
  }
  final double magnitude = value.abs();
  if (magnitude >= 1000000000) {
    return '${_trim(value / 1000000000)}B';
  }
  if (magnitude >= 1000000) {
    return '${_trim(value / 1000000)}M';
  }
  if (magnitude >= 1000) {
    return '${_trim(value / 1000)}K';
  }
  return _trim(value);
}

/// Formats [value] with exactly [fractionDigits] decimals, keeping separators out.
String varietyFormatFixed(double value, int fractionDigits) =>
    value.isFinite ? value.toStringAsFixed(fractionDigits) : '-';

/// Formats [value] using a simplified numeric pattern.
///
/// Supported syntax: digit placeholders (`0` and `#`) after an optional decimal
/// point, a comma for grouping, and a trailing `%` which multiplies the value by
/// one hundred. The number of `0` placeholders determines how many fraction
/// digits are always shown.
String varietyFormatPattern(double value, String pattern) {
  if (!value.isFinite) {
    return '-';
  }
  final bool percent = pattern.endsWith('%');
  final bool grouped = pattern.contains(',');
  final int dot = pattern.indexOf('.');
  int fractionDigits = 0;
  int mandatoryDigits = 0;
  if (dot >= 0) {
    final String fraction = pattern.substring(dot + 1).replaceAll('%', '');
    fractionDigits = fraction.replaceAll(RegExp(r'[^0#]'), '').length;
    mandatoryDigits = fraction.replaceAll(RegExp(r'[^0]'), '').length;
  }
  final double scaled = percent ? value * 100 : value;
  String text = scaled.toStringAsFixed(fractionDigits);
  if (fractionDigits > 0 && mandatoryDigits < fractionDigits) {
    while (text.contains('.') &&
        text.endsWith('0') &&
        text.split('.').last.length > mandatoryDigits) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
  }
  if (grouped) {
    final bool negative = text.startsWith('-');
    final String body = negative ? text.substring(1) : text;
    final List<String> parts = body.split('.');
    final String digits = parts.first;
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    text =
        '${negative ? '-' : ''}$buffer${parts.length > 1 ? '.${parts[1]}' : ''}';
  }
  return percent ? '$text%' : text;
}

/// Formats a [DateTime] using a subset of the common pattern tokens.
///
/// Supported tokens: `yyyy`, `yy`, `MMMM`, `MMM`, `MM`, `M`, `dd`, `d`,
/// `EEEE`, `EEE`, `HH`, `H`, `hh`, `h`, `mm`, `m`, `ss`, `s`, `SSS` and `a`.
/// Any other character is copied verbatim. Wrap literal text in single quotes.
String varietyFormatDateTime(DateTime value, String pattern) {
  final StringBuffer buffer = StringBuffer();
  int index = 0;
  while (index < pattern.length) {
    final String current = pattern[index];
    if (current == "'") {
      final int end = pattern.indexOf("'", index + 1);
      if (end < 0) {
        buffer.write(pattern.substring(index + 1));
        break;
      }
      buffer.write(pattern.substring(index + 1, end));
      index = end + 1;
      continue;
    }
    final String? token = _matchToken(pattern, index);
    if (token == null) {
      buffer.write(current);
      index++;
      continue;
    }
    buffer.write(_applyToken(value, token));
    index += token.length;
  }
  return buffer.toString();
}

String? _matchToken(String pattern, int index) {
  const List<String> tokens = <String>[
    'yyyy',
    'yy',
    'MMMM',
    'MMM',
    'MM',
    'M',
    'EEEE',
    'EEE',
    'dd',
    'd',
    'HH',
    'H',
    'hh',
    'h',
    'mm',
    'm',
    'ss',
    's',
    'SSS',
    'a',
  ];
  for (final String token in tokens) {
    if (pattern.startsWith(token, index)) {
      return token;
    }
  }
  return null;
}

String _applyToken(DateTime value, String token) {
  switch (token) {
    case 'yyyy':
      return value.year.toString().padLeft(4, '0');
    case 'yy':
      return (value.year % 100).toString().padLeft(2, '0');
    case 'MMMM':
      return _monthLong[value.month - 1];
    case 'MMM':
      return _monthShort[value.month - 1];
    case 'MM':
      return value.month.toString().padLeft(2, '0');
    case 'M':
      return value.month.toString();
    case 'EEEE':
      return _dayLong[value.weekday - 1];
    case 'EEE':
      return _dayShort[value.weekday - 1];
    case 'dd':
      return value.day.toString().padLeft(2, '0');
    case 'd':
      return value.day.toString();
    case 'HH':
      return value.hour.toString().padLeft(2, '0');
    case 'H':
      return value.hour.toString();
    case 'hh':
      final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
      return hour.toString().padLeft(2, '0');
    case 'h':
      final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
      return hour.toString();
    case 'mm':
      return value.minute.toString().padLeft(2, '0');
    case 'm':
      return value.minute.toString();
    case 'ss':
      return value.second.toString().padLeft(2, '0');
    case 's':
      return value.second.toString();
    case 'SSS':
      return value.millisecond.toString().padLeft(3, '0');
    case 'a':
      return value.hour < 12 ? 'AM' : 'PM';
    default:
      return token;
  }
}

/// Picks a sensible date pattern for a visible time span.
String varietyAutoDateFormat(Duration span) {
  if (span.inDays > 365 * 4) {
    return 'yyyy';
  }
  if (span.inDays > 120) {
    return 'MMM yyyy';
  }
  if (span.inDays > 3) {
    return 'dd MMM';
  }
  if (span.inHours > 6) {
    return 'HH:mm';
  }
  if (span.inMinutes > 3) {
    return 'HH:mm';
  }
  return 'HH:mm:ss';
}

/// Formats an arbitrary axis value, dispatching on its runtime type.
String varietyFormatValue(dynamic value, {String? datePattern}) {
  if (value is DateTime) {
    return varietyFormatDateTime(value, datePattern ?? 'dd MMM');
  }
  if (value is num) {
    return varietyFormatNumber(value.toDouble());
  }
  return value?.toString() ?? '';
}

String _trim(double value) {
  if (value == value.roundToDouble() && value.abs() < 1e15) {
    return value.toInt().toString();
  }
  String text = value.toStringAsFixed(2);
  if (text.contains('.')) {
    text = text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return text;
}

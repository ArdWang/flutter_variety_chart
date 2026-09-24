import 'package:flutter_variety_chart/flutter_variety_chart.dart';

/// Long-form monthly revenue samples used across the demo pages.
const List<VarietyChartData> monthlyRevenue = <VarietyChartData>[
  VarietyChartData('Jan', 32, label: 'January'),
  VarietyChartData('Feb', 48, label: 'February'),
  VarietyChartData('Mar', 41, label: 'March'),
  VarietyChartData('Apr', 55, label: 'April'),
  VarietyChartData('May', 49, label: 'May'),
  VarietyChartData('Jun', 63, label: 'June'),
  VarietyChartData('Jul', 58, label: 'July'),
  VarietyChartData('Aug', 72, label: 'August'),
];

/// The same months expressed as a target line.
const List<VarietyChartData> monthlyTarget = <VarietyChartData>[
  VarietyChartData('Jan', 40, label: 'January'),
  VarietyChartData('Feb', 42, label: 'February'),
  VarietyChartData('Mar', 45, label: 'March'),
  VarietyChartData('Apr', 47, label: 'April'),
  VarietyChartData('May', 50, label: 'May'),
  VarietyChartData('Jun', 52, label: 'June'),
  VarietyChartData('Jul', 55, label: 'July'),
  VarietyChartData('Aug', 57, label: 'August'),
];

/// Indoor temperature, in degrees Celsius, for the two-axis demo. It shares its
/// categories with [indoorHumidity] so both series land on the same slots.
const List<VarietyChartData> indoorTemperature = <VarietyChartData>[
  VarietyChartData('Jan', 21.4),
  VarietyChartData('Feb', 22.1),
  VarietyChartData('Mar', 23.6),
  VarietyChartData('Apr', 25.2),
  VarietyChartData('May', 26.8),
  VarietyChartData('Jun', 28.1),
  VarietyChartData('Jul', 28.9),
  VarietyChartData('Aug', 28.2),
];

/// Relative humidity, in percent, for the two-axis demo.
///
/// The values sit in a band that has nothing to do with the temperature scale,
/// which is exactly why the pair needs its own axis instead of sharing one.
const List<VarietyChartData> indoorHumidity = <VarietyChartData>[
  VarietyChartData('Jan', 62),
  VarietyChartData('Feb', 58),
  VarietyChartData('Mar', 52),
  VarietyChartData('Apr', 46),
  VarietyChartData('May', 41),
  VarietyChartData('Jun', 38),
  VarietyChartData('Jul', 36),
  VarietyChartData('Aug', 39),
];

/// A typical conversion funnel.
const List<VarietyChartData> funnelStages = <VarietyChartData>[
  VarietyChartData('Visited', 1200, label: 'Visited'),
  VarietyChartData('Signed up', 820, label: 'Signed up'),
  VarietyChartData('Activated', 460, label: 'Activated'),
  VarietyChartData('Subscribed', 190, label: 'Subscribed'),
];

/// Traffic split used by the circular demos.
const List<VarietyChartData> trafficSources = <VarietyChartData>[
  VarietyChartData('Search', 52),
  VarietyChartData('Direct', 24),
  VarietyChartData('Social', 15),
  VarietyChartData('Referral', 6),
  VarietyChartData('Other', 3),
];

/// Stacked composition across a few quarters.
const List<VarietyChartData> stackedMobile = <VarietyChartData>[
  VarietyChartData('Q1', 42),
  VarietyChartData('Q2', 48),
  VarietyChartData('Q3', 55),
  VarietyChartData('Q4', 61),
];

/// Second slice of the stacked composition.
const List<VarietyChartData> stackedDesktop = <VarietyChartData>[
  VarietyChartData('Q1', 38),
  VarietyChartData('Q2', 36),
  VarietyChartData('Q3', 33),
  VarietyChartData('Q4', 31),
];

/// Third slice of the stacked composition.
const List<VarietyChartData> stackedTablet = <VarietyChartData>[
  VarietyChartData('Q1', 20),
  VarietyChartData('Q2', 16),
  VarietyChartData('Q3', 12),
  VarietyChartData('Q4', 8),
];

/// Scatter samples with a visible upward trend.
const List<VarietyChartData> scatterSamples = <VarietyChartData>[
  VarietyChartData(1, 12),
  VarietyChartData(2, 19),
  VarietyChartData(3, 15),
  VarietyChartData(4, 27),
  VarietyChartData(5, 31),
  VarietyChartData(6, 26),
  VarietyChartData(7, 38),
  VarietyChartData(8, 44),
  VarietyChartData(9, 41),
  VarietyChartData(10, 52),
];

/// Bubble samples whose magnitude drives the marker radius.
const List<VarietyChartData> bubbleSamples = <VarietyChartData>[
  VarietyChartData(1, 20, size: 12),
  VarietyChartData(2, 34, size: 40),
  VarietyChartData(3, 28, size: 22),
  VarietyChartData(4, 46, size: 68),
  VarietyChartData(5, 39, size: 34),
  VarietyChartData(6, 58, size: 90),
];

/// Raw samples used to build a histogram.
List<VarietyChartData> histogramSamples() {
  const List<double> values = <double>[
    12,
    14,
    15,
    16,
    16,
    17,
    18,
    18,
    19,
    19,
    20,
    20,
    20,
    21,
    21,
    21,
    22,
    22,
    22,
    23,
    23,
    23,
    24,
    24,
    25,
    25,
    26,
    27,
    28,
    30,
    33,
    35,
    36,
    38,
    41,
    44,
    47,
    51,
    55,
    60,
  ];
  return List<VarietyChartData>.generate(
    values.length,
    (int i) => VarietyChartData(i, values[i]),
  );
}

/// Daily close prices used by the financial demos.
const List<VarietyChartData> dailyPrices = <VarietyChartData>[
  VarietyChartData(1, 0, open: 118, high: 129, low: 115, close: 126),
  VarietyChartData(2, 0, open: 126, high: 131, low: 121, close: 123),
  VarietyChartData(3, 0, open: 123, high: 128, low: 119, close: 127),
  VarietyChartData(4, 0, open: 127, high: 134, low: 125, close: 132),
  VarietyChartData(5, 0, open: 132, high: 136, low: 128, close: 130),
  VarietyChartData(6, 0, open: 130, high: 133, low: 122, close: 124),
  VarietyChartData(7, 0, open: 124, high: 127, low: 118, close: 121),
  VarietyChartData(8, 0, open: 121, high: 126, low: 117, close: 125),
  VarietyChartData(9, 0, open: 125, high: 131, low: 123, close: 129),
  VarietyChartData(10, 0, open: 129, high: 137, low: 128, close: 135),
];

/// Day-by-day load samples for the date-time axis demo.
List<VarietyChartData> loadByDay() {
  final DateTime start = DateTime(2026, 1, 1);
  const List<double> values = <double>[
    42,
    45,
    51,
    48,
    39,
    36,
    44,
    58,
    61,
    55,
    49,
    47,
    52,
    66,
    71,
    64,
    58,
    55,
    60,
    68,
  ];
  return List<VarietyChartData>.generate(
    values.length,
    (int i) => VarietyChartData(start.add(Duration(days: i)), values[i]),
  );
}

/// Quarter-over-quarter deltas for the waterfall demo.
const List<VarietyChartData> waterfallDeltas = <VarietyChartData>[
  VarietyChartData('Start', 120),
  VarietyChartData('New', 46),
  VarietyChartData('Expansion', 28),
  VarietyChartData('Churn', -34),
  VarietyChartData('Downgrade', -18),
];

/// A single flat series used by the sparkline demo.
const List<double> sparklineValues = <double>[
  4,
  6,
  5,
  8,
  7,
  11,
  9,
  12,
  15,
  13,
  16,
  19,
];

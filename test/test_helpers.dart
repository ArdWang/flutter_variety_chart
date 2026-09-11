import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

/// Wraps [child] so it has a bounded size inside a widget test surface.
Widget host(Widget child, {double width = 400, double height = 300}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: width, height: height, child: child)),
    ),
  );
}

/// A short category data set shared by the tests.
List<VarietyChartData> monthly() => const <VarietyChartData>[
      VarietyChartData('Jan', 32, label: 'Jan'),
      VarietyChartData('Feb', 48, label: 'Feb'),
      VarietyChartData('Mar', 41, label: 'Mar'),
      VarietyChartData('Apr', 55, label: 'Apr'),
    ];

/// A rising numeric series used by the indicator and trendline tests.
List<VarietyChartData> rising() => List<VarietyChartData>.generate(
      10,
      (int i) => VarietyChartData(i, i.toDouble() + 1),
    );

/// The standard plot rectangle used by the geometry tests.
const Rect defaultPlotRect = Rect.fromLTWH(40, 10, 320, 220);

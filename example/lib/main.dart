import 'package:flutter/material.dart';

import 'pages/advanced_page.dart';
import 'pages/annotations_page.dart';
import 'pages/circular_page.dart';
import 'pages/column_bar_page.dart';
import 'pages/financial_page.dart';
import 'pages/indicators_page.dart';
import 'pages/interaction_page.dart';
import 'pages/line_area_page.dart';
import 'pages/misc_page.dart';
import 'pages/spark_page.dart';
import 'pages/stacked_page.dart';

void main() => runApp(const VarietyChartExampleApp());

/// The example application root.
class VarietyChartExampleApp extends StatelessWidget {
  /// Creates the example application.
  const VarietyChartExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Variety Chart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F6FE0)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F6FE0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// A catalogue of every demo shipped with the example.
class HomePage extends StatelessWidget {
  /// Creates the home page.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_Demo> demos = <_Demo>[
      _Demo(
        'Line and area',
        'Straight, curved, stepped, fast and range variants',
        Icons.show_chart,
        (BuildContext context) => const LineAreaPage(),
      ),
      _Demo(
        'Column and bar',
        'Grouped columns, bars, scatter and bubble',
        Icons.bar_chart,
        (BuildContext context) => const ColumnBarPage(),
      ),
      _Demo(
        'Stacking',
        'Normal and 100% stacked columns, bars, lines and areas',
        Icons.stacked_bar_chart,
        (BuildContext context) => const StackedPage(),
      ),
      _Demo(
        'Circular',
        'Pie, doughnut and radial bar',
        Icons.pie_chart,
        (BuildContext context) => const CircularPage(),
      ),
      _Demo(
        'Financial',
        'Candlestick, hi-lo, hi-lo-open-close and waterfall',
        Icons.candlestick_chart,
        (BuildContext context) => const FinancialPage(),
      ),
      _Demo(
        'Indicators',
        'SMA, EMA, RSI, Bollinger, MACD and stochastic',
        Icons.analytics,
        (BuildContext context) => const IndicatorsPage(),
      ),
      _Demo(
        'Interactions',
        'Tooltip, trackball, crosshair, zoom, pan and selection',
        Icons.touch_app,
        (BuildContext context) => const InteractionPage(),
      ),
      _Demo(
        'Annotations and plot bands',
        'Text, lines, shapes and axis bands',
        Icons.edit_note,
        (BuildContext context) => const AnnotationsPage(),
      ),
      _Demo(
        'Advanced',
        'Box plots, error bars, empty points, label handling and callbacks',
        Icons.auto_graph,
        (BuildContext context) => const AdvancedPage(),
      ),
      _Demo(
        'Spark charts',
        'Line, area, bar and win/loss micro charts',
        Icons.insights,
        (BuildContext context) => const SparkPage(),
      ),
      _Demo(
        'Funnel, pyramid and sparkline',
        'Funnel, pyramid and compact charts',
        Icons.filter_alt,
        (BuildContext context) => const MiscPage(),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Variety Chart')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: demos.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final _Demo demo = demos[index];
          return ListTile(
            leading: CircleAvatar(child: Icon(demo.icon)),
            title: Text(demo.title),
            subtitle: Text(demo.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: demo.builder),
            ),
          );
        },
      ),
    );
  }
}

class _Demo {
  const _Demo(this.title, this.subtitle, this.icon, this.builder);

  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
}

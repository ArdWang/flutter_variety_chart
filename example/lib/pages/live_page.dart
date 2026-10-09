import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../data/sample_data.dart';
import '../widgets/demo_scaffold.dart';

/// Demonstrates driving a chart from outside it: two charts sharing one
/// window, a series fed a reading a second, a marker that picks itself out and
/// a caption that answers a tap.
class LivePage extends StatefulWidget {
  /// Creates the live data demo page.
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  // One controller, handed to both charts, is what keeps them on the same
  // sessions: a pinch on either one moves both.
  final VarietyRangeController _sharedRange = VarietyRangeController();
  final VarietyCartesianChartController _live =
      VarietyCartesianChartController();
  final List<VarietyChartData> _readings = <VarietyChartData>[];
  Timer? _timer;
  int _tick = 0;
  String? _tappedCaption;
  final math.Random _random = math.Random(7);

  /// The prices anchored on real dates, so the shared axis has instant to work
  /// with rather than an index.
  List<VarietyChartData> get _datedPrices {
    final DateTime start = DateTime(2026, 1, 1);
    return dailyPrices
        .map(
          (VarietyChartData point) => VarietyChartData(
            start.add(Duration(days: point.x as int)),
            0,
            open: point.open,
            high: point.high,
            low: point.low,
            close: point.close,
          ),
        )
        .toList(growable: false);
  }

  /// The same sessions as columns, for the chart beneath the prices.
  List<VarietyChartData> get _volumes {
    final DateTime start = DateTime(2026, 1, 1);
    return dailyPrices
        .map(
          (VarietyChartData point) => VarietyChartData(
            start.add(Duration(days: point.x as int)),
            // The day's spread, which is what a volume column under a candle
            // usually stands in for here.
            ((point.high ?? 0) - (point.low ?? 0)).abs() + 4,
          ),
        )
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 24; i++) {
      _readings.add(_reading(i));
    }
    _tick = 24;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      _readings.add(_reading(_tick));
      _tick++;
      // The point goes into the list the chart was built with, and this is all
      // the chart needs to be told: no rebuild, no replayed animation, and the
      // window the reader is looking at is kept.
      _live.updateDataSource();
    });
  }

  VarietyChartData _reading(int i) => VarietyChartData(
        i,
        20 + 12 * math.sin(i / 3) + _random.nextDouble() * 3,
      );

  @override
  void dispose() {
    _timer?.cancel();
    _sharedRange.dispose();
    _live.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Driving a chart',
      description:
          'A chart need not be rebuilt to change: a shared range controller '
          'keeps two charts on one window, and new points go straight into the '
          'list the series was built with. Below that, a marker that picks '
          'itself out and a caption that answers a tap.',
      children: <Widget>[
        ChartCard(
          title: 'Two charts, one window',
          height: 320,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 200,
                child: VarietyCartesianChart(
                  primaryXAxis: VarietyAxis(
                    type: VarietyAxisType.dateTime,
                    rangeController: _sharedRange,
                  ),
                  primaryYAxis: const VarietyAxis(
                    opposedPosition: true,
                    title: 'Price',
                  ),
                  series: <VarietySeries>[
                    VarietyCandleSeries(name: 'ACME', data: _datedPrices),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 88,
                child: VarietyCartesianChart(
                  primaryXAxis: VarietyAxis(
                    type: VarietyAxisType.dateTime,
                    rangeController: _sharedRange,
                  ),
                  primaryYAxis: const VarietyAxis(
                    opposedPosition: true,
                    title: 'Volume',
                  ),
                  series: <VarietySeries>[
                    VarietyColumnSeries(name: 'Volume', data: _volumes),
                  ],
                ),
              ),
            ],
          ),
        ),
        _WindowButtons(sharedRange: _sharedRange),
        ChartCard(
          title: 'A reading a second',
          height: 260,
          child: VarietyCartesianChart(
            controller: _live,
            // A live chart is a chart whose series are replaced every frame,
            // and a line that draws itself from nothing at that rate never
            // settles: realtime animation once, then updates in place.
            animationType: VarietyAnimationType.realtime,
            primaryXAxis: const VarietyAxis(
              type: VarietyAxisType.numeric,
              // Twenty points in view, and the window follows the newest one,
              // which is what a monitor wants.
              autoScrollingDelta: 20,
            ),
            primaryYAxis: const VarietyAxis(minimum: 0, maximum: 40),
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'Sensor',
                data: _readings,
                markerSettings: const VarietyMarkerSettings(
                    isVisible: true, height: 5, width: 5),
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'A marker that picks itself out',
          height: 260,
          child: VarietyCartesianChart(
            onMarkerRender: (VarietyMarkerRenderDetails details) {
              // Every reading above 27 degrees is drawn as a red square; the
              // rest take whatever the series asked for. Answering `null`
              // would drop a marker entirely.
              final double value = details.point.y ?? 0;
              if (value < 27) {
                return details;
              }
              return details.copyWith(
                color: const Color(0xFFD32F2F),
                size: 11,
                shape: VarietyMarkerShape.square,
              );
            },
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'Temperature',
                color: const Color(0xFF3F6FE0),
                data: indoorTemperature,
                markerSettings: const VarietyMarkerSettings(
                  isVisible: true,
                  height: 7,
                  width: 7,
                ),
              ),
            ],
          ),
        ),
        ChartCard(
          title: 'A caption that answers a tap',
          height: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: VarietyCartesianChart(
                  onDataLabelTapped: (VarietyDataLabelTapDetails details) {
                    setState(() {
                      _tappedCaption =
                          '${details.series.name} · ${details.text} (point ${details.pointIndex})';
                    });
                  },
                  series: <VarietySeries>[
                    VarietyColumnSeries(
                      name: 'Revenue',
                      data: monthlyRevenue,
                      dataLabelSettings: const VarietyDataLabelSettings(
                        isVisible: true,
                        position: VarietyLabelPosition.outside,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  _tappedCaption ?? 'Tap a caption above.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Moves the window both charts are showing, so the shared range can be seen
/// working without having to pinch a desktop window.
class _WindowButtons extends StatelessWidget {
  const _WindowButtons({required this.sharedRange});

  final VarietyRangeController sharedRange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        children: <Widget>[
          FilledButton.tonal(
            onPressed: () => sharedRange.setRange(null, null),
            child: const Text('Whole year'),
          ),
          FilledButton.tonal(
            onPressed: () => sharedRange.setDateTimeRange(
              DateTime(2026, 1, 5),
              DateTime(2026, 1, 20),
            ),
            child: const Text('Early January'),
          ),
          FilledButton.tonal(
            onPressed: () => sharedRange.setDateTimeRange(
              DateTime(2026, 1, 20),
              null,
            ),
            child: const Text('From the 20th on'),
          ),
        ],
      ),
    );
  }
}

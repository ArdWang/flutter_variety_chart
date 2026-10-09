import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_variety_chart/src/painters/variety_cartesian_painter.dart';

import '../test_helpers.dart';

/// Everything the painter needs answered, drawn so nothing of the frame's own
/// furniture competes with the markers being counted.
const VarietyChartTheme painterTheme = VarietyChartTheme(
  gridLineColor: Color(0x00FFFFFF),
  axisLineColor: Color(0x00FFFFFF),
  labelColor: Color(0xFF000000),
  tooltipBackgroundColor: Color(0xFF32323A),
  tooltipTextColor: Color(0xFFFFFFFF),
  markerBorderColor: Color(0xFFFFFFFF),
);

/// Four readings with their markers on and their captions showing.
const List<VarietyChartData> readings = <VarietyChartData>[
  VarietyChartData(0, 4),
  VarietyChartData(1, 8),
  VarietyChartData(2, 2),
  VarietyChartData(3, 6),
];

const Color seriesColor = Color(0xFF3F6FE0);

VarietyAxis silentAxis({bool category = true}) => VarietyAxis(
      type: category ? VarietyAxisType.category : VarietyAxisType.numeric,
      showLabels: false,
      showTicks: false,
      showGridLines: false,
      showAxisLine: false,
    );

VarietyCartesianGeometry marksUp({
  bool labels = false,
  List<VarietySeries>? series,
}) =>
    VarietyCartesianGeometry(
      series: series ??
          <VarietySeries>[
            VarietyLineSeries(
              name: 'n',
              color: seriesColor,
              data: readings,
              markerSettings: const VarietyMarkerSettings(isVisible: true),
              dataLabelSettings: VarietyDataLabelSettings(
                isVisible: labels,
                color: const Color(0xFF000000),
              ),
            ),
          ],
      xAxis: silentAxis(category: false),
      yAxis: silentAxis(category: false),
      plotRect: const Rect.fromLTWH(0, 0, 300, 200),
      progress: 1,
    );

/// Every circle and square the painter drew, so a marker can be told apart
/// from the rest of what a frame draws.
class _RecordingCanvas implements ui.Canvas {
  final List<double> radii = <double>[];
  final List<Color> circles = <Color>[];
  final List<Rect> squares = <Rect>[];

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    radii.add(radius);
    circles.add(paint.color);
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    // Every marker is drawn square and centred, so only the extent tells it
    // apart from anything else a frame draws.
    squares.add(rect);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getSaveCount) {
      return 1;
    }
    if (invocation.memberName == #getDestinationClipBounds ||
        invocation.memberName == #getLocalClipBounds) {
      return Rect.zero;
    }
    return null;
  }
}

void main() {
  group('onMarkerRender', () {
    test('is asked once per point, and knows which point', () {
      final VarietyCartesianGeometry geometry = marksUp();
      final List<int> asked = <int>[];
      final VarietyCartesianPainter painter = VarietyCartesianPainter(
        geometry: geometry,
        theme: painterTheme,
        markerRenderer: (VarietyMarkerRenderDetails details) {
          asked.add(details.pointIndex);
          return details;
        },
      );
      painter.paint(_RecordingCanvas(), const Size(300, 200));
      // One marker per reading, in the order the points come, and every one of
      // them able to name the point it stands for.
      expect(asked, <int>[0, 1, 2, 3]);
    });

    test('hands the point and its series to the callback', () {
      final VarietyCartesianGeometry geometry = marksUp();
      VarietyMarkerRenderDetails? seen;
      final VarietyCartesianPainter painter = VarietyCartesianPainter(
        geometry: geometry,
        theme: painterTheme,
        markerRenderer: (VarietyMarkerRenderDetails details) {
          seen ??= details;
          return details;
        },
      );
      painter.paint(_RecordingCanvas(), const Size(300, 200));
      expect(seen, isNotNull);
      expect(seen!.seriesIndex, 0);
      expect(seen!.pointIndex, 0);
      expect(seen!.point.y, 4);
      expect(seen!.series.name, 'n');
      expect(seen!.size, greaterThan(0));
    });

    test('a colour it answers with is the colour drawn', () {
      final VarietyCartesianGeometry geometry = marksUp();
      final _RecordingCanvas canvas = _RecordingCanvas();
      const Color asked = Color(0xFFFF0000);
      VarietyCartesianPainter(
        geometry: geometry,
        theme: painterTheme,
        markerRenderer: (VarietyMarkerRenderDetails details) =>
            details.copyWith(color: asked),
      ).paint(canvas, const Size(300, 200));

      expect(canvas.circles.length, 4);
      expect(canvas.circles.every((Color c) => c == asked), isTrue);
    });

    test('answering null draws no marker at all', () {
      final VarietyCartesianGeometry geometry = marksUp();
      final _RecordingCanvas canvas = _RecordingCanvas();
      VarietyCartesianPainter(
        geometry: geometry,
        theme: painterTheme,
        // Only the second reading is marked, which is how one point of a line
        // calls attention to itself.
        markerRenderer: (VarietyMarkerRenderDetails details) =>
            details.pointIndex == 1 ? details : null,
      ).paint(canvas, const Size(300, 200));

      expect(canvas.circles.length, 1);
    });

    test('a size it answers with is the size drawn', () {
      final VarietyCartesianGeometry geometry = marksUp();
      final _RecordingCanvas baseline = _RecordingCanvas();
      VarietyCartesianPainter(
        geometry: geometry,
        theme: painterTheme,
      ).paint(baseline, const Size(300, 200));

      final _RecordingCanvas grown = _RecordingCanvas();
      VarietyCartesianPainter(
        geometry: geometry,
        theme: painterTheme,
        markerRenderer: (VarietyMarkerRenderDetails details) =>
            details.copyWith(size: details.size * 3),
      ).paint(grown, const Size(300, 200));

      expect(baseline.radii.first, greaterThan(0));
      expect(grown.radii.first, closeTo(baseline.radii.first * 3, 1e-6));
    });

    test('a shape it answers with is the shape drawn', () {
      final VarietyCartesianGeometry geometry = marksUp();
      final _RecordingCanvas canvas = _RecordingCanvas();
      VarietyCartesianPainter(
        geometry: geometry,
        theme: painterTheme,
        markerRenderer: (VarietyMarkerRenderDetails details) =>
            details.copyWith(shape: VarietyMarkerShape.square),
      ).paint(canvas, const Size(300, 200));

      // Nothing round was drawn, and every reading drew a square instead.
      expect(canvas.circles, isEmpty);
      expect(canvas.squares.length, 4);
    });

    test('the marks of a box plot are left to themselves', () {
      final VarietyCartesianGeometry geometry = VarietyCartesianGeometry(
        series: <VarietySeries>[
          VarietyBoxAndWhiskerSeries(
            name: 'box',
            color: seriesColor,
            data: readings,
            showMean: true,
          ),
        ],
        xAxis: silentAxis(),
        yAxis: silentAxis(category: false),
        plotRect: const Rect.fromLTWH(0, 0, 300, 200),
        progress: 1,
      );
      int asked = 0;
      VarietyCartesianPainter(
        geometry: geometry,
        theme: painterTheme,
        markerRenderer: (VarietyMarkerRenderDetails details) {
          asked++;
          return details;
        },
      ).paint(_RecordingCanvas(), const Size(300, 200));

      // A mean is not a reading. It answers to its own options, which is why
      // it is never asked what colour to be.
      expect(asked, 0);
    });

    test('costs nothing when nobody answers', () {
      final VarietyCartesianGeometry geometry = marksUp();
      final _RecordingCanvas canvas = _RecordingCanvas();
      VarietyCartesianPainter(
        geometry: geometry,
        theme: painterTheme,
      ).paint(canvas, const Size(300, 200));
      expect(canvas.circles.length, 4);
      for (final Color colour in canvas.circles) {
        expect(colour, seriesColor);
      }
    });
  });

  group('onDataLabelTapped', () {
    testWidgets('answers with the point the caption names', (
      WidgetTester tester,
    ) async {
      VarietyDataLabelTapDetails? tapped;
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            enableAnimation: false,
            onDataLabelTapped: (VarietyDataLabelTapDetails details) {
              tapped = details;
            },
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'n',
                data: readings,
                dataLabelSettings: const VarietyDataLabelSettings(
                  isVisible: true,
                  color: Color(0xFF000000),
                ),
              ),
            ],
          ),
        ),
      );

      VarietyCartesianPainter painter = painterOf(tester);
      expect(painter.dataLabelHits, isNotEmpty);
      painter.dataLabelHits!.sort(
        (VarietyDataLabelHit a, VarietyDataLabelHit b) =>
            a.pointIndex.compareTo(b.pointIndex),
      );
      final VarietyDataLabelHit second = painter.dataLabelHits![1];

      await tester.tapAt(
        tester.getTopLeft(canvasFinder) + second.rect.center,
      );
      await tester.pump();
      expect(tapped, isNotNull);
      expect(tapped!.pointIndex, 1);
      expect(tapped!.point.y, 8);
      expect(tapped!.text, second.text);
      expect(tapped!.series.name, 'n');
    });

    testWidgets('is left unanswered when the tap is elsewhere', (
      WidgetTester tester,
    ) async {
      int calls = 0;
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            enableAnimation: false,
            onDataLabelTapped: (VarietyDataLabelTapDetails _) {
              calls++;
            },
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'n',
                data: readings,
                dataLabelSettings: const VarietyDataLabelSettings(
                  isVisible: true,
                  color: Color(0xFF000000),
                ),
              ),
            ],
          ),
        ),
      );
      final VarietyCartesianPainter painter = painterOf(tester);
      expect(painter.dataLabelHits, isNotEmpty);
      // The corner of the plot, which no caption sits on: a tap there has to
      // carry on to the points rather than be swallowed as a caption.
      await tester.tapAt(tester.getTopLeft(canvasFinder) + const Offset(4, 4));
      await tester.pump();
      expect(calls, 0);
    });

    testWidgets('records nothing when nobody is listening', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            enableAnimation: false,
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'n',
                data: readings,
                dataLabelSettings: const VarietyDataLabelSettings(
                  isVisible: true,
                  color: Color(0xFF000000),
                ),
              ),
            ],
          ),
        ),
      );
      expect(painterOf(tester).dataLabelHits, isNull);
    });
  });
}

/// The canvas that drew the plot, out of the several the chart builds.
Finder get canvasFinder => find
    .byWidgetPredicate((Widget widget) =>
        widget is CustomPaint && widget.painter is VarietyCartesianPainter)
    .first;

VarietyCartesianPainter painterOf(WidgetTester tester) =>
    (tester.widget(canvasFinder) as CustomPaint).painter!
        as VarietyCartesianPainter;

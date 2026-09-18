import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_variety_chart/src/painters/variety_cartesian_painter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

const Rect plotRect = Rect.fromLTWH(60, 10, 300, 200);
const Size surface = Size(400, 300);

const VarietyChartTheme theme = VarietyChartTheme(
  gridLineColor: Color(0xFFCCCCCC),
  axisLineColor: Color(0xFF000000),
  labelColor: Color(0xFF333333),
  tooltipBackgroundColor: Color(0xFF32323A),
  tooltipTextColor: Color(0xFFFFFFFF),
  markerBorderColor: Color(0xFFFFFFFF),
);

VarietyCartesianGeometry geometryOf(
  List<VarietySeries> series, {
  VarietyAxis? xAxis,
  VarietyAxis? yAxis,
}) {
  return VarietyCartesianGeometry(
    series: series,
    xAxis: xAxis ?? const VarietyAxis(type: VarietyAxisType.category),
    yAxis: yAxis ?? const VarietyAxis(type: VarietyAxisType.numeric),
    plotRect: plotRect,
    progress: 1,
  );
}

Future<ByteData> raster(
  VarietyCartesianGeometry geometry, {
  bool showElements = true,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  VarietyCartesianPainter(
    geometry: geometry,
    theme: theme,
    showElements: showElements,
  ).paint(Canvas(recorder), surface);
  final ui.Image image = await recorder
      .endRecording()
      .toImage(surface.width.toInt(), surface.height.toInt());
  final ByteData bytes =
      (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  image.dispose();
  return bytes;
}

(int, int, int, int) pixel(ByteData bytes, int x, int y) {
  final int offset = (y * surface.width.toInt() + x) * 4;
  return (
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
    bytes.getUint8(offset + 3),
  );
}

/// The painter the chart handed its canvas, so the resolved state can be read
/// back without scraping pixels.
VarietyCartesianPainter canvasPainter(WidgetTester tester) {
  return tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(VarietyCartesianChart),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((CustomPaint paint) => paint.painter)
      .whereType<VarietyCartesianPainter>()
      .first;
}

void main() {
  group('empty point markers', () {
    List<VarietyChartData> hole() => const <VarietyChartData>[
          VarietyChartData('A', 10),
          VarietyChartData('B', 20),
          VarietyChartData('C', null, isEmpty: true),
          VarietyChartData('D', 40),
        ];

    List<VarietyMarker> markersOf({required bool showMarker}) {
      final VarietyCartesianGeometry geometry = geometryOf(<VarietySeries>[
        VarietyScatterSeries(
          data: hole(),
          emptyPointSettings: VarietyEmptyPointSettings(
            mode: VarietyEmptyPointMode.average,
            showMarker: showMarker,
          ),
        ),
      ]);
      return geometry.elements
          .whereType<VarietyMarkersElement>()
          .expand((VarietyMarkersElement element) => element.markers)
          .toList();
    }

    test('a substituted point gets no marker by default', () {
      // Three real points and one interpolated reading between them.
      expect(markersOf(showMarker: false).length, 3);
    });

    test('showMarker puts a marker on the substituted point', () {
      expect(markersOf(showMarker: true).length, 4);
    });
  });

  group('cumulative data labels', () {
    List<VarietySeries> stacked({required bool cumulative}) => <VarietySeries>[
          VarietyColumnSeries(
            name: 'A',
            data: const <VarietyChartData>[
              VarietyChartData('x', 10),
              VarietyChartData('y', 20),
            ],
            stackMode: VarietyStackingMode.normal,
          ),
          VarietyColumnSeries(
            name: 'B',
            data: const <VarietyChartData>[
              VarietyChartData('x', 5),
              VarietyChartData('y', 15),
            ],
            stackMode: VarietyStackingMode.normal,
            dataLabelSettings: VarietyDataLabelSettings(
              isVisible: true,
              showCumulativeTotal: cumulative,
            ),
          ),
        ];

    String labelOf(VarietyCartesianGeometry geometry, int seriesIndex) {
      final VarietyLabelsElement element = geometry.elements
          .whereType<VarietyLabelsElement>()
          .firstWhere((VarietyLabelsElement e) => e.seriesIndex == seriesIndex);
      return element.labels.first.text;
    }

    test('a stacked label reports its own step by default', () {
      final VarietyCartesianGeometry geometry =
          geometryOf(stacked(cumulative: false));
      expect(labelOf(geometry, 1), varietyFormatNumber(5));
    });

    test('showCumulativeTotal reports the running total', () {
      final VarietyCartesianGeometry geometry =
          geometryOf(stacked(cumulative: true));
      expect(labelOf(geometry, 1), varietyFormatNumber(15));
    });
  });

  group('data label connector lines', () {
    test('the connector settings reach the drawn label', () {
      final VarietyCartesianGeometry geometry = geometryOf(<VarietySeries>[
        VarietyLineSeries(
          data: monthly(),
          dataLabelSettings: const VarietyDataLabelSettings(
            isVisible: true,
            connectorLineSettings: VarietyConnectorLineSettings(
              length: 18,
              width: 2.5,
              type: VarietyConnectorType.bezier,
            ),
          ),
        ),
      ]);
      final VarietyLabelItem item = geometry.elements
          .whereType<VarietyLabelsElement>()
          .first
          .labels
          .first;
      expect(item.connectorLength, 18);
      expect(item.connectorWidth, 2.5);
      expect(item.connectorType, VarietyConnectorType.bezier);
      // A connector with no colour of its own takes the series colour, which
      // is what keeps the line reading as part of the series.
      expect(item.connectorColor, isNotNull);
    });

    test('no settings draws no connector', () {
      final VarietyCartesianGeometry geometry = geometryOf(<VarietySeries>[
        VarietyLineSeries(
          data: monthly(),
          dataLabelSettings: const VarietyDataLabelSettings(isVisible: true),
        ),
      ]);
      expect(
        geometry.elements
            .whereType<VarietyLabelsElement>()
            .first
            .labels
            .first
            .connectorLength,
        0,
      );
    });
  });

  group('error bar direction', () {
    List<VarietySegment> stems(VarietyErrorBarDirection direction) {
      final VarietyCartesianGeometry geometry = geometryOf(<VarietySeries>[
        VarietyLineSeries(
          data: const <VarietyChartData>[
            VarietyChartData(0, 10),
            VarietyChartData(1, 20),
            VarietyChartData(2, 30),
          ],
          errorBar: VarietyErrorBarSeries(
            data: const <VarietyChartData>[],
            direction: direction,
            mode: VarietyErrorBarMode.vertical,
            errorValue: 4,
          ),
        ),
      ], xAxis: const VarietyAxis(type: VarietyAxisType.numeric));
      return geometry.elements
          .whereType<VarietySegmentsElement>()
          .expand((VarietySegmentsElement element) => element.segments)
          .where((VarietySegment segment) => segment.from.dx == segment.to.dx)
          .toList();
    }

    test('both reaches either side of the point', () {
      final List<VarietySegment> both = stems(VarietyErrorBarDirection.both);
      expect(both.length, 3);
      expect(both.first.from.dy, lessThan(both.first.to.dy));
    });

    test('plus reaches upwards only', () {
      final VarietyCartesianGeometry geometry = geometryOf(<VarietySeries>[
        VarietyLineSeries(
          data: const <VarietyChartData>[
            VarietyChartData(0, 10),
            VarietyChartData(1, 20),
            VarietyChartData(2, 30),
          ],
          errorBar: const VarietyErrorBarSeries(
            data: <VarietyChartData>[],
            direction: VarietyErrorBarDirection.plus,
            mode: VarietyErrorBarMode.vertical,
            errorValue: 4,
          ),
        ),
      ], xAxis: const VarietyAxis(type: VarietyAxisType.numeric));
      final VarietySegment stem = geometry.elements
          .whereType<VarietySegmentsElement>()
          .expand((VarietySegmentsElement element) => element.segments)
          .where((VarietySegment segment) => segment.from.dx == segment.to.dx)
          .first;
      // The lower end of a one sided whisker sits exactly on its point.
      expect(
        stem.to.dy,
        moreOrLessEquals(geometry.pointPositions[0][0].dy, epsilon: 0.001),
      );
    });

    test('minus reaches downwards only', () {
      final List<VarietySegment> minus = stems(VarietyErrorBarDirection.minus);
      expect(minus.length, 3);
      final VarietyCartesianGeometry geometry = geometryOf(<VarietySeries>[
        VarietyLineSeries(
          data: const <VarietyChartData>[
            VarietyChartData(0, 10),
            VarietyChartData(1, 20),
            VarietyChartData(2, 30),
          ],
          errorBar: const VarietyErrorBarSeries(
            data: <VarietyChartData>[],
            direction: VarietyErrorBarDirection.minus,
            mode: VarietyErrorBarMode.vertical,
            errorValue: 4,
          ),
        ),
      ], xAxis: const VarietyAxis(type: VarietyAxisType.numeric));
      expect(
        minus.first.from.dy,
        moreOrLessEquals(geometry.pointPositions[0][0].dy, epsilon: 0.001),
      );
    });
  });

  group('plot bands', () {
    const VarietyAxis bareY = VarietyAxis(
      type: VarietyAxisType.numeric,
      showGridLines: false,
      showLabels: false,
      showTicks: false,
    );

    VarietyAxis bandedAxis(VarietyPlotBand band) => VarietyAxis(
          type: VarietyAxisType.numeric,
          showGridLines: false,
          showLabels: false,
          showTicks: false,
          plotBands: <VarietyPlotBand>[band],
        );

    test('associatedAxis bounds a band vertically', () async {
      final ByteData bytes = await raster(
        geometryOf(
          <VarietySeries>[
            VarietyLineSeries(
              data: const <VarietyChartData>[
                VarietyChartData(0, 0),
                VarietyChartData(1, 100),
              ],
            ),
          ],
          xAxis: bandedAxis(
            const VarietyPlotBand(
              start: 0.4,
              end: 0.6,
              color: Color(0xFFFF0000),
              opacity: 1,
              associatedAxisStart: 0,
              associatedAxisEnd: 50,
            ),
          ),
          yAxis: bareY,
        ),
        showElements: false,
      );
      // The band stops at the middle of the value range: the lower half of the
      // stripe is red, the upper half is left alone.
      expect(pixel(bytes, 200, 150).$1, greaterThan(200));
      expect(pixel(bytes, 200, 60).$1, lessThan(60));
    });

    test('a gradient replaces the flat colour', () async {
      final ByteData bytes = await raster(
        geometryOf(
          <VarietySeries>[
            VarietyLineSeries(
              data: const <VarietyChartData>[
                VarietyChartData(0, 0),
                VarietyChartData(1, 100),
              ],
            ),
          ],
          xAxis: bandedAxis(
            const VarietyPlotBand(
              start: 0.4,
              end: 0.6,
              opacity: 1,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0xFF0000FF), Color(0xFFFF0000)],
              ),
            ),
          ),
          yAxis: bareY,
        ),
        showElements: false,
      );
      final (int, int, int, int) top = pixel(bytes, 200, 20);
      final (int, int, int, int) bottom = pixel(bytes, 200, 200);
      // Blue at the top, red at the bottom.
      expect(top.$3, greaterThan(top.$1));
      expect(bottom.$1, greaterThan(bottom.$3));
    });

    test('a dash array outlines the band instead of filling its edge',
        () async {
      Future<int> outlineInk({required List<double> dash}) async {
        final ByteData bytes = await raster(
          geometryOf(
            <VarietySeries>[
              VarietyLineSeries(
                data: const <VarietyChartData>[
                  VarietyChartData(0, 0),
                  VarietyChartData(1, 100),
                ],
              ),
            ],
            xAxis: bandedAxis(
              VarietyPlotBand(
                start: 0.4,
                end: 0.6,
                color: const Color(0xFF000000),
                opacity: 0,
                associatedAxisStart: 0,
                associatedAxisEnd: 100,
                dashArray: dash,
              ),
            ),
            yAxis: bareY,
          ),
          showElements: false,
        );
        int count = 0;
        // Kept clear of the x axis line at the bottom of the plot, which is
        // inked whatever the band does.
        for (int x = 100; x < 300; x++) {
          for (int y = 10; y <= 200; y++) {
            if (pixel(bytes, x, y).$4 > 40) {
              count++;
            }
          }
        }
        return count;
      }

      final int solid = await outlineInk(dash: <double>[]);
      final int dashed = await outlineInk(dash: <double>[6, 4]);
      // With no dash array and a fully transparent fill there is nothing to
      // draw at all; a dash array turns the outline on.
      final int dashedSparse = await outlineInk(dash: <double>[2, 30]);
      expect(solid, 0);
      expect(dashed, greaterThan(0));
      expect(dashedSparse, lessThan(dashed));
    });
  });

  group('chart palette', () {
    test('a chart palette colours the first series', () {
      final VarietyCartesianGeometry geometry = VarietyCartesianGeometry(
        series: <VarietySeries>[VarietyLineSeries(data: monthly())],
        xAxis: const VarietyAxis(type: VarietyAxisType.category),
        yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
        plotRect: plotRect,
        progress: 1,
        palette: const <Color>[Color(0xFF00FF00)],
      );
      expect(geometry.seriesColors.first, const Color(0xFF00FF00));
      final VarietyPathElement path =
          geometry.elements.whereType<VarietyPathElement>().first;
      expect(path.strokeColor, const Color(0xFF00FF00));
    });
  });

  group('selection', () {
    testWidgets('initialSelectedDataIndexes opens with a selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'Revenue',
                showMarkers: true,
                data: monthly(),
                initialSelectedDataIndexes: const <int>[1, 2],
              ),
            ],
            selectionBehavior: const VarietySelectionBehavior(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final VarietyCartesianPainter painter = canvasPainter(tester);
      expect(
        painter.selected.map((VarietyHitResult hit) => hit.pointIndex).toList(),
        <int>[1, 2],
      );
    });

    testWidgets('toggling off keeps a selection through a second tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyLineSeries(
                  name: 'Revenue', showMarkers: true, data: monthly()),
            ],
            selectionBehavior:
                const VarietySelectionBehavior(toggleSelection: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Rect canvasRect =
          tester.getRect(find.byType(VarietyCartesianChart));
      final Offset spot = canvasRect.topLeft + const Offset(88.0, 221.0);
      await tester.tapAt(spot);
      await tester.pumpAndSettle();
      expect(canvasPainter(tester).selected.length, 1);
      await tester.tapAt(spot);
      await tester.pumpAndSettle();
      expect(canvasPainter(tester).selected.length, 1);
    });

    testWidgets('toggling on clears a selection through a second tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyLineSeries(
                  name: 'Revenue', showMarkers: true, data: monthly()),
            ],
            selectionBehavior: const VarietySelectionBehavior(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Rect canvasRect =
          tester.getRect(find.byType(VarietyCartesianChart));
      final Offset spot = canvasRect.topLeft + const Offset(88.0, 221.0);
      await tester.tapAt(spot);
      await tester.pumpAndSettle();
      expect(canvasPainter(tester).selected.length, 1);
      await tester.tapAt(spot);
      await tester.pumpAndSettle();
      expect(canvasPainter(tester).selected, isEmpty);
    });
  });

  group('animation delay', () {
    testWidgets('a delayed series follows the one before it',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            animationDuration: const Duration(seconds: 1),
            series: <VarietySeries>[
              VarietyLineSeries(name: 'A', data: monthly()),
              VarietyLineSeries(
                name: 'B',
                data: monthly(),
                animationDelay: const Duration(milliseconds: 500),
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final List<double>? progress =
          canvasPainter(tester).geometry.seriesProgress;
      expect(progress, isNotNull);
      // Half a second into a one and a half second timeline the delayed series
      // has not started rising yet.
      expect(progress![1], 0);
      expect(progress[0], greaterThan(0));
    });
  });

  group('tooltip', () {
    testWidgets('a pointer tooltip follows the pointer rather than the point',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyLineSeries(
                  name: 'Revenue', showMarkers: true, data: monthly()),
            ],
            tooltipBehavior: const VarietyTooltipBehavior(
              tooltipPosition: VarietyTooltipPosition.pointer,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Rect canvasRect =
          tester.getRect(find.byType(VarietyCartesianChart));
      final TestGesture gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: canvasRect.topLeft);
      addTearDown(gesture.removePointer);
      await tester.pump();
      // Deliberately away from the marker at index 0, which sits low left.
      final Offset hover = canvasRect.topLeft + const Offset(200.0, 80.0);
      await gesture.moveTo(hover);
      await tester.pumpAndSettle();
      final VarietyAnchoredCard card =
          tester.widget<VarietyAnchoredCard>(find.byType(VarietyAnchoredCard));
      expect(card.anchor.dx, moreOrLessEquals(200.0, epsilon: 0.5));
      expect(card.anchor.dy, moreOrLessEquals(80.0, epsilon: 0.5));
    });

    testWidgets('a header caption leads the card', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyLineSeries(
                  name: 'Revenue', showMarkers: true, data: monthly()),
            ],
            tooltipBehavior: const VarietyTooltipBehavior(
              header: 'Quarter to date',
              showDuration: Duration.zero,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Rect canvasRect =
          tester.getRect(find.byType(VarietyCartesianChart));
      await tester.tapAt(canvasRect.topLeft + const Offset(88.0, 221.0));
      await tester.pumpAndSettle();
      expect(find.text('Quarter to date'), findsOneWidget);
    });
  });

  group('legend', () {
    test('auto picks a side from the shape of the box', () {
      expect(
        VarietyLegend.resolvePosition(
          VarietyLegendPosition.auto,
          const Size(400, 300),
        ),
        VarietyLegendPosition.right,
      );
      expect(
        VarietyLegend.resolvePosition(
          VarietyLegendPosition.auto,
          const Size(300, 400),
        ),
        VarietyLegendPosition.bottom,
      );
      expect(
        VarietyLegend.resolvePosition(
          VarietyLegendPosition.top,
          const Size(300, 400),
        ),
        VarietyLegendPosition.top,
      );
    });

    testWidgets('a wide chart resolves auto to the right',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            legendPosition: VarietyLegendPosition.auto,
            series: <VarietySeries>[
              VarietyLineSeries(name: 'Revenue', data: monthly()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final VarietyLegend legend =
          tester.widget<VarietyLegend>(find.byType(VarietyLegend));
      expect(legend.position, VarietyLegendPosition.right);
    });

    /// The alpha of a pixel of the legend swatch, painted on its own.
    Future<int> swatchAlpha(
      WidgetTester tester,
      VarietySeries series,
      int x,
      int y,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: VarietyLegend(
                series: <VarietySeries>[series],
                settings: const VarietyLegendSettings(
                  iconType: VarietyLegendIconType.rectangle,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final CustomPaint paint = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(VarietyLegend),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      final Size size = paint.size;
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      paint.painter!.paint(Canvas(recorder), size);
      final ui.Picture picture = recorder.endRecording();
      // Rasterizing is real engine work and has to happen outside the fake
      // async zone a widget test installs, or the future never completes.
      final int alpha = (await tester.runAsync(() async {
        final ui.Image image =
            await picture.toImage(size.width.toInt(), size.height.toInt());
        final ByteData bytes =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        image.dispose();
        return bytes.getUint8((y * size.width.toInt() + x) * 4 + 3);
      }))!;
      picture.dispose();
      return alpha;
    }

    testWidgets('a series icon wins over the chart wide one',
        (WidgetTester tester) async {
      // The rectangle fills its box corner to corner; a circle leaves the
      // corners clear, so the corner pixel tells the two apart.
      final int round = await swatchAlpha(
        tester,
        VarietyLineSeries(
          name: 'Revenue',
          data: monthly(),
          legendIconType: VarietyLegendIconType.circle,
        ),
        1,
        1,
      );
      final int square = await swatchAlpha(
        tester,
        VarietyLineSeries(name: 'Revenue', data: monthly()),
        1,
        1,
      );
      // The corner is left completely clear by a circle and is covered, if
      // only partly by anti-aliasing, by a square.
      expect(round, 0);
      expect(square, greaterThan(40));
    });
  });

  group('plot area interaction', () {
    testWidgets('raw touch callbacks report every pointer position',
        (WidgetTester tester) async {
      final List<Offset> downs = <Offset>[];
      final List<Offset> ups = <Offset>[];
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyLineSeries(name: 'Revenue', data: monthly()),
            ],
            onChartTouchInteractionDown: (VarietyChartTouchArgs args) =>
                downs.add(args.position),
            onChartTouchInteractionUp: (VarietyChartTouchArgs args) =>
                ups.add(args.position),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Rect canvasRect =
          tester.getRect(find.byType(VarietyCartesianChart));
      // A corner of the plot, far from every point, so this is not the point
      // callback in disguise.
      final Offset spot = canvasRect.topLeft + const Offset(320.0, 40.0);
      await tester.tapAt(spot);
      await tester.pumpAndSettle();
      expect(downs.single.dx, moreOrLessEquals(320.0, epsilon: 0.5));
      expect(ups.single.dy, moreOrLessEquals(40.0, epsilon: 0.5));
    });

    testWidgets('a pan that runs out of data reports the end', (
      WidgetTester tester,
    ) async {
      final List<VarietySwipeDirection> swipes = <VarietySwipeDirection>[];
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyLineSeries(
                name: 'Revenue',
                data: List<VarietyChartData>.generate(
                  30,
                  (int i) => VarietyChartData('M$i', (i % 7).toDouble()),
                ),
              ),
            ],
            primaryXAxis: const VarietyAxis(
              type: VarietyAxisType.category,
              initialZoomFactor: 0.4,
            ),
            zoomPanBehavior: const VarietyZoomPanBehavior(),
            onPlotAreaSwipe: swipes.add,
            loadMoreIndicatorBuilder: (BuildContext context) =>
                const Text('loading'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The window opens on the oldest points, so dragging right has nowhere
      // to go: the pan runs out at the start. Two moves are needed because the
      // first one only establishes where the pan started from.
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(VarietyCartesianChart)),
      );
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(swipes, <VarietySwipeDirection>[VarietySwipeDirection.start]);
      expect(find.text('loading'), findsOneWidget);
    });

    testWidgets('a chart that is not zoomed does not report a swipe', (
      WidgetTester tester,
    ) async {
      final List<VarietySwipeDirection> swipes = <VarietySwipeDirection>[];
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            series: <VarietySeries>[
              VarietyLineSeries(name: 'Revenue', data: monthly()),
            ],
            zoomPanBehavior: const VarietyZoomPanBehavior(),
            onPlotAreaSwipe: swipes.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(VarietyCartesianChart),
        const Offset(160, 0),
      );
      await tester.pumpAndSettle();
      expect(swipes, isEmpty);
    });
  });
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
// The two painters are not part of the public surface, but every check below
// is about something a painter either draws or leaves out, so they are driven
// directly and the outlines they ask for are read back off a recording canvas.
import 'package:flutter_variety_chart/src/painters/variety_cartesian_painter.dart';
import 'package:flutter_variety_chart/src/painters/variety_circular_painter.dart';

import '../test_helpers.dart';

const VarietyChartTheme base = VarietyChartTheme(
  gridLineColor: Color(0xFFCCCCCC),
  axisLineColor: Color(0xFF000000),
  labelColor: Color(0xFF333333),
  tooltipBackgroundColor: Color(0xFF32323A),
  tooltipTextColor: Color(0xFFFFFFFF),
  markerBorderColor: Color(0xFFFFFFFF),
);

const Color red = Color(0xFFFF0000);

const Size surface = Size(400, 300);

/// A canvas that keeps what a painter asked it to draw.
///
/// None of the painters here read a value back out of the canvas, so answering
/// everything else with `null` still lets a paint run through and leaves the
/// calls behind to be checked.
class _Recorder implements ui.Canvas {
  final List<Paint> pathPaints = <Paint>[];
  final List<RRect> roundRects = <RRect>[];
  final List<(Offset, Offset)> lines = <(Offset, Offset)>[];
  final List<Paint> linePaints = <Paint>[];
  final List<ui.Paragraph> paragraphs = <ui.Paragraph>[];

  @override
  void drawPath(Path path, Paint paint) => pathPaints.add(paint);

  @override
  void drawRRect(RRect rrect, Paint paint) => roundRects.add(rrect);

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    lines.add((p1, p2));
    linePaints.add(paint);
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) =>
      paragraphs.add(paragraph);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Answering the calls that want a value keeps a future one from tripping
    // over a null.
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

/// A value axis that draws nothing of its own, for tests about another axis.
const VarietyAxis quietY = VarietyAxis(
  type: VarietyAxisType.numeric,
  showGridLines: false,
  showLabels: false,
  showTicks: false,
);

const VarietyAxis quietX = VarietyAxis(
  type: VarietyAxisType.numeric,
  showGridLines: false,
  showLabels: false,
  showTicks: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the track behind a radial bar', () {
    test('is filled but never outlined', () {
      final VarietyCircularGeometry geometry = VarietyCircularGeometry(
        series: <VarietySeries>[
          VarietyRadialBarSeries(
            name: 'Load',
            data: const <VarietyChartData>[
              VarietyChartData('CPU', 0.7),
              VarietyChartData('RAM', 0.5),
              VarietyChartData('Disk', 0.3),
            ],
          ),
        ],
        center: const Offset(100, 100),
        maxRadius: 80,
        progress: 1,
      );
      final _Recorder recorder = _Recorder();
      VarietyCircularPainter(geometry: geometry, theme: base)
          .paint(recorder, const Size(200, 200));

      final int readings =
          geometry.rings.where((VarietySlice s) => !s.isTrack).length;
      // Every reading gets a track of its own behind it, which is the shape
      // the rest of this test depends on.
      expect(readings, 3);
      expect(geometry.rings.length, readings * 2);

      final int outlines = recorder.pathPaints
          .where((Paint p) => p.style == PaintingStyle.stroke)
          .length;
      // A track used to be told apart from a reading by whether the point it
      // carried had a value, but the track reuses the reading's own point, so
      // the answer was always no and every track was outlined as well.
      expect(outlines, readings);
    });
  });

  group('themed tick marks', () {
    VarietyCartesianGeometry geometry() => VarietyCartesianGeometry(
          series: <VarietySeries>[
            VarietyLineSeries(
              data: const <VarietyChartData>[
                VarietyChartData(0, 10),
                VarietyChartData(5, 40),
                VarietyChartData(10, 20),
              ],
            ),
          ],
          xAxis: quietX,
          yAxis: const VarietyAxis(
            type: VarietyAxisType.numeric,
            showGridLines: false,
            showLabels: false,
            tickLength: 8,
          ),
          plotRect: defaultPlotRect,
          progress: 1,
        );

    int redLines(VarietyChartTheme theme) {
      final _Recorder recorder = _Recorder();
      VarietyCartesianPainter(geometry: geometry(), theme: theme)
          .paint(recorder, surface);
      return recorder.linePaints.where((Paint p) => p.color == red).length;
    }

    test('the theme names the colour of the major tick marks', () {
      // The theme carried the field, its getter and its copyWith entry, and no
      // painter ever asked for it, so both of these used to come out at zero.
      expect(redLines(base), 0);
      expect(
        redLines(base.copyWith(majorTickLineColor: red)),
        greaterThan(0),
      );
    });
  });

  group('the card behind a data label', () {
    Rect card(EdgeInsets margin) {
      final _Recorder recorder = _Recorder();
      VarietyElementRenderer(base).drawLabelCard(
        recorder,
        VarietyLabelItem(
          anchor: Offset.zero,
          text: '42',
          backgroundColor: const Color(0xFF204080),
          margin: margin,
        ),
        const Rect.fromLTWH(10, 20, 40, 16),
      );
      return recorder.roundRects.single.outerRect;
    }

    test('grows by the margin the caption was given', () {
      final Rect tight = card(EdgeInsets.zero);
      final Rect roomy = card(const EdgeInsets.all(6));
      expect(tight.width, closeTo(40, 0.001));
      expect(roomy.width - tight.width, closeTo(12, 0.001));
      expect(roomy.height - tight.height, closeTo(12, 0.001));
    });

    test('and the settings are what carry it down to the caption', () {
      final VarietyCartesianGeometry geometry = VarietyCartesianGeometry(
        series: <VarietySeries>[
          VarietyLineSeries(
            data: const <VarietyChartData>[
              VarietyChartData(0, 10),
              VarietyChartData(5, 40),
            ],
            dataLabelSettings: const VarietyDataLabelSettings(
              isVisible: true,
              margin: EdgeInsets.all(9),
            ),
          ),
        ],
        xAxis: quietX,
        yAxis: quietY,
        plotRect: defaultPlotRect,
        progress: 1,
      );
      final VarietyLabelsElement labels =
          geometry.elements.whereType<VarietyLabelsElement>().first;
      expect(labels.labels.first.margin, const EdgeInsets.all(9));
    });
  });

  group('multi level brackets', () {
    VarietyCartesianGeometry labelled(double overlap) =>
        VarietyCartesianGeometry(
          series: <VarietySeries>[VarietyColumnSeries(data: monthly())],
          xAxis: VarietyAxis(
            type: VarietyAxisType.category,
            multiLevelLabels: VarietyMultiLevelLabels(
              overlap: overlap,
              groups: const <VarietyLabelGroup>[
                VarietyLabelGroup(start: 0, end: 1, text: 'H1'),
                VarietyLabelGroup(start: 2, end: 3, text: 'H2'),
              ],
            ),
          ),
          yAxis: quietY,
          plotRect: defaultPlotRect,
          progress: 1,
        );

    /// The distance between the right edge of the first bracket and the left
    /// edge of the second. Zero means they meet, negative means they overlap.
    double gapBetween(double overlap) {
      final _Recorder recorder = _Recorder();
      VarietyCartesianPainter(geometry: labelled(overlap), theme: base)
          .paint(recorder, surface);
      final List<Rect> brackets = recorder.roundRects
          .map((RRect r) => r.outerRect)
          // Anything below the plot area is a bracket; the columns themselves
          // are square so they never land in this list.
          .where((Rect r) => r.top >= defaultPlotRect.bottom)
          .toList(growable: false);
      expect(brackets, hasLength(2));
      return brackets[1].left - brackets[0].right;
    }

    test('neighbours meet exactly by default', () {
      expect(gapBetween(0), closeTo(0, 0.001));
    });

    test('an overlap bleeds each bracket into the next', () {
      // The option was declared, documented as the distance neighbours may
      // share, and never read: both numbers used to be zero.
      expect(gapBetween(10), closeTo(-10, 0.001));
    });
  });

  group('a rule annotation', () {
    double coverage(VarietyAnnotationRegion region) {
      final VarietyCartesianGeometry geometry = VarietyCartesianGeometry(
        series: <VarietySeries>[
          VarietyLineSeries(
            data: const <VarietyChartData>[
              VarietyChartData(0, 10),
              VarietyChartData(5, 40),
              VarietyChartData(10, 20),
            ],
          ),
        ],
        xAxis: quietX,
        yAxis: quietY,
        plotRect: defaultPlotRect,
        progress: 1,
      );
      final _Recorder recorder = _Recorder();
      VarietyCartesianPainter(
        geometry: geometry,
        theme: base,
        annotations: <VarietyAnnotation>[
          VarietyAnnotation.horizontalLine(y: 30, region: region),
        ],
      ).paint(recorder, surface);

      final double y = geometry.pixelY(30);
      double widest = 0;
      for (final (Offset a, Offset b) in recorder.lines) {
        if ((a.dy - y).abs() > 0.01 || (b.dy - y).abs() > 0.01) {
          continue;
        }
        widest = math.max(widest, (b.dx - a.dx).abs());
      }
      return widest;
    }

    test('stays inside the plot area by default', () {
      expect(coverage(VarietyAnnotationRegion.plotArea),
          closeTo(defaultPlotRect.width, 0.001));
    });

    test('runs through the axis gutters when it asks to', () {
      // The region enum had no reader at all, so a rule always stopped at the
      // plot edge whatever it was asked for.
      expect(coverage(VarietyAnnotationRegion.chart),
          closeTo(surface.width, 0.001));
    });
  });

  group('the title of an extra value axis', () {
    VarietyCartesianGeometry dual() => VarietyCartesianGeometry(
          series: <VarietySeries>[
            VarietyColumnSeries(data: monthly()),
            VarietyLineSeries(
              name: 'Rate',
              yAxisName: 'rate',
              data: const <VarietyChartData>[
                VarietyChartData('Jan', 40),
                VarietyChartData('Feb', 60),
                VarietyChartData('Mar', 45),
                VarietyChartData('Apr', 70),
              ],
            ),
          ],
          xAxis: const VarietyAxis(type: VarietyAxisType.category),
          yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
          secondaryYAxes: const <VarietyAxis>[
            VarietyAxis(
              type: VarietyAxisType.numeric,
              name: 'rate',
              title: 'Humidity',
              minimum: 0,
              maximum: 100,
            ),
          ],
          plotRect: defaultPlotRect,
          progress: 1,
        );

    double tallestText(VarietyChartTheme theme) {
      final _Recorder recorder = _Recorder();
      VarietyCartesianPainter(geometry: dual(), theme: theme)
          .paint(recorder, surface);
      return recorder.paragraphs
          .map((ui.Paragraph paragraph) => paragraph.height)
          .reduce(math.max);
    }

    test('is painted in the style the theme names', () {
      // The captions themselves are left at the fallback size in both runs, so
      // the only text that can grow is the title.
      expect(
        tallestText(base.copyWith(
          axisTitleTextStyle: const TextStyle(fontSize: 40),
        )),
        greaterThan(tallestText(base)),
      );
    });
  });

  group('a series that starts hidden', () {
    /// How many paths reach the canvas with the second series visible or not.
    int pathsDrawn({required bool visible}) {
      const List<VarietyChartData> first = <VarietyChartData>[
        VarietyChartData(0, 4),
        VarietyChartData(1, 9),
        VarietyChartData(2, 6),
      ];
      const List<VarietyChartData> second = <VarietyChartData>[
        VarietyChartData(0, 8),
        VarietyChartData(1, 5),
        VarietyChartData(2, 9),
      ];
      final VarietyCartesianGeometry geometry = VarietyCartesianGeometry(
        series: <VarietySeries>[
          VarietyLineSeries(data: first),
          VarietyLineSeries(data: second, initialIsVisible: visible),
        ],
        xAxis: quietX,
        yAxis: const VarietyAxis(
          type: VarietyAxisType.numeric,
          showGridLines: false,
          showLabels: false,
          showTicks: false,
        ),
        plotRect: defaultPlotRect,
        progress: 1,
      );
      final _Recorder recorder = _Recorder();
      VarietyCartesianPainter(geometry: geometry, theme: base)
          .paint(recorder, surface);
      return recorder.pathPaints.length;
    }

    test('leaves it off the canvas', () {
      // The flag is read by the painter rather than by the geometry, so it only
      // shows in what reaches the canvas.
      expect(pathsDrawn(visible: false), lessThan(pathsDrawn(visible: true)));
    });
  });
}

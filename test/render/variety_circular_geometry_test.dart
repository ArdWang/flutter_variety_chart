import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// The painter is not part of the public surface, but this test has to drive it
// directly to check the outline it actually draws.
import 'package:flutter_variety_chart/src/painters/variety_circular_painter.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

const VarietyChartTheme _theme = VarietyChartTheme(
  gridLineColor: Color(0x1F000000),
  axisLineColor: Color(0x59000000),
  labelColor: Color(0xBF000000),
  tooltipBackgroundColor: Color(0xFF32323A),
  tooltipTextColor: Colors.white,
  markerBorderColor: Colors.white,
);

VarietyCircularGeometry buildCircular({
  required List<VarietySeries> series,
  double progress = 1,
  double maxRadius = 80,
}) {
  return VarietyCircularGeometry(
    series: series,
    center: const Offset(100, 100),
    maxRadius: maxRadius,
    progress: progress,
  );
}

void main() {
  group('pie', () {
    test('produces one slice per positive value and skips zeroes', () {
      final VarietyCircularGeometry geometry = buildCircular(
        series: <VarietySeries>[
          VarietyPieSeries(
            name: 'Share',
            data: const <VarietyChartData>[
              VarietyChartData('A', 30),
              VarietyChartData('B', 70),
              VarietyChartData('C', 0),
            ],
          ),
        ],
      );
      expect(geometry.slices.length, 2);
      expect(geometry.slices.first.sweepAngle,
          closeTo(0.3 * 2 * 3.141592653589793, 0.02));
    });

    test('collapses the sweep at progress zero', () {
      final VarietyCircularGeometry geometry = buildCircular(
        progress: 0,
        series: <VarietySeries>[
          VarietyPieSeries(
            data: const <VarietyChartData>[VarietyChartData('A', 50)],
          ),
        ],
      );
      expect(geometry.slices.single.sweepAngle, closeTo(0, 0.0001));
    });

    test('gives every slice the same sweep when equalSlices is set', () {
      final VarietyCircularGeometry geometry = buildCircular(
        series: <VarietySeries>[
          VarietyPieSeries(
            equalSlices: true,
            data: const <VarietyChartData>[
              VarietyChartData('A', 80),
              VarietyChartData('B', 10),
              VarietyChartData('C', 10),
            ],
          ),
        ],
      );
      final double first = geometry.slices[0].sweepAngle;
      expect(geometry.slices[1].sweepAngle, closeTo(first, 0.0001));
      expect(geometry.slices[2].sweepAngle, closeTo(first, 0.0001));
    });

    test('groups slices under the threshold', () {
      final VarietyCircularGeometry geometry = buildCircular(
        series: <VarietySeries>[
          VarietyPieSeries(
            groupSmallSlices: true,
            groupTo: 10,
            data: const <VarietyChartData>[
              VarietyChartData('A', 80),
              VarietyChartData('B', 5),
              VarietyChartData('C', 5),
              VarietyChartData('D', 10),
            ],
          ),
        ],
      );
      expect(geometry.slices.length, 3);
      expect(geometry.slices.last.point.label, 'Others');
      expect(geometry.slices.last.point.y, 10);
    });

    test('pushes an exploded slice away from the centre', () {
      final VarietyCircularGeometry geometry = buildCircular(
        series: <VarietySeries>[
          VarietyPieSeries(
            explodeIndex: 0,
            explodeOffset: 20,
            data: const <VarietyChartData>[
              VarietyChartData('A', 50),
              VarietyChartData('B', 50),
            ],
          ),
        ],
      );
      expect(geometry.slices.first.center, isNot(const Offset(100, 100)));
      expect(geometry.slices.last.center, const Offset(100, 100));
    });

    test('hit tests a point inside a slice', () {
      final VarietyCircularGeometry geometry = buildCircular(
        series: <VarietySeries>[
          VarietyPieSeries(
            data: const <VarietyChartData>[
              VarietyChartData('A', 50),
              VarietyChartData('B', 50),
            ],
          ),
        ],
      );
      // The first slice starts at -90 degrees, so a point straight up hits it.
      final VarietyHitResult? hit = geometry.hitTest(const Offset(100, 40));
      expect(hit, isNotNull);
      expect(hit!.pointIndex, 0);
    });
  });

  group('doughnut', () {
    test('honours the inner radius factor', () {
      final VarietyCircularGeometry geometry = buildCircular(
        series: <VarietySeries>[
          VarietyDoughnutSeries(
            innerRadiusFactor: 0.5,
            data: const <VarietyChartData>[VarietyChartData('A', 100)],
          ),
        ],
      );
      expect(
          geometry.slices.single.innerRadius, closeTo(80 * 0.85 * 0.5, 0.001));
    });

    test('does not hit test inside the hollow centre', () {
      final VarietyCircularGeometry geometry = buildCircular(
        series: <VarietySeries>[
          VarietyDoughnutSeries(
            innerRadiusFactor: 0.6,
            data: const <VarietyChartData>[VarietyChartData('A', 100)],
          ),
        ],
      );
      expect(geometry.hitTest(const Offset(100, 100)), isNull);
    });
  });

  group('radial bar', () {
    test('builds one ring per value with decreasing radii', () {
      final VarietyCircularGeometry geometry = buildCircular(
        series: <VarietySeries>[
          VarietyRadialBarSeries(
            showTrack: false,
            data: const <VarietyChartData>[
              VarietyChartData('A', 5),
              VarietyChartData('B', 10),
            ],
          ),
        ],
      );
      expect(geometry.rings.length, 2);
      expect(geometry.rings.first.outerRadius,
          greaterThan(geometry.rings.last.outerRadius));
    });

    test('emits a track ring when requested', () {
      final VarietyCircularGeometry geometry = buildCircular(
        series: <VarietySeries>[
          VarietyRadialBarSeries(
            showTrack: true,
            data: const <VarietyChartData>[VarietyChartData('A', 5)],
          ),
        ],
      );
      expect(geometry.rings.length, 2);
      expect(geometry.rings.last.isTrack, isTrue);
      expect(geometry.rings.first.isTrack, isFalse);
    });

    test('scales the sweep by the maximum', () {
      final VarietyCircularGeometry geometry = buildCircular(
        series: <VarietySeries>[
          VarietyRadialBarSeries(
            showTrack: false,
            maximum: 10,
            data: const <VarietyChartData>[VarietyChartData('A', 5)],
          ),
        ],
      );
      expect(
          geometry.rings.single.sweepAngle, closeTo(3.141592653589793, 0.001));
    });
  });

  group('rounded slices', () {
    // The last entry is deliberately tiny: a corner that eats more of the arc
    // than it should is invisible on the 52% slice and tears the 4% one open.
    List<VarietyChartData> traffic() => const <VarietyChartData>[
          VarietyChartData('Search', 52),
          VarietyChartData('Direct', 24),
          VarietyChartData('Social', 15),
          VarietyChartData('Referral', 5),
          VarietyChartData('Other', 4),
        ];

    test('every rounded slice keeps its hole open and its band whole', () {
      final VarietyCircularGeometry geometry = buildCircular(
        series: <VarietySeries>[
          VarietyDoughnutSeries(
            name: 'Traffic',
            innerRadiusFactor: 0.62,
            cornerRadius: 6,
            data: traffic(),
          ),
        ],
      );
      final _PathRecorder recorder = _PathRecorder();
      VarietyCircularPainter(geometry: geometry, theme: _theme)
          .paint(recorder, const Size(200, 200));

      expect(recorder.paths, hasLength(geometry.slices.length));
      for (int i = 0; i < geometry.slices.length; i++) {
        final VarietySlice slice = geometry.slices[i];
        final Path path = recorder.paths[i];
        final String which = 'the ${slice.point.x} slice';

        // The hole has to stay a hole. The corner path used to run a line
        // straight across the slice, which filled the middle of the chart and
        // left the band looking like a spike instead of a ring.
        expect(
          path.contains(slice.center),
          isFalse,
          reason: 'the centre must not be painted ($which)',
        );

        final double mid = slice.startAngle + slice.sweepAngle / 2;
        final Offset outward = Offset(math.cos(mid), math.sin(mid));
        final double band = (slice.outerRadius + slice.innerRadius) / 2;
        // The middle of the band, and both ends of it just inside the two arcs.
        // A corner that overruns its arc leaves one of these unpainted.
        for (final double radius in <double>[
          band,
          slice.innerRadius + 1,
          slice.outerRadius - 1,
        ]) {
          expect(
            path.contains(slice.center + outward * radius),
            isTrue,
            reason: 'radius $radius must be painted ($which)',
          );
        }

        // And nothing reaches past the outer edge.
        expect(
          path.contains(slice.center + outward * (slice.outerRadius + 4)),
          isFalse,
          reason: 'nothing may paint outside the outer radius ($which)',
        );
      }
    });
  });
}

/// A canvas that keeps the outlines a painter asked for.
///
/// Nothing in the painter reads a value back out of the canvas, so answering
/// every other call with `null` still lets a paint run through and leaves the
/// paths behind to be checked.
class _PathRecorder implements ui.Canvas {
  final List<Path> paths = <Path>[];

  @override
  void drawPath(Path path, Paint paint) => paths.add(path);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

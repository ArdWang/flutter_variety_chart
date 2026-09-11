import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

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
      expect(geometry.slices.first.sweepAngle, closeTo(0.3 * 2 * 3.141592653589793, 0.02));
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
      expect(geometry.slices.single.innerRadius, closeTo(80 * 0.85 * 0.5, 0.001));
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
      expect(geometry.rings.first.outerRadius, greaterThan(geometry.rings.last.outerRadius));
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
      expect(geometry.rings.single.sweepAngle, closeTo(3.141592653589793, 0.001));
    });
  });
}

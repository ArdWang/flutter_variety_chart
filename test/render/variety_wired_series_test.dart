import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_variety_chart/src/painters/variety_cartesian_painter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

const Color red = Color(0xFFCC0000);

/// The geometry a chart laid out, read back off its plot painter.
VarietyCartesianGeometry paintedGeometry(WidgetTester tester) {
  for (final Element element in find.byType(CustomPaint).evaluate()) {
    final CustomPaint paint = element.widget as CustomPaint;
    if (paint.painter is VarietyCartesianPainter) {
      return (paint.painter! as VarietyCartesianPainter).geometry;
    }
  }
  throw StateError('The chart drew with no cartesian painter.');
}

VarietyCartesianGeometry geometryOf(List<VarietySeries> series) =>
    VarietyCartesianGeometry(
      series: series,
      xAxis: const VarietyAxis(type: VarietyAxisType.category),
      yAxis: const VarietyAxis(type: VarietyAxisType.numeric),
      plotRect: defaultPlotRect,
      progress: 1,
    );

void main() {
  group('a bar is a column on its side', () {
    test('its corner radius reaches the rectangle', () {
      final VarietyCartesianGeometry geometry = geometryOf(<VarietySeries>[
        VarietyBarSeries(data: monthly(), cornerRadius: 6),
      ]);
      final VarietyRectsElement rects =
          geometry.elements.whereType<VarietyRectsElement>().first;
      // The bar and the column share one builder, and only the column was
      // asked for its radius: a bar declared six and drew square corners.
      expect(rects.radius, 6);
    });

    test('its outline reaches the rectangle', () {
      final VarietyCartesianGeometry geometry = geometryOf(<VarietySeries>[
        VarietyBarSeries(
          data: monthly(),
          borderColor: red,
          borderWidth: 2,
        ),
      ]);
      final VarietyRectsElement rects =
          geometry.elements.whereType<VarietyRectsElement>().first;
      expect(rects.border, red);
      expect(rects.borderWidth, 2);
    });

    test('a column still answers for its own outline', () {
      final VarietyCartesianGeometry geometry = geometryOf(<VarietySeries>[
        VarietyColumnSeries(
          data: monthly(),
          borderColor: red,
          borderWidth: 3,
          cornerRadius: 4,
        ),
      ]);
      final VarietyRectsElement rects =
          geometry.elements.whereType<VarietyRectsElement>().first;
      expect(rects.border, red);
      expect(rects.borderWidth, 3);
      expect(rects.radius, 4);
    });
  });

  group('a line that asks to be filled', () {
    List<VarietyPathElement> pathsOf(VarietyLineSeries series) =>
        geometryOf(<VarietySeries>[series])
            .elements
            .whereType<VarietyPathElement>()
            .toList();

    test('fills the area under it', () {
      final VarietyPathElement path = pathsOf(
        VarietyLineSeries(data: monthly(), fillOpacity: 0.3),
      ).first;
      // The value was declared, documented and read only to place the top of a
      // stacked run, so a plain line with a fill drew the same stroke as one
      // without it.
      expect(path.fillColor, isNotNull);
      expect(path.fillOpacity, 0.3);
      // The fill is closed back to the axis, so the path ends where the run
      // began rather than staying an open stroke.
      expect(path.path.getBounds().height, greaterThan(0));
    });

    test('stays a bare stroke at the default opacity', () {
      final VarietyPathElement path = pathsOf(
        VarietyLineSeries(data: monthly()),
      ).first;
      expect(path.fillColor, isNull);
    });
  });

  group('the room a value label is given', () {
    testWidgets('grows with the offset it is drawn at',
        (WidgetTester tester) async {
      Future<double> plotLeftFor(double offset) async {
        await tester.pumpWidget(
          host(
            VarietyCartesianChart(
              primaryXAxis: const VarietyAxis(type: VarietyAxisType.category),
              primaryYAxis: VarietyAxis(
                type: VarietyAxisType.numeric,
                labelOffset: offset,
              ),
              enableAnimation: false,
              series: <VarietySeries>[
                VarietyLineSeries(name: 'a', data: monthly()),
              ],
            ),
          ),
        );
        await tester.pump();
        return paintedGeometry(tester).plotRect.left;
      }

      final double near = await plotLeftFor(8);
      final double far = await plotLeftFor(40);
      // The painter moves the caption one offset away from the axis line; the
      // inset used to be a hard coded 12 and cropped whatever went past it.
      expect(far, greaterThan(near + 20));
    });
  });

  group('a series that opts out of the entrance', () {
    testWidgets('is drawn finished while the others rise',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          VarietyCartesianChart(
            animationDuration: const Duration(seconds: 1),
            series: <VarietySeries>[
              VarietyLineSeries(name: 'a', data: monthly()),
              VarietyLineSeries(name: 'b', data: monthly(), animate: false),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      final List<double>? progress = paintedGeometry(tester).seriesProgress;
      expect(progress, isNotNull);
      // The flag used to mean only "the chart animates unless every series
      // opts out", so one series asking to stand still was ignored.
      expect(progress![1], 1);
      expect(progress[0], lessThan(1));
    });
  });
}

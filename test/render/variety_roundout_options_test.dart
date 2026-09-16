import 'package:flutter/material.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';
import 'package:flutter_test/flutter_test.dart';

const Rect plotRect = Rect.fromLTWH(40, 10, 320, 220);

VarietyCartesianGeometry build(
  List<VarietySeries> series, {
  VarietyAxis xAxis = const VarietyAxis(type: VarietyAxisType.numeric),
  VarietyAxis yAxis = const VarietyAxis(type: VarietyAxisType.numeric),
}) {
  return VarietyCartesianGeometry(
    series: series,
    xAxis: xAxis,
    yAxis: yAxis,
    plotRect: plotRect,
    progress: 1,
  );
}

List<VarietyChartData> spread() => const <VarietyChartData>[
      VarietyChartData(0, 10),
      VarietyChartData(1, 20),
      VarietyChartData(2, 15),
    ];

void main() {
  group('range padding', () {
    // A range that is deliberately awkward so rounding is visible.
    List<VarietyChartData> awkward() => const <VarietyChartData>[
          VarietyChartData(1, 13),
          VarietyChartData(2, 47),
        ];

    double yMin(VarietyRangePadding padding) => build(
          <VarietySeries>[
            VarietyLineSeries(data: awkward()),
          ],
          yAxis:
              VarietyAxis(type: VarietyAxisType.numeric, rangePadding: padding),
        ).yMinimum;

    double yMax(VarietyRangePadding padding) => build(
          <VarietySeries>[
            VarietyLineSeries(data: awkward()),
          ],
          yAxis:
              VarietyAxis(type: VarietyAxisType.numeric, rangePadding: padding),
        ).yMaximum;

    test('none spans exactly the data', () {
      expect(yMin(VarietyRangePadding.none), 13);
      expect(yMax(VarietyRangePadding.none), 47);
    });

    test('round snaps outwards on both ends', () {
      expect(yMin(VarietyRangePadding.round), lessThanOrEqualTo(13));
      expect(yMax(VarietyRangePadding.round), greaterThanOrEqualTo(47));
    });

    test('roundStart leaves the top end alone', () {
      expect(yMin(VarietyRangePadding.roundStart), lessThanOrEqualTo(13));
      expect(yMax(VarietyRangePadding.roundStart), 47);
    });

    test('roundEnd leaves the bottom end alone', () {
      expect(yMin(VarietyRangePadding.roundEnd), 13);
      expect(yMax(VarietyRangePadding.roundEnd), greaterThanOrEqualTo(47));
    });

    test('additional pads past the rounded ends', () {
      expect(yMin(VarietyRangePadding.additional),
          lessThan(yMin(VarietyRangePadding.round)));
      expect(yMax(VarietyRangePadding.additional),
          greaterThan(yMax(VarietyRangePadding.round)));
    });

    test('additionalStart only pads the bottom', () {
      expect(yMin(VarietyRangePadding.additionalStart),
          lessThan(yMin(VarietyRangePadding.round)));
      expect(yMax(VarietyRangePadding.additionalStart),
          yMax(VarietyRangePadding.round));
    });

    test('additionalEnd only pads the top', () {
      expect(yMin(VarietyRangePadding.additionalEnd),
          yMin(VarietyRangePadding.round));
      expect(yMax(VarietyRangePadding.additionalEnd),
          greaterThan(yMax(VarietyRangePadding.round)));
    });

    test('normal behaves like round', () {
      expect(yMin(VarietyRangePadding.normal), yMin(VarietyRangePadding.round));
      expect(yMax(VarietyRangePadding.normal), yMax(VarietyRangePadding.round));
    });
  });

  group('marker shapes', () {
    test('every shape produces drawable geometry', () {
      final VarietyElementRenderer renderer =
          VarietyElementRenderer(const VarietyChartTheme(
        gridLineColor: Color(0xFFCCCCCC),
        axisLineColor: Color(0xFF888888),
        labelColor: Color(0xFF333333),
        tooltipBackgroundColor: Color(0xFF32323A),
        tooltipTextColor: Colors.white,
        markerBorderColor: Colors.white,
      ));
      for (final VarietyMarkerShape shape in VarietyMarkerShape.values) {
        final Path path =
            renderer.markerPath(shape, const Offset(100, 100), 10);
        final Rect bounds = path.getBounds();
        // A stroke-like shape is flat on one axis, so width and height are
        // checked together rather than one at a time.
        expect(bounds.width + bounds.height, greaterThan(0),
            reason: '$shape drew nothing');
      }
    });

    test('a pentagon spans most of the marker box', () {
      final VarietyElementRenderer renderer =
          VarietyElementRenderer(const VarietyChartTheme(
        gridLineColor: Color(0xFFCCCCCC),
        axisLineColor: Color(0xFF888888),
        labelColor: Color(0xFF333333),
        tooltipBackgroundColor: Color(0xFF32323A),
        tooltipTextColor: Colors.white,
        markerBorderColor: Colors.white,
      ));
      final Path path = renderer.markerPath(
          VarietyMarkerShape.pentagon, const Offset(100, 100), 10);
      final Rect bounds = path.getBounds();
      // The five corners sit on a radius of five, so the box lands between
      // the inscribed square and the circumscribed one.
      expect(bounds.width, greaterThan(8));
      expect(bounds.width, lessThanOrEqualTo(10));
      expect(bounds.height, greaterThan(8));
      expect(bounds.height, lessThanOrEqualTo(10));
    });
  });

  group('selection', () {
    test('cluster reports one point per series at the tapped slot', () {
      final VarietyCartesianGeometry geometry = build(<VarietySeries>[
        VarietyLineSeries(name: 'A', data: spread()),
        VarietyLineSeries(name: 'B', data: spread()),
      ]);
      final double aimed = geometry.pointPositions[0][1].dx;
      final List<VarietyHitResult> hits =
          geometry.hitsAtSlot(Offset(aimed, plotRect.center.dy));
      expect(hits.length, 2);
      for (final VarietyHitResult hit in hits) {
        expect(hit.pointIndex, 1);
      }
    });
  });

  group('tooltip value formatting', () {
    test('drops decimals on a whole number', () {
      expect(VarietyTooltipCard.formatValue(12), '12');
    });

    test('decimalPlaces rounds and pads', () {
      expect(
          VarietyTooltipCard.formatValue(12.3456, decimalPlaces: 2), '12.35');
      expect(VarietyTooltipCard.formatValue(12.3456, decimalPlaces: 0), '12');
      expect(VarietyTooltipCard.formatValue(12, decimalPlaces: 3), '12.000');
    });

    test('template wraps the number', () {
      expect(
          VarietyTooltipCard.formatValue(12, template: '{value} kg'), '12 kg');
      expect(VarietyTooltipCard.formatValue(12.5, template: r'$ {value}'),
          r'$ 12.50');
    });

    test('a null value stays a dash', () {
      expect(VarietyTooltipCard.formatValue(null, template: '{value} kg'), '-');
    });
  });

  group('data label options', () {
    VarietySeries labelled(VarietyDataLabelSettings settings) =>
        VarietyLineSeries(
          data: spread(),
          dataLabelSettings: settings,
        );

    List<VarietyLabelItem> itemsOf(VarietyCartesianGeometry geometry) =>
        geometry.elements
            .whereType<VarietyLabelsElement>()
            .expand((VarietyLabelsElement e) => e.labels)
            .toList();

    test('carry their card, rotation and shift onto the caption', () {
      final VarietyCartesianGeometry geometry = build(<VarietySeries>[
        labelled(const VarietyDataLabelSettings(
          isVisible: true,
          offset: Offset(3, -4),
          backgroundColor: Color(0xFFFFEE00),
          borderColor: Color(0xFF112233),
          borderWidth: 2,
          borderRadius: 6,
          angle: 12,
        )),
      ]);
      final List<VarietyLabelItem> items = itemsOf(geometry);
      expect(items, hasLength(3));
      for (final VarietyLabelItem item in items) {
        expect(item.shift, const Offset(3, -4));
        expect(item.backgroundColor, const Color(0xFFFFEE00));
        expect(item.borderColor, const Color(0xFF112233));
        expect(item.borderWidth, 2);
        expect(item.borderRadius, 6);
        expect(item.angle, 12);
      }
    });

    test('showZeroValue false drops a zero caption', () {
      const List<VarietyChartData> data = <VarietyChartData>[
        VarietyChartData(0, 0),
        VarietyChartData(1, 20),
      ];
      final VarietyCartesianGeometry shown = build(<VarietySeries>[
        VarietyLineSeries(
          data: data,
          dataLabelSettings: const VarietyDataLabelSettings(isVisible: true),
        ),
      ]);
      final VarietyCartesianGeometry hidden = build(<VarietySeries>[
        VarietyLineSeries(
          data: data,
          dataLabelSettings: const VarietyDataLabelSettings(
            isVisible: true,
            showZeroValue: false,
          ),
        ),
      ]);
      expect(itemsOf(shown), hasLength(2));
      expect(itemsOf(hidden), hasLength(1));
    });

    test('useSeriesColor tints the caption with the series colour', () {
      final VarietyCartesianGeometry geometry = build(<VarietySeries>[
        VarietyLineSeries(
          data: spread(),
          color: const Color(0xFF123456),
          dataLabelSettings: const VarietyDataLabelSettings(
            isVisible: true,
            useSeriesColor: true,
          ),
        ),
      ]);
      final List<VarietyLabelItem> items = itemsOf(geometry);
      expect(items, isNotEmpty);
      for (final VarietyLabelItem item in items) {
        expect(item.color, const Color(0xFF123456));
      }
    });
  });
}

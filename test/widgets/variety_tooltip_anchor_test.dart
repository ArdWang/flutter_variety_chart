import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../test_helpers.dart';

Finder chartCanvas() => find
    .descendant(
      of: find.byType(VarietyCartesianChart),
      matching: find.byType(CustomPaint),
    )
    .first;

/// Pumps a marker chart, taps [marker] (in canvas coordinates) and returns
/// the rendered tooltip rect together with the tapped spot.
Future<(Rect, Offset)> tapMarker(WidgetTester tester, Offset marker) async {
  await tester.pumpWidget(
    host(
      VarietyCartesianChart(
        series: <VarietySeries>[
          VarietyLineSeries(
              name: 'Revenue', showMarkers: true, data: monthly()),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
  final Rect canvasRect = tester.getRect(chartCanvas());
  final Offset tapSpot = canvasRect.topLeft + marker;
  await tester.tapAt(tapSpot);
  await tester.pumpAndSettle();
  final Rect card = tester.getRect(find.byType(VarietyTooltipCard));
  return (card, tapSpot);
}

void main() {
  testWidgets('tooltip is centred above a marker with headroom',
      (WidgetTester tester) async {
    // Index 0 sits low in the plot, leaving room above the marker.
    final (Rect card, Offset marker) =
        await tapMarker(tester, const Offset(88.0, 221.0));
    expect(
        marker.dx - card.left, moreOrLessEquals(card.width / 2, epsilon: 0.5));
    expect(marker.dy - card.bottom, moreOrLessEquals(7.0, epsilon: 0.5));
    final Rect canvasRect = tester.getRect(chartCanvas());
    expect(canvasRect.contains(card.topLeft), isTrue);
    expect(canvasRect.contains(card.bottomRight), isTrue);
  });

  testWidgets('tooltip flips below a marker at the top edge',
      (WidgetTester tester) async {
    // Index 3 touches the top of the plot, so the card must flip below.
    final (Rect card, Offset marker) =
        await tapMarker(tester, const Offset(340.0, 14.0));
    expect(
        marker.dx - card.left, moreOrLessEquals(card.width / 2, epsilon: 0.5));
    expect(card.top - marker.dy, moreOrLessEquals(7.0, epsilon: 0.5));
    final Rect canvasRect = tester.getRect(chartCanvas());
    expect(canvasRect.contains(card.topLeft), isTrue);
    expect(canvasRect.contains(card.bottomRight), isTrue);
  });
}

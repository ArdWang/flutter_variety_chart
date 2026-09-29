import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_variety_chart/flutter_variety_chart.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('renders one entry per named series',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyLegend(
          series: <VarietySeries>[
            VarietyLineSeries(name: 'Alpha', data: const <VarietyChartData>[]),
            VarietyLineSeries(name: 'Beta', data: const <VarietyChartData>[]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('skips unnamed series', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyLegend(
          series: <VarietySeries>[
            VarietyLineSeries(data: const <VarietyChartData>[]),
            VarietyLineSeries(name: 'Named', data: const <VarietyChartData>[]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Named'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('collapses when nothing can be labelled',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyLegend(
          series: <VarietySeries>[
            VarietyLineSeries(data: const <VarietyChartData>[]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('reports taps on an item', (WidgetTester tester) async {
    VarietySeries? tapped;
    await tester.pumpWidget(
      host(
        VarietyLegend(
          onItemTap: (VarietySeries series, int index) => tapped = series,
          series: <VarietySeries>[
            VarietyLineSeries(name: 'Alpha', data: const <VarietyChartData>[]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(tapped?.name, 'Alpha');
  });

  testWidgets('uses a vertical layout on the side',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyLegend(
          position: VarietyLegendPosition.right,
          series: <VarietySeries>[
            VarietyLineSeries(name: 'Alpha', data: const <VarietyChartData>[]),
            VarietyLineSeries(name: 'Beta', data: const <VarietyChartData>[]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Column), findsWidgets);
  });

  testWidgets('supports a custom item builder', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(
        VarietyLegend(
          itemBuilder:
              (BuildContext context, VarietySeries series, int index) =>
                  Text('custom-${series.name}'),
          series: <VarietySeries>[
            VarietyLineSeries(name: 'Alpha', data: const <VarietyChartData>[]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('custom-Alpha'), findsOneWidget);
  });

  group('legend glyph', () {
    const VarietyLegendSettings plain = VarietyLegendSettings();

    VarietyLineSeries series({
      VarietyMarkerShape? shape,
      VarietyLegendIconType? iconType,
    }) {
      return VarietyLineSeries(
        name: 'Alpha',
        data: const <VarietyChartData>[],
        legendIconShape: shape,
        legendIconType: iconType,
      );
    }

    test('a marker shape on the series names the glyph', () {
      // Before the shape reached this code a series could name any glyph it
      // liked and always got the one the series kind implies.
      expect(
        VarietyLegend.iconFor(series(shape: VarietyMarkerShape.diamond), plain),
        VarietyLegendIconType.diamond,
      );
      expect(
        VarietyLegend.iconFor(series(shape: VarietyMarkerShape.square), plain),
        VarietyLegendIconType.rectangle,
      );
      expect(
        VarietyLegend.iconFor(
            series(shape: VarietyMarkerShape.invertedTriangle), plain),
        VarietyLegendIconType.invertedTriangle,
      );
    });

    test('none asks for a caption with no glyph at all', () {
      expect(
        VarietyLegend.iconFor(series(shape: VarietyMarkerShape.none), plain),
        isNull,
      );
    });

    test('the marker shape wins over the legend icon type', () {
      expect(
        VarietyLegend.iconFor(
          series(
            shape: VarietyMarkerShape.triangle,
            iconType: VarietyLegendIconType.circle,
          ),
          plain,
        ),
        VarietyLegendIconType.triangle,
      );
    });

    test('a series that names neither follows the legend setting', () {
      expect(
        VarietyLegend.iconFor(series(), plain),
        VarietyLegendIconType.line,
      );
      expect(
        VarietyLegend.iconFor(
          series(),
          const VarietyLegendSettings(
            iconType: VarietyLegendIconType.pentagon,
          ),
        ),
        VarietyLegendIconType.pentagon,
      );
      expect(
        VarietyLegend.iconFor(
          series(iconType: VarietyLegendIconType.cross),
          const VarietyLegendSettings(
            iconType: VarietyLegendIconType.pentagon,
          ),
        ),
        VarietyLegendIconType.cross,
      );
    });
  });

  group('legend spacing', () {
    Future<double> entryGap(WidgetTester tester, double spacing) async {
      await tester.pumpWidget(
        host(
          VarietyLegend(
            settings: VarietyLegendSettings(spacing: spacing),
            series: <VarietySeries>[
              VarietyLineSeries(
                  name: 'Alpha', data: const <VarietyChartData>[]),
              VarietyLineSeries(name: 'Beta', data: const <VarietyChartData>[]),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The two entries are laid out the same width, so how far apart they
      // start is how much room was left between them.
      return tester.getTopLeft(find.text('Beta')).dx -
          tester.getTopLeft(find.text('Alpha')).dx;
    }

    testWidgets('the setting carries the space between two entries',
        (WidgetTester tester) async {
      // The widget used to keep a fixed 16 of its own and ignore the setting,
      // so both measurements used to come out identical.
      expect(
        await entryGap(tester, 40) - await entryGap(tester, 16),
        closeTo(24, 0.01),
      );
    });
  });
}

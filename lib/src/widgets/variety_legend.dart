import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/variety_enums.dart';
import '../models/variety_legend_settings.dart';
import '../models/variety_options.dart';
import '../models/variety_series.dart';
import '../render/variety_chart_theme.dart';

/// A legend describing the series shown by a chart.
class VarietyLegend extends StatelessWidget {
  /// Creates a legend for [series].
  const VarietyLegend({
    super.key,
    required this.series,
    this.position = VarietyLegendPosition.bottom,
    this.textStyle,
    this.padding,
    this.spacing = 16,
    this.runSpacing = 8,
    this.swatchSize = 10,
    this.swatchRadius = 2,
    this.itemBuilder,
    this.onItemTap,
    this.settings = const VarietyLegendSettings(),
    this.hiddenIndexes = const <int>{},
  });

  /// The series entries shown by the legend.
  final List<VarietySeries> series;

  /// Where the legend is anchored. Controls the layout direction.
  final VarietyLegendPosition position;

  /// An optional override for the item text style.
  final TextStyle? textStyle;

  /// An optional override for the padding around the legend.
  final EdgeInsetsGeometry? padding;

  /// Horizontal space between two items.
  final double spacing;

  /// Vertical space between two rows.
  final double runSpacing;

  /// The width and height of the colour swatch.
  final double swatchSize;

  /// The corner radius of the colour swatch.
  final double swatchRadius;

  /// Builds a custom item for the given series index.
  final Widget Function(BuildContext context, VarietySeries series, int index)?
      itemBuilder;

  /// Called when a legend item is tapped.
  final void Function(VarietySeries series, int index)? onItemTap;

  /// Additional presentation options.
  final VarietyLegendSettings settings;

  /// The indexes of the series that are currently hidden.
  final Set<int> hiddenIndexes;

  bool get _isVertical {
    switch (settings.itemOrientation) {
      case VarietyLegendItemOrientation.vertical:
        return true;
      case VarietyLegendItemOrientation.horizontal:
        return false;
      case VarietyLegendItemOrientation.auto:
        return position == VarietyLegendPosition.left ||
            position == VarietyLegendPosition.right;
    }
  }

  WrapAlignment get _wrapAlignment {
    switch (settings.alignment) {
      case VarietyLegendAlignment.start:
        return WrapAlignment.start;
      case VarietyLegendAlignment.center:
        return WrapAlignment.center;
      case VarietyLegendAlignment.end:
        return WrapAlignment.end;
    }
  }

  @override
  Widget build(BuildContext context) {
    final VarietyChartTheme chartTheme = VarietyChartTheme.of(context);
    final TextStyle fallback = (chartTheme.legendTextStyle ??
            Theme.of(context).textTheme.bodySmall ??
            const TextStyle(fontSize: 12))
        .copyWith(color: chartTheme.legendTextColor);
    final List<Widget> items = <Widget>[];
    for (int i = 0; i < series.length; i++) {
      final VarietySeries item = series[i];
      if (item.isVisibleInLegend == false) {
        continue;
      }
      if (item.name == null && item.legendItemText == null) {
        continue;
      }
      final Widget child = itemBuilder?.call(context, item, i) ??
          settings.itemBuilder?.call(context, item, i) ??
          _defaultItem(
            context,
            item,
            i,
            settings.textStyle ?? textStyle ?? fallback,
          );
      items.add(
        onItemTap == null
            ? child
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onItemTap!(item, i),
                child: Opacity(
                  opacity: hiddenIndexes.contains(i) ? 0.4 : 1,
                  child: child,
                ),
              ),
      );
    }
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final Widget content;
    if (_isVertical) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            if (i > 0) SizedBox(height: runSpacing),
            items[i],
          ],
        ],
      );
    } else {
      final Wrap wrap = Wrap(
        alignment: _wrapAlignment,
        spacing: spacing,
        runSpacing: runSpacing,
        children: items,
      );
      content = settings.overflowMode == VarietyLegendOverflowMode.scroll
          ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: wrap)
          : wrap;
    }
    final Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if ((settings.title ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              settings.title!,
              style: (settings.titleStyle ??
                          chartTheme.legendTitleTextStyle ??
                          Theme.of(context).textTheme.labelLarge)
                      ?.copyWith(color: chartTheme.legendTitleColor) ??
                  TextStyle(color: chartTheme.legendTitleColor),
            ),
          ),
        content,
      ],
    );
    final Widget framed =
        settings.isResponsive ? body : IntrinsicWidth(child: body);
    final Color? fill = chartTheme.legendBackgroundColor;
    return Padding(
      padding: padding ?? settings.padding,
      child: fill == null ? framed : ColoredBox(color: fill, child: framed),
    );
  }

  Widget _defaultItem(
    BuildContext context,
    VarietySeries series,
    int index,
    TextStyle style,
  ) {
    final Color color = series.color ??
        varietyDefaultPalette[index % varietyDefaultPalette.length];
    return Padding(
      padding: settings.itemPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: settings.iconWidth,
            height: settings.iconHeight,
            child: Center(
              child: CustomPaint(
                size: Size(settings.iconWidth, settings.iconHeight),
                painter: _LegendIconPainter(
                  settings.iconType == VarietyLegendIconType.seriesType
                      ? _fromSeries(series)
                      : settings.iconType,
                  color,
                  swatchSize,
                  swatchRadius,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(series.legendItemText ?? series.name!, style: style),
        ],
      ),
    );
  }

  static VarietyLegendIconType _fromSeries(VarietySeries series) {
    if (series is VarietyLineSeries) {
      return VarietyLegendIconType.line;
    }
    if (series is VarietyAreaSeries ||
        series is VarietySplineAreaSeries ||
        series is VarietyStepAreaSeries) {
      return VarietyLegendIconType.rectangle;
    }
    if (series is VarietyScatterSeries || series is VarietyBubbleSeries) {
      return VarietyLegendIconType.circle;
    }
    if (series.isRange || series is VarietyHiLoSeries) {
      return VarietyLegendIconType.line;
    }
    return VarietyLegendIconType.rectangle;
  }
}

class _LegendIconPainter extends CustomPainter {
  const _LegendIconPainter(this.type, this.color, this.size, this.radius);

  final VarietyLegendIconType type;
  final Color color;
  final double size;
  final double radius;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final Offset center = canvasSize.center(Offset.zero);
    final double half = size / 2;
    switch (type) {
      case VarietyLegendIconType.circle:
        canvas.drawCircle(center, half, fill);
      case VarietyLegendIconType.diamond:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - half)
            ..lineTo(center.dx + half, center.dy)
            ..lineTo(center.dx, center.dy + half)
            ..lineTo(center.dx - half, center.dy)
            ..close(),
          fill,
        );
      case VarietyLegendIconType.triangle:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - half)
            ..lineTo(center.dx + half, center.dy + half)
            ..lineTo(center.dx - half, center.dy + half)
            ..close(),
          fill,
        );
      case VarietyLegendIconType.invertedTriangle:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy + half)
            ..lineTo(center.dx + half, center.dy - half)
            ..lineTo(center.dx - half, center.dy - half)
            ..close(),
          fill,
        );
      case VarietyLegendIconType.line:
        canvas.drawLine(
          Offset(canvasSize.width * 0.05, center.dy),
          Offset(canvasSize.width * 0.95, center.dy),
          stroke,
        );
      case VarietyLegendIconType.cross:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx - half, center.dy - half)
            ..lineTo(center.dx + half, center.dy + half)
            ..moveTo(center.dx + half, center.dy - half)
            ..lineTo(center.dx - half, center.dy + half),
          stroke,
        );
      case VarietyLegendIconType.plus:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx - half, center.dy)
            ..lineTo(center.dx + half, center.dy)
            ..moveTo(center.dx, center.dy - half)
            ..lineTo(center.dx, center.dy + half),
          stroke,
        );
      case VarietyLegendIconType.rectangle:
      case VarietyLegendIconType.seriesType:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center,
              width: math.max(size, canvasSize.width * 0.8),
              height: math.max(size, canvasSize.height * 0.8),
            ),
            Radius.circular(radius),
          ),
          fill,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _LegendIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.type != type;
}

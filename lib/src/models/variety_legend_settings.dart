import 'package:flutter/widgets.dart';

import 'variety_options.dart';
import 'variety_series.dart';

/// Groups the presentation options of a chart legend.
@immutable
class VarietyLegendSettings {
  /// Creates legend settings.
  const VarietyLegendSettings({
    this.iconType = VarietyLegendIconType.seriesType,
    this.iconWidth = 12,
    this.iconHeight = 12,
    this.itemOrientation = VarietyLegendItemOrientation.auto,
    this.overflowMode = VarietyLegendOverflowMode.wrap,
    this.alignment = VarietyLegendAlignment.center,
    this.title,
    this.titleStyle,
    this.toggleSeriesVisibility = false,
    this.isResponsive = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 8),
    this.spacing = 16,
    this.runSpacing = 8,
    this.textStyle,
    this.itemBuilder,
  });

  /// How a series is represented.
  final VarietyLegendIconType iconType;

  /// The width of the icon column.
  final double iconWidth;

  /// The height of the icon column.
  final double iconHeight;

  /// The direction items are laid out in.
  final VarietyLegendItemOrientation itemOrientation;

  /// What happens when the items run out of room.
  final VarietyLegendOverflowMode overflowMode;

  /// How items are aligned along the cross axis.
  final VarietyLegendAlignment alignment;

  /// An optional legend caption.
  final String? title;

  /// The text style applied to [title].
  final TextStyle? titleStyle;

  /// When `true`, tapping an item hides or shows the matching series.
  final bool toggleSeriesVisibility;

  /// When `true`, the legend shrinks to the space it is given.
  final bool isResponsive;

  /// Padding applied around the whole legend.
  final EdgeInsetsGeometry padding;

  /// Padding applied to a single item.
  final EdgeInsetsGeometry itemPadding;

  /// Horizontal space between two items.
  final double spacing;

  /// Vertical space between two rows.
  final double runSpacing;

  /// An optional override for the item text style.
  final TextStyle? textStyle;

  /// Builds a custom item for a given series.
  final Widget Function(BuildContext context, VarietySeries series, int index)? itemBuilder;
}

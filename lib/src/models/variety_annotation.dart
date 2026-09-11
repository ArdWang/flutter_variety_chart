import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'variety_enums.dart';

/// A decoration anchored to a data coordinate or to the plot area itself.
@immutable
class VarietyAnnotation {
  /// Creates an annotation.
  const VarietyAnnotation({
    required this.shapeType,
    this.x,
    this.y,
    this.text,
    this.textStyle,
    this.fillColor,
    this.borderColor,
    this.borderWidth = 1.5,
    this.width = 0,
    this.height = 0,
    this.fontSize = 13,
    this.dashArray = const <double>[],
    this.image,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.isVisible = true,
  });

  /// Creates a horizontal rule at the given [y] value.
  const VarietyAnnotation.horizontalLine({
    required this.y,
    this.text,
    this.textStyle,
    this.fillColor,
    this.borderColor,
    this.borderWidth = 1.5,
    this.dashArray = const <double>[6, 4],
    this.isVisible = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  })  : shapeType = VarietyShapeType.horizontalLine,
        x = null,
        width = 0,
        height = 0,
        fontSize = 13,
        image = null;

  /// Creates a vertical rule at the given [x] value.
  const VarietyAnnotation.verticalLine({
    required this.x,
    this.text,
    this.textStyle,
    this.fillColor,
    this.borderColor,
    this.borderWidth = 1.5,
    this.dashArray = const <double>[6, 4],
    this.isVisible = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  })  : shapeType = VarietyShapeType.verticalLine,
        y = null,
        width = 0,
        height = 0,
        fontSize = 13,
        image = null;

  /// The primitive to draw.
  final VarietyShapeType shapeType;

  /// The primary-axis anchor. `null` spans the full plot width.
  final dynamic x;

  /// The secondary-axis anchor. `null` spans the full plot height.
  final dynamic y;

  /// An optional caption.
  final String? text;

  /// The text style applied to [text].
  final TextStyle? textStyle;

  /// The fill colour of the shape.
  final Color? fillColor;

  /// The stroke colour of the shape.
  final Color? borderColor;

  /// The stroke thickness.
  final double borderWidth;

  /// The width of a rectangle or ellipse annotation.
  final double width;

  /// The height of a rectangle or ellipse annotation.
  final double height;

  /// The font size used when [textStyle] is omitted.
  final double fontSize;

  /// A dash pattern applied to line annotations.
  final List<double> dashArray;

  /// The picture drawn by an image annotation.
  final ImageProvider? image;

  /// Padding reserved around the caption.
  final EdgeInsets padding;

  /// Whether the annotation is painted.
  final bool isVisible;
}

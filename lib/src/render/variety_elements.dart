import 'package:flutter/painting.dart';

import '../models/variety_enums.dart';

/// Base class for every drawable produced by a chart layout.
///
/// The layout turns series data into a flat list of elements; the painter only
/// walks that list. Keeping the geometry and the drawing apart makes it cheap
/// to add new series kinds without touching the painter.
sealed class VarietyElement {
  /// Creates an element.
  const VarietyElement({this.seriesIndex});

  /// The index of the series this element belongs to, or `null` if the
  /// element is chart-wide furniture that should always be drawn.
  final int? seriesIndex;
}

/// A stroked and optionally filled path.
class VarietyPathElement extends VarietyElement {
  /// Creates a path element.
  const VarietyPathElement({
    super.seriesIndex,
    required this.path,
    this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1.0,
    this.dashPattern = const <double>[],
    this.fillOpacity = 1.0,
    this.strokeOpacity = 1.0,
    this.antiAlias = true,
    this.fillGradient,
    this.strokeGradient,
  });

  /// The geometry to draw.
  final Path path;

  /// The fill colour, or `null` for an unfilled path.
  final Color? fillColor;

  /// The stroke colour, or `null` for an unstroked path.
  final Color? strokeColor;

  /// The stroke thickness.
  final double strokeWidth;

  /// A dash pattern of alternating on/off lengths. Empty means solid.
  final List<double> dashPattern;

  /// The alpha applied to [fillColor].
  final double fillOpacity;

  /// The alpha applied to [strokeColor].
  final double strokeOpacity;

  /// Whether the path is drawn with anti-aliasing. Disabling it is faster and
  /// is what the fast line series does.
  final bool antiAlias;

  /// A gradient painted inside the path, overriding [fillColor].
  final Gradient? fillGradient;

  /// A gradient stroked along the path, overriding [strokeColor].
  final Gradient? strokeGradient;
}

/// A single marker glyph.
class VarietyMarker {
  /// Creates a marker at [center].
  const VarietyMarker(this.center, {this.color, this.size});

  /// The centre of the glyph.
  final Offset center;

  /// An optional per-marker colour override.
  final Color? color;

  /// An optional per-marker size override.
  final double? size;
}

/// A set of markers that share one style.
class VarietyMarkersElement extends VarietyElement {
  /// Creates a marker element.
  const VarietyMarkersElement({
    super.seriesIndex,
    required this.markers,
    required this.size,
    required this.shape,
    required this.color,
    this.border,
    this.borderWidth = 1.4,
  });

  /// The markers to draw.
  final List<VarietyMarker> markers;

  /// The default glyph diameter.
  final double size;

  /// The glyph shape.
  final VarietyMarkerShape shape;

  /// The default fill colour.
  final Color color;

  /// An optional outline colour.
  final Color? border;

  /// The outline thickness.
  final double borderWidth;
}

/// A single bubble glyph.
class VarietyBubble {
  /// Creates a bubble at [center] with the given [radius].
  const VarietyBubble(this.center, this.radius, {this.color});

  /// The centre of the bubble.
  final Offset center;

  /// The bubble radius in logical pixels.
  final double radius;

  /// An optional per-bubble colour override.
  final Color? color;
}

/// A set of bubbles that share one style.
class VarietyBubblesElement extends VarietyElement {
  /// Creates a bubble element.
  const VarietyBubblesElement({
    super.seriesIndex,
    required this.bubbles,
    required this.color,
    this.border,
    this.borderWidth = 1.5,
    this.fillOpacity = 0.7,
  });

  /// The bubbles to draw.
  final List<VarietyBubble> bubbles;

  /// The default fill colour.
  final Color color;

  /// An optional outline colour.
  final Color? border;

  /// The outline thickness.
  final double borderWidth;

  /// The alpha applied to the fill.
  final double fillOpacity;
}

/// A set of rectangles that share one style.
class VarietyRectsElement extends VarietyElement {
  /// Creates a rectangle element.
  const VarietyRectsElement({
    super.seriesIndex,
    required this.rects,
    required this.color,
    this.radius = 0,
    this.border,
    this.borderWidth = 0,
  });

  /// The rectangles to draw.
  final List<Rect> rects;

  /// The fill colour. Per-rectangle colours are expressed by separate elements.
  final Color color;

  /// The corner radius applied to every rectangle.
  final double radius;

  /// An optional outline colour.
  final Color? border;

  /// The outline thickness.
  final double borderWidth;
}

/// A single straight segment.
class VarietySegment {
  /// Creates a segment between [from] and [to].
  const VarietySegment(this.from, this.to);

  /// The start point.
  final Offset from;

  /// The end point.
  final Offset to;
}

/// A set of straight segments that share one style.
class VarietySegmentsElement extends VarietyElement {
  /// Creates a segment element.
  const VarietySegmentsElement({
    super.seriesIndex,
    required this.segments,
    required this.color,
    required this.width,
    this.dashPattern = const <double>[],
  });

  /// The segments to draw.
  final List<VarietySegment> segments;

  /// The stroke colour.
  final Color color;

  /// The stroke thickness.
  final double width;

  /// A dash pattern of alternating on/off lengths. Empty means solid.
  final List<double> dashPattern;
}

/// A single text caption.
class VarietyLabelItem {
  /// Creates a caption anchored at [anchor].
  const VarietyLabelItem({
    required this.anchor,
    required this.text,
    this.position = VarietyLabelPosition.auto,
    this.offset = 6,
    this.color,
  });

  /// The point the caption is anchored to.
  final Offset anchor;

  /// The caption text.
  final String text;

  /// Where the caption sits relative to [anchor].
  final VarietyLabelPosition position;

  /// The distance between [anchor] and the caption.
  final double offset;

  /// An optional colour override.
  final Color? color;
}

/// A set of text captions that share one style.
class VarietyLabelsElement extends VarietyElement {
  /// Creates a label element.
  const VarietyLabelsElement({
    super.seriesIndex,
    required this.labels,
    this.style,
  });

  /// The captions to draw.
  final List<VarietyLabelItem> labels;

  /// The base text style, overridden per item by [VarietyLabelItem.color].
  final TextStyle? style;
}

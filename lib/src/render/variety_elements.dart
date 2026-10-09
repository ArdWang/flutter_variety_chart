import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../models/variety_enums.dart';
import '../models/variety_options.dart';

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

/// Where one painted data label ended up, and what it names.
///
/// A caption is a rectangle on the canvas and an address in the data: which
/// series, which point, and what it printed. A tap inside [rect] is a tap on
/// the point the caption is about, which is what a chart that offers the whole
/// point as a target cannot say — the caption may well sit clear of it.
@immutable
class VarietyDataLabelHit {
  /// Creates a data label hit record.
  const VarietyDataLabelHit({
    required this.seriesIndex,
    required this.pointIndex,
    required this.text,
    required this.rect,
  });

  /// The series that owns the caption.
  final int seriesIndex;

  /// The point the caption names.
  final int pointIndex;

  /// The caption that was painted.
  final String text;

  /// The painted rectangle of the caption, card included.
  final Rect rect;
}

/// A single marker glyph.
class VarietyMarker {
  /// Creates a marker at [center].
  const VarietyMarker(
    this.center, {
    this.color,
    this.size,
    this.shape,
    this.pointIndex,
  });

  /// The centre of the glyph.
  final Offset center;

  /// An optional per-marker colour override.
  final Color? color;

  /// An optional per-marker size override.
  final double? size;

  /// An optional per-marker shape override.
  ///
  /// A set of markers otherwise shares the shape of its element, which is how
  /// a series declares one. This is what lets a single point of that series be
  /// drawn differently from its neighbours.
  final VarietyMarkerShape? shape;

  /// The point this marker stands for, when it stands for one.
  ///
  /// `null` for a glyph that is not a reading of its own: the mean of a box
  /// plot, an outlier, an inner point. Those answer to their own settings and
  /// are deliberately left out of anything that addresses them by point.
  final int? pointIndex;
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
    this.margin = const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.borderRadius = 4,
    this.angle = 0,
    this.shift = Offset.zero,
    this.opacity = 1,
    this.connectorLength = 0,
    this.connectorWidth = 1.5,
    this.connectorColor,
    this.connectorType = VarietyConnectorType.line,
    this.pointIndex,
  });

  /// The point the caption is anchored to.
  final Offset anchor;

  /// The caption text.
  final String text;

  /// Where the caption sits relative to [anchor].
  final VarietyLabelPosition position;

  /// The distance between [anchor] and the caption.
  final double offset;

  /// The room left around the caption inside its card.
  final EdgeInsets margin;

  /// An optional colour override.
  final Color? color;

  /// A card colour painted behind the caption.
  final Color? backgroundColor;

  /// The colour of the card outline.
  final Color? borderColor;

  /// The thickness of the card outline. Zero skips the outline.
  final double borderWidth;

  /// The corner radius of the card.
  final double borderRadius;

  /// Rotation of the caption about its own centre, in degrees.
  final double angle;

  /// An extra translation applied once [position] is resolved.
  final Offset shift;

  /// A multiplier applied to the alpha of the text and its card.
  final double opacity;

  /// How far a connector line runs from the caption towards the point. Zero
  /// draws no connector.
  final double connectorLength;

  /// The thickness of the connector line.
  final double connectorWidth;

  /// The colour of the connector line. Falls back to the caption colour.
  final Color? connectorColor;

  /// Whether the connector is straight or curved.
  final VarietyConnectorType connectorType;

  /// The point this caption names, when it names one.
  ///
  /// Set for a caption standing on a data point, which is what a tap on the
  /// caption has to be able to answer with.
  final int? pointIndex;
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

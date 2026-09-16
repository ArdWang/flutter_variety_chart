import 'package:flutter/material.dart';

import '../models/variety_enums.dart';
import '../models/variety_options.dart';
import '../render/variety_geometry.dart';
import 'variety_interaction_details.dart';

/// Configures the tooltip shown when a single data point is highlighted.
@immutable
class VarietyTooltipBehavior {
  /// Creates a tooltip behaviour.
  const VarietyTooltipBehavior({
    this.enabled = true,
    this.backgroundColor,
    this.textStyle,
    this.borderRadius = 8,
    this.showDuration = Duration.zero,
    this.builder,
    this.borderColor,
    this.borderWidth = 0,
    this.opacity = 1,
    this.elevation = 4,
    this.canShowMarker = true,
    this.decimalPlaces,
    this.format,
  });

  /// Whether the tooltip is shown at all.
  final bool enabled;

  /// The card background colour.
  final Color? backgroundColor;

  /// The text style used inside the card.
  final TextStyle? textStyle;

  /// The corner radius of the card.
  final double borderRadius;

  /// How long the pointer must rest before the card appears.
  final Duration showDuration;

  /// Builds a fully custom card body.
  final Widget Function(BuildContext context, VarietyHitResult result)? builder;

  /// The colour of the card outline.
  final Color? borderColor;

  /// The thickness of the card outline. Zero skips the outline.
  final double borderWidth;

  /// The opacity of the whole card, between `0` and `1`.
  final double opacity;

  /// The shadow depth under the card.
  final double elevation;

  /// Whether the card leads with a dot in the series colour.
  final bool canShowMarker;

  /// Rounds the value to this many decimals before it is captioned. Null
  /// leaves the value as it is.
  final int? decimalPlaces;

  /// Wraps the captioned value. `{value}` is replaced by the formatted
  /// number, so `'{value} kg'` prints `12 kg`.
  final String? format;
}

/// The marker a trackball draws at every highlighted point.
@immutable
class VarietyTrackballMarkerSettings {
  /// Creates trackball marker settings.
  const VarietyTrackballMarkerSettings({
    this.isVisible = true,
    this.shape = VarietyMarkerShape.circle,
    this.size = 8,
    this.color,
    this.borderColor,
    this.borderWidth = 2,
  });

  /// Whether markers are drawn.
  final bool isVisible;

  /// The glyph of the marker.
  final VarietyMarkerShape shape;

  /// The diameter of the marker.
  final double size;

  /// The fill colour. Defaults to the series colour.
  final Color? color;

  /// The outline colour.
  final Color? borderColor;

  /// The outline thickness.
  final double borderWidth;
}

/// Configures the vertical guide and shared tooltip of a trackball.
@immutable
class VarietyTrackballBehavior {
  /// Creates a trackball behaviour.
  const VarietyTrackballBehavior({
    this.enabled = true,
    this.activationMode = VarietyActivationMode.longPress,
    this.lineColor,
    this.lineWidth = 1.2,
    this.lineDashPattern = const <double>[4, 4],
    this.showLine = true,
    this.showMarkers = true,
    this.markerShape = VarietyMarkerShape.circle,
    this.markerSize = 8,
    this.activationDistance = 48,
    this.showTooltip = true,
    this.builder,
    this.lineType = VarietyTrackballLineType.vertical,
    this.displayMode = VarietyTrackballDisplayMode.groupAllPoints,
    this.visibilityMode = VarietyTrackballVisibilityMode.auto,
    this.markerSettings = const VarietyTrackballMarkerSettings(),
    this.hideDelay = const Duration(seconds: 3),
    this.shouldAlwaysShow = false,
  });

  /// Whether the trackball reacts to input.
  final bool enabled;

  /// The gesture that reveals the trackball.
  final VarietyActivationMode activationMode;

  /// The colour of the guide.
  final Color? lineColor;

  /// The thickness of the guide.
  final double lineWidth;

  /// A dash pattern applied to the guide.
  final List<double> lineDashPattern;

  /// Whether the guide line is drawn.
  final bool showLine;

  /// Whether a marker is drawn on every series at the active slot.
  final bool showMarkers;

  /// The shape of the markers.
  final VarietyMarkerShape markerShape;

  /// The diameter of the markers.
  final double markerSize;

  /// How close a tap must land to a point, in logical pixels, before the
  /// trackball activates. Taps farther away dismiss it instead.
  final double activationDistance;

  /// Whether the shared tooltip card is shown.
  final bool showTooltip;

  /// Builds a fully custom tooltip body for all series at the active slot.
  final Widget Function(BuildContext context, List<VarietyHitResult> results)?
      builder;

  /// Which guides the trackball draws.
  final VarietyTrackballLineType lineType;

  /// What the shared tooltip lists.
  final VarietyTrackballDisplayMode displayMode;

  /// When the trackball appears and disappears.
  final VarietyTrackballVisibilityMode visibilityMode;

  /// The styling of the markers drawn at every highlighted point.
  final VarietyTrackballMarkerSettings markerSettings;

  /// How long the trackball lingers once the pointer leaves.
  final Duration hideDelay;

  /// Whether the trackball stays on screen after the first activation.
  final bool shouldAlwaysShow;
}

/// Configures the horizontal and vertical crosshair guides.
@immutable
class VarietyCrosshairBehavior {
  /// Creates a crosshair behaviour.
  const VarietyCrosshairBehavior({
    this.enabled = true,
    this.activationMode = VarietyActivationMode.auto,
    this.lineColor,
    this.lineWidth = 1.0,
    this.lineDashPattern = const <double>[4, 4],
    this.showVerticalLine = true,
    this.showHorizontalLine = true,
    this.showTooltip = true,
    this.builder,
    this.lineType,
  });

  /// Whether the crosshair reacts to input.
  final bool enabled;

  /// The gesture that reveals the crosshair.
  final VarietyActivationMode activationMode;

  /// The colour of the guides.
  final Color? lineColor;

  /// The thickness of the guides.
  final double lineWidth;

  /// A dash pattern applied to the guides.
  final List<double> lineDashPattern;

  /// Whether the vertical guide is drawn.
  final bool showVerticalLine;

  /// Whether the horizontal guide is drawn.
  final bool showHorizontalLine;

  /// Whether a tooltip card accompanies the guides.
  final bool showTooltip;

  /// Builds a fully custom tooltip body.
  final Widget Function(BuildContext context, VarietyHitResult result)? builder;

  /// Which guides are drawn. When `null` the two booleans above decide.
  final VarietyTrackballLineType? lineType;
}

/// Configures zooming and panning on a cartesian chart.
@immutable
class VarietyZoomPanBehavior {
  /// Creates a zoom and pan behaviour.
  const VarietyZoomPanBehavior({
    this.enabled = true,
    this.mode = VarietyZoomMode.pinch,
    this.enablePanning = true,
    this.enablePinchZooming = true,
    this.enableDoubleTapZooming = true,
    this.enableMouseWheelZooming = true,
    this.minimumZoomLevel = 0.02,
    this.maximumZoomLevel = 1.0,
    this.selectionRectColor,
    this.selectionRectBorderColor,
    this.axisMode = VarietyZoomAxisMode.xy,
    this.enableDeferredZooming = true,
    this.onZoomStart,
    this.onZoomEnd,
  });

  /// Whether zooming reacts to input.
  final bool enabled;

  /// Which gestures are accepted. [VarietyZoomMode.none] disables the
  /// behaviour outright, even when [enabled] is true.
  ///
  /// Selection zooming ([VarietyZoomMode.selection] and
  /// [VarietyZoomMode.both]) is bound to a long press so it can share the
  /// chart with panning and the trackball. While it is active a long press
  /// draws the zoom region instead of activating a long-press trackball.
  final VarietyZoomMode mode;

  /// Whether the plot can be dragged while zoomed in.
  final bool enablePanning;

  /// Whether a pinch gesture zooms.
  final bool enablePinchZooming;

  /// Whether a double tap zooms in and a second double tap resets.
  final bool enableDoubleTapZooming;

  /// Whether the mouse wheel zooms on desktop and web.
  final bool enableMouseWheelZooming;

  /// The smallest zoom window expressed as a fraction of the full range.
  final double minimumZoomLevel;

  /// The largest zoom window expressed as a fraction of the full range.
  final double maximumZoomLevel;

  /// The fill colour of the rubber-band selection rectangle.
  final Color? selectionRectColor;

  /// The border colour of the rubber-band selection rectangle.
  final Color? selectionRectBorderColor;

  /// Which axes a zoom gesture scales; pinch and wheel gestures zoom both
  /// axes by default.
  final VarietyZoomAxisMode axisMode;

  /// Whether the series are repainted continuously during a pinch. Disabling
  /// this keeps the interaction cheap on very large data sets.
  final bool enableDeferredZooming;

  /// Called as soon as a zoom gesture starts.
  final void Function(VarietyZoomDetails details)? onZoomStart;

  /// Called once a zoom gesture settles.
  final void Function(VarietyZoomDetails details)? onZoomEnd;
}

/// Configures point and series selection.
@immutable
class VarietySelectionBehavior {
  /// Creates a selection behaviour.
  const VarietySelectionBehavior({
    this.enabled = true,
    this.selectionType = VarietySelectionType.point,
    this.selectedColor,
    this.selectedBorderColor,
    this.selectedBorderWidth = 2,
    this.selectedOpacity = 1,
    this.unselectedOpacity = 0.35,
    this.unselectedColor,
    this.unselectedBorderColor,
    this.unselectedBorderWidth,
    this.onSelectionChanged,
    this.enableMultiSelection = false,
    this.toggleSelection = true,
  });

  /// Whether selection reacts to input.
  final bool enabled;

  /// Whether a single point, a whole series, or one slot across every series
  /// is selected.
  final VarietySelectionType selectionType;

  /// The colour applied to the selected point or series.
  final Color? selectedColor;

  /// The outline colour drawn around a selected point.
  final Color? selectedBorderColor;

  /// The outline thickness drawn around a selected point.
  final double selectedBorderWidth;

  /// The opacity applied to selected points.
  final double selectedOpacity;

  /// The opacity applied to everything that is not selected.
  final double unselectedOpacity;

  /// The colour applied to everything that is not selected.
  final Color? unselectedColor;

  /// The outline colour applied to unselected points.
  final Color? unselectedBorderColor;

  /// The outline thickness applied to unselected points. Null keeps the
  /// series' own outline.
  final double? unselectedBorderWidth;

  /// Called whenever the selection changes.
  final void Function(List<VarietyHitResult> selected)? onSelectionChanged;

  /// Whether more than one point can be selected at a time.
  final bool enableMultiSelection;

  /// Whether tapping an already selected point removes it from the selection.
  final bool toggleSelection;
}

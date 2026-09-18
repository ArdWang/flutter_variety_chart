import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../models/variety_axis.dart';
import '../models/variety_chart_data.dart';
import '../models/variety_series.dart';
import '../render/variety_geometry.dart';

/// Details handed to the range changed callback of a chart.
@immutable
class VarietyRangeChangedDetails {
  /// Creates a range change description.
  const VarietyRangeChangedDetails({
    required this.axis,
    required this.minimum,
    required this.maximum,
    required this.oldMinimum,
    required this.oldMaximum,
  });

  /// The axis whose range changed.
  final VarietyAxis axis;

  /// The new lowest value.
  final double minimum;

  /// The new highest value.
  final double maximum;

  /// The previous lowest value.
  final double oldMinimum;

  /// The previous highest value.
  final double oldMaximum;
}

/// Details handed to the data label callback of a chart.
@immutable
class VarietyDataLabelRenderDetails {
  /// Creates a data label description.
  const VarietyDataLabelRenderDetails({
    required this.series,
    required this.seriesIndex,
    required this.point,
    required this.pointIndex,
    this.text,
  });

  /// The series that owns the label.
  final VarietySeries series;

  /// The index of the owning series.
  final int seriesIndex;

  /// The point being labelled.
  final VarietyChartData point;

  /// The index of the point.
  final int pointIndex;

  /// The caption the chart is about to draw, when one was produced.
  final String? text;

  /// Returns a copy of these details with a replacement caption.
  VarietyDataLabelRenderDetails withText(String? value) =>
      VarietyDataLabelRenderDetails(
        series: series,
        seriesIndex: seriesIndex,
        point: point,
        pointIndex: pointIndex,
        text: value,
      );
}

/// Details handed to the tooltip callback of a chart.
@immutable
class VarietyTooltipDetails {
  /// Creates a tooltip description.
  const VarietyTooltipDetails({
    required this.hit,
    required this.header,
    required this.text,
  });

  /// The highlighted point.
  final VarietyHitResult hit;

  /// The tooltip header, normally the primary axis caption.
  final String header;

  /// The value line shown inside the tooltip.
  final String text;

  /// Returns a copy of these details with a replacement value line.
  VarietyTooltipDetails withText(String value) =>
      VarietyTooltipDetails(hit: hit, header: header, text: value);
}

/// Details handed to the legend tap callback of a chart.
@immutable
class VarietyLegendTapDetails {
  /// Creates a legend tap description.
  const VarietyLegendTapDetails({
    required this.series,
    required this.seriesIndex,
    required this.isVisible,
  });

  /// The series that was tapped.
  final VarietySeries series;

  /// The index of that series inside the chart.
  final int seriesIndex;

  /// Whether the series is still visible after the tap.
  final bool isVisible;
}

/// Details handed to the zoom callbacks of a chart.
@immutable
class VarietyZoomDetails {
  /// Creates a zoom description.
  const VarietyZoomDetails({
    required this.axis,
    required this.minimum,
    required this.maximum,
    required this.factor,
  });

  /// The axis being zoomed.
  final VarietyAxis axis;

  /// The visible minimum after the gesture.
  final double minimum;

  /// The visible maximum after the gesture.
  final double maximum;

  /// How much the current window is scaled relative to the full range.
  final double factor;
}

/// The direction a horizontal pan ran out of data in.
///
/// Mirrors `ChartSwipeDirection` in the reference implementation.
enum VarietySwipeDirection {
  /// The pan reached the low end of the axis.
  start,

  /// The pan reached the high end of the axis.
  end,
}

/// The pointer position of a raw touch interaction.
///
/// Unlike the point callbacks this reports every touch, whether or not it
/// landed on a series, which is what a chart needs in order to drive an
/// outside control from a drag over the plot.
@immutable
class VarietyChartTouchArgs {
  /// Creates a touch description.
  const VarietyChartTouchArgs({required this.position});

  /// The position in the chart's own coordinate space.
  final Offset position;
}

/// Details handed to the axis label tap callback of a chart.
@immutable
class VarietyAxisLabelTapDetails {
  /// Creates an axis label tap description.
  const VarietyAxisLabelTapDetails({
    required this.axis,
    required this.text,
    required this.value,
  });

  /// The axis that owns the label.
  final VarietyAxis axis;

  /// The caption that was tapped.
  final String text;

  /// The value the caption represents.
  final double value;
}

/// Lets an application drive and observe the selection of a chart.
class VarietySelectionController extends ChangeNotifier {
  List<VarietyHitResult> _selected = const <VarietyHitResult>[];

  /// The currently selected points, in the order they were selected.
  List<VarietyHitResult> get selected => _selected;

  /// Whether nothing is selected.
  bool get isEmpty => _selected.isEmpty;

  /// Replaces the selection outright.
  void select(List<VarietyHitResult> hits) {
    _selected = List<VarietyHitResult>.unmodifiable(hits);
    notifyListeners();
  }

  /// Adds a point to the selection, ignoring duplicates.
  void add(VarietyHitResult hit) {
    if (_selected.contains(hit)) {
      return;
    }
    _selected = List<VarietyHitResult>.unmodifiable(
      <VarietyHitResult>[..._selected, hit],
    );
    notifyListeners();
  }

  /// Removes a point from the selection.
  void remove(VarietyHitResult hit) {
    if (!_selected.contains(hit)) {
      return;
    }
    _selected = List<VarietyHitResult>.unmodifiable(
      _selected.where((VarietyHitResult item) => item != hit),
    );
    notifyListeners();
  }

  /// Clears the selection.
  void clear() {
    if (_selected.isEmpty) {
      return;
    }
    _selected = const <VarietyHitResult>[];
    notifyListeners();
  }
}

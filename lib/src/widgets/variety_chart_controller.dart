import 'package:flutter/foundation.dart';

import '../models/variety_chart_data.dart';

/// What happened to the points of a series.
enum VarietyDataChangeType {
  /// Points were appended past the last one.
  append,

  /// Points were inserted at an index the caller names.
  insert,

  /// Points already in the series were replaced in place.
  replace,

  /// Points were taken out of the series.
  remove,
}

/// One change to one series' points, waiting to be applied.
///
/// A change is described rather than applied so that the chart can apply it to
/// the very list the application handed to the series. Growing that list here
/// and growing it in the application are the same list, which is what keeps
/// one source of truth.
@immutable
class VarietyDataSourceChange {
  /// Creates a data change description.
  const VarietyDataSourceChange({
    required this.seriesIndex,
    this.type = VarietyDataChangeType.append,
    this.points,
    this.index,
    this.indexes,
  });

  /// The position of the series within `VarietyCartesianChart.series`.
  final int seriesIndex;

  /// What happened to the points.
  final VarietyDataChangeType type;

  /// The new points, for every change but [VarietyDataChangeType.remove].
  final List<VarietyChartData>? points;

  /// Where the change starts, for an insertion, a replacement or a single
  /// removal.
  final int? index;

  /// The points taken out, for a removal of several at once.
  final List<int>? indexes;
}

/// Drives the data of a [VarietyCartesianChart] from outside it.
///
/// A chart whose points arrive one at a time — a reading off a sensor, a price
/// off a feed, a sample off a microphone — used to have to be rebuilt to show
/// them. Rebuilding a chart rebuilds everything it owns: the whole entrance
/// animation plays again, so the line redraws itself from nothing on every
/// sample, and whatever window the reader had zoomed to is thrown away.
///
/// Hand the chart one of these and call [updateDataSource] instead. The points
/// go into the list the application already owns, the chart repaints what it
/// is showing, and nothing else moves:
///
/// ```dart
/// final VarietyCartesianChartController chart = VarietyCartesianChartController();
/// final List<VarietyChartData> readings = <VarietyChartData>[];
///
/// VarietyCartesianChart(
///   controller: chart,
///   series: <VarietySeries>[VarietyLineSeries(data: readings)],
/// )
///
/// // Later, once per reading:
/// readings.add(VarietyChartData(x, y));
/// chart.updateDataSource();
/// ```
///
/// Combined with `VarietyAxis.autoScrollingDelta` the window follows the newest
/// points by itself, which is what a monitor wants. Without it the axis keeps
/// growing and every point gets thinner, so give a live chart a delta or an
/// axis whose minimum and maximum name a view.
class VarietyCartesianChartController extends ChangeNotifier {
  VarietyDataSourceChange? _pending;
  int _count = 0;

  /// The change waiting to be applied, if there is one.
  ///
  /// `null` before the first call and after [clear].
  VarietyDataSourceChange? get pendingChange => _pending;

  /// How many changes this controller has announced, whether or not they
  /// carried points.
  int get changeCount => _count;

  /// Announces that a series' data have changed and asks the chart to redraw.
  ///
  /// Every parameter describes the same list the series was built with, so the
  /// chart applies the change to the application's own data rather than to a
  /// copy it made. A change that names no series index is applied to the first
  /// one, which is what a chart of a single series wants.
  ///
  /// The chart repaints and keeps whatever window the reader is looking at. It
  /// does not replay its entrance animation.
  void updateDataSource({
    int seriesIndex = 0,
    VarietyDataChangeType type = VarietyDataChangeType.append,
    List<VarietyChartData>? points,
    int? index,
    List<int>? indexes,
  }) {
    _pending = VarietyDataSourceChange(
      seriesIndex: seriesIndex,
      type: type,
      points: points,
      index: index,
      indexes: indexes,
    );
    _count++;
    notifyListeners();
  }

  /// Forgets the last change.
  ///
  /// Nothing is undone: the points are already in the caller's list. This only
  /// stops the next chart to ask from seeing a change it has already applied.
  void clear() {
    _pending = null;
  }
}

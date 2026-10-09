import 'package:flutter/foundation.dart';

/// Drives the visible range of an axis from outside the chart.
///
/// An axis normally resolves its own range from the points it is given. Hand
/// one a [VarietyRangeController] and the window becomes yours: set [start]
/// and [end] and the axis shows exactly that, whatever the data says.
///
/// The controller is also what a gesture talks back through. A pinch, a pan
/// or a double tap moves the window, and the chart records the window it
/// moved to on the same controller, so reading [start] and [end] always
/// answers with what is on screen even if nothing ever set them. That is the
/// pair a chart needs to be driven rather than merely fed.
///
/// Sharing one controller between two charts ties their windows together.
/// That is how a price chart and a volume chart below it stay honest about
/// which sessions the reader is looking at:
///
/// ```dart
/// final VarietyRangeController sharedRange = VarietyRangeController();
///
/// VarietyCartesianChart(
///   primaryXAxis: VarietyAxis(rangeController: sharedRange),
///   series: <VarietySeries>[price],
/// )
/// VarietyCartesianChart(
///   primaryXAxis: VarietyAxis(rangeController: sharedRange),
///   series: <VarietySeries>[volume],
/// )
/// ```
///
/// A pinned end is honoured to the extent the data allows: values outside the
/// range the axis derived from its own points are clamped back into it, since
/// a window has to be a window onto something. Setting both ends to `null`
/// through [clear] hands the axis back to itself.
class VarietyRangeController extends ChangeNotifier {
  /// Creates a range controller, optionally opening on a window.
  ///
  /// Leaving an end `null` leaves that end of the axis free.
  VarietyRangeController({double? start, double? end})
      : _start = start,
        _end = end;

  static double? _microsOf(DateTime? value) =>
      value == null ? null : value.microsecondsSinceEpoch.toDouble();

  static DateTime? _dateOf(double? value) =>
      value == null ? null : DateTime.fromMicrosecondsSinceEpoch(value.round());

  double? _start;
  double? _end;

  /// The lowest value the axis shows, in the axis' own units.
  ///
  /// `null` leaves this end to the axis. On a horizontal axis whose points
  /// carry a [DateTime] the unit is microseconds since the epoch, which is
  /// what [dateTimeStart] reads and writes for you.
  double? get start => _start;
  set start(double? value) => setRange(value, _end);

  /// The highest value the axis shows, in the axis' own units.
  ///
  /// `null` leaves this end to the axis. See [start] for the unit of a
  /// horizontal axis carrying [DateTime] values.
  double? get end => _end;
  set end(double? value) => setRange(_start, value);

  /// [start] read as an instant, for a horizontal axis of dates.
  DateTime? get dateTimeStart => _dateOf(_start);
  set dateTimeStart(DateTime? value) => start = _microsOf(value);

  /// [end] read as an instant, for a horizontal axis of dates.
  DateTime? get dateTimeEnd => _dateOf(_end);
  set dateTimeEnd(DateTime? value) => end = _microsOf(value);

  /// Whether either end is pinned.
  ///
  /// True once one of them has been given a value, even if the other has not:
  /// an axis whose low end is pinned is no longer choosing its own window
  /// either.
  bool get isPinned => _start != null || _end != null;

  /// Moves both ends in one notification.
  ///
  /// Either one may be `null` to free that end, and a free end goes on
  /// following the axis: as data grows so does the window it takes. Setting
  /// this notifies every chart listening to this controller once, so
  /// a chart acting on it can never disagree with a chart showing it.
  void setRange(double? start, double? end) {
    if (_start == start && _end == end) {
      return;
    }
    _start = start;
    _end = end;
    notifyListeners();
  }

  /// Moves both ends to instants, for a horizontal axis of dates.
  void setDateTimeRange(DateTime? start, DateTime? end) =>
      setRange(_microsOf(start), _microsOf(end));

  /// Frees both ends, handing the axis back to its own range.
  void clear() => setRange(null, null);
}

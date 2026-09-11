import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/variety_spark.dart';
import '../render/variety_chart_theme.dart';

/// Paints a spark chart: line, area, bar or win/loss.
///
/// A spark chart is axis free, so all the geometry is derived from the values
/// alone. The painter also draws the optional axis line, plot band, markers,
/// data labels and trackball.
class VarietySparkPainter extends CustomPainter {
  /// Creates a spark chart painter.
  VarietySparkPainter({
    required this.data,
    required this.seriesType,
    required this.theme,
    required this.progress,
    this.color,
    this.strokeWidth = 2,
    this.dashArray,
    this.borderWidth = 0,
    this.borderColor,
    this.axisCrossesAt = 0,
    this.axisLineColor,
    this.axisLineWidth = 2,
    this.axisLineDashArray,
    this.highPointColor,
    this.lowPointColor,
    this.negativePointColor,
    this.firstPointColor,
    this.lastPointColor,
    this.tiePointColor,
    this.plotBand,
    this.marker,
    this.labelDisplayMode,
    this.labelStyle,
    this.trackball,
    this.trackballIndex,
  });

  /// The values plotted by the spark chart.
  final List<double> data;

  /// The shape drawn by the spark chart.
  final VarietySparkSeriesType seriesType;

  /// The resolved colours for this build.
  final VarietyChartTheme theme;

  /// The entrance animation progress, from `0` to `1`.
  final double progress;

  /// The base series colour.
  final Color? color;

  /// The stroke thickness of a line, or the bar gap for bars.
  final double strokeWidth;

  /// A dash pattern applied to the line.
  final List<double>? dashArray;

  /// The outline thickness of an area or bar.
  final double borderWidth;

  /// The outline colour of an area or bar.
  final Color? borderColor;

  /// The value the axis line is drawn at.
  final double axisCrossesAt;

  /// The colour of the axis line.
  final Color? axisLineColor;

  /// The thickness of the axis line.
  final double axisLineWidth;

  /// A dash pattern applied to the axis line.
  final List<double>? axisLineDashArray;

  /// The colour of the highest point.
  final Color? highPointColor;

  /// The colour of the lowest point.
  final Color? lowPointColor;

  /// The colour of a point whose value is below zero.
  final Color? negativePointColor;

  /// The colour of the first point.
  final Color? firstPointColor;

  /// The colour of the last point.
  final Color? lastPointColor;

  /// The colour of a win/loss bar whose value is exactly zero.
  final Color? tiePointColor;

  /// An optional shaded value range.
  final VarietySparkPlotBand? plotBand;

  /// The marker configuration.
  final VarietySparkMarker? marker;

  /// Which points carry a data label.
  final VarietySparkLabelDisplayMode? labelDisplayMode;

  /// The text style of the data labels.
  final TextStyle? labelStyle;

  /// The trackball configuration.
  final VarietySparkTrackball? trackball;

  /// The index the trackball is currently pinned to.
  final int? trackballIndex;

  double _plotLeft = 0;
  double _plotTop = 0;
  double _plotRight = 0;
  double _plotBottom = 0;
  double _min = 0;
  double _max = 1;

  double get _plotWidth => math.max(_plotRight - _plotLeft, 1);

  double get _plotHeight => math.max(_plotBottom - _plotTop, 1);

  bool get _isBand =>
      seriesType == VarietySparkSeriesType.bar ||
      seriesType == VarietySparkSeriesType.winLoss;

  /// Resolves the internal geometry for a box of [size].
  ///
  /// Call this before [pointFor] or [axisPixel] when the geometry is needed
  /// outside of a paint pass, for example from a test or an overlay.
  void layoutFor(Size size) => _resolveBounds(size);

  /// The pixel of the data point at [index] after [layoutFor] has run.
  ///
  /// A spark chart has no padding, so the first point sits on the left edge and
  /// the last one on the right edge.
  Offset pointFor(int index) => _pointCenter(index);

  /// The pixel of the axis line after [layoutFor] has run.
  double get axisPixel => _axisY();

  /// The width of the drawing area after [layoutFor] has run.
  double get drawingWidth => _plotWidth;

  /// The height of the drawing area after [layoutFor] has run.
  double get drawingHeight => _plotHeight;

  @override
  void paint(Canvas canvas, Size size) {
    _resolveBounds(size);
    _paintPlotBand(canvas);
    _paintAxisLine(canvas);
    switch (seriesType) {
      case VarietySparkSeriesType.line:
        _paintLine(canvas, filled: false);
      case VarietySparkSeriesType.area:
        _paintLine(canvas, filled: true);
      case VarietySparkSeriesType.bar:
        _paintBars(canvas);
      case VarietySparkSeriesType.winLoss:
        _paintWinLoss(canvas);
    }
    _paintMarkers(canvas);
    _paintLabels(canvas);
    _paintTrackball(canvas, size);
  }

  void _resolveBounds(Size size) {
    // The range only follows the data, exactly like the reference widget: the
    // axis line position does not stretch the scale.
    _min = data.isEmpty ? 0 : data.reduce(math.min);
    _max = data.isEmpty ? 1 : data.reduce(math.max);
    // The drawing area is the whole box, so the first and last point sit on
    // the edges.
    _plotLeft = 0;
    _plotRight = math.max(size.width, 1);
    _plotTop = 0;
    _plotBottom = math.max(size.height, 1);
  }

  /// Whether the series is degenerate, in which case every point is drawn on
  /// the top edge.
  bool get _isFlat => data.length <= 1 || (_max - _min).abs() < 1e-9;

  double _ratioOf(double value) => (value - _min) / math.max(_max - _min, 1e-9);

  double _yFor(double value) {
    if (_isFlat) {
      return _plotTop;
    }
    return _plotBottom - _ratioOf(value) * _plotHeight;
  }

  /// The pixel of the axis line, clamped into the drawing area.
  double _axisY() {
    if (_isFlat) {
      return _plotTop;
    }
    return (_plotBottom - _ratioOf(axisCrossesAt) * _plotHeight)
        .clamp(_plotTop, _plotBottom);
  }

  double _xAt(int index) {
    final int count = data.length;
    if (count <= 1) {
      return _plotWidth / 2;
    }
    if (_isBand) {
      final double slot = _plotWidth / count;
      return _plotLeft + slot * (index + 0.5);
    }
    return _plotLeft + _plotWidth * index / (count - 1);
  }

  double _bandWidth() {
    final int count = math.max(data.length, 1);
    final double slot = _plotWidth / count;
    return math.max(slot * 0.7, 1);
  }

  double _animated(double value) {
    final double from = axisCrossesAt;
    return from + (value - from) * progress.clamp(0.0, 1.0);
  }

  Color get _baseColor => color ?? theme.gridLineColor.withValues(alpha: 1);

  Color _colorAt(int index) {
    final double value = data[index];
    if (index == 0 && firstPointColor != null) {
      return firstPointColor!;
    }
    if (index == data.length - 1 && lastPointColor != null) {
      return lastPointColor!;
    }
    if (value == _max && highPointColor != null) {
      return highPointColor!;
    }
    if (value == _min && lowPointColor != null) {
      return lowPointColor!;
    }
    if (value < axisCrossesAt && negativePointColor != null) {
      return negativePointColor!;
    }
    return _baseColor;
  }

  void _paintPlotBand(Canvas canvas) {
    final VarietySparkPlotBand? band = plotBand;
    if (band == null || band.start == null || band.end == null) {
      return;
    }
    final double from = _yFor(band.start!);
    final double to = _yFor(band.end!);
    final Rect rect = Rect.fromLTRB(
      _plotLeft,
      math.min(from, to),
      _plotRight,
      math.max(from, to),
    );
    canvas.drawRect(rect, Paint()..color = band.color);
    if (band.borderColor != null && band.borderWidth > 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = band.borderColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = band.borderWidth,
      );
    }
  }

  void _paintAxisLine(Canvas canvas) {
    final double y = _axisY();
    final Paint paint = Paint()
      ..color = axisLineColor ?? theme.axisLineColor
      ..strokeWidth = axisLineWidth
      ..isAntiAlias = true;
    _drawLine(
      canvas,
      Offset(_plotLeft, y),
      Offset(_plotRight, y),
      paint,
      axisLineDashArray ?? const <double>[],
    );
  }

  void _paintLine(Canvas canvas, {required bool filled}) {
    if (data.isEmpty) {
      return;
    }
    final List<Offset> points = <Offset>[
      for (int i = 0; i < data.length; i++)
        Offset(_xAt(i), _yFor(_animated(data[i]))),
    ];
    if (filled) {
      final double base = _axisY();
      final Path area = Path()..moveTo(points.first.dx, base);
      for (final Offset point in points) {
        area.lineTo(point.dx, point.dy);
      }
      area
        ..lineTo(points.last.dx, base)
        ..close();
      final Color fill = _baseColor;
      canvas.drawPath(
        area,
        Paint()
          ..color = fill.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill,
      );
    }
    if (points.length >= 2) {
      final Path path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      final Paint paint = Paint()
        ..color = borderColor ?? _baseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            filled ? (borderWidth > 0 ? borderWidth : strokeWidth) : strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;
      if (filled && borderWidth <= 0) {
        return;
      }
      _drawPath(canvas, path, paint, dashArray ?? const <double>[]);
    }
  }

  void _paintBars(Canvas canvas) {
    if (data.isEmpty) {
      return;
    }
    final double base = _axisY();
    final double width = _bandWidth();
    for (int i = 0; i < data.length; i++) {
      final double x = _xAt(i);
      final double top = _yFor(_animated(data[i]));
      final Rect rect = Rect.fromLTRB(
        x - width / 2,
        math.min(base, top),
        x + width / 2,
        math.max(base, top),
      );
      final Color fill = _colorAt(i);
      canvas.drawRect(rect, Paint()..color = fill);
      if (borderColor != null && borderWidth > 0) {
        canvas.drawRect(
          rect,
          Paint()
            ..color = borderColor!
            ..style = PaintingStyle.stroke
            ..strokeWidth = borderWidth,
        );
      }
    }
  }

  void _paintWinLoss(Canvas canvas) {
    if (data.isEmpty) {
      return;
    }
    final double base = _axisY();
    final double width = _bandWidth();
    final double half = _plotHeight / 2 * progress.clamp(0.0, 1.0);
    for (int i = 0; i < data.length; i++) {
      final double x = _xAt(i);
      final double value = data[i];
      Rect rect;
      Color fill;
      // The direction follows the sign of the value, relative to the axis line.
      if (value == axisCrossesAt) {
        rect =
            Rect.fromLTRB(x - width / 2, base - 1.5, x + width / 2, base + 1.5);
        fill = tiePointColor ?? negativePointColor ?? _baseColor;
      } else if (value > axisCrossesAt) {
        rect = Rect.fromLTRB(x - width / 2, base - half, x + width / 2, base);
        fill = _colorAt(i);
      } else {
        rect = Rect.fromLTRB(x - width / 2, base, x + width / 2, base + half);
        fill = negativePointColor ?? _colorAt(i);
      }
      canvas.drawRect(rect, Paint()..color = fill);
      if (borderColor != null && borderWidth > 0) {
        canvas.drawRect(
          rect,
          Paint()
            ..color = borderColor!
            ..style = PaintingStyle.stroke
            ..strokeWidth = borderWidth,
        );
      }
    }
  }

  Iterable<int> _markerIndexes() sync* {
    final VarietySparkMarker? config = marker;
    if (config == null ||
        config.displayMode == VarietySparkMarkerDisplayMode.none) {
      return;
    }
    switch (config.displayMode) {
      case VarietySparkMarkerDisplayMode.all:
        for (int i = 0; i < data.length; i++) {
          yield i;
        }
      case VarietySparkMarkerDisplayMode.high:
        final int index = data.indexOf(_max);
        if (index >= 0) {
          yield index;
        }
      case VarietySparkMarkerDisplayMode.low:
        final int index = data.indexOf(_min);
        if (index >= 0) {
          yield index;
        }
      case VarietySparkMarkerDisplayMode.first:
        if (data.isNotEmpty) {
          yield 0;
        }
      case VarietySparkMarkerDisplayMode.last:
        if (data.isNotEmpty) {
          yield data.length - 1;
        }
      case VarietySparkMarkerDisplayMode.none:
        break;
    }
  }

  void _paintMarkers(Canvas canvas) {
    final VarietySparkMarker? config = marker;
    if (config == null) {
      return;
    }
    for (final int index in _markerIndexes()) {
      final Offset center = _pointCenter(index);
      final Path path = _markerPath(config.shape, center, config.size);
      canvas.drawPath(
        path,
        Paint()
          ..color = config.color ?? _colorAt(index)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      if (config.borderWidth > 0) {
        canvas.drawPath(
          path,
          Paint()
            ..color = config.borderColor ?? config.color ?? _baseColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = config.borderWidth
            ..isAntiAlias = true,
        );
      }
    }
  }

  Offset _pointCenter(int index) {
    if (_isBand) {
      final double x = _xAt(index);
      return Offset(x, _yFor(_animated(data[index])));
    }
    return Offset(_xAt(index), _yFor(_animated(data[index])));
  }

  Iterable<int> _labelIndexes() sync* {
    final VarietySparkLabelDisplayMode? mode = labelDisplayMode;
    if (mode == null || mode == VarietySparkLabelDisplayMode.none) {
      return;
    }
    switch (mode) {
      case VarietySparkLabelDisplayMode.all:
        for (int i = 0; i < data.length; i++) {
          yield i;
        }
      case VarietySparkLabelDisplayMode.high:
        final int index = data.indexOf(_max);
        if (index >= 0) {
          yield index;
        }
      case VarietySparkLabelDisplayMode.low:
        final int index = data.indexOf(_min);
        if (index >= 0) {
          yield index;
        }
      case VarietySparkLabelDisplayMode.first:
        if (data.isNotEmpty) {
          yield 0;
        }
      case VarietySparkLabelDisplayMode.last:
        if (data.isNotEmpty) {
          yield data.length - 1;
        }
      case VarietySparkLabelDisplayMode.none:
        break;
    }
  }

  void _paintLabels(Canvas canvas) {
    final TextStyle base = labelStyle ??
        const TextStyle(fontSize: 10, fontWeight: FontWeight.w600);
    final TextStyle style =
        base.color == null ? base.copyWith(color: theme.labelColor) : base;
    final bool hasMarker = marker != null &&
        marker!.displayMode != VarietySparkMarkerDisplayMode.none;
    final double markerInset = hasMarker ? marker!.size / 2 : 0;
    for (final int index in _labelIndexes()) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: _format(data[index]), style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final Offset center = _pointCenter(index);
      // A label sits above a positive value and below a negative one.
      final double top = data[index] > 0
          ? center.dy - painter.height - markerInset
          : center.dy + markerInset;
      final double left = (center.dx - painter.width / 2)
          .clamp(_plotLeft, math.max(_plotRight - painter.width, _plotLeft));
      final double clampedTop =
          top.clamp(_plotTop, math.max(_plotBottom - painter.height, _plotTop));
      painter.paint(canvas, Offset(left, clampedTop));
    }
  }

  void _paintTrackball(Canvas canvas, Size size) {
    final VarietySparkTrackball? config = trackball;
    final int? index = trackballIndex;
    if (config == null || index == null || index < 0 || index >= data.length) {
      return;
    }
    final double x = _xAt(index);
    _drawLine(
      canvas,
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = config.color ?? theme.axisLineColor
        ..strokeWidth = config.width
        ..isAntiAlias = true,
      config.dashArray ?? const <double>[],
    );
    final Offset center = _pointCenter(index);
    canvas.drawCircle(
      center,
      math.max(config.width, 3) + 1.5,
      Paint()..color = theme.markerBorderColor,
    );
    canvas.drawCircle(
      center,
      math.max(config.width, 3) + 1.5,
      Paint()
        ..color = config.color ?? _baseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final String caption = _tooltipText(config, index);
    final TextStyle style = config.labelStyle ??
        TextStyle(color: theme.tooltipTextColor, fontSize: 11);
    final TextPainter painter = TextPainter(
      text: TextSpan(text: caption, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    const double padding = 6;
    final double cardWidth = painter.width + padding * 2;
    final double cardHeight = painter.height + padding * 1.4;
    double left = x + 8;
    if (left + cardWidth > size.width) {
      left = x - 8 - cardWidth;
    }
    left = left.clamp(0.0, math.max(size.width - cardWidth, 0));
    double top = center.dy - cardHeight - 8;
    if (top < 0) {
      top = center.dy + 8;
    }
    top = top.clamp(0.0, math.max(size.height - cardHeight, 0));
    final RRect card = config.borderRadius.toRRect(
      Rect.fromLTWH(left, top, cardWidth, cardHeight),
    );
    canvas.drawRRect(
      card,
      Paint()..color = config.backgroundColor ?? theme.tooltipBackgroundColor,
    );
    if (config.borderColor != null && config.borderWidth > 0) {
      canvas.drawRRect(
        card,
        Paint()
          ..color = config.borderColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = config.borderWidth,
      );
    }
    painter.paint(canvas, Offset(left + padding, top + padding * 0.7));
  }

  String _tooltipText(VarietySparkTrackball config, int index) {
    final String fallback = '$index : ${_format(data[index])}';
    final String Function(VarietySparkTooltipFormatterDetails)? formatter =
        config.tooltipFormatter;
    if (formatter == null) {
      return fallback;
    }
    return formatter(
      VarietySparkTooltipFormatterDetails(
        index: index,
        x: index,
        y: data[index],
        label: fallback,
      ),
    );
  }

  static String _format(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  Path _markerPath(VarietySparkMarkerShape shape, Offset center, double size) {
    final double half = size / 2;
    final Path path = Path();
    switch (shape) {
      case VarietySparkMarkerShape.circle:
        path.addOval(Rect.fromCircle(center: center, radius: half));
      case VarietySparkMarkerShape.square:
        path.addRect(
            Rect.fromCenter(center: center, width: size, height: size));
      case VarietySparkMarkerShape.diamond:
        path
          ..moveTo(center.dx, center.dy - half)
          ..lineTo(center.dx + half, center.dy)
          ..lineTo(center.dx, center.dy + half)
          ..lineTo(center.dx - half, center.dy)
          ..close();
      case VarietySparkMarkerShape.triangle:
        path
          ..moveTo(center.dx, center.dy - half)
          ..lineTo(center.dx + half, center.dy + half)
          ..lineTo(center.dx - half, center.dy + half)
          ..close();
      case VarietySparkMarkerShape.invertedTriangle:
        path
          ..moveTo(center.dx, center.dy + half)
          ..lineTo(center.dx + half, center.dy - half)
          ..lineTo(center.dx - half, center.dy - half)
          ..close();
    }
    return path;
  }

  void _drawLine(
      Canvas canvas, Offset from, Offset to, Paint paint, List<double> dash) {
    if (dash.isEmpty) {
      canvas.drawLine(from, to, paint);
      return;
    }
    final Path path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy);
    _drawPath(canvas, path, paint, dash);
  }

  void _drawPath(Canvas canvas, Path path, Paint paint, List<double> dash) {
    if (dash.isEmpty) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      int index = 0;
      while (distance < metric.length) {
        final double length = dash[index % dash.length];
        final double next = math.min(distance + length, metric.length);
        if (index.isEven) {
          canvas.drawPath(metric.extractPath(distance, next), paint);
        }
        distance = next;
        index++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant VarietySparkPainter oldDelegate) => true;
}

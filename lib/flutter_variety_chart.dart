/// Flutter Variety Chart — a lightweight, dependency-free chart library.
///
/// The package ships five chart widgets:
///
/// * [VarietyCartesianChart] for line, area, column, bar, scatter, bubble,
///   candle, hi-lo, waterfall, histogram, range and stacked series.
/// * [VarietyCircularChart] for pie, doughnut and radial bar series.
/// * [VarietyFunnelChart] for funnel and pyramid series.
/// * [VarietySparkline] for compact axis-less charts in tables and tiles.
///
/// Import the library and feed it a list of series:
///
/// ```dart
/// import 'package:flutter_variety_chart/flutter_variety_chart.dart';
///
/// VarietyCartesianChart(
///   series: <VarietySeries>[
///     VarietyLineSeries(
///       name: 'Revenue',
///       data: <VarietyChartData>[
///         VarietyChartData('Jan', 32),
///         VarietyChartData('Feb', 48),
///         VarietyChartData('Mar', 41),
///       ],
///     ),
///   ],
/// )
/// ```
library;

// Models
export 'src/models/variety_annotation.dart';
export 'src/models/variety_axis.dart';
export 'src/models/variety_empty_points.dart';
export 'src/models/variety_chart_data.dart';
export 'src/models/variety_enums.dart';
export 'src/models/variety_legend_settings.dart';
export 'src/models/variety_marker_settings.dart';
export 'src/models/variety_options.dart';
export 'src/models/variety_spark.dart';
export 'src/models/variety_indicators.dart';
export 'src/models/variety_series.dart';
export 'src/models/variety_trendline.dart';

// Behaviours
export 'src/behaviors/variety_behaviors.dart';
export 'src/behaviors/variety_interaction_details.dart';

// Analysis
export 'src/analysis/variety_regression.dart'
    show
        varietyFitTrendline,
        varietyMovingAverage,
        varietyMovingAverageTrendline;

// Rendering
export 'src/render/variety_chart_theme.dart';
export 'src/render/variety_elements.dart';
export 'src/render/variety_geometry.dart'
    show
        VarietyHitResult,
        VarietySlice,
        VarietyFunnelSegment,
        VarietyCartesianGeometry,
        VarietyCircularGeometry,
        VarietyFunnelGeometry;

// Utilities
export 'src/utils/variety_label_utils.dart';

// Widgets
export 'src/painters/variety_cartesian_painter.dart' show VarietyAxisLabelHit;
export 'src/painters/variety_element_renderer.dart'
    show VarietyElementRenderer, VarietyRendererFactory, VarietyShaderFactory;
export 'src/painters/variety_spark_painter.dart' show VarietySparkPainter;
export 'src/widgets/variety_cartesian_chart.dart';
export 'src/widgets/variety_chart_title.dart';
export 'src/widgets/variety_circular_chart.dart';
export 'src/widgets/variety_funnel_chart.dart';
export 'src/widgets/variety_legend.dart';
export 'src/widgets/variety_spark_charts.dart';
export 'src/widgets/variety_sparkline.dart';
export 'src/widgets/variety_tooltip.dart';

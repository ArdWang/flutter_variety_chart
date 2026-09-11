import 'package:flutter/material.dart';

/// A caption rendered above a chart.
class VarietyChartTitle extends StatelessWidget {
  /// Creates a chart title.
  const VarietyChartTitle({
    super.key,
    required this.text,
    this.textStyle,
    this.textAlign = TextAlign.center,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  /// The caption shown to the user.
  final String text;

  /// An optional override for the text style.
  final TextStyle? textStyle;

  /// How the caption is aligned horizontally.
  final TextAlign textAlign;

  /// Padding applied around the caption.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final TextStyle fallback = Theme.of(context).textTheme.titleMedium ?? const TextStyle();
    return Padding(
      padding: padding,
      child: SizedBox(
        width: double.infinity,
        child: Text(
          text,
          textAlign: textAlign,
          style: (textStyle ?? fallback).copyWith(
            fontWeight: textStyle?.fontWeight ?? FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

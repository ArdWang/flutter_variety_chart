import 'package:flutter/material.dart';

/// A scaffold that gives each demo a consistent title and description.
class DemoScaffold extends StatelessWidget {
  /// Creates a demo scaffold.
  const DemoScaffold({
    super.key,
    required this.title,
    required this.description,
    required this.children,
  });

  /// The page title.
  final String title;

  /// A short explanation of what is being demonstrated.
  final String description;

  /// The chart cards shown below the description.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// A titled card that hosts a single chart.
class ChartCard extends StatelessWidget {
  /// Creates a chart card.
  const ChartCard({
    super.key,
    required this.title,
    required this.height,
    required this.child,
  });

  /// The card caption.
  final String title;

  /// The height reserved for the chart.
  final double height;

  /// The chart itself.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(height: height, child: child),
          ],
        ),
      ),
    );
  }
}

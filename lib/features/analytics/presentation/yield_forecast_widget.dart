import 'package:flutter/material.dart';

class YieldForecastWidget extends StatelessWidget {
  final double moistureCompliance;
  const YieldForecastWidget({super.key, required this.moistureCompliance});

  @override
  Widget build(BuildContext context) {
    final forecast = (moistureCompliance * 95).clamp(0, 100).toStringAsFixed(1);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.show_chart),
        title: Text('Yield Forecast: $forecast%'),
        subtitle: Text(
          'Moisture compliance ${(moistureCompliance * 100).toStringAsFixed(0)}%',
        ),
      ),
    );
  }
}

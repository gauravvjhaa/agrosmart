import 'package:flutter/material.dart';

class CropCalendarScreen extends StatelessWidget {
  const CropCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = [
      {
        'crop': 'Tomato',
        'zone': 'Zone 2',
        'stage': 'Vegetative',
        'daysLeft': 40,
      },
      {
        'crop': 'Potato',
        'zone': 'Zone 1',
        'stage': 'Flowering',
        'daysLeft': 25,
      },
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Calendar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: plans
                .map(
                  (p) => SizedBox(
                    width: 300,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['crop'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Zone: ${p['zone']}'),
                            Text('Stage: ${p['stage']}'),
                            Text('Days Remaining: ${p['daysLeft']}'),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value:
                                  1 - ((p['daysLeft'] as int) / 90).clamp(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Crop Plan'),
            onPressed: () {},
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.rotate_left),
              title: const Text('Rotation Recommendation'),
              subtitle: const Text(
                'Consider legumes next cycle to improve nitrogen & soil structure.',
              ),
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Details'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AutomationPolicyScreen extends StatelessWidget {
  const AutomationPolicyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final rules = [
      {'crop': 'Tomato', 'stage': 'Flowering', 'min': 32, 'max': 42},
      {'crop': 'Potato', 'stage': 'Vegetative', 'min': 28, 'max': 38},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Automation Policies')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Threshold Rules',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...rules.map(
            (r) => Card(
              child: ListTile(
                title: Text('${r['crop']} • ${r['stage']}'),
                subtitle: Text('Moisture ${r['min']}% - ${r['max']}%'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {},
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Predictive Engine',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            value: true,
            title: const Text('Enable ML-based Scheduling'),
            subtitle: const Text('Learns response curves & optimizes runtime'),
            onChanged: (_) {},
          ),
          SwitchListTile(
            value: true,
            title: const Text('Use Weather Forecast'),
            subtitle: const Text('Skips irrigation if rain probability high'),
            onChanged: (_) {},
          ),
          SwitchListTile(
            value: false,
            title: const Text('Adaptive Dose Refinement'),
            subtitle: const Text('Adjusts minutes per zone over time'),
            onChanged: (_) {},
          ),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Rule'),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

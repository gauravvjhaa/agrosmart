import 'package:flutter/material.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});
  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  int step = 0;
  @override
  Widget build(BuildContext context) {
    final steps = [
      _step('Connect Gateway', 'Power and pair the gateway device.'),
      _step('Add Zones', 'Define irrigation zones and sensors.'),
      _step('Assign Crops', 'Select crop & growth stage per zone.'),
      _step('Finalize', 'Review & finish setup.'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Wizard')),
      body: steps[step],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (step > 0)
              TextButton(
                onPressed: () => setState(() => step--),
                child: const Text('Back'),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                if (step < steps.length - 1) {
                  setState(() => step++);
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(step == steps.length - 1 ? 'Finish' : 'Next'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String title, String desc) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(desc, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

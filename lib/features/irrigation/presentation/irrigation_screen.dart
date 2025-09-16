import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/models/zone.dart';

class IrrigationScreen extends StatelessWidget {
  const IrrigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cache = ServiceLocator.get<CacheService>();
    final zones = cache.zones;
    return Scaffold(
      appBar: AppBar(title: const Text('Irrigation Control')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.play_circle),
                  label: const Text('Open All 5m'),
                  onPressed: () {
                    for (final z in zones) {
                      cache.queueCommand({
                        'zoneId': z.id,
                        'action': 'OPEN',
                        'durationSec': 300,
                      });
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Batch commands queued')),
                    );
                  },
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.pause_circle),
                  label: const Text('Close All'),
                  onPressed: () {
                    for (final z in zones) {
                      cache.queueCommand({'zoneId': z.id, 'action': 'CLOSE'});
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All zones closed')),
                    );
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: const Text('Create Schedule'),
                  onPressed: () {
                    // TODO: open schedule editor
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.analytics),
                  label: const Text('Optimize  '),
                  onPressed: () {
                    // TODO: invoke optimization service
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: zones.length,
              itemBuilder: (_, i) {
                final z = zones[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ExpansionTile(
                    leading: Icon(
                      z.mode == ZoneIrrigationMode.auto
                          ? Icons.auto_mode
                          : Icons.handyman,
                      color: Colors.green,
                    ),
                    title: Text(z.name),
                    subtitle: Text(
                      'Moisture ${z.moisture.toStringAsFixed(1)}% | Temp ${z.temperature.toStringAsFixed(1)}°C',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton(
                              onPressed: () {
                                cache.queueCommand({
                                  'zoneId': z.id,
                                  'action': 'OPEN',
                                  'durationSec': 300,
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Irrigation for 5 min'),
                                  ),
                                );
                              },
                              child: const Text('Irrigate 5m'),
                            ),
                            FilledButton(
                              onPressed: () {
                                cache.queueCommand({
                                  'zoneId': z.id,
                                  'action': 'OPEN',
                                  'durationSec': 600,
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Irrigation for 10 min'),
                                  ),
                                );
                              },
                              child: const Text('Irrigate 10m'),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                cache.queueCommand({
                                  'zoneId': z.id,
                                  'action': z.valveOpen ? 'CLOSE' : 'OPEN',
                                });
                              },
                              child: const Text('Toggle Valve'),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                // TODO: open schedule editor
                              },
                              child: const Text('Edit Schedule'),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                // TODO: switch irrigation mode
                              },
                              child: const Text('Switch Mode'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

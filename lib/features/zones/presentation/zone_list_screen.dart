import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/models/zone.dart';

class ZoneListScreen extends StatefulWidget {
  const ZoneListScreen({super.key});

  @override
  State<ZoneListScreen> createState() => _ZoneListScreenState();
}

class _ZoneListScreenState extends State<ZoneListScreen> {
  // Reference to the zones root in Realtime Database
  final DatabaseReference _zonesRef = FirebaseDatabase.instance.ref('zones');

  // Helper: normalize possible DB ids for a zone
  Iterable<String> _candidateIds(Zone z) sync* {
    final raw = z.id;
    yield raw;
    yield raw.toUpperCase();
    yield raw.toLowerCase();
    // Common pattern: zone_1 -> Z1
    if (raw.toLowerCase().startsWith('zone_')) {
      final tail = raw.split('_').last;
      yield 'Z$tail';
    }
    // Reverse: Z1 -> zone_1
    if (RegExp(r'^[Zz]\d+$').hasMatch(raw)) {
      yield 'zone_${raw.substring(1)}';
    }
  }

  bool _dbHasZone(Set<String> dbKeys, Zone z) {
    for (final c in _candidateIds(z)) {
      if (dbKeys.contains(c)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final allZones = ServiceLocator.get<CacheService>().zones;

    return Scaffold(
      appBar: AppBar(title: const Text('All Zones')),
      body: StreamBuilder<DatabaseEvent>(
        stream: _zonesRef.onValue,
        builder: (context, snap) {
          if (snap.hasError) {
            return _centerText(
              'Error loading zones from database:\n${snap.error}',
              icon: Icons.error,
              color: Colors.red,
            );
          }
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Extract keys present in the DB
          final event = snap.data;
          Set<String> presentIds = {};
          if (event != null && event.snapshot.value is Map) {
            final m = Map<Object?, Object?>.from(event.snapshot.value as Map);
            presentIds = m.keys.map((k) => k.toString()).toSet();
          }

          // Filter cached zones against db keys
          final visibleZones = allZones
              .where((z) => _dbHasZone(presentIds, z))
              .toList();

          if (visibleZones.isEmpty) {
            if (presentIds.isEmpty) {
              return _centerText(
                'No zones present in database path /zones.\n'
                'Add a node like /zones/Z1 to see it here.',
                icon: Icons.info_outline,
              );
            } else {
              return _centerText(
                'No matching cached zones found for existing DB keys:\n'
                '${presentIds.join(', ')}',
                icon: Icons.info_outline,
              );
            }
          }

          return ListView.separated(
            itemCount: visibleZones.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (_, i) {
              final z = visibleZones[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Text('${i + 1}'),
                ),
                title: Text(z.name),
                subtitle: Text(
                  'Moisture ${z.moisture.toStringAsFixed(1)}% • '
                  'Temp ${z.temperature.toStringAsFixed(1)}°C',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      z.mode == ZoneIrrigationMode.auto
                          ? Icons.auto_mode
                          : Icons.handyman,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      z.valveOpen ? Icons.power : Icons.power_off,
                      color: z.valveOpen ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
                onTap: () =>
                    Navigator.pushNamed(context, '/zone/detail', arguments: z),
              );
            },
          );
        },
      ),
    );
  }

  Widget _centerText(
    String msg, {
    IconData icon = Icons.info_outline,
    Color? color,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: color ?? Colors.blueGrey),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

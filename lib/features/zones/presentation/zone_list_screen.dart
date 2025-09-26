import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/models/zone.dart';
import '../../../core/state/app_state.dart';

class ZoneListScreen extends StatefulWidget {
  const ZoneListScreen({super.key});

  @override
  State<ZoneListScreen> createState() => _ZoneListScreenState();
}

class _ZoneListScreenState extends State<ZoneListScreen> {
  late final AppState _appState;
  final DatabaseReference _zonesRef = FirebaseDatabase.instance.ref('zones');

  // --- Self-Contained Localization ---
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'all_zones': 'All Zones',
      'moisture': 'Moisture',
      'temp': 'Temp',
      'error_loading': 'Error loading zones from database:',
      'no_zones_in_db': 'No zones found in the database at /zones.',
    },
    'hi': {
      'all_zones': 'सभी ज़ोन',
      'moisture': 'नमी',
      'temp': 'तापमान',
      'error_loading': 'डेटाबेस से ज़ोन लोड करने में त्रुटि:',
      'no_zones_in_db': 'डेटाबेस में /zones पर कोई ज़ोन नहीं मिला।',
    },
    'ne': {
      'all_zones': 'सबै क्षेत्रहरू',
      'moisture': 'नमी',
      'temp': 'तापमान',
      'error_loading': 'डाटाबेसबाट क्षेत्रहरू लोड गर्दा त्रुटि:',
      'no_zones_in_db': 'डाटाबेसको /zones मा कुनै क्षेत्रहरू फेला परेन।',
    },
  };

  String _tr(String key) {
    return _translations[_appState.locale.languageCode]?[key] ??
        _translations['en']![key]!;
  }
  // --- End of Localization ---

  @override
  void initState() {
    super.initState();
    _appState = ServiceLocator.get<AppState>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tr('all_zones'))),
      body: StreamBuilder<DatabaseEvent>(
        stream: _zonesRef.onValue,
        builder: (context, snap) {
          if (snap.hasError) {
            return _centerText(
              '${_tr('error_loading')}\n${snap.error}',
              icon: Icons.error,
              color: Colors.red,
            );
          }
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final event = snap.data;
          if (event == null ||
              !event.snapshot.exists ||
              event.snapshot.value == null) {
            return _centerText(_tr('no_zones_in_db'), icon: Icons.info_outline);
          }

          final zonesMap = Map<String, dynamic>.from(
            event.snapshot.value as Map,
          );
          final liveZones = zonesMap.entries.map((entry) {
            final zoneId = entry.key;
            final zoneData = Map<String, dynamic>.from(entry.value as Map);

            double toDouble(dynamic v) => (v is num)
                ? v.toDouble()
                : (double.tryParse(v.toString()) ?? 0.0);
            // --- FIX: Helper to convert timestamp to DateTime ---
            DateTime toDateTime(dynamic v) => (v is int)
                ? DateTime.fromMillisecondsSinceEpoch(v)
                : DateTime.now();

            return Zone(
              id: zoneId,
              name: zoneId,
              moisture: toDouble(
                zoneData['soil_pct'] ?? zoneData['moisture_pct'],
              ),
              temperature: toDouble(zoneData['temp_c']),
              mode:
                  (zoneData['mode']?.toString().toUpperCase() ?? 'AUTO') ==
                      'MANUAL'
                  ? ZoneIrrigationMode.manual
                  : ZoneIrrigationMode.auto,
              valveOpen:
                  (zoneData['valve_state']?.toString().toUpperCase() ??
                      'CLOSED') ==
                  'OPEN',
              ph: toDouble(zoneData['ph']),
              ec: toDouble(zoneData['ec']),
              // --- FIX: Added the required 'updatedAt' parameter ---
              updatedAt: toDateTime(zoneData['last_ts']),
            );
          }).toList()..sort((a, b) => a.name.compareTo(b.name));

          if (liveZones.isEmpty) {
            return _centerText(_tr('no_zones_in_db'), icon: Icons.info_outline);
          }

          return ListView.separated(
            itemCount: liveZones.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (_, i) {
              final z = liveZones[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Text(z.id.replaceAll(RegExp(r'[^0-9]'), '')),
                ),
                title: Text(z.name),
                subtitle: Text(
                  '${_tr('moisture')} ${z.moisture.toStringAsFixed(1)}% • '
                  '${_tr('temp')} ${z.temperature.toStringAsFixed(1)}°C',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      z.mode == ZoneIrrigationMode.auto
                          ? Icons.auto_mode
                          : Icons.handyman,
                      color: Theme.of(context).colorScheme.secondary,
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

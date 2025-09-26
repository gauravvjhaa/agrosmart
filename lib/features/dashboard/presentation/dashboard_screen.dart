import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/models/zone.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/state/app_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum ZoneMoistureState {
  criticallyDry,
  approachingDry,
  optimal,
  aboveTarget,
  stale,
}

class ZoneVisual {
  ZoneVisual({
    required this.state,
    required this.gradient,
    required this.label,
    required this.labelColor,
    required this.icon,
  });
  final ZoneMoistureState state;
  final List<Color> gradient;
  final String label;
  final Color labelColor;
  final IconData icon;
}

// Lightweight view model for live RTDB data
// Lightweight view model for live RTDB data
class UiZone {
  UiZone({
    required this.id,
    required this.name,
    required this.moisture,
    required this.temperature,
    required this.humidity,
    required this.tankLevel,
    required this.mode,
    required this.valveOpen,
    required this.updatedAt, // <-- ADD THIS
    this.ph,
  });

  final String id;
  final String name;
  final double moisture;
  final double temperature;
  final double humidity;
  final double tankLevel;
  final ZoneIrrigationMode mode;
  final bool valveOpen;
  final DateTime updatedAt; // <-- ADD THIS
  final double? ph;
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- Self-Contained Localization System ---
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'welcome': 'Welcome,',
      'farmer': 'Farmer',
      'temp': 'Temp',
      'humidity': 'Humidity',
      'ph': 'pH',
      'tank': 'Tank',
      'dry': 'DRY',
      'low': 'LOW',
      'ok': 'OK',
      'wet': 'WET',
      'stale': 'STALE',
      'auto': 'AUTO',
      'manual': 'MANUAL',
      'valve_open': 'VALVE OPEN',
      'closed': 'CLOSED',
      'zones': 'Zones',
      'irrigation': 'Irrigation',
      'automation': 'Automation',
      'crops': 'Crops',
      'community': 'Community',
      'audit': 'Audit',
      'support': 'Support',
      'tutorial': 'Tutorial',
      'settings': 'Settings',
      'error_loading_zones': 'Error loading zones',
      'no_zones_found': 'No zones found',
      'active_zones': 'Active Zones',
      'auto_zones': 'Auto Zones',
      'avg_moisture': 'Avg Moisture',
      'avg_temp': 'Avg Temp',
    },
    'hi': {
      'welcome': 'स्वागत है,',
      'farmer': 'किसान',
      'temp': 'तापमान',
      'humidity': 'नमी',
      'ph': 'पीएच',
      'tank': 'टैंक',
      'dry': 'सूखा',
      'low': 'कम',
      'ok': 'ठीक',
      'wet': 'गीला',
      'stale': 'बासी',
      'auto': 'ऑटो',
      'manual': 'मैनुअल',
      'valve_open': 'वाल्व खुला',
      'closed': 'बंद',
      'zones': 'ज़ोन',
      'irrigation': 'सिंचाई',
      'automation': 'स्वचालन',
      'crops': 'फसलें',
      'community': 'समुदाय',
      'audit': 'लेखा परीक्षा',
      'support': 'सहायता',
      'tutorial': 'ट्यूटोरियल',
      'settings': 'सेटिंग्स',
      'error_loading_zones': 'ज़ोन लोड करने में त्रुटि',
      'no_zones_found': 'कोई ज़ोन नहीं मिला',
      'active_zones': 'सक्रिय ज़ोन',
      'auto_zones': 'ऑटो ज़ोन',
      'avg_moisture': 'औसत नमी',
      'avg_temp': 'औसत तापमान',
    },
    'ne': {
      'welcome': 'स्वागत छ,',
      'farmer': 'किसान',
      'temp': 'तापमान',
      'humidity': 'आर्द्रता',
      'ph': 'pH',
      'tank': 'ट्याङ्की',
      'dry': 'सुख्खा',
      'low': 'कम',
      'ok': 'ठीक',
      'wet': 'भिजेको',
      'stale': 'बासी',
      'auto': 'स्वत:',
      'manual': 'म्यानुअल',
      'valve_open': 'भल्भ खुला',
      'closed': 'बन्द',
      'zones': 'क्षेत्रहरू',
      'irrigation': 'सिंचाई',
      'automation': 'स्वचालन',
      'crops': 'बालीहरू',
      'community': 'समुदाय',
      'audit': 'लेखा परीक्षण',
      'support': 'समर्थन',
      'tutorial': 'ट्यूटोरियल',
      'settings': 'सेटिङहरू',
      'error_loading_zones': 'क्षेत्रहरू लोड गर्दा त्रुटि',
      'no_zones_found': 'कुनै क्षेत्रहरू फेला परेनन्',
      'active_zones': 'सक्रिय क्षेत्रहरू',
      'auto_zones': 'स्वत: क्षेत्रहरू',
      'avg_moisture': 'औसत आर्द्रता',
      'avg_temp': 'औसत तापमान',
    },
  };

  String _tr(String key) {
    return _translations[_userLangCode]?[key] ?? _translations['en']![key]!;
  }
  // --- End of Localization System ---

  static const double _defaultThetaStart = 30;
  static const double _defaultThetaStop = 45;

  late final FirebaseDatabase _db;
  late final Stream<List<UiZone>> _zones$;

  bool _isUserLoading = true;
  String _userName = '';
  String _userLangCode = 'en'; // Default to English

  @override
  void initState() {
    super.initState();
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://agro-smart-dec18-default-rtdb.asia-southeast1.firebasedatabase.app',
    );
    _zones$ = _db
        .ref('zones')
        .onValue
        .map((e) => _mapZones(e.snapshot))
        .handleError((_) => <UiZone>[]);
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() => _isUserLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isUserLoading = false);
      return;
    }

    try {
      final userRef = _db.ref('farmers/${user.uid}');
      final nameSnapshot = await userRef.child('details/name').get();
      final langSnapshot = await userRef.child('preferences/language').get();

      final fetchedName = (nameSnapshot.exists && nameSnapshot.value != null)
          ? nameSnapshot.value.toString()
          : _tr('farmer');

      final fetchedLangName =
          (langSnapshot.exists && langSnapshot.value != null)
          ? langSnapshot.value.toString()
          : 'English';

      final langCode =
          {'English': 'en', 'Hindi': 'hi', 'Nepali': 'ne'}[fetchedLangName] ??
          'en';

      if (mounted) {
        setState(() {
          _userName = fetchedName;
          _userLangCode = langCode;
          _isUserLoading = false;
        });
      }
    } catch (e) {
      // Handle potential errors (e.g., network issues)
      if (mounted) {
        setState(() => _isUserLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ServiceLocator.get<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: _isUserLoading ? null : Text('${_tr('welcome')} $_userName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => appState.logout(),
          ),
        ],
      ),
      drawer: _drawer(context),
      body: _isUserLoading
          ? Center(
              child: SpinKitFadingCircle(
                color: Theme.of(context).primaryColor,
                size: 50.0,
              ),
            )
          : LayoutBuilder(
              builder: (_, constraints) {
                final wide = constraints.maxWidth > 1100;
                return StreamBuilder<List<UiZone>>(
                  stream: _zones$,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return Center(
                        child: SpinKitFadingCircle(
                          color: Theme.of(context).primaryColor,
                          size: 50.0,
                        ),
                      );
                    }
                    if (snap.hasError) {
                      return Center(child: Text(_tr('error_loading_zones')));
                    }
                    if (!snap.hasData || snap.data!.isEmpty) {
                      return Center(child: Text(_tr('no_zones_found')));
                    }

                    final liveZones = snap.data!;
                    return Row(
                      children: [
                        Expanded(
                          flex: wide ? 3 : 5,
                          child: _zoneGrid(liveZones, wide),
                        ),
                        if (wide)
                          Expanded(flex: 2, child: _metricsPanel(liveZones)),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  List<UiZone> _mapZones(DataSnapshot snapshot) {
    final value = snapshot.value;
    if (value is! Map) return <UiZone>[];

    final zonesMap = Map<String, dynamic>.from(value);

    double toDouble(dynamic v) =>
        (v is num) ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);
    // Helper to convert timestamp
    DateTime toDateTime(dynamic v) =>
        (v is int) ? DateTime.fromMillisecondsSinceEpoch(v) : DateTime.now();

    return zonesMap.entries.map((e) {
      final id = e.key;
      final m = Map<String, dynamic>.from(e.value as Map);

      return UiZone(
        id: id,
        name: id,
        moisture: toDouble(m['soil_pct']),
        temperature: toDouble(m['temp_c']),
        humidity: toDouble(m['humidity_pct']),
        tankLevel: toDouble(m['tank_level_pct']),
        ph: m.containsKey('ph') ? toDouble(m['ph']) : null,
        mode: (m['mode']?.toString().toUpperCase() ?? 'AUTO') == 'MANUAL'
            ? ZoneIrrigationMode.manual
            : ZoneIrrigationMode.auto,
        valveOpen:
            (m['valve_state']?.toString().toUpperCase() ?? 'CLOSED') == 'OPEN',
        updatedAt: toDateTime(m['last_ts']), // <-- ADD THIS
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  ZoneVisual _visualFor(double moisture) {
    final m = moisture;
    const margin = 4.0;
    ZoneMoistureState st;

    if (m < _defaultThetaStart - margin)
      st = ZoneMoistureState.criticallyDry;
    else if (m < _defaultThetaStart)
      st = ZoneMoistureState.approachingDry;
    else if (m <= _defaultThetaStop)
      st = ZoneMoistureState.optimal;
    else
      st = ZoneMoistureState.aboveTarget;

    switch (st) {
      case ZoneMoistureState.criticallyDry:
        return ZoneVisual(
          state: st,
          gradient: [const Color(0xFFD32F2F), const Color(0xFF8B0000)],
          label: _tr('dry'),
          labelColor: Colors.white,
          icon: Icons.warning_amber_rounded,
        );
      case ZoneMoistureState.approachingDry:
        return ZoneVisual(
          state: st,
          gradient: [const Color(0xFFFFA000), const Color(0xFFE65100)],
          label: _tr('low'),
          labelColor: Colors.black87,
          icon: Icons.water_drop,
        );
      case ZoneMoistureState.optimal:
        return ZoneVisual(
          state: st,
          gradient: [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
          label: _tr('ok'),
          labelColor: Colors.white,
          icon: Icons.check_circle,
        );
      case ZoneMoistureState.aboveTarget:
        return ZoneVisual(
          state: st,
          gradient: [const Color(0xFF1565C0), const Color(0xFF0D47A1)],
          label: _tr('wet'),
          labelColor: Colors.white,
          icon: Icons.invert_colors,
        );
      case ZoneMoistureState.stale:
        return ZoneVisual(
          state: st,
          gradient: [Colors.grey.shade500, Colors.grey.shade700],
          label: _tr('stale'),
          labelColor: Colors.white,
          icon: Icons.hourglass_bottom,
        );
    }
  }

  Widget _zoneGrid(List<UiZone> zones, bool wide) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 3 : 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: zones.length,
      itemBuilder: (_, i) => _zoneCard(zones[i]),
    );
  }

  Widget _zoneCard(UiZone zone) {
    final vis = _visualFor(zone.moisture);
    return InkWell(
      onTap: () {
        // Create a full `Zone` object to pass as the argument
        final zoneToPass = Zone(
          id: zone.id,
          name: zone.name,
          moisture: zone.moisture,
          temperature: zone.temperature,
          ph: zone.ph,
          valveOpen: zone.valveOpen,
          mode: zone.mode,
          updatedAt: zone.updatedAt,
        );
        Navigator.pushNamed(context, '/zone/detail', arguments: zoneToPass);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        // ... rest of the widget
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: vis.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: vis.gradient.last.withOpacity(.35),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    zone.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                _smallModeChip(zone.mode == ZoneIrrigationMode.auto),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(vis.icon, color: Colors.white.withOpacity(.95), size: 18),
                const SizedBox(width: 4),
                Text(
                  '${zone.moisture.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _stateChip(vis),
              ],
            ),
            const Spacer(),
            _infoRow(_tr('temp'), '${zone.temperature.toStringAsFixed(1)}°C'),
            _infoRow(_tr('humidity'), '${zone.humidity.toStringAsFixed(1)}%'),
            if (zone.ph != null)
              _infoRow(_tr('ph'), zone.ph!.toStringAsFixed(1)),
            _infoRow(_tr('tank'), '${zone.tankLevel.toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            Row(children: [_valveChip(zone.valveOpen), const Spacer()]),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stateChip(ZoneVisual vis) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(.35), width: 1),
      ),
      child: Text(
        vis.label,
        style: TextStyle(
          color: vis.labelColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _smallModeChip(bool auto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: auto
            ? Colors.white.withOpacity(.18)
            : Colors.purpleAccent.withOpacity(.28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(.35), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            auto ? Icons.auto_mode : Icons.handyman,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            auto ? _tr('auto') : _tr('manual'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _valveChip(bool open) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: open ? Colors.white.withOpacity(.22) : Colors.white12,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            open ? Icons.water : Icons.watch_off_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            open ? _tr('valve_open') : _tr('closed'),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsPanel(List<UiZone> liveZones) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _metricCard(
            _tr('active_zones'),
            liveZones.length.toString(),
            Icons.grass,
          ),
          _metricCard(
            _tr('auto_zones'),
            liveZones
                .where((z) => z.mode == ZoneIrrigationMode.auto)
                .length
                .toString(),
            Icons.auto_mode,
          ),
          _metricCard(
            _tr('avg_moisture'),
            '${_avgDouble(liveZones.map((e) => e.moisture)).toStringAsFixed(1)}%',
            Icons.water_drop,
          ),
          _metricCard(
            _tr('avg_temp'),
            '${_avgDouble(liveZones.map((e) => e.temperature)).toStringAsFixed(1)}°C',
            Icons.thermostat,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.auto_graph),
            label: Text(_tr('automation')),
            onPressed: () => Navigator.pushNamed(context, '/automation'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.timeline),
            label: Text(_tr('irrigation')),
            onPressed: () => Navigator.pushNamed(context, '/irrigation'),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(icon, color: Colors.green.shade800),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _avgDouble(Iterable<double> list) =>
      list.isEmpty ? 0 : list.reduce((a, b) => a + b) / list.length;

  Drawer _drawer(BuildContext context) => Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.green, Colors.lightGreen]),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              'AgroSmart',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _navTile(context, Icons.sensors, _tr('zones'), '/zones'),
        _navTile(context, Icons.water, _tr('irrigation'), '/irrigation'),
        _navTile(context, Icons.auto_mode, _tr('automation'), '/automation'),
        _navTile(context, Icons.spa, _tr('crops'), '/crops'),
        _navTile(context, Icons.people, _tr('community'), '/community'),
        _navTile(context, Icons.security, _tr('audit'), '/admin/audit'),
        _navTile(context, Icons.support_agent, _tr('support'), '/support'),
        _navTile(context, Icons.school, _tr('tutorial'), '/tutorial'),
        _navTile(context, Icons.settings, _tr('settings'), '/settings'),
      ],
    ),
  );

  ListTile _navTile(BuildContext c, IconData i, String t, String route) =>
      ListTile(
        leading: Icon(i),
        title: Text(t),
        onTap: () {
          Navigator.pop(c);
          Navigator.pushNamed(c, route);
        },
      );
}

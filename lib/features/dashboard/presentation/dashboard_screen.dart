import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/alert_service.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../core/models/zone.dart';
import '../../../core/state/app_state.dart';
import '../../../core/localization/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// ---- MOVED OUT: Enum must be top-level ----
enum ZoneMoistureState {
  criticallyDry,
  approachingDry,
  optimal,
  aboveTarget,
  stale,
}

// ---- MOVED OUT: Helper data carrier ----
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

class _DashboardScreenState extends State<DashboardScreen> {
  late final CacheService _cache;
  late final AlertService _alerts;
  late final MockDataService _mock;

  // Default thresholds (replace with per-zone values if you add them to Zone)
  static const double _defaultThetaStart = 30;
  static const double _defaultThetaStop = 45;

  @override
  void initState() {
    super.initState();
    _cache = ServiceLocator.get<CacheService>();
    _alerts = ServiceLocator.get<AlertService>();
    _mock = ServiceLocator.get<MockDataService>();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final zones = _cache.zones;
    final alerts = _alerts.generateAlerts(zones);
    final appState = ServiceLocator.get<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome, ${appState.username.isEmpty ? 'Farmer' : appState.username}',
        ),
        actions: [
          IconButton(
            tooltip: 'Random Tick',
            onPressed: () {
              setState(() {
                _mock.randomTick();
              });
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              appState.logout();
            },
          ),
        ],
      ),
      drawer: _drawer(context),
      body: LayoutBuilder(
        builder: (_, c) {
          final wide = c.maxWidth > 1100;
          return Column(
            children: [
              if (alerts.isNotEmpty) _alertBar(alerts),
              Expanded(
                child: Row(
                  children: [
                    Expanded(flex: wide ? 3 : 5, child: _zoneGrid(zones, wide)),
                    if (wide)
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              _metricCard(
                                'Active Zones',
                                zones.length.toString(),
                                Icons.grass,
                              ),
                              _metricCard(
                                'Auto Zones',
                                zones
                                    .where(
                                      (z) => z.mode == ZoneIrrigationMode.auto,
                                    )
                                    .length
                                    .toString(),
                                Icons.auto_mode,
                              ),
                              _metricCard(
                                'Avg Moisture',
                                _avg(zones.map((e) => e.moisture)),
                                Icons.water_drop,
                              ),
                              _metricCard(
                                'Avg Temp',
                                '${_avgDouble(zones.map((e) => e.temperature)).toStringAsFixed(1)}°C',
                                Icons.thermostat,
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                icon: const Icon(Icons.auto_graph),
                                label: const Text('Automation'),
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/automation'),
                              ),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                icon: const Icon(Icons.timeline),
                                label: const Text('Irrigation'),
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/irrigation'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Semantic visual mapping for a zone's moisture
  ZoneVisual _visualFor(Zone z) {
    final thetaStart = _defaultThetaStart;
    final thetaStop = _defaultThetaStop;
    final m = z.moisture;
    const margin = 4.0;

    ZoneMoistureState st;
    if (m < thetaStart - margin) {
      st = ZoneMoistureState.criticallyDry;
    } else if (m < thetaStart) {
      st = ZoneMoistureState.approachingDry;
    } else if (m <= thetaStop) {
      st = ZoneMoistureState.optimal;
    } else {
      st = ZoneMoistureState.aboveTarget;
    }

    // Potential stale detection hook (if zone.lastUpdate exists later)
    // if (z.lastUpdate != null &&
    //     DateTime.now().difference(z.lastUpdate!).inMinutes > 30) {
    //   st = ZoneMoistureState.stale;
    // }

    switch (st) {
      case ZoneMoistureState.criticallyDry:
        return ZoneVisual(
          state: st,
          gradient: [const Color(0xFFD32F2F), const Color(0xFF8B0000)],
          label: 'DRY',
          labelColor: Colors.white,
          icon: Icons.warning_amber_rounded,
        );
      case ZoneMoistureState.approachingDry:
        return ZoneVisual(
          state: st,
          gradient: [const Color(0xFFFFA000), const Color(0xFFE65100)],
          label: 'LOW',
          labelColor: Colors.black87,
          icon: Icons.water_drop,
        );
      case ZoneMoistureState.optimal:
        return ZoneVisual(
          state: st,
          gradient: [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
          label: 'OK',
          labelColor: Colors.white,
          icon: Icons.check_circle,
        );
      case ZoneMoistureState.aboveTarget:
        return ZoneVisual(
          state: st,
          gradient: [const Color(0xFF1565C0), const Color(0xFF0D47A1)],
          label: 'WET',
          labelColor: Colors.white,
          icon: Icons.invert_colors,
        );
      case ZoneMoistureState.stale:
        return ZoneVisual(
          state: st,
          gradient: [Colors.grey.shade500, Colors.grey.shade700],
          label: 'STALE',
          labelColor: Colors.white,
          icon: Icons.hourglass_bottom,
        );
    }
  }

  Widget _zoneGrid(List<Zone> zones, bool wide) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 3 : 2,
        childAspectRatio: 1.05,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: zones.length,
      itemBuilder: (_, i) => _zoneCard(zones[i]),
    );
  }

  Widget _zoneCard(Zone zone) {
    final vis = _visualFor(zone);

    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/zone/detail', arguments: zone),
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
        padding: const EdgeInsets.all(14),
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
                      letterSpacing: .5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _smallModeChip(zone),
              ],
            ),
            const SizedBox(height: 6),
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
            Text(
              'Temp: ${zone.temperature.toStringAsFixed(1)}°C',
              style: const TextStyle(color: Colors.white),
            ),
            if (zone.ph != null)
              Text(
                'pH: ${zone.ph!.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white),
              ),
            const SizedBox(height: 8),
            Row(children: [_valveChip(zone), const Spacer()]),
          ],
        ),
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
          letterSpacing: .5,
        ),
      ),
    );
  }

  Widget _smallModeChip(Zone zone) {
    final auto = zone.mode == ZoneIrrigationMode.auto;
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
            auto ? 'AUTO' : 'MANUAL',
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

  Widget _valveChip(Zone z) {
    final open = z.valveOpen;
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
            open ? 'VALVE OPEN' : 'CLOSED',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: .4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertBar(List<String> alerts) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(8),
    color: Colors.red.shade100,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: alerts
            .map(
              (a) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      a,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ),
  );

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

  String _avg(Iterable<double> list) =>
      _avgDouble(list).toStringAsFixed(1) + '%';

  double _avgDouble(Iterable<double> list) =>
      list.isEmpty ? 0 : list.reduce((a, b) => a + b) / list.length;

  Drawer _drawer(BuildContext context) => Drawer(
    child: ListView(
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
        _navTile(context, Icons.sensors, 'Zones', '/zones'),
        _navTile(context, Icons.water, 'Irrigation', '/irrigation'),
        _navTile(context, Icons.auto_mode, 'Automation', '/automation'),
        _navTile(context, Icons.spa, 'Crops', '/crops'),
        _navTile(context, Icons.people, 'Community', '/community'),
        _navTile(context, Icons.security, 'Audit', '/admin/audit'),
        _navTile(context, Icons.support_agent, 'Support', '/support'),
        _navTile(context, Icons.school, 'Tutorial', '/tutorial'),
        _navTile(context, Icons.settings, 'Settings', '/settings'),
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

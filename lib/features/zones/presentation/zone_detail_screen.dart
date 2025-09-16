import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../../../core/models/zone.dart';

// Realtime database mapped model
class RealtimeZoneData {
  final String command; // e.g. "AUTO"
  final DateTime commandTs;
  final double moisturePct; // moisture_pct
  final double tempC; // temp_c
  final double humidityPct; // humidity_pct
  final double soilPct; // soil_pct (if meaningful; else 0)
  final int thetaStartUsed; // theta_start_used
  final int thetaStopUsed; // theta_stop_used
  final String valveState; // valve_state
  final DateTime lastTs;

  RealtimeZoneData({
    required this.command,
    required this.commandTs,
    required this.moisturePct,
    required this.tempC,
    required this.humidityPct,
    required this.soilPct,
    required this.thetaStartUsed,
    required this.thetaStopUsed,
    required this.valveState,
    required this.lastTs,
  });
}

class ZoneDetailScreen extends StatefulWidget {
  final Zone zone;
  const ZoneDetailScreen({super.key, required this.zone});

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  static const String _dbUrl =
      'https://agro-smart-dec18-default-rtdb.asia-southeast1.firebasedatabase.app/';
  RealtimeZoneData? _rt;
  bool _loading = true;
  String? _error;
  StreamSubscription<DatabaseEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    // Use refFromURL to avoid needing instanceFor(app: ...)
    final ref = FirebaseDatabase.instance.refFromURL(
      'https://agro-smart-dec18-default-rtdb.asia-southeast1.firebasedatabase.app/zones/Z1',
    );
    _sub = ref.onValue.listen(
      (event) {
        final snap = event.snapshot;
        if (snap.exists && snap.value is Map) {
          _rt = _mapSnapshot(Map<String, dynamic>.from(snap.value as Map));
        } else {
          _rt = _fallbackData();
        }
        if (mounted) {
          setState(() {
            _loading = false;
            _error = null;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _rt = _fallbackData();
            _loading = false;
          });
        }
      },
    );
  }

  RealtimeZoneData _mapSnapshot(Map<String, dynamic> m) {
    return RealtimeZoneData(
      command: (m['command'] ?? 'AUTO').toString(),
      commandTs: _toDT(m['command_ts']),
      moisturePct: _toD(m['moisture_pct'], fallback: widget.zone.moisture),
      tempC: _toD(m['temp_c'], fallback: widget.zone.temperature),
      humidityPct: _toD(m['humidity_pct'], fallback: 60),
      soilPct: _toD(m['soil_pct'], fallback: 0),
      thetaStartUsed: _toI(m['theta_start_used'], fallback: 28),
      thetaStopUsed: _toI(m['theta_stop_used'], fallback: 42),
      valveState:
          (m['valve_state'] ?? (widget.zone.valveOpen ? 'OPEN' : 'CLOSED'))
              .toString(),
      lastTs: _toDT(m['last_ts']),
    );
  }

  DateTime _toDT(dynamic v) => v is int
      ? DateTime.fromMillisecondsSinceEpoch(v, isUtc: true)
      : DateTime.now().toUtc();
  double _toD(dynamic v, {required double fallback}) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  int _toI(dynamic v, {required int fallback}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  RealtimeZoneData _fallbackData() {
    if (widget.zone.id.toLowerCase() == 'z1' || widget.zone.id == 'zone_1') {
      // Your provided static sample (only used if live fetch fails)
      return RealtimeZoneData(
        command: 'AUTO',
        commandTs: DateTime.fromMillisecondsSinceEpoch(
          1758025555945,
          isUtc: true,
        ),
        moisturePct: 77,
        tempC: 25, // updated to match your latest sample (25)
        humidityPct: 73,
        soilPct: 0,
        thetaStartUsed: 30,
        thetaStopUsed: 45,
        valveState: 'OPEN',
        lastTs: DateTime.fromMillisecondsSinceEpoch(1758026273826, isUtc: true),
      );
    }
    final rnd = Random(widget.zone.id.hashCode);
    return RealtimeZoneData(
      command: widget.zone.mode == ZoneIrrigationMode.auto ? 'AUTO' : 'MANUAL',
      commandTs: DateTime.now().subtract(const Duration(minutes: 10)),
      moisturePct: widget.zone.moisture.clamp(0, 100),
      tempC: widget.zone.temperature,
      humidityPct: 55 + rnd.nextInt(25).toDouble(),
      soilPct: rnd.nextInt(4).toDouble(),
      thetaStartUsed: 28,
      thetaStopUsed: 42,
      valveState: widget.zone.valveOpen ? 'OPEN' : 'CLOSED',
      lastTs: DateTime.now().subtract(const Duration(minutes: 2)),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rt = _rt;
    return Scaffold(
      appBar: AppBar(title: Text(widget.zone.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : rt == null
          ? _errorWidget()
          : LayoutBuilder(
              builder: (_, c) {
                final wide = c.maxWidth > 900;
                final charts = _charts(context);
                // CHANGED: use the new StreamBuilder panel instead of static one
                final info = _infoPanelStream(context);
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: wide
                      ? Row(
                          children: [
                            Expanded(flex: 3, child: charts),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: info),
                          ],
                        )
                      : ListView(
                          children: [charts, const SizedBox(height: 20), info],
                        ),
                );
              },
            ),
    );
  }

  Widget _errorWidget() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error, color: Colors.red, size: 42),
        const SizedBox(height: 12),
        Text(_error ?? 'Unknown error'),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _loading = true;
              _error = null;
            });
            _sub?.cancel();
            _startListening();
          },
          child: const Text('Retry'),
        ),
      ],
    ),
  );

  Widget _charts(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trend Analysis', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _placeholderChart('Moisture % (Last 48h)', Colors.blue),
          const SizedBox(height: 16),
          _placeholderChart('Temperature (Last 48h)', Colors.orange),
          const SizedBox(height: 16),
          _placeholderChart('Humidity (Last 48h)', Colors.teal),
          const SizedBox(height: 16),
          _placeholderChart('pH & EC Variation', Colors.purple),
          const SizedBox(height: 16),
          _placeholderChart('Irrigation Events Overlay', Colors.green),
        ],
      ),
    ),
  );

  Widget _infoPanel(BuildContext context, RealtimeZoneData rt) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Snapshot',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _kv('Mode (command)', rt.command),
          _kv('Moisture', '${rt.moisturePct.toStringAsFixed(1)} %'),
          _kv('Temperature', '${rt.tempC.toStringAsFixed(1)} °C'),
          _kv('Humidity', '${rt.humidityPct.toStringAsFixed(0)} %'),
          if (widget.zone.ph != null)
            _kv('pH', widget.zone.ph!.toStringAsFixed(1)),
          if (widget.zone.ec != null)
            _kv('EC', '${widget.zone.ec!.toStringAsFixed(2)} mS/cm'),
          _kv('Valve', rt.valveState),
          _kv('Soil Raw (soil_pct)', rt.soilPct.toStringAsFixed(1)),
          _kv('Theta Start Used', '${rt.thetaStartUsed}%'),
          _kv('Theta Stop Used', '${rt.thetaStopUsed}%'),
          _kv('Command TS', rt.commandTs.toIso8601String()),
          _kv('Last Update', rt.lastTs.toIso8601String()),
          const Divider(height: 32),
          Text(
            'Irrigation Recommendation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(_recommendation(rt)),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: Text('Start ${_suggestedRunMinutes(rt)} min'),
            onPressed: () {},
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.auto_mode),
            label: Text(
              rt.command == 'AUTO' ? 'Already AUTO' : 'Switch to AUTO',
            ),
            onPressed: () {},
          ),
          const SizedBox(height: 24),
          Text(
            'Soil Chemistry',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'pH & EC stable. Continue current fertigation cycle. Adjust only if pH drift > ±0.5 next week.',
          ),
          const SizedBox(height: 24),
          Text(
            'Hardware Status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          _badge('Sensor', Icons.sensors, Colors.green),
          _badge('Valve', Icons.power, Colors.green),
          _badge('LoRa Link', Icons.wifi_tethering, Colors.green),
          _badge('Battery 78%', Icons.battery_5_bar, Colors.amber),
        ],
      ),
    ),
  );

  // ADDED: StreamBuilder wrapper to live-update info panel without altering existing logic.
  Widget _infoPanelStream(BuildContext context) {
    final ref = FirebaseDatabase.instance.refFromURL(
      // Keeping same hard-coded Z1 path to mirror existing _startListening behavior.
      'https://agro-smart-dec18-default-rtdb.asia-southeast1.firebasedatabase.app/zones/Z1',
    );
    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // fall back to existing error widget (does not modify original)
          return _errorWidget();
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            _rt == null) {
          return const Card(
            child: SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        RealtimeZoneData data;
        if (snapshot.hasData &&
            snapshot.data!.snapshot.value is Map<String, dynamic>) {
          data = _mapSnapshot(
            Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map),
          );
        } else if (snapshot.hasData && snapshot.data!.snapshot.value is Map) {
          // Handle non-typed Map (dynamic keys)
          data = _mapSnapshot(
            Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map),
          );
        } else {
          data = _rt ?? _fallbackData();
        }
        return _infoPanel(context, data);
      },
    );
  }

  String _recommendation(RealtimeZoneData rt) {
    final withinBand =
        rt.moisturePct >= rt.thetaStartUsed &&
        rt.moisturePct <= rt.thetaStopUsed;
    if (withinBand) {
      return 'Moisture within target band (${rt.thetaStartUsed}–${rt.thetaStopUsed}%). Monitor only.';
    } else if (rt.moisturePct < rt.thetaStartUsed) {
      final deficit = (rt.thetaStartUsed - rt.moisturePct).toStringAsFixed(1);
      return 'Below start threshold by $deficit%. Irrigation advisable.';
    } else {
      return 'Above stop threshold. Skip irrigation.';
    }
  }

  int _suggestedRunMinutes(RealtimeZoneData rt) {
    if (rt.moisturePct < rt.thetaStartUsed) {
      final gap = rt.thetaStartUsed - rt.moisturePct;
      return (5 + gap * 0.6).clamp(5, 20).round();
    }
    return 0;
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(k)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _placeholderChart(String title, Color color) => Container(
    height: 140,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        colors: [color.withOpacity(.15), color.withOpacity(.35)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    padding: const EdgeInsets.all(12),
    child: Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const Center(
          child: Text(
            'Chart Placeholder',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ],
    ),
  );

  Widget _badge(String text, IconData icon, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(text),
      backgroundColor: color.withOpacity(.12),
    ),
  );
}

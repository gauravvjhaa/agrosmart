import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/models/zone.dart';

// Realtime database mapped model
class RealtimeZoneData {
  final String command; // e.g. "AUTO" (mapped from zones.mode)
  final DateTime commandTs;
  final double moisturePct; // moisture_pct
  final double tempC; // temp_c
  final double humidityPct; // humidity_pct
  final double soilPct; // soil_pct (if meaningful; else 0)
  final int thetaStartUsed; // theta_start_used
  final int thetaStopUsed; // theta_stop_used
  final String valveState; // valve_state
  final DateTime lastTs;
  // ADDED: optional crop and lingo from DB
  final String? crop;
  // REMOVE USING ZONE-LEVEL LINGO; language comes from farmers prefs
  final String? lingo;
  final DateTime? valveLastOpened; // NEW

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
    this.crop,
    this.lingo,
    this.valveLastOpened, // NEW
  });
}

// Historical data model for charts
class SensorData {
  final DateTime timestamp;
  final double value;

  SensorData(this.timestamp, this.value);
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

  // Farmer language (from DB), selected crop, and thresholds
  String _lingo = 'en';
  String? _crop;
  double _thetaStart = 30;
  double _thetaStop = 45;
  StreamSubscription<DatabaseEvent>? _metaSub;

  // Historical data for charts
  List<SensorData> _moistureData = [];
  List<SensorData> _temperatureData = [];
  List<SensorData> _humidityData = [];
  List<SensorData> _tankLevelData = [];
  bool _chartsLoading = true;
  StreamSubscription<DatabaseEvent>? _historicalSub;

  // i18n: add Nepali and few extra keys
  final Map<String, Map<String, String>> _i18n = {
    'en': {
      'current_snapshot': 'Current Snapshot',
      'mode_command': 'Mode (command)',
      'moisture': 'Moisture',
      'temperature': 'Temperature',
      'humidity': 'Humidity',
      'ph': 'pH',
      'ec': 'EC',
      'valve': 'Valve',
      'soil_raw': 'Soil Raw (soil_pct)',
      'command_ts': 'Command TS',
      'last_update': 'Last Update',
      'irrigation_recommendation': 'Irrigation Recommendation',
      'tap_for_reco': 'Tap the title to get irrigation advice (coming soon)',
      'start': 'Start',
      'switch_auto': 'Switch to AUTO',
      'already_auto': 'Already AUTO',
      'soil_chemistry': 'Soil Chemistry',
      'chemistry_note':
          'pH & EC stable. Continue current fertigation cycle. Adjust only if pH drift > ±0.5 next week.',
      'hardware_status': 'Hardware Status',
      'sensor': 'Sensor',
      'valve_device': 'Valve',
      'lora_link': 'LoRa Link',
      'battery': 'Battery',
      'trend_analysis': 'Trend Analysis',
      'moisture_trend': 'Moisture % (Last 48h)',
      'temperature_trend': 'Temperature (Last 48h)',
      'humidity_trend': 'Humidity (Last 48h)',
      'tank_level_trend': 'Tank Level % (Last 48h)',
      'ph_ec_trend': 'pH & EC Variation',
      'irrigation_events': 'Irrigation Events Overlay',
      'chart_placeholder': 'Chart Placeholder',
      'retry': 'Retry',
      'select_crop': 'Select crop',
      'coming_soon': 'Coming soon: crop-based irrigation recommendation',
      'trend_analysis': 'Trend Analysis',
      'irrigation_recommendation': 'Irrigation Recommendation',
      'tap_for_reco': 'Tap the title to get irrigation advice (coming soon)',
      'auto_mode': 'Auto Mode',
      'valve': 'Valve',
      'open': 'OPEN',
      'closed': 'CLOSED',
      'thresholds': 'Moisture Thresholds',
      'start_threshold': 'Start (min %)',
      'stop_threshold': 'Stop (max %)',
      'tank_level': 'Tank Level',
    },
    'hi': {
      'current_snapshot': 'वर्तमान स्थिति',
      'mode_command': 'मोड (कमांड)',
      'moisture': 'नमी',
      'temperature': 'तापमान',
      'humidity': 'आर्द्रता',
      'ph': 'pH',
      'ec': 'EC',
      'valve': 'वाल्व',
      'soil_raw': 'मिट्टी रॉ (soil_pct)',
      'command_ts': 'कमांड समय',
      'last_update': 'अंतिम अपडेट',
      'irrigation_recommendation': 'सिंचाई सलाह',
      'tap_for_reco': 'सलाह देखने के लिए शीर्षक पर टैप करें (जल्द आ रहा है)',
      'start': 'शुरू',
      'switch_auto': 'ऑटो पर स्विच करें',
      'already_auto': 'पहले से ऑटो',
      'soil_chemistry': 'मृदा रसायन',
      'chemistry_note':
          'pH और EC स्थिर। वर्तमान फर्टिगेशन जारी रखें। अगले सप्ताह pH ±0.5 से अधिक बदले तो ही समायोजन करें।',
      'hardware_status': 'हार्डवेयर स्थिति',
      'sensor': 'सेंसर',
      'valve_device': 'वाल्व',
      'lora_link': 'LoRa लिंक',
      'battery': 'बैटरी',
      'trend_analysis': 'ट्रेंड विश्लेषण',
      'moisture_trend': 'नमी % (पिछले 48घंटे)',
      'temperature_trend': 'तापमान (पिछले 48घंटे)',
      'humidity_trend': 'आर्द्रता (पिछले 48घंटे)',
      'tank_level_trend': 'टैंक स्तर % (पिछले 48घंटे)',
      'ph_ec_trend': 'pH व EC परिवर्तन',
      'irrigation_events': 'सिंचाई घटनाएँ ओवरले',
      'chart_placeholder': 'चार्ट प्लेसहोल्डर',
      'retry': 'पुनः प्रयास',
      'select_crop': 'फसल चुनें',
      'coming_soon': 'जल्द आ रहा है: फसल-आधारित सिंचाई सलाह',
      'trend_analysis': 'प्रवृत्ति विश्लेषण',
      'irrigation_recommendation': 'सिँचाइ सिफारिस',
      'tap_for_reco': 'सिफारिस हेर्न शीर्षकमा ट्याप गर्नुहोस् (छिट्टै आउँदै)',
      'auto_mode': 'अटो मोड',
      'valve': 'वाल्व',
      'open': 'खुला',
      'closed': 'बन्द',
      'thresholds': 'नमी थ्रेसहोल्ड',
      'start_threshold': 'स्टार्ट (न्यूनतम %)',
      'stop_threshold': 'स्टॉप (अधिकतम %)',
      'tank_level': 'टैंक स्तर',
      // crop names
      'crop.Wheat': 'गेहूं',
      'crop.Rice': 'धान',
      'crop.Maize': 'मक्का',
      'crop.Tomato': 'टमाटर',
      'crop.Potato': 'आलू',
      'crop.Onion': 'प्याज़',
      'crop.Cotton': 'कपास',
    },
    'ne': {
      'current_snapshot': 'हालको स्थिति',
      'mode_command': 'मोड',
      'moisture': 'आर्द्रता',
      'temperature': 'तापक्रम',
      'humidity': 'आर्द्रता',
      'ph': 'pH',
      'ec': 'EC',
      'valve': 'भल्भ',
      'soil_raw': 'माटो (soil_pct)',
      'command_ts': 'कमाण्ड समय',
      'last_update': 'अन्तिम अपडेट',
      'irrigation_recommendation': 'सिँचाइ सिफारिस',
      'tap_for_reco': 'सिफारिस हेर्न शीर्षकमा ट्याप गर्नुहोस् (छिट्टै आउँदै)',
      'start': 'सुरु',
      'trend_analysis': 'प्रवृत्ति विश्लेषण',
      'moisture_trend': 'आर्द्रता % (४८ घण्टा)',
      'temperature_trend': 'तापक्रम (४८ घण्टा)',
      'humidity_trend': 'आर्द्रता (४८ घण्टा)',
      'tank_level_trend': 'ट्यांक स्तर % (४८ घण्टा)',
      'ph_ec_trend': 'pH र EC परिवर्तन',
      'irrigation_events': 'सिँचाइ घटनाहरू',
      'chart_placeholder': 'चार्ट प्लेसहोल्डर',
      'retry': 'फेरि प्रयास',
      'select_crop': 'बाली छान्नुहोस्',
      'coming_soon': 'छिट्टै: बाली-आधारित सिँचाइ सिफारिस',
      'auto_mode': 'अटो मोड',
      'open': 'खुला',
      'closed': 'बन्द',
      'thresholds': 'आर्द्रता थ्रेसहोल्ड',
      'start_threshold': 'सुरु (न्यून %)',
      'stop_threshold': 'रोक (अधिकतम %)',
      'tank_level': 'ट्यांक स्तर',
      // crop names
      'crop.Wheat': 'गहुँ',
      'crop.Rice': 'धान',
      'crop.Maize': 'मकै',
      'crop.Tomato': 'टमाटर',
      'crop.Potato': 'आलु',
      'crop.Onion': 'प्याज',
      'crop.Cotton': 'कपास',
    },
  };

  String t(String key) => _i18n[_lingo]?[key] ?? _i18n['en']![key] ?? key;
  String tCrop(String name) => _i18n[_lingo]?['crop.$name'] ?? name;

  final List<String> _crops = [
    'Wheat',
    'Rice',
    'Maize',
    'Tomato',
    'Potato',
    'Onion',
    'Cotton',
  ];

  DatabaseReference get _zoneRef => FirebaseDatabase.instance.refFromURL(
    '$_dbUrl'
    'zones/${widget.zone.id}',
  );
  DatabaseReference get _metaRef => FirebaseDatabase.instance.refFromURL(
    '$_dbUrl'
    'meta/${widget.zone.id}',
  );

  // NEW: Historical data reference for logs/Z1/, logs/Z2/, etc.
  DatabaseReference get _historicalRef => FirebaseDatabase.instance.refFromURL(
    '$_dbUrl'
    'logs/${widget.zone.id.toUpperCase()}/',
  );

  @override
  void initState() {
    super.initState();
    _loadUserLingo();
    _startListening();
    _startMetaListening();
    _startHistoricalListening(); // NEW: Start listening to historical data
  }

  Future<void> _loadUserLingo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseDatabase.instance
        .refFromURL(
          '$_dbUrl'
          'farmers/${user.uid}/preferences/language',
        )
        .get();
    if (!mounted) return;
    if (snap.exists && snap.value is String) {
      final name = snap.value as String;
      final code =
          {'English': 'en', 'Hindi': 'hi', 'Nepali': 'ne'}[name] ?? 'en';
      setState(() => _lingo = code);
    }
  }

  void _startMetaListening() {
    _metaSub = _metaRef.onValue.listen((e) {
      final v = e.snapshot.value;
      if (v is Map) {
        final m = Map<String, dynamic>.from(v);
        setState(() {
          _thetaStart = _toD(
            m['theta_start_pct'],
            fallback: _thetaStart,
          ).clamp(0, 100);
          _thetaStop = _toD(
            m['theta_stop_pct'],
            fallback: _thetaStop,
          ).clamp(0, 100);
        });
      }
    });
  }

  // NEW: Start listening to historical data from logs/Z1/
  void _startHistoricalListening() {
    final fortyEightHoursAgo = DateTime.now().subtract(
      const Duration(hours: 48),
    );

    _historicalSub = _historicalRef
        .orderByChild('ts')
        .startAt(fortyEightHoursAgo.millisecondsSinceEpoch)
        .onValue
        .listen(
          (event) {
            if (event.snapshot.exists) {
              final Map<dynamic, dynamic> data =
                  event.snapshot.value as Map<dynamic, dynamic>;
              final moistureData = <SensorData>[];
              final temperatureData = <SensorData>[];
              final humidityData = <SensorData>[];
              final tankLevelData = <SensorData>[];

              data.forEach((key, value) {
                if (value is Map) {
                  final map = Map<String, dynamic>.from(value);
                  final timestamp = map['ts'];
                  if (timestamp is int) {
                    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);

                    // Add moisture data (soil_pct)
                    if (map['soil_pct'] != null) {
                      final moisture = _toDOrNaN(map['soil_pct']);
                      if (!moisture.isNaN) {
                        moistureData.add(SensorData(date, moisture));
                      }
                    }

                    // Add temperature data (temp_c)
                    if (map['temp_c'] != null) {
                      final temp = _toDOrNaN(map['temp_c']);
                      if (!temp.isNaN) {
                        temperatureData.add(SensorData(date, temp));
                      }
                    }

                    // Add humidity data (humidity_pct)
                    if (map['humidity_pct'] != null) {
                      final humidity = _toDOrNaN(map['humidity_pct']);
                      if (!humidity.isNaN) {
                        humidityData.add(SensorData(date, humidity));
                      }
                    }

                    // Add tank level data (tank_level_pct)
                    if (map['tank_level_pct'] != null) {
                      final tankLevel = _toDOrNaN(map['tank_level_pct']);
                      if (!tankLevel.isNaN) {
                        tankLevelData.add(SensorData(date, tankLevel));
                      }
                    }
                  }
                }
              });

              // Sort by timestamp
              moistureData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
              temperatureData.sort(
                (a, b) => a.timestamp.compareTo(b.timestamp),
              );
              humidityData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
              tankLevelData.sort((a, b) => a.timestamp.compareTo(b.timestamp));

              if (mounted) {
                setState(() {
                  _moistureData = moistureData;
                  _temperatureData = temperatureData;
                  _humidityData = humidityData;
                  _tankLevelData = tankLevelData;
                  _chartsLoading = false;
                });
              }
            } else {
              if (mounted) {
                setState(() {
                  _chartsLoading = false;
                });
              }
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _chartsLoading = false;
              });
            }
          },
        );
  }

  Timer? _openTimer; // NEW: periodic ticker
  Duration _openElapsed = Duration.zero; // NEW: elapsed display cache
  String? _lastValveState; // NEW: last known valve state from DB
  bool _gotFirstSnapshot = false; // NEW: guard to avoid stomping on first load

  void _startListening() {
    final ref = _zoneRef;
    _sub = ref.onValue.listen(
      (event) {
        // NEW: capture previous valve state before mapping new snapshot
        final prevState = _rt?.valveState.toUpperCase();
        // ...existing code...
        if (event.snapshot.exists && event.snapshot.value is Map) {
          _rt = _mapSnapshot(
            Map<String, dynamic>.from(event.snapshot.value as Map),
          );
          _crop ??= _rt!.crop;
        } else {
          _rt = _fallbackData();
        }

        // NEW: transition-aware stamping and timer seeding
        final nowState = _rt?.valveState.toUpperCase();
        if (!_gotFirstSnapshot) {
          // First snapshot: only stamp if OPEN and missing valve_last_opened
          if (nowState == 'OPEN' && _rt?.valveLastOpened == null) {
            _zoneRef.update({'valve_last_opened': ServerValue.timestamp});
          }
          _gotFirstSnapshot = true;
        } else {
          // Subsequent snapshots: stamp only on CLOSED -> OPEN transitions
          if (_lastValveState != 'OPEN' && nowState == 'OPEN') {
            _zoneRef.update({'valve_last_opened': ServerValue.timestamp});
          }
        }

        // Start/stop local timer using DB timestamp if available
        if (nowState == 'OPEN') {
          _startElapsedTimer(_rt?.valveLastOpened ?? DateTime.now().toUtc());
        } else {
          _stopElapsedTimer();
        }
        _lastValveState = nowState;

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

  // NEW: helper to parse nullable timestamp
  DateTime? _toDTNullable(dynamic v) =>
      v is int ? DateTime.fromMillisecondsSinceEpoch(v, isUtc: true) : null;

  // Add: formatters to render N.A on missing values
  String _fmtPct(double v) => v.isNaN ? 'N.A' : '${v.toStringAsFixed(1)} %';
  String _fmtPct0(double v) => v.isNaN ? 'N.A' : '${v.toStringAsFixed(0)} %';
  String _fmtPct1(double v) => v.isNaN ? 'N.A' : '${v.toStringAsFixed(1)} %';
  String _fmtTemp(double v) => v.isNaN ? 'N.A' : '${v.toStringAsFixed(1)} °C';
  String _fmtOptDouble(double? v, {int digits = 1, String unit = ''}) =>
      v == null
      ? 'N.A'
      : '${v.toStringAsFixed(digits)}${unit.isNotEmpty ? ' $unit' : ''}';

  // Add: NaN-friendly number parser (no defaults)
  double _toDOrNaN(dynamic v) {
    if (v == null) return double.nan;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? double.nan;
    return double.nan;
  }

  RealtimeZoneData _mapSnapshot(Map<String, dynamic> m) {
    return RealtimeZoneData(
      command: (m['mode'] ?? m['command'] ?? 'AUTO').toString().toUpperCase(),
      commandTs: _toDT(m['command_ts'] ?? m['last_ts']),
      // CHANGED: read as-is; if missing -> NaN (no widget defaults)
      moisturePct: _toDOrNaN(m['soil_pct'] ?? m['moisture_pct']),
      tempC: _toDOrNaN(m['temp_c']),
      humidityPct: _toDOrNaN(m['humidity_pct']),
      soilPct: _toDOrNaN(m['soil_pct']),
      // keep fields but not used for UI; thresholds come from meta
      thetaStartUsed: _thetaStart.round(),
      thetaStopUsed: _thetaStop.round(),
      valveState:
          (m['valve_state'] ?? (widget.zone.valveOpen ? 'OPEN' : 'CLOSED'))
              .toString(),
      lastTs: _toDT(m['last_ts']),
      crop: m['crop_type']?.toString(),
      lingo: null, // language is fetched from farmers prefs
      valveLastOpened: _toDTNullable(m['valve_last_opened']), // NEW
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
    // CHANGED: do not fabricate random values; mark as missing
    return RealtimeZoneData(
      command: widget.zone.mode == ZoneIrrigationMode.auto ? 'AUTO' : 'MANUAL',
      commandTs: DateTime.now().subtract(const Duration(minutes: 10)),
      moisturePct: double.nan,
      tempC: double.nan,
      humidityPct: double.nan,
      soilPct: double.nan,
      thetaStartUsed: _thetaStart.round(),
      thetaStopUsed: _thetaStop.round(),
      valveState: widget.zone.valveOpen ? 'OPEN' : 'CLOSED',
      lastTs: DateTime.now().subtract(const Duration(minutes: 2)),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _metaSub?.cancel();
    _historicalSub?.cancel(); // NEW: Cancel historical subscription
    _openTimer?.cancel(); // NEW
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rt = _rt;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.zone.name),
        // REMOVED: language picker actions; language comes from DB
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : rt == null
          ? _errorWidget()
          : LayoutBuilder(
              builder: (_, c) {
                final wide = c.maxWidth > 900;
                final charts = _charts(context);
                final info = _infoPanelStream(context);
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: wide
                      ? Row(
                          children: [
                            Expanded(flex: 2, child: info),
                            const SizedBox(width: 20),
                            Expanded(flex: 3, child: charts),
                          ],
                        )
                      : ListView(
                          children: [info, const SizedBox(height: 20), charts],
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
          // CHANGED: localized label
          child: Text(t('retry')),
        ),
      ],
    ),
  );

  // UPDATED: Real charts with actual data
  Widget _charts(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('trend_analysis'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _buildRealChart(t('moisture_trend'), _moistureData, Colors.blue, '%'),
          const SizedBox(height: 16),
          _buildRealChart(
            t('temperature_trend'),
            _temperatureData,
            Colors.orange,
            '°C',
          ),
          const SizedBox(height: 16),
          _buildRealChart(t('humidity_trend'), _humidityData, Colors.teal, '%'),
          const SizedBox(height: 16),
          _buildRealChart(
            t('tank_level_trend'),
            _tankLevelData,
            Colors.green,
            '%',
          ),
        ],
      ),
    ),
  );

  Widget _buildRealChart(
    String title,
    List<SensorData> data,
    Color color,
    String unit,
  ) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (data.isNotEmpty)
                Text(
                  'Latest: ${data.last.value.toStringAsFixed(1)}$unit',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _chartsLoading
                ? Center(child: CircularProgressIndicator(color: color))
                : data.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : SfCartesianChart(
                    margin: EdgeInsets.zero,
                    primaryXAxis: DateTimeAxis(
                      dateFormat: DateFormat.Hm(),
                      majorGridLines: const MajorGridLines(width: 0),
                      edgeLabelPlacement: EdgeLabelPlacement.shift,
                      intervalType: DateTimeIntervalType.hours,
                      interval: 6,
                    ),
                    primaryYAxis: NumericAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                    ),
                    series: <CartesianSeries>[
                      LineSeries<SensorData, DateTime>(
                        dataSource: data,
                        xValueMapper: (SensorData data, _) => data.timestamp,
                        yValueMapper: (SensorData data, _) => data.value,
                        color: color,
                        width: 2,
                        markerSettings: const MarkerSettings(
                          isVisible: true,
                          height: 3,
                          width: 3,
                        ),
                      ),
                    ],
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      format: 'point.x : point.y$unit',
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoPanel(BuildContext context, RealtimeZoneData rt) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('current_snapshot'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _kv(t('mode_command'), rt.command),
          // CHANGED: show N.A if missing
          _kv(t('moisture'), _fmtPct(rt.moisturePct)),
          _kv(t('temperature'), _fmtTemp(rt.tempC)),
          _kv(t('humidity'), _fmtPct0(rt.humidityPct)),
          _kv(t('soil_raw'), _fmtPct1(rt.soilPct)),
          // NEW: Add tank level from current data if available
          _kv(t('tank_level'), _fmtPct(_rt?.moisturePct ?? double.nan)),
          // CHANGED: always show pH/EC; print N.A if null
          _kv(t('ph'), _fmtOptDouble(widget.zone.ph, digits: 1)),
          _kv(t('ec'), _fmtOptDouble(widget.zone.ec, digits: 2, unit: 'mS/cm')),
          _kv(t('valve'), rt.valveState),
          // thresholds now from meta
          _kv(t('start_threshold'), '${_thetaStart.round()}%'),
          _kv(t('stop_threshold'), '${_thetaStop.round()}%'),
          _kv(t('command_ts'), rt.commandTs.toIso8601String()),
          _kv(t('last_update'), rt.lastTs.toIso8601String()),
          const Divider(height: 32),

          // Crop selector -> zones/{id}/crop_type
          DropdownButtonFormField<String>(
            value: _crop,
            isExpanded: true,
            hint: Text(t('select_crop')),
            items: _crops
                .map((c) => DropdownMenuItem(value: c, child: Text(tCrop(c))))
                .toList(),
            onChanged: (v) {
              setState(() => _crop = v);
              if (v != null) _zoneRef.update({'crop_type': v});
            },
          ),
          const SizedBox(height: 16),

          // Manual/Auto toggler -> zones/{id}/mode
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(t('auto_mode')),
            value: rt.command == 'AUTO',
            onChanged: (isAuto) {
              if (isAuto) {
                _zoneRef.update({
                  'mode': 'AUTO',
                  'min_thres': _thetaStart.round(),
                  'max_thres': _thetaStop.round(),
                });
              } else {
                _zoneRef.update({'mode': 'MANUAL'});
              }
            },
          ),

          // Valve toggle when MANUAL -> zones/{id}/valve_state
          if (rt.command == 'MANUAL') ...[
            const SizedBox(height: 6),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(t('valve')),
              value: rt.valveState.toUpperCase() == 'OPEN',
              onChanged: (open) {
                if (open) {
                  _zoneRef.update({
                    'valve_state': 'OPEN',
                    'valve_last_opened': ServerValue.timestamp,
                  });
                } else {
                  _zoneRef.update({'valve_state': 'CLOSED'});
                }
              },
              secondary: Icon(
                rt.valveState.toUpperCase() == 'OPEN'
                    ? Icons.power
                    : Icons.power_off,
                color: rt.valveState.toUpperCase() == 'OPEN'
                    ? Colors.green
                    : Colors.grey,
              ),
              subtitle: Text(
                rt.valveState.toUpperCase() == 'OPEN' ? t('open') : t('closed'),
              ),
            ),
          ],

          // SHOW thresholds ONLY in AUTO
          if (rt.command == 'AUTO') ...[
            const SizedBox(height: 12),
            Text(
              t('thresholds'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            // Start threshold slider (min)
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _thetaStart.clamp(0, _thetaStop - 1),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${_thetaStart.round()}%',
                    onChanged: (v) => setState(
                      () => _thetaStart = v.clamp(0, _thetaStop - 1),
                    ),
                    onChangeEnd: (v) {
                      _metaRef.update({
                        'theta_start_pct': v.round(),
                        'theta_stop_pct': _thetaStop.round(),
                        'updated_ts': ServerValue.timestamp,
                      });
                      // NEW: also persist in /zones
                      _zoneRef.update({
                        'min_thres': v.round(),
                        'max_thres': _thetaStop.round(),
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text('${_thetaStart.round()}%'),
              ],
            ),
            // Stop threshold slider (max)
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _thetaStop.clamp(_thetaStart + 1, 100),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${_thetaStop.round()}%',
                    onChanged: (v) => setState(
                      () => _thetaStop = v.clamp(_thetaStart + 1, 100),
                    ),
                    onChangeEnd: (v) {
                      _metaRef.update({
                        'theta_start_pct': _thetaStart.round(),
                        'theta_stop_pct': v.round(),
                        'updated_ts': ServerValue.timestamp,
                      });
                      // NEW: also persist in /zones
                      _zoneRef.update({
                        'min_thres': _thetaStart.round(),
                        'max_thres': v.round(),
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text('${_thetaStop.round()}%'),
              ],
            ),
          ],

          const Divider(height: 24),

          // REPLACED: quick action button -> read-only timer info (no onPressed, no play icon)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(.18),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rt.valveState.toUpperCase() == 'OPEN' &&
                            rt.valveLastOpened != null
                        ? '${t('open')} • ${_fmtElapsed(_openElapsed)}'
                        : t('closed'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ...existing Hardware Status block...
          Text(
            t('hardware_status'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          _badge(t('sensor'), Icons.sensors, Colors.green),
          _badge(t('valve'), Icons.power, Colors.green),
          _badge('LoRa', Icons.wifi_tethering, Colors.green),
          _badge('${t('battery')} N.A', Icons.battery_5_bar, Colors.amber),
        ],
      ),
    ),
  );

  Widget _infoPanelStream(BuildContext context) {
    final ref = _zoneRef;
    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
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

  // ADDED: show "coming soon" on recommendation tap
  void _showComingSoon() {
    final cropPart = _crop != null ? ' (${tCrop(_crop!)})' : '';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${t('coming_soon')}$cropPart')));
  }

  int _suggestedRunMinutes(RealtimeZoneData rt) {
    // Use meta thresholds for quick calc; capped range 0–20 min
    final start = _thetaStart;
    if (rt.moisturePct < start) {
      final gap = start - rt.moisturePct;
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

  Widget _badge(String text, IconData icon, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(text),
      backgroundColor: color.withOpacity(.12),
    ),
  );

  // NEW: start/stop ticker
  void _startElapsedTimer(DateTime startUtc) {
    _openTimer?.cancel();
    _tickElapsed(startUtc);
    _openTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickElapsed(startUtc),
    );
  }

  void _tickElapsed(DateTime startUtc) {
    setState(() => _openElapsed = DateTime.now().toUtc().difference(startUtc));
  }

  void _stopElapsedTimer() {
    _openTimer?.cancel();
    _openTimer = null;
    if (mounted) setState(() => _openElapsed = Duration.zero);
  }

  String _fmtElapsed(Duration d) {
    int h = d.inHours;
    int m = d.inMinutes.remainder(60);
    int s = d.inSeconds.remainder(60);
    return h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

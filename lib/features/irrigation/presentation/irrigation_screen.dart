import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class Zone {
  final String id;
  final String name;
  final double moisture;
  final double temperature;
  final bool valveOpen;
  final String mode;
  final String? cropType;

  Zone({
    required this.id,
    required this.name,
    required this.moisture,
    required this.temperature,
    required this.valveOpen,
    required this.mode,
    this.cropType,
  });
}

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  static const String _dbUrl =
      'https://agro-smart-dec18-default-rtdb.asia-southeast1.firebasedatabase.app/';

  String _language = 'English';
  bool _loading = true;
  List<Zone> _zones = [];

  // Translation maps
  final Map<String, Map<String, String>> _translations = {
    'English': {
      'irrigation_control': 'Irrigation Control',
      'open_all': 'Open All',
      'close_all': 'Close All',
      'moisture': 'Moisture',
      'temperature': 'Temperature',
      'crop': 'Crop',
      'soil_status': 'Soil Status',
      'valve_status': 'Valve Status',
      'auto_mode': 'Auto Mode',
      'manual_mode': 'Manual Mode',
      'open': 'OPEN',
      'closed': 'CLOSED',
      'dry': 'Dry',
      'optimal': 'Optimal',
      'wet': 'Wet',
      'very_dry': 'Very Dry',
      'very_wet': 'Very Wet',
      'batch_commands_queued': 'Commands sent',
      'all_zones_closed': 'All zones closed',
      'toggle_valve': 'Toggle Valve',
      'switch_mode': 'Switch Mode',
      'no_zones_available': 'No zones available',
      'loading': 'Loading...',
      'not_set': 'Not Set',
    },
    'Hindi': {
      'irrigation_control': 'सिंचाई नियंत्रण',
      'open_all': 'सभी खोलें',
      'close_all': 'सभी बंद करें',
      'moisture': 'नमी',
      'temperature': 'तापमान',
      'crop': 'फसल',
      'soil_status': 'मिट्टी की स्थिति',
      'valve_status': 'वाल्व स्थिति',
      'auto_mode': 'ऑटो मोड',
      'manual_mode': 'मैनुअल मोड',
      'open': 'खुला',
      'closed': 'बंद',
      'dry': 'सूखा',
      'optimal': 'उत्तम',
      'wet': 'गीला',
      'very_dry': 'बहुत सूखा',
      'very_wet': 'बहुत गीला',
      'batch_commands_queued': 'आदेश भेजे गए',
      'all_zones_closed': 'सभी जोन बंद',
      'toggle_valve': 'वाल्व टॉगल करें',
      'switch_mode': 'मोड बदलें',
      'no_zones_available': 'कोई जोन उपलब्ध नहीं',
      'loading': 'लोड हो रहा है...',
      'not_set': 'सेट नहीं',
    },
    'Nepali': {
      'irrigation_control': 'सिँचाइ नियन्त्रण',
      'open_all': 'सबै खोल्नुहोस्',
      'close_all': 'सबै बन्द गर्नुहोस्',
      'moisture': 'आर्द्रता',
      'temperature': 'तापक्रम',
      'crop': 'बाली',
      'soil_status': 'माटोको अवस्था',
      'valve_status': 'भल्भ अवस्था',
      'auto_mode': 'अटो मोड',
      'manual_mode': 'म्यानुअल मोड',
      'open': 'खुला',
      'closed': 'बन्द',
      'dry': 'सुख्खा',
      'optimal': 'उत्तम',
      'wet': 'भिजेको',
      'very_dry': 'धेरै सुख्खा',
      'very_wet': 'धेरै भिजेको',
      'batch_commands_queued': 'आदेशहरू पठाइयो',
      'all_zones_closed': 'सबै क्षेत्र बन्द',
      'toggle_valve': 'भल्भ टगल गर्नुहोस्',
      'switch_mode': 'मोड परिवर्तन गर्नुहोस्',
      'no_zones_available': 'कुनै क्षेत्र उपलब्ध छैन',
      'loading': 'लोड हुँदैछ...',
      'not_set': 'सेट गरिएको छैन',
    },
  };

  // Crop translations
  final Map<String, Map<String, String>> _cropTranslations = {
    'English': {
      'Wheat': 'Wheat',
      'Rice': 'Rice',
      'Maize': 'Maize',
      'Tomato': 'Tomato',
      'Potato': 'Potato',
      'Onion': 'Onion',
      'Cotton': 'Cotton',
    },
    'Hindi': {
      'Wheat': 'गेहूं',
      'Rice': 'धान',
      'Maize': 'मक्का',
      'Tomato': 'टमाटर',
      'Potato': 'आलू',
      'Onion': 'प्याज़',
      'Cotton': 'कपास',
    },
    'Nepali': {
      'Wheat': 'गहुँ',
      'Rice': 'धान',
      'Maize': 'मकै',
      'Tomato': 'टमाटर',
      'Potato': 'आलु',
      'Onion': 'प्याज',
      'Cotton': 'कपास',
    },
  };

  String t(String key) => _translations[_language]?[key] ?? key;
  String tCrop(String cropName) =>
      _cropTranslations[_language]?[cropName] ?? cropName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load user language preference
      await _loadUserLanguage();

      // Load zones data
      await _loadZones();

      setState(() {
        _loading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadUserLanguage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseDatabase.instance
            .ref('farmers/${user.uid}/preferences/language')
            .get();

        if (snapshot.exists && snapshot.value != null) {
          setState(() {
            _language = snapshot.value.toString();
          });
        }
      }
    } catch (e) {
      print('Error loading language: $e');
    }
  }

  Future<void> _loadZones() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('zones').get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> zonesData =
            snapshot.value as Map<dynamic, dynamic>;
        final List<Zone> zones = [];

        zonesData.forEach((zoneId, zoneData) {
          if (zoneData is Map) {
            final data = Map<String, dynamic>.from(zoneData);

            // Parse the data with safe defaults
            final moisture = _parseDouble(data['soil_pct']) ?? 0.0;
            final temperature = _parseDouble(data['temp_c']) ?? 0.0;
            final valveOpen =
                (data['valve_state'] ?? 'CLOSED').toString().toUpperCase() ==
                'OPEN';
            final mode = (data['mode'] ?? 'AUTO').toString();
            final cropType = data['crop_type']?.toString();

            zones.add(
              Zone(
                id: zoneId.toString(),
                name: 'Zone ${zoneId.toString().replaceAll('Z', '')}',
                moisture: moisture,
                temperature: temperature,
                valveOpen: valveOpen,
                mode: mode,
                cropType: cropType,
              ),
            );
          }
        });

        // Sort zones by ID (Z1, Z2, Z3, Z4)
        zones.sort((a, b) => a.id.compareTo(b.id));

        setState(() {
          _zones = zones;
        });
      }
    } catch (e) {
      print('Error loading zones: $e');
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _getSoilStatus(double soilPct) {
    if (soilPct < 20) return t('very_dry');
    if (soilPct < 40) return t('dry');
    if (soilPct < 70) return t('optimal');
    if (soilPct < 85) return t('wet');
    return t('very_wet');
  }

  Color _getSoilStatusColor(double soilPct) {
    if (soilPct < 20) return Colors.red;
    if (soilPct < 40) return Colors.orange;
    if (soilPct < 70) return Colors.green;
    if (soilPct < 85) return Colors.blue;
    return Colors.purple;
  }

  Future<void> _toggleValve(Zone zone) async {
    try {
      final newValveState = !zone.valveOpen;

      await FirebaseDatabase.instance
          .ref('zones/${zone.id}/valve_state')
          .set(newValveState ? 'OPEN' : 'CLOSED');

      // Update local state
      setState(() {
        final index = _zones.indexWhere((z) => z.id == zone.id);
        if (index != -1) {
          _zones[index] = Zone(
            id: zone.id,
            name: zone.name,
            moisture: zone.moisture,
            temperature: zone.temperature,
            valveOpen: newValveState,
            mode: zone.mode,
            cropType: zone.cropType,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${zone.name} ${newValveState ? t('open') : t('closed')}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update valve: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _switchMode(Zone zone) async {
    try {
      final newMode = zone.mode.toUpperCase() == 'AUTO' ? 'MANUAL' : 'AUTO';

      await FirebaseDatabase.instance.ref('zones/${zone.id}/mode').set(newMode);

      // Update local state
      setState(() {
        final index = _zones.indexWhere((z) => z.id == zone.id);
        if (index != -1) {
          _zones[index] = Zone(
            id: zone.id,
            name: zone.name,
            moisture: zone.moisture,
            temperature: zone.temperature,
            valveOpen: zone.valveOpen,
            mode: newMode,
            cropType: zone.cropType,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${zone.name} switched to ${newMode == 'AUTO' ? t('auto_mode') : t('manual_mode')}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to switch mode: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openAllZones() async {
    try {
      for (final zone in _zones) {
        await FirebaseDatabase.instance
            .ref('zones/${zone.id}/valve_state')
            .set('OPEN');
      }

      // Update local state
      setState(() {
        _zones = _zones
            .map(
              (zone) => Zone(
                id: zone.id,
                name: zone.name,
                moisture: zone.moisture,
                temperature: zone.temperature,
                valveOpen: true,
                mode: zone.mode,
                cropType: zone.cropType,
              ),
            )
            .toList();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('batch_commands_queued'))));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open all zones: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _closeAllZones() async {
    try {
      for (final zone in _zones) {
        await FirebaseDatabase.instance
            .ref('zones/${zone.id}/valve_state')
            .set('CLOSED');
      }

      // Update local state
      setState(() {
        _zones = _zones
            .map(
              (zone) => Zone(
                id: zone.id,
                name: zone.name,
                moisture: zone.moisture,
                temperature: zone.temperature,
                valveOpen: false,
                mode: zone.mode,
                cropType: zone.cropType,
              ),
            )
            .toList();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('all_zones_closed'))));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to close all zones: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(t('irrigation_control'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(t('loading')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('irrigation_control'))),
      body: Column(
        children: [
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: Text(t('open_all')),
                  onPressed: _openAllZones,
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.stop),
                  label: Text(t('close_all')),
                  onPressed: _closeAllZones,
                ),
              ],
            ),
          ),

          // Zones list
          Expanded(
            child: _zones.isEmpty
                ? Center(
                    child: Text(
                      t('no_zones_available'),
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _zones.length,
                    itemBuilder: (_, index) {
                      final zone = _zones[index];
                      final soilStatus = _getSoilStatus(zone.moisture);
                      final soilColor = _getSoilStatusColor(zone.moisture);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ExpansionTile(
                          leading: Icon(
                            zone.mode.toUpperCase() == 'AUTO'
                                ? Icons.auto_mode
                                : Icons.handyman,
                            color: zone.valveOpen ? Colors.green : Colors.grey,
                          ),
                          title: Text(zone.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${t('moisture')}: ${zone.moisture.toStringAsFixed(1)}% | '
                                '${t('temperature')}: ${zone.temperature.toStringAsFixed(1)}°C',
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  // Crop badge
                                  if (zone.cropType != null &&
                                      zone.cropType!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        border: Border.all(color: Colors.blue),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        tCrop(zone.cropType!),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  // Soil status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: soilColor.withOpacity(0.1),
                                      border: Border.all(color: soilColor),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      soilStatus,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: soilColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // Valve status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: zone.valveOpen
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      border: Border.all(
                                        color: zone.valveOpen
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      zone.valveOpen ? t('open') : t('closed'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: zone.valveOpen
                                            ? Colors.green
                                            : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Detailed information
                                  if (zone.cropType != null &&
                                      zone.cropType!.isNotEmpty)
                                    _buildInfoRow(
                                      Icons.agriculture,
                                      '${t('crop')}:',
                                      tCrop(zone.cropType!),
                                    ),

                                  _buildInfoRow(
                                    Icons.water_drop,
                                    '${t('soil_status')}:',
                                    '$soilStatus (${zone.moisture.toStringAsFixed(1)}%)',
                                  ),

                                  _buildInfoRow(
                                    Icons.power,
                                    '${t('valve_status')}:',
                                    zone.valveOpen ? t('open') : t('closed'),
                                  ),

                                  _buildInfoRow(
                                    Icons.settings,
                                    'Mode:',
                                    zone.mode.toUpperCase() == 'AUTO'
                                        ? t('auto_mode')
                                        : t('manual_mode'),
                                  ),

                                  const SizedBox(height: 16),

                                  // Action buttons
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: Icon(
                                          zone.valveOpen
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                        ),
                                        onPressed: () => _toggleValve(zone),
                                        label: Text(t('toggle_valve')),
                                      ),
                                      OutlinedButton.icon(
                                        icon: Icon(Icons.settings),
                                        onPressed: () => _switchMode(zone),
                                        label: Text(t('switch_mode')),
                                      ),
                                    ],
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

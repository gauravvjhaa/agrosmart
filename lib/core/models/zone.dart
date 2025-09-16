enum ZoneIrrigationMode { manual, auto }

class Zone {
  final String id;
  final String name;
  final double moisture; // %
  final double temperature;
  final double? ph;
  final double? ec;
  final bool valveOpen;
  final ZoneIrrigationMode mode;
  final String? cropId;
  final DateTime updatedAt;

  Zone({
    required this.id,
    required this.name,
    required this.moisture,
    required this.temperature,
    this.ph,
    this.ec,
    required this.valveOpen,
    required this.mode,
    required this.updatedAt,
    this.cropId,
  });

  Zone copyWith({
    double? moisture,
    double? temperature,
    double? ph,
    double? ec,
    bool? valveOpen,
    ZoneIrrigationMode? mode,
    DateTime? updatedAt,
    String? cropId,
  }) => Zone(
    id: id,
    name: name,
    moisture: moisture ?? this.moisture,
    temperature: temperature ?? this.temperature,
    ph: ph ?? this.ph,
    ec: ec ?? this.ec,
    valveOpen: valveOpen ?? this.valveOpen,
    mode: mode ?? this.mode,
    updatedAt: updatedAt ?? this.updatedAt,
    cropId: cropId ?? this.cropId,
  );
}

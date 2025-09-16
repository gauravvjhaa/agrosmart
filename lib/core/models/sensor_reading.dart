class SensorReading {
  final String zoneId;
  final DateTime ts;
  final double moisture;
  final double temperature;
  final double? ph;
  final double? ec;

  SensorReading({
    required this.zoneId,
    required this.ts,
    required this.moisture,
    required this.temperature,
    this.ph,
    this.ec,
  });
}

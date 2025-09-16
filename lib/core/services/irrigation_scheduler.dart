import 'cache_service.dart';
import 'weather_service.dart';
import '../models/zone.dart';

class IrrigationScheduler {
  final WeatherService weatherService;
  final CacheService cacheService;

  IrrigationScheduler({
    required this.weatherService,
    required this.cacheService,
  });

  List<Map<String, dynamic>> computeAutoCommands() {
    final forecastRain = weatherService.nextRainProbability();
    final cmds = <Map<String, dynamic>>[];
    for (final z in cacheService.zones) {
      if (z.mode != ZoneIrrigationMode.auto) continue;
      final lowerThreshold = 28.0; // TODO: derive from crop stage
      if (z.moisture < lowerThreshold && forecastRain < 0.6) {
        cmds.add({
          'zoneId': z.id,
          'action': 'OPEN',
          'durationSec': _predictDuration(z),
          'issuedBy': 'auto',
        });
      }
    }
    return cmds;
  }

  int _predictDuration(Zone z) {
    // Placeholder ML logic: adaptive factor based on deficit
    final deficit = (35 - z.moisture).clamp(5, 25);
    return (deficit * 20).toInt();
  }
}

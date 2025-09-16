import 'dart:math';
import '../models/zone.dart';
import 'cache_service.dart';

class MockDataService {
  final CacheService cache;
  final _rng = Random();
  MockDataService({required this.cache});

  void seed() {
    if (cache.zones.isNotEmpty) return;
    for (int i = 1; i <= 10; i++) {
      cache.upsertZone(
        Zone(
          id: 'zone_$i',
          name: 'Zone $i',
          moisture: 20 + _rng.nextDouble() * 35,
          temperature: 15 + _rng.nextDouble() * 12,
          ph: 5.5 + _rng.nextDouble() * 2.5,
          ec: 0.8 + _rng.nextDouble() * 1.2,
          valveOpen: _rng.nextBool(),
          mode: i.isOdd ? ZoneIrrigationMode.auto : ZoneIrrigationMode.manual,
          cropId: i.isEven ? 'crop_tomato' : 'crop_potato',
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  void randomTick() {
    for (final z in cache.zones) {
      final delta = (_rng.nextDouble() * 2) - 1;
      cache.upsertZone(
        z.copyWith(
          moisture: (z.moisture + delta).clamp(10, 70),
          temperature: (z.temperature + delta / 2).clamp(10, 35),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }
}

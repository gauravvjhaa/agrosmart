import '../models/zone.dart';

class AlertService {
  List<String> generateAlerts(List<Zone> zones) {
    final out = <String>[];
    for (final z in zones) {
      if (z.moisture < 20) out.add('CRITICAL: ${z.name} moisture very low');
      if (z.ph != null && (z.ph! < 5.5 || z.ph! > 8.0))
        out.add('pH out of range in ${z.name}');
    }
    return out;
  }
}

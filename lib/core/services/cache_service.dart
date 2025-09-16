import '../models/zone.dart';

class CacheService {
  final _zones = <String, Zone>{};
  final _pendingCommands = <Map<String, dynamic>>[];

  List<Zone> get zones => _zones.values.toList();
  void upsertZone(Zone z) => _zones[z.id] = z;

  void queueCommand(Map<String, dynamic> cmd) => _pendingCommands.add(cmd);
  List<Map<String, dynamic>> drainCommands() {
    final copy = List<Map<String, dynamic>>.from(_pendingCommands);
    _pendingCommands.clear();
    return copy;
  }
}

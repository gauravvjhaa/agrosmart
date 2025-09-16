import 'dart:async';
import 'cache_service.dart';
import 'connectivity_service.dart';

class OfflineSyncService {
  final CacheService cache;
  final ConnectivityService connectivity;
  Timer? _timer;

  OfflineSyncService({required this.cache, required this.connectivity}) {
    connectivity.onStatus.listen((online) {
      if (online) _flush();
    });
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (connectivity.isOnline) _flush();
    });
  }

  Future<void> _flush() async {
    final cmds = cache.drainCommands();
    if (cmds.isEmpty) return;
    // TODO: push to backend (Firestore/API)
    // Retry strategy can be added here
  }

  void dispose() => _timer?.cancel();
}

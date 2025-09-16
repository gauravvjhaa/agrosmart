import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/connectivity_service.dart';

class OfflineStatusBanner extends StatefulWidget {
  const OfflineStatusBanner({super.key});
  @override
  State<OfflineStatusBanner> createState() => _OfflineStatusBannerState();
}

class _OfflineStatusBannerState extends State<OfflineStatusBanner> {
  late final ConnectivityService _conn;
  bool _online = true;
  @override
  void initState() {
    super.initState();
    _conn = ServiceLocator.get<ConnectivityService>();
    _online = _conn.isOnline;
    _conn.onStatus.listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_online) return const SizedBox.shrink();
    return Container(
      color: Colors.orange,
      padding: const EdgeInsets.all(6),
      child: const Center(
        child: Text(
          'Offline mode: actions queued',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

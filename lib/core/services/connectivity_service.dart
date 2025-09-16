import 'dart:async';

class ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  bool _online = true;

  Stream<bool> get onStatus => _controller.stream;
  bool get isOnline => _online;

  void setOnline(bool v) {
    if (_online == v) return;
    _online = v;
    _controller.add(v);
  }

  void dispose() => _controller.close();
}

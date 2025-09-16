import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  bool loggedIn = false;
  String username = '';
  void login(String name) {
    username = name;
    loggedIn = true;
    notifyListeners();
  }

  void logout() {
    loggedIn = false;
    username = '';
    notifyListeners();
  }
}

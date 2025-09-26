import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// Helper map to convert between language names and codes
const Map<String, String> _languageCodeMap = {
  'English': 'en',
  'Hindi': 'hi',
  'Nepali': 'ne',
};

class AppState extends ChangeNotifier {
  // Authentication state
  bool loggedIn = false;
  String username = '';

  // App-wide theme and locale settings
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  bool _preferencesLoaded = false;

  /// Fetches user preferences from Firebase and updates the state.
  /// This should be called once after a user is authenticated.
  Future<void> fetchAndSetUserPreferences() async {
    // Prevent multiple fetches if already loaded
    if (_preferencesLoaded) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://agro-smart-dec18-default-rtdb.asia-southeast1.firebasedatabase.app',
      );
      final userPrefsRef = db.ref('farmers/${user.uid}/preferences');
      final snapshot = await userPrefsRef.get();

      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final themeStr = data['theme'] as String? ?? 'light';
        final langStr = data['language'] as String? ?? 'English';

        _themeMode = themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
        _locale = Locale(_languageCodeMap[langStr] ?? 'en');
        _preferencesLoaded = true;

        // Notify listeners to update the UI with the fetched preferences
        notifyListeners();
      }
    } catch (e) {
      // Handle potential errors (e.g., network issues)
      debugPrint("Error fetching user preferences: $e");
    }
  }

  /// Sets the login state from the Firebase auth stream.
  void setLoggedIn(bool isLoggedIn, {String? name}) {
    if (loggedIn != isLoggedIn) {
      loggedIn = isLoggedIn;
      username = name ?? '';
      if (!isLoggedIn) {
        // Reset preferences on logout
        _preferencesLoaded = false;
        _themeMode = ThemeMode.light;
        _locale = const Locale('en');
      }
      notifyListeners();
    }
  }

  /// Updates the theme and notifies listeners.
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  /// Updates the locale and notifies listeners.
  void setLocale(Locale locale) {
    if (_locale != locale) {
      _locale = locale;
      notifyListeners();
    }
  }

  /// Signs the user out of Firebase.
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}

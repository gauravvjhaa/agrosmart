import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/state/app_state.dart';

// Helper map to convert between language names and codes
const Map<String, String> _languageCodeMap = {
  'English': 'en',
  'Hindi': 'hi',
  'Nepali': 'ne',
};

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AppState _appState;
  DatabaseReference? _userPrefsRef;

  // Local state for UI
  ThemeMode _currentTheme = ThemeMode.light;
  String _currentLanguage = 'English';
  bool _isLoading = true;

  // --- Self-Contained Localization ---
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'voice_commands': 'Voice Commands',
      'voice_subtitle': 'Enable speech control',
      'roles_access': 'Roles & Access',
      'role_info_title': 'Your Role',
      'role_info_body':
          'You are registered as a "Farmer". For more details on roles and permissions, please contact us.',
      'maintenance_title': 'Feature Under Maintenance',
      'maintenance_body':
          'This feature is currently being worked on and will be available soon.',
      'call_us': 'Call Us',
      'email_us': 'Email Us',
      'close': 'Close',
    },
    'hi': {
      'settings': 'सेटिंग्स',
      'dark_mode': 'डार्क मोड',
      'language': 'भाषा',
      'voice_commands': 'आवाज आज्ञा',
      'voice_subtitle': 'बोलकर नियंत्रण सक्षम करें',
      'roles_access': 'भूमिकाएँ और पहुँच',
      'role_info_title': 'आपकी भूमिका',
      'role_info_body':
          'आप एक "किसान" के रूप में पंजीकृत हैं। भूमिकाओं और अनुमतियों के बारे में अधिक जानकारी के लिए, कृपया हमसे संपर्क करें।',
      'maintenance_title': 'सुविधा रखरखाव में है',
      'maintenance_body':
          'इस सुविधा पर वर्तमान में काम चल रहा है और यह जल्द ही उपलब्ध होगी।',
      'call_us': 'हमें कॉल करें',
      'email_us': 'हमें ईमेल करें',
      'close': 'बंद करें',
    },
    'ne': {
      'settings': 'सेटिङहरू',
      'dark_mode': 'डार्क मोड',
      'language': 'भाषा',
      'voice_commands': 'आवाज आदेशहरू',
      'voice_subtitle': 'वाणी नियन्त्रण सक्षम गर्नुहोस्',
      'roles_access': 'भूमिका र पहुँच',
      'role_info_title': 'तपाईंको भूमिका',
      'role_info_body':
          'तपाईं "किसान" को रूपमा दर्ता हुनुहुन्छ। भूमिकाहरू र अनुमतिहरूको बारेमा थप विवरणहरूको लागि, कृपया हामीलाई सम्पर्क गर्नुहोस्।',
      'maintenance_title': 'सुविधा मर्मत अन्तर्गत छ',
      'maintenance_body': 'यो सुविधा हाल निर्माणाधीन छ र चाँडै उपलब्ध हुनेछ।',
      'call_us': 'हामीलाई कल गर्नुहोस्',
      'email_us': 'हामीलाई इमेल गर्नुहोस्',
      'close': 'बन्द गर्नुहोस्',
    },
  };

  String _tr(String key) {
    return _translations[_appState.locale.languageCode]?[key] ??
        _translations['en']![key]!;
  }
  // --- End of Localization ---

  @override
  void initState() {
    super.initState();
    _appState = ServiceLocator.get<AppState>();
    _fetchInitialPreferences();
  }

  Future<void> _fetchInitialPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    _userPrefsRef = FirebaseDatabase.instance.ref(
      'farmers/${user.uid}/preferences',
    );

    final snapshot = await _userPrefsRef!.get();
    if (snapshot.exists && snapshot.value is Map) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final themeStr = data['theme'] as String? ?? 'light';
      final langStr = data['language'] as String? ?? 'English';

      if (mounted) {
        setState(() {
          _currentTheme = themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
          _currentLanguage = langStr;
          // Sync with global state
          _appState.setThemeMode(_currentTheme);
          _appState.setLocale(Locale(_languageCodeMap[langStr] ?? 'en'));
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTheme(bool isDark) async {
    final newThemeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    setState(() => _currentTheme = newThemeMode); // Update local UI first
    _appState.setThemeMode(newThemeMode); // Update global app state
    await _userPrefsRef?.update({'theme': isDark ? 'dark' : 'light'});
  }

  Future<void> _updateLanguage(String newLanguage) async {
    final newLocale = Locale(_languageCodeMap[newLanguage] ?? 'en');
    setState(() => _currentLanguage = newLanguage); // Update local UI
    _appState.setLocale(newLocale); // Update global app state
    await _userPrefsRef?.update({'language': newLanguage});
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(_tr('language')),
        children: _languageCodeMap.keys.map((lang) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _updateLanguage(lang);
            },
            child: Text(lang),
          );
        }).toList(),
      ),
    );
  }

  void _showRoleInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_tr('role_info_title')),
        content: Text(_tr('role_info_body')),
        actions: [
          TextButton(
            onPressed: () => launchUrl(Uri.parse('tel:+919354897359')),
            child: Text(_tr('call_us')),
          ),
          TextButton(
            onPressed: () => launchUrl(Uri.parse('mailto:ravv.apps@gmail.com')),
            child: Text(_tr('email_us')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_tr('close')),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_tr('maintenance_title')),
        content: Text(_tr('maintenance_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_tr('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Re-get app state to ensure it's the latest
    final appState = ServiceLocator.get<AppState>();

    return Scaffold(
      appBar: AppBar(title: Text(_tr('settings'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(_tr('dark_mode')),
                  value: _currentTheme == ThemeMode.dark,
                  onChanged: _updateTheme,
                  secondary: const Icon(Icons.brightness_6),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(_tr('language')),
                  subtitle: Text(_currentLanguage),
                  onTap: _showLanguageDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.voice_chat),
                  title: Text(_tr('voice_commands')),
                  subtitle: Text(_tr('voice_subtitle')),
                  onTap: _showMaintenanceDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: Text(_tr('roles_access')),
                  onTap: _showRoleInfoDialog,
                ),
              ],
            ),
    );
  }
}

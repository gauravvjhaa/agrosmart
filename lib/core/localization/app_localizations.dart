import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static final Map<String, Map<String, String>> _vals = {
    'en': {
      'dashboard': 'Dashboard',
      'zones': 'Zones',
      'irrigate': 'Irrigate',
      'auto_mode': 'AUTO',
      'manual_mode': 'MANUAL',
    },
    'hi': {
      'dashboard': 'डैशबोर्ड',
      'zones': 'ज़ोन',
      'irrigate': 'सिंचाई',
      'auto_mode': 'स्वचालित',
      'manual_mode': 'मैनुअल',
    },
  };

  String t(String key) => _vals[locale.languageCode]?[key] ?? key;
}

class _AppLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

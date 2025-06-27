import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LanguageHelper {
  static const String _languageCodeKey = 'languageCode';
  static const String _countryCodeKey = 'countryCode';
  static const String _languageSelectedKey = 'languageSelected';

  static Future<void> saveLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, locale.languageCode);
    await prefs.setString(_countryCodeKey, locale.countryCode ?? '');
    await prefs.setBool(_languageSelectedKey, true);
  }

  static Future<Locale?> getSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey);
    final countryCode = prefs.getString(_countryCodeKey);

    if (languageCode != null) {
      return Locale(languageCode, countryCode);
    }
    return null;
  }

  static Future<bool> isLanguageSelected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_languageSelectedKey) ?? false;
  }
}

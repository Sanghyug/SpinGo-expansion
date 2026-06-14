import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

enum AppLang { ko, en }

class LanguageManager {
  static const _key = 'app_language';
  static final ValueNotifier<AppLang> current = ValueNotifier<AppLang>(
      AppLang.ko);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code == 'en') {
      current.value = AppLang.en;
    } else {
      current.value = AppLang.ko;
    }
  }

  static Future<void> set(AppLang lang) async {
    current.value = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang == AppLang.en ? 'en' : 'ko');
  }
}

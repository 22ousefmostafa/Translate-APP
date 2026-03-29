import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static Box? _translationsBox;

  static Future<void> init() async {
    _translationsBox = await Hive.openBox('translations');
  }

  static Box get translationsBox => _translationsBox!;

  static Future<String?> getTranslation(String key) async {
    return _translationsBox?.get(key);
  }

  static Future<void> saveTranslation(String key, String value) async {
    await _translationsBox?.put(key, value);
  }

  static List<String> getAllKeys() {
    return _translationsBox?.keys.cast<String>().toList() ?? [];
  }

  static Future<void> clearAllTranslations() async {
    await _translationsBox?.clear();
  }

  static Future<void> clearTranslation(String key) async {
    await _translationsBox?.delete(key);
  }
}

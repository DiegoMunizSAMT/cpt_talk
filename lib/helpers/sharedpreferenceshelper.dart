import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();

  static Future<void> saveData(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }

  static Future<String> readData(String key) async {
    final prefs = await _prefs;
    String counter = prefs.getString(key) ?? "";
    return counter;
  }

  static Future<void> removeData(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }

  static Future<Map<String, dynamic>> readAll() async {
    final prefs = await _prefs;
    return prefs.getKeys().fold<Map<String, dynamic>>({}, (map, key) {
      map[key] = prefs.get(key);
      return map;
    });
  }
}

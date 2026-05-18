import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

class HistoryService {
  static const _key = 'gblackai_history';
  static const _maxEntries = 50;

  static Future<List<HistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final entries = <HistoryEntry>[];
    for (final e in raw) {
      try {
        entries.add(HistoryEntry.fromJson(jsonDecode(e) as Map<String, dynamic>));
      } catch (_) {}
    }
    return entries.reversed.toList();
  }

  static Future<void> save(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(entry.toJson()));
    if (raw.length > _maxEntries) raw.removeAt(0);
    await prefs.setStringList(_key, raw);
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((e) {
      try {
        return (jsonDecode(e) as Map)['id'] == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_key, raw);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

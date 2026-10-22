import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary_entry.dart';

class DiaryStorage {
  static const String _key = 'diary_entries_list';

  static Future<List<DiaryEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];
    List<DiaryEntry> entries = [];
    for (final item in rawList) {
      try {
        entries.add(DiaryEntry.fromJson(item));
      } catch (e) {
        // Skip corrupted items
      }
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  static Future<void> saveEntries(List<DiaryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = entries.map((e) => e.toJson()).toList();
    await prefs.setStringList(_key, stringList);
  }

  static Future<void> saveOrUpdateEntry(DiaryEntry entry) async {
    final entries = await loadEntries();
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.insert(0, entry);
    }
    await saveEntries(entries);
  }

  static Future<void> deleteEntry(String id) async {
    final entries = await loadEntries();
    entries.removeWhere((e) => e.id == id);
    await saveEntries(entries);
  }
}

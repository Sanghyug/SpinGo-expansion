import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScoreEntry {
  final String name;
  final int score;
  ScoreEntry(this.name, this.score);

  Map<String, dynamic> toJson() => {'name': name, 'score': score};
  static ScoreEntry fromJson(Map<String, dynamic> j) => ScoreEntry(j['name'] as String, j['score'] as int);
}

class ScoreManager {
  static const _key = 'leaderboard_top7';

  static Future<List<ScoreEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return [];
    final List list = jsonDecode(s);
    return list.map((e) => ScoreEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> save(List<ScoreEntry> items) async {
    final prefs = await SharedPreferences.getInstance();
    final s = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, s);
  }

  static Future<List<ScoreEntry>> addIfTop7(ScoreEntry entry) async {
    final items = await load();
    items.add(entry);
    items.sort((a, b) => b.score.compareTo(a.score)); // desc
    final top7 = items.take(7).toList();
    await save(top7);
    return top7;
  }

  static Future<bool> qualifies(int score) async {
    final items = await load();
    if (items.length < 7) return true;
    final worst = items.last.score;
    return score > worst;
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class ScoreStore {
  static const key = 'best_score';

  Future<int> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? 0;
  }

  Future<void> writeIfHigher(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(key) ?? 0;
    if (score > current) {
      await prefs.setInt(key, score);
    }
  }
}

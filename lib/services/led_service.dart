import 'package:http/http.dart' as http;

class LedService {
  static const String _ledIp = 'http://172.20.10.6';

  static final Map<String, int> _minigameScores = {
    'toilet': 0,
    'hangout': 0,
    'food': 0,
    'stage': 0,
    'festivalcleaner': 0,
  };
  static final Map<String, bool> _minigameCompleted = {
    'toilet': false,
    'hangout': false,
    'food': false,
    'stage': false,
    'festivalcleaner': false,
  };

  static final Map<String, bool> _minigameVisited = {
    'toilet': false,
    'hangout': false,
    'food': false,
    'stage': false,
    'festivalcleaner': false,
  };

  static Future<void> updateLeds(int points) async {
    try {
      final url = Uri.parse('$_ledIp/set?punten=$points');
      print('🔄 Sending request to: $url');
      await http.get(url).timeout(const Duration(seconds: 5));
      print('✅ LED updated successfully: $points punten');
    } catch (e) {
      print('❌ LED update failed: $e');
    }
  }

  static Future<void> addPoints(int points) async {
    print('📊 Adding points: $points');
    await updateLeds(points);
  }

  // Nieuw: minigame afronden + score opslaan
  static Future<void> completeMinigame(String name, int score) async {
    if (!_minigameScores.containsKey(name)) return;
    _minigameScores[name] = score;
    _minigameCompleted[name] = true;
    _minigameVisited[name] = true;
    await updateLeds(getTotalPoints());
  }

  // Nieuw: minigame markeren als geopend/gespeeld
  static void markMinigameOpened(String name) {
    if (_minigameVisited.containsKey(name)) {
      _minigameVisited[name] = true;
    }
  }

  // Nieuw: helpers
  static bool isMinigameCompleted(String name) =>
      _minigameCompleted[name] ?? false;

  static bool areAllMinigamesCompleted() =>
      _minigameCompleted.values.every((done) => done);

  static bool areAllMinigamesVisited() =>
      _minigameVisited.values.every((v) => v);

  static int getMinigameScore(String name) => _minigameScores[name] ?? 0;

  static int getTotalPoints() =>
      _minigameScores.values.fold(0, (sum, s) => sum + s);

  static Map<String, int> getAllScores() => Map.from(_minigameScores);

  static Map<String, bool> getCompletedStatus() => Map.from(_minigameCompleted);

  static Map<String, bool> getVisitedStatus() => Map.from(_minigameVisited);

  static Future<void> resetPoints() async {
    print('🔄 Resetting points to 0');
    _minigameScores.updateAll((_, __) => 0);
    _minigameCompleted.updateAll((_, __) => false);
    _minigameVisited.updateAll((_, __) => false);
    await updateLeds(0);
  }
}

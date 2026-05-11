class LedService {
  static Future<void> markMinigameOpened(String game) async {
    // TODO: connect real LED system later
    print('Minigame opened: $game');
  }

  static Future<void> completeMinigame(
    String game,
    int score,
  ) async {
    // TODO: connect real LED system later
    print('Minigame completed: $game with score $score');
  }
}
enum CompetitivePlayerId { p1, p2 }

enum CompetitiveItemType {
  bananaPeel, //good
  leaf, //good
  compost, //good
  sawdust, //good
  cigaretteBud, //bad
  gum, //bad
}

/// Result of a player trying to deposit an item.
enum DepositOutcome {
  correct,
  wrong,
  ignored,
}

/// Tunable values for round duration, spawn pace and penalties.
class GameConfig {
  final int gameDurationSec;
  final int startLives;
  final double startSpawnIntervalSec;
  final double minSpawnIntervalSec;
  final double startTtlSec;
  final double minTtlSec;
  final int pointsCorrect;
  final int penaltyWrong;
  final int penaltyMissed;

  const GameConfig({
    this.gameDurationSec = 60,
    this.startLives = 3,
    this.startSpawnIntervalSec = 2.2,
    this.minSpawnIntervalSec = 0.35,
    this.startTtlSec = 6.0,
    this.minTtlSec = 1.2,
    this.pointsCorrect = 1,
    this.penaltyWrong = 1,
    this.penaltyMissed = 0,
  });
}

/// Runtime player stats for the competitive round.
class CompetitivePlayerState {
  final CompetitivePlayerId id;
  int lives;
  int score;
  int correct;
  int wrong;

  CompetitivePlayerState({
    required this.id,
    required this.lives,
    this.score = 0,
    this.correct = 0,
    this.wrong = 0,
  });
}

/// One spawned piece of trash currently active in the arena.
class CompetitiveItemSpawn {
  final String id;
  final CompetitiveItemType type;
  final double spawnedAtSec;
  final double ttlSec;

  CompetitiveItemSpawn({
    required this.id,
    required this.type,
    required this.spawnedAtSec,
    required this.ttlSec,
  });

  bool isExpired(double nowSec) => nowSec - spawnedAtSec >= ttlSec;
}

/// Full mutable game state used by the timer-driven game loop.
class ToiletCompetitiveState {
  double elapsedSec;
  bool running;
  bool finished;
  final Map<CompetitivePlayerId, CompetitivePlayerState> players;
  final List<CompetitiveItemSpawn> activeItems;
  double nextSpawnAtSec;
  int idCounter;

  ToiletCompetitiveState({
    required this.elapsedSec,
    required this.running,
    required this.finished,
    required this.players,
    required this.activeItems,
    required this.nextSpawnAtSec,
    required this.idCounter,
  });
}
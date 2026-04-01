enum CompetitivePlayerId { p1, p2 }

/// The bin assigned to a player for this round.
enum BinType {
  organic,
  recycling,
}

/// Trash category used for game rules.
enum WasteType {
  organic,
  recycling,
  unrecyclable,
}

enum CompetitiveItemType {
  cigaretteBud,
  gum,
  bananaPeel,
  appleCore,
  leaf,
  metalCan,
  juiceBox,
  waterBottle,
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
  final BinType playerOneBin;
  final BinType playerTwoBin;
  final double organicSpawnShare;
  final double recyclingSpawnShare;

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
    this.playerOneBin = BinType.organic,
    this.playerTwoBin = BinType.recycling,
    this.organicSpawnShare = 0.45,
    this.recyclingSpawnShare = 0.45,
  });
}

/// Runtime player stats for the competitive round.
class CompetitivePlayerState {
  final CompetitivePlayerId id;
  final BinType binType;
  int lives;
  int score;
  int correct;
  int wrong;

  CompetitivePlayerState({
    required this.id,
    required this.binType,
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
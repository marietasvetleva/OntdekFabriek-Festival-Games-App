enum CompetitivePlayerId { p1, p2 }

enum BinType {
  organic,
  recycling,
}

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

enum DepositOutcome {
  correct,
  wrong,
  ignored,
}

/// Tunable values for round duration, pacing and penalties.
/// This is now Whack-A-Mole style:
/// - frequent spawn checks
/// - at most one new item per check
/// - active item cap changes over time
/// - TTL shrinks as the round progresses
class GameConfig {
  final int gameDurationSec;
  final int startLives;

  /// How often the game checks whether it should spawn ONE new item.
  final double spawnCheckIntervalSec;

  /// Intro phase duration where the game stays calmer.
  final double introDurationSec;

  /// Maximum simultaneous items on screen in different phases.
  final int startMaxActiveItems;
  final int midMaxActiveItems;
  final int lateMaxActiveItems;

  /// Chance to spawn one new item when a spawn check happens.
  final double startSpawnChance;
  final double midSpawnChance;
  final double lateSpawnChance;

  /// How long items stay alive in different phases.
  final double startTtlSec;
  final double midTtlSec;
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
    this.spawnCheckIntervalSec = 0.25,
    this.introDurationSec = 8.0,
    this.startMaxActiveItems = 1,
    this.midMaxActiveItems = 2,
    this.lateMaxActiveItems = 3,
    this.startSpawnChance = 0.35,
    this.midSpawnChance = 0.55,
    this.lateSpawnChance = 0.78,
    this.startTtlSec = 3.2,
    this.midTtlSec = 2.2,
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

class CompetitiveItemSpawn {
  final String id;
  final CompetitiveItemType type;
  final double spawnedAtSec;
  final double ttlSec;
  final double spawnXNorm;
  final double spawnYNorm;

  CompetitiveItemSpawn({
    required this.id,
    required this.type,
    required this.spawnedAtSec,
    required this.ttlSec,
    this.spawnXNorm = 0.5,
    this.spawnYNorm = 0.5,
  });

  bool isExpired(double nowSec) => nowSec - spawnedAtSec >= ttlSec;
}

class ToiletCompetitiveState {
  double elapsedSec;
  bool running;
  bool finished;

  final Map<CompetitivePlayerId, CompetitivePlayerState> players;
  final List<CompetitiveItemSpawn> activeItems;

  /// Time of next spawn check. Not an exact forced spawn.
  double nextSpawnCheckAtSec;
  // Backward-compatible field for older logic implementations.
  double nextSpawnAtSec;

  int idCounter;

  ToiletCompetitiveState({
    required this.elapsedSec,
    required this.running,
    required this.finished,
    required this.players,
    required this.activeItems,
    required this.nextSpawnCheckAtSec,
    this.nextSpawnAtSec = 0,
    required this.idCounter,
  });
}
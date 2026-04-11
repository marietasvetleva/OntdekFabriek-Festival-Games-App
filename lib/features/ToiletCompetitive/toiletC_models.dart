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

class GameConfig {
  final int gameDurationSec;
  final int startLives;
  final double spawnCheckIntervalSec;
  final double introDurationSec;
  final int startMaxActiveItems;
  final int midMaxActiveItems;
  final int lateMaxActiveItems;
  final double startSpawnChance;
  final double midSpawnChance;
  final double lateSpawnChance;
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

  bool isBeingHeld;
  double totalHeldSec;
  double? holdStartedAtSec;

  CompetitiveItemSpawn({
    required this.id,
    required this.type,
    required this.spawnedAtSec,
    required this.ttlSec,
    this.spawnXNorm = 0.5,
    this.spawnYNorm = 0.5,
    this.isBeingHeld = false,
    this.totalHeldSec = 0,
    this.holdStartedAtSec,
  });

  bool isExpired(double nowSec) {
    final activeAge = nowSec - spawnedAtSec - totalHeldSec;
    return activeAge >= ttlSec;
  }
}

class ToiletCompetitiveState {
  double elapsedSec;
  bool running;
  bool finished;

  final Map<CompetitivePlayerId, CompetitivePlayerState> players;
  final List<CompetitiveItemSpawn> activeItems;

  double nextSpawnCheckAtSec;
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
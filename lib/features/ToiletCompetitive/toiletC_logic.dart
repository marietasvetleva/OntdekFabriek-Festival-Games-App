import 'dart:math';

import 'toiletC_models.dart';

/// Core gameplay rules for the 2-player Toilet Competitive minigame.
class ToiletCompetitiveLogic {
  final GameConfig config;
  final Random _rng;

  ToiletCompetitiveLogic({
    this.config = const GameConfig(),
    Random? random,
  }) : _rng = random ?? Random();

  /// Creates an empty state before a round starts.
  ToiletCompetitiveState createInitialState() {
    return ToiletCompetitiveState(
      elapsedSec: 0,
      running: false,
      finished: false,
      players: {
        CompetitivePlayerId.p1: CompetitivePlayerState(
          id: CompetitivePlayerId.p1,
          binType: config.playerOneBin,
          lives: config.startLives,
        ),
        CompetitivePlayerId.p2: CompetitivePlayerState(
          id: CompetitivePlayerId.p2,
          binType: config.playerTwoBin,
          lives: config.startLives,
        ),
      },
      activeItems: <CompetitiveItemSpawn>[],
      nextSpawnAtSec: 0,
      idCounter: 0,
    );
  }

  /// Starts or restarts a match.
  void start(ToiletCompetitiveState state) {
    state.elapsedSec = 0;
    state.running = true;
    state.finished = false;
    state.activeItems.clear();
    state.nextSpawnAtSec = 0;
    state.idCounter = 0;

    for (final player in state.players.values) {
      player.lives = config.startLives;
      player.score = 0;
      player.correct = 0;
      player.wrong = 0;
    }
  }

  /// Advances time, updates spawn pacing, and expires old items.
  void tick(ToiletCompetitiveState state, double dtSec) {
    if (!state.running || state.finished) return;

    state.elapsedSec += dtSec;
    if (state.elapsedSec >= config.gameDurationSec) {
      state.elapsedSec = config.gameDurationSec.toDouble();
      state.running = false;
      state.finished = true;
      _expireItems(state);
      return;
    }

    while (state.elapsedSec >= state.nextSpawnAtSec) {
      _spawnOne(state);
      state.nextSpawnAtSec += _currentSpawnIntervalSec(state);
    }

    _expireItems(state);
    if (isGameOver(state)) {
      state.running = false;
      state.finished = true;
    }
  }

  /// Handles a player dropping an item into their bin.
  DepositOutcome depositItem({
    required ToiletCompetitiveState state,
    required CompetitivePlayerId playerId,
    required String itemId,
  }) {
    if (!state.running || state.finished) return DepositOutcome.ignored;

    CompetitiveItemSpawn? item;
    for (final it in state.activeItems) {
      if (it.id == itemId) {
        item = it;
        break;
      }
    }
    if (item == null) {
      return DepositOutcome.ignored;
    }

    state.activeItems.remove(item);
    final player = state.players[playerId]!;

    if (isCorrectForPlayer(player.binType, item.type)) {
      player.score += config.pointsCorrect;
      player.correct += 1;
      return DepositOutcome.correct;
    }

    player.lives -= config.penaltyWrong;
    player.wrong += 1;

    if (isGameOver(state)) {
      state.running = false;
      state.finished = true;
    }
    return DepositOutcome.wrong;
  }

  /// Returns remaining round time in seconds.
  double timeLeftSec(ToiletCompetitiveState state) {
    return max(0, config.gameDurationSec - state.elapsedSec);
  }

  /// Returns true when the match should stop.
  bool isGameOver(ToiletCompetitiveState state) {
    final p1Lives = state.players[CompetitivePlayerId.p1]!.lives;
    final p2Lives = state.players[CompetitivePlayerId.p2]!.lives;
    return p1Lives <= 0 ||
        p2Lives <= 0 ||
        state.elapsedSec >= config.gameDurationSec;
  }

  /// Returns winner by score, then lives; null on exact tie.
  CompetitivePlayerId? winner(ToiletCompetitiveState state) {
    final p1 = state.players[CompetitivePlayerId.p1]!;
    final p2 = state.players[CompetitivePlayerId.p2]!;

    if (p1.score > p2.score) return CompetitivePlayerId.p1;
    if (p2.score > p1.score) return CompetitivePlayerId.p2;
    if (p1.lives > p2.lives) return CompetitivePlayerId.p1;
    if (p2.lives > p1.lives) return CompetitivePlayerId.p2;
    return null;
  }

  /// Returns the waste category for an item type.
  WasteType wasteTypeForItem(CompetitiveItemType type) => _wasteTypeOf(type);

  /// Keeps UI compatibility: true for scorable items, false for unrecyclable.
  bool isGoodItem(CompetitiveItemType type) {
    return wasteTypeForItem(type) != WasteType.unrecyclable;
  }

  /// True when the given item matches the player's assigned bin.
  bool isCorrectForPlayer(BinType playerBin, CompetitiveItemType itemType) {
    final wasteType = wasteTypeForItem(itemType);
    if (wasteType == WasteType.unrecyclable) return false;
    return (playerBin == BinType.organic && wasteType == WasteType.organic) ||
        (playerBin == BinType.recycling && wasteType == WasteType.recycling);
  }

  /// How far through its TTL the item is: 0 at spawn, 1 when expired.
  double itemAgeProgress(
    ToiletCompetitiveState state,
    CompetitiveItemSpawn item,
  ) {
    final age = state.elapsedSec - item.spawnedAtSec;
    if (item.ttlSec <= 0) return 1;
    return (age / item.ttlSec).clamp(0.0, 1.0);
  }

  /// Maps TTL progress to a pixel size (large when new, small near expiry).
  double itemDisplaySizePixels({
    required ToiletCompetitiveState state,
    required CompetitiveItemSpawn item,
    required double maxSize,
    required double minSize,
  }) {
    final t = itemAgeProgress(state, item);
    return maxSize + (minSize - maxSize) * t;
  }

  // ===========================================================================
  // Helper methods
  // ===========================================================================

  /// Returns 0..1 progress from round start to end.
  double _progress(ToiletCompetitiveState state) {
    return (state.elapsedSec / config.gameDurationSec).clamp(0.0, 1.0);
  }

  /// Exponential interpolation used for spawn and ttl curves.
  double _expLerp({
    required double start,
    required double end,
    required double progress,
  }) {
    return start * pow(end / start, progress).toDouble();
  }

  /// Gets current spawn interval based on elapsed time.
  double _currentSpawnIntervalSec(ToiletCompetitiveState state) {
    return _expLerp(
      start: config.startSpawnIntervalSec,
      end: config.minSpawnIntervalSec,
      progress: _progress(state),
    );
  }

  /// Gets current item TTL based on elapsed time.
  double _currentTtlSec(ToiletCompetitiveState state) {
    return _expLerp(
      start: config.startTtlSec,
      end: config.minTtlSec,
      progress: _progress(state),
    );
  }

  /// Spawns one random item with current TTL settings.
  void _spawnOne(ToiletCompetitiveState state) {
    final item = CompetitiveItemSpawn(
      id: 'i_${state.idCounter++}',
      type: _rollItemType(),
      spawnedAtSec: state.elapsedSec,
      ttlSec: _currentTtlSec(state),
    );
    state.activeItems.add(item);
  }

  /// Removes expired items and applies missed penalties if configured.
  void _expireItems(ToiletCompetitiveState state) {
    if (state.activeItems.isEmpty) return;

    final expired = <CompetitiveItemSpawn>[];
    for (final item in state.activeItems) {
      if (item.isExpired(state.elapsedSec)) expired.add(item);
    }
    if (expired.isEmpty) return;

    for (final item in expired) {
      state.activeItems.remove(item);
    }

    if (config.penaltyMissed > 0) {
      for (final player in state.players.values) {
        player.lives -= config.penaltyMissed;
      }
    }
  }

  /// Rolls random item type with fair category shares by default.
  CompetitiveItemType _rollItemType() {
    const organicItems = <CompetitiveItemType>[
      CompetitiveItemType.bananaPeel,
      CompetitiveItemType.appleCore,
      CompetitiveItemType.leaf,
    ];
    const recyclingItems = <CompetitiveItemType>[
      CompetitiveItemType.metalCan,
      CompetitiveItemType.juiceBox,
      CompetitiveItemType.waterBottle,
    ];
    const unrecyclableItems = <CompetitiveItemType>[
      CompetitiveItemType.cigaretteBud,
      CompetitiveItemType.gum,
    ];

    final organicShare = config.organicSpawnShare.clamp(0.0, 1.0);
    final recyclingShare = config.recyclingSpawnShare.clamp(0.0, 1.0);
    final totalShare = organicShare + recyclingShare;
    final normalizedOrganic = totalShare > 0 ? organicShare / totalShare : 0.5;
    final normalizedRecycling =
        totalShare > 0 ? recyclingShare / totalShare : 0.5;

    final unrecyclableShare = (1.0 - totalShare).clamp(0.0, 1.0);
    final r = _rng.nextDouble();

    if (r < normalizedOrganic * (1 - unrecyclableShare)) {
      return organicItems[_rng.nextInt(organicItems.length)];
    }
    if (r < (normalizedOrganic + normalizedRecycling) * (1 - unrecyclableShare)) {
      return recyclingItems[_rng.nextInt(recyclingItems.length)];
    }
    return unrecyclableItems[_rng.nextInt(unrecyclableItems.length)];
  }

  /// Maps concrete items to their bin category.
  WasteType _wasteTypeOf(CompetitiveItemType type) {
    switch (type) {
      case CompetitiveItemType.bananaPeel:
      case CompetitiveItemType.appleCore:
      case CompetitiveItemType.leaf:
        return WasteType.organic;
      case CompetitiveItemType.metalCan:
      case CompetitiveItemType.juiceBox:
      case CompetitiveItemType.waterBottle:
        return WasteType.recycling;
      case CompetitiveItemType.cigaretteBud:
      case CompetitiveItemType.gum:
        return WasteType.unrecyclable;
    }
  }
}

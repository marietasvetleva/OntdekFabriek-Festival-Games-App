import 'dart:math';

import 'toiletC_models.dart';

class ToiletCompetitiveLogic {
  final GameConfig config;
  final Random _rng;
  final List<CompetitiveItemType> _recentSpawnedTypes = [];

  static const int _recentHistorySize = 3;
  static const List<double> _recentTypePenalties = [0.07, 0.15, 0.25];
  static const double _weightFloor = 0.0001;

  ToiletCompetitiveLogic({
    this.config = const GameConfig(),
    Random? random,
  }) : _rng = random ?? Random();

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
      nextSpawnCheckAtSec: 0,
      idCounter: 0,
    );
  }

  void start(ToiletCompetitiveState state) {
    state.elapsedSec = 0;
    state.running = true;
    state.finished = false;
    state.activeItems.clear();
    state.nextSpawnCheckAtSec = 0;
    state.idCounter = 0;
    _recentSpawnedTypes.clear();

    for (final player in state.players.values) {
      player.lives = config.startLives;
      player.score = 0;
      player.correct = 0;
      player.wrong = 0;
    }
  }

  void tick(ToiletCompetitiveState state, double dtSec) {
    if (!state.running || state.finished) return;

    state.elapsedSec += dtSec;

    if (state.elapsedSec >= config.gameDurationSec) {
      state.elapsedSec = config.gameDurationSec.toDouble();
      _removeExpiredItems(state);
      state.running = false;
      state.finished = true;
      return;
    }

    _removeExpiredItems(state);

    while (state.elapsedSec >= state.nextSpawnCheckAtSec) {
      _runSpawnCheck(state, state.nextSpawnCheckAtSec);
      state.nextSpawnCheckAtSec += config.spawnCheckIntervalSec;
    }

    if (isGameOver(state)) {
      state.running = false;
      state.finished = true;
    }
  }

  void _runSpawnCheck(ToiletCompetitiveState state, double checkTimeSec) {
    final maxActive = _maxActiveItemsAt(checkTimeSec);

    if (state.activeItems.length >= maxActive) return;

    final spawnChance = _spawnChanceAt(checkTimeSec);

    if (_rng.nextDouble() > spawnChance) return;

    final ttlSec = _ttlAt(checkTimeSec);

    final spawnType = _rollItemType();
    final spawnPoint = _pickSpawnPoint(state);
    state.activeItems.add(
      CompetitiveItemSpawn(
        id: 'i_${state.idCounter++}',
        type: spawnType,
        spawnedAtSec: checkTimeSec,
        ttlSec: ttlSec,
        spawnXNorm: spawnPoint.$1,
        spawnYNorm: spawnPoint.$2,
      ),
    );
    _rememberSpawnedType(spawnType);
  }

  (double, double) _pickSpawnPoint(ToiletCompetitiveState state) {
    const minNorm = 0.08;
    const maxNorm = 0.92;
    const minDistance = 0.36;
    const maxAttempts = 12;

    var bestX = minNorm + _rng.nextDouble() * (maxNorm - minNorm);
    var bestY = minNorm + _rng.nextDouble() * (maxNorm - minNorm);
    var bestDistance = -1.0;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final x = minNorm + _rng.nextDouble() * (maxNorm - minNorm);
      final y = minNorm + _rng.nextDouble() * (maxNorm - minNorm);

      var nearest = double.infinity;
      for (final item in state.activeItems) {
        final dx = item.spawnXNorm - x;
        final dy = item.spawnYNorm - y;
        final d = sqrt(dx * dx + dy * dy);
        if (d < nearest) nearest = d;
      }

      if (state.activeItems.isEmpty || nearest >= minDistance) {
        return (x, y);
      }
      if (nearest > bestDistance) {
        bestDistance = nearest;
        bestX = x;
        bestY = y;
      }
    }

    return (bestX, bestY);
  }

  int _maxActiveItemsAt(double timeSec) {
    if (timeSec < config.introDurationSec) {
      return config.startMaxActiveItems;
    }

    final halfPoint = config.gameDurationSec * 0.55;
    if (timeSec < halfPoint) {
      return config.midMaxActiveItems;
    }

    return config.lateMaxActiveItems;
  }

  double _spawnChanceAt(double timeSec) {
    if (timeSec < config.introDurationSec) {
      return config.startSpawnChance;
    }

    final halfPoint = config.gameDurationSec * 0.55;
    if (timeSec < halfPoint) {
      return config.midSpawnChance;
    }

    return config.lateSpawnChance;
  }

  double _ttlAt(double timeSec) {
    if (timeSec < config.introDurationSec) {
      return _randomBetween(config.startTtlSec * 0.9, config.startTtlSec * 1.1);
    }

    final halfPoint = config.gameDurationSec * 0.55;
    if (timeSec < halfPoint) {
      return _randomBetween(config.midTtlSec * 0.9, config.midTtlSec * 1.1);
    }

    return _randomBetween(config.minTtlSec * 0.9, config.minTtlSec * 1.1);
  }

  double _randomBetween(double min, double max) {
    return min + _rng.nextDouble() * (max - min);
  }

  DepositOutcome depositItem({
    required ToiletCompetitiveState state,
    required CompetitivePlayerId playerId,
    required String itemId,
  }) {
    if (!state.running || state.finished) {
      return DepositOutcome.ignored;
    }

    CompetitiveItemSpawn? item;
    for (final activeItem in state.activeItems) {
      if (activeItem.id == itemId) {
        item = activeItem;
        break;
      }
    }

    if (item == null) {
      return DepositOutcome.ignored;
    }

    state.activeItems.remove(item);

    final player = state.players[playerId]!;
    final wasteType = wasteTypeForItem(item.type);

    if (wasteType != WasteType.unrecyclable &&
        ((player.binType == BinType.organic &&
                wasteType == WasteType.organic) ||
            (player.binType == BinType.recycling &&
                wasteType == WasteType.recycling))) {
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

  double timeLeftSec(ToiletCompetitiveState state) {
    return max(0, config.gameDurationSec - state.elapsedSec);
  }

  bool isGameOver(ToiletCompetitiveState state) {
    final p1Lives = state.players[CompetitivePlayerId.p1]!.lives;
    final p2Lives = state.players[CompetitivePlayerId.p2]!.lives;

    return p1Lives <= 0 ||
        p2Lives <= 0 ||
        state.elapsedSec >= config.gameDurationSec;
  }

  CompetitivePlayerId? winner(ToiletCompetitiveState state) {
    final p1 = state.players[CompetitivePlayerId.p1]!;
    final p2 = state.players[CompetitivePlayerId.p2]!;

    if (p1.lives <= 0 && p2.lives > 0) return CompetitivePlayerId.p2;
    if (p2.lives <= 0 && p1.lives > 0) return CompetitivePlayerId.p1;
    if (p1.score > p2.score) return CompetitivePlayerId.p1;
    if (p2.score > p1.score) return CompetitivePlayerId.p2;
    return null;
  }

  WasteType wasteTypeForItem(CompetitiveItemType type) {
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

  bool isGoodItem(CompetitiveItemType type) {
    return wasteTypeForItem(type) != WasteType.unrecyclable;
  }

  bool isCorrectForPlayer(BinType playerBin, CompetitiveItemType itemType) {
    final wasteType = wasteTypeForItem(itemType);

    if (wasteType == WasteType.unrecyclable) return false;

    return (playerBin == BinType.organic && wasteType == WasteType.organic) ||
        (playerBin == BinType.recycling && wasteType == WasteType.recycling);
  }

  double itemAgeProgress(
    ToiletCompetitiveState state,
    CompetitiveItemSpawn item,
  ) {
    final age = itemActiveAgeSec(state, item);
    if (item.ttlSec <= 0) return 1.0;

    return (age / item.ttlSec).clamp(0.0, 1.0);
  }

  double itemActiveAgeSec(
    ToiletCompetitiveState state,
    CompetitiveItemSpawn item,
  ) {
    var heldSec = item.totalHeldSec;

    if (item.isBeingHeld && item.holdStartedAtSec != null) {
      heldSec += state.elapsedSec - item.holdStartedAtSec!;
    }

    return max(0.0, state.elapsedSec - item.spawnedAtSec - heldSec);
  }

  double itemDisplaySizePixels({
    required ToiletCompetitiveState state,
    required CompetitiveItemSpawn item,
    required double maxSize,
    required double minSize,
  }) {
    final progress = itemAgeProgress(state, item);
    return maxSize + (minSize - maxSize) * progress;
  }

  void _removeExpiredItems(ToiletCompetitiveState state) {
    if (state.activeItems.isEmpty) return;

    final expiredItems = <CompetitiveItemSpawn>[];

    for (final item in state.activeItems) {
      if (item.isBeingHeld) continue;

      if (item.isExpired(state.elapsedSec)) {
        expiredItems.add(item);
      }
    }

    if (expiredItems.isEmpty) return;

    for (final item in expiredItems) {
      state.activeItems.remove(item);
    }

    if (config.penaltyMissed > 0) {
      for (final player in state.players.values) {
        player.lives -= config.penaltyMissed;
      }
    }
  }

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

    final recyclableTotal = organicShare + recyclingShare;
    final normalizedOrganic =
        recyclableTotal > 0 ? organicShare / recyclableTotal : 0.5;
    final normalizedRecycling =
        recyclableTotal > 0 ? recyclingShare / recyclableTotal : 0.5;
    final unrecyclableShare = (1.0 - recyclableTotal).clamp(0.0, 1.0);

    final organicMass = normalizedOrganic * (1.0 - unrecyclableShare);
    final recyclingMass = normalizedRecycling * (1.0 - unrecyclableShare);
    final unrecyclableMass = unrecyclableShare;

    final perOrganicWeight = organicMass / organicItems.length;
    final perRecyclingWeight = recyclingMass / recyclingItems.length;
    final perUnrecyclableWeight = unrecyclableMass / unrecyclableItems.length;

    final weightedByType = <CompetitiveItemType, double>{};
    for (final type in organicItems) {
      weightedByType[type] =
          max(_weightFloor, perOrganicWeight * _recencyMultiplierFor(type));
    }
    for (final type in recyclingItems) {
      weightedByType[type] =
          max(_weightFloor, perRecyclingWeight * _recencyMultiplierFor(type));
    }
    for (final type in unrecyclableItems) {
      weightedByType[type] = max(
        _weightFloor,
        perUnrecyclableWeight * _recencyMultiplierFor(type),
      );
    }

    return _pickWeightedType(weightedByType);
  }

  double _recencyMultiplierFor(CompetitiveItemType type) {
    final historyCount = min(_recentSpawnedTypes.length, _recentTypePenalties.length);
    for (var i = 0; i < historyCount; i++) {
      final recentType = _recentSpawnedTypes[_recentSpawnedTypes.length - 1 - i];
      if (recentType == type) {
        return _recentTypePenalties[i];
      }
    }
    return 1.0;
  }

  CompetitiveItemType _pickWeightedType(
    Map<CompetitiveItemType, double> weightedByType,
  ) {
    var totalWeight = 0.0;
    for (final weight in weightedByType.values) {
      totalWeight += weight;
    }

    final roll = _rng.nextDouble() * totalWeight;
    var cumulative = 0.0;

    for (final entry in weightedByType.entries) {
      cumulative += entry.value;
      if (roll <= cumulative) {
        return entry.key;
      }
    }

    return weightedByType.keys.last;
  }

  void _rememberSpawnedType(CompetitiveItemType type) {
    _recentSpawnedTypes.add(type);
    if (_recentSpawnedTypes.length > _recentHistorySize) {
      _recentSpawnedTypes.removeAt(0);
    }
  }
}
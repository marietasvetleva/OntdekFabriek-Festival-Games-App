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
          lives: config.startLives,
        ),
        CompetitivePlayerId.p2: CompetitivePlayerState(
          id: CompetitivePlayerId.p2,
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

    if (_isGood(item.type)) {
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

  /// Rolls random item type (good items are slightly more frequent).
  CompetitiveItemType _rollItemType() {
    const good = <CompetitiveItemType>[
      CompetitiveItemType.bananaPeel,
      CompetitiveItemType.leaf,
      CompetitiveItemType.compost,
      CompetitiveItemType.sawdust,
    ];
    const bad = <CompetitiveItemType>[
      CompetitiveItemType.cigaretteBud,
      CompetitiveItemType.gum,
    ];

    final pickGood = _rng.nextDouble() < 0.68;
    final pool = pickGood ? good : bad;
    return pool[_rng.nextInt(pool.length)];
  }

  /// Checks whether an item counts as correct trash.
  bool _isGood(CompetitiveItemType type) {
    return type == CompetitiveItemType.bananaPeel ||
        type == CompetitiveItemType.leaf ||
        type == CompetitiveItemType.compost ||
        type == CompetitiveItemType.sawdust;
  }
}

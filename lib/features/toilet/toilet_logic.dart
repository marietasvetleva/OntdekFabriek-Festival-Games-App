import 'dart:math';

import 'toilet_models.dart';
import 'toilet_movement.dart';

/// Contains all non-UI Toilet game rules and state transitions.
class ToiletGameLogic {
  static const int targetToFill = 10;
  static const int numSlots = 3;
  static const double slotWidth = 100;
  static const double slotHeight = 100;
  static const double bucketWidth = 100;

  final Random _rnd = Random();

  final List<ToiletItemSpec> specs = const <ToiletItemSpec>[
    ToiletItemSpec('bananapeel', 'assets/ToiletImage/Bananapeel.png', true),
    ToiletItemSpec('compost', 'assets/ToiletImage/Compost.png', true),
    ToiletItemSpec('leaf', 'assets/ToiletImage/Leaf.png', true),
    ToiletItemSpec('sawdust', 'assets/ToiletImage/Sawdust.png', true),
    ToiletItemSpec('sigaret', 'assets/ToiletImage/Sigaret.png', false),
    ToiletItemSpec('chewingum', 'assets/ToiletImage/Chewingum.png', false),
  ];

  /// Creates a fresh game state before the player presses Start.
  ToiletGameState createInitialState() {
    return ToiletGameState(
      showIntro: true,
      isRunning: true,
      hearts: 3,
      itemsCaught: 0,
      winGame: false,
      gameOver: false,
      bucketX: 0,
      bucketY: 0,
      items: <ToiletFallingItem>[],
      slots: List<ToiletSlotItem?>.filled(numSlots, null),
      feedbackMessage: null,
      feedbackIsGood: false,
    );
  }

  /// Resets runtime state and fills top slots for a new round.
  void startGame(ToiletGameState state) {
    state.showIntro = false;
    state.isRunning = true;
    state.hearts = 3;
    state.itemsCaught = 0;
    state.winGame = false;
    state.gameOver = false;
    state.items.clear();
    for (int i = 0; i < numSlots; i++) {
      state.slots[i] = null;
    }
    for (int i = 0; i < numSlots; i++) {
      state.slots[i] = _createSlotItem();
    }
  }

  /// Re-fills empty top slots during spawn ticks.
  void fillEmptySlots(ToiletGameState state) {
    for (int i = 0; i < numSlots; i++) {
      if (state.slots[i] == null) {
        state.slots[i] = _createSlotItem();
      }
    }
  }

  /// Converts a slot tap into a new falling item instance.
  void onSlotTapped({
    required ToiletGameState state,
    required int slotIndex,
    required double screenWidth,
  }) {
    if (!state.isRunning || state.slots[slotIndex] == null) return;
    final item = state.slots[slotIndex]!;
    final randomX = _rnd.nextDouble() * (screenWidth - 36);
    state.items.add(
      ToiletFallingItem(
        x: randomX,
        y: 100 + slotHeight,
        size: 36,
        speed: 200 + _rnd.nextDouble() * 100,
        spec: item.spec,
      ),
    );
    state.slots[slotIndex] = null;
  }

  /// Applies player drag input to bucket position.
  void moveBucketBy({
    required ToiletGameState state,
    required double deltaX,
    required double screenWidth,
  }) {
    state.bucketX = clampBucketX(
      bucketX: state.bucketX + deltaX,
      screenWidth: screenWidth,
      bucketWidth: bucketWidth,
    );
  }

  /// Runs one simulation tick and returns points when game ends.
  int? tick({
    required ToiletGameState state,
    required double dt,
    required double screenWidth,
    required double screenHeight,
  }) {
    state.bucketX = clampBucketX(
      bucketX: state.bucketX,
      screenWidth: screenWidth,
      bucketWidth: bucketWidth,
    );
    state.bucketY = screenHeight - 160;

    moveFallingItems(items: state.items, dt: dt);

    final caught = <ToiletFallingItem>[];
    final remove = <ToiletFallingItem>[];
    for (final item in state.items) {
      final hit = isBucketCollision(
        item: item,
        bucketX: state.bucketX,
        bucketY: state.bucketY,
        bucketWidth: bucketWidth,
      );
      if (hit) {
        caught.add(item);
      } else if (item.y > screenHeight + 60) {
        remove.add(item);
      }
    }

    for (final item in caught) {
      state.items.remove(item);
      if (item.spec.good) {
        state.feedbackIsGood = true;
        state.itemsCaught++;
        if (state.itemsCaught >= targetToFill) {
          state.isRunning = false;
          state.winGame = true;
        }
      } else {
        state.feedbackIsGood = false;
        state.hearts--;
        if (state.hearts <= 0) {
          state.isRunning = false;
          state.gameOver = true;
        }
      }
      state.feedbackMessage = 'show';
    }

    for (final item in remove) {
      state.items.remove(item);
    }

    if (state.winGame || state.gameOver) {
      state.winGame = false;
      state.gameOver = false;
      return calculateAwardedPoints(state.itemsCaught);
    }
    return null;
  }

  /// Converts collected items to backend score (0..5).
  int calculateAwardedPoints(int itemsCaught) {
    return (itemsCaught * 0.5).round().clamp(0, 5);
  }

  ToiletSlotItem _createSlotItem() {
    final spec = specs[_rnd.nextInt(specs.length)];
    return ToiletSlotItem(spec: spec);
  }
}

import 'package:audioplayers/audioplayers.dart';

class StageAudioService {
  static const String _audioBase = 'StageGameV2-audio';

  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _powerPlayer = AudioPlayer();

  bool _backgroundStarted = false;

  double _backgroundVolume = 0.25;

  Future<void> init() async {
    await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
    await _backgroundPlayer.setVolume(_backgroundVolume);

    /*
      AANWIJZING:
      Default effect volume is now lower.
      Distortion, boo and cheer are also set individually lower below.
    */
    await _effectPlayer.setReleaseMode(ReleaseMode.stop);
    await _effectPlayer.setVolume(0.30);

    await _powerPlayer.setReleaseMode(ReleaseMode.stop);
    await _powerPlayer.setVolume(0.45);
  }

  Future<void> startBackgroundMusic() async {
    try {
      if (_backgroundStarted) {
        await _backgroundPlayer.resume();
        await _backgroundPlayer.setVolume(_backgroundVolume);
        return;
      }

      _backgroundStarted = true;

      await _backgroundPlayer.play(
        AssetSource('$_audioBase/festival_background_loop.mp3'),
        volume: _backgroundVolume,
      );
    } catch (_) {
      // Empty for prototype.
    }
  }

  Future<void> pauseBackgroundMusic() async {
    try {
      await _backgroundPlayer.pause();
    } catch (_) {}
  }

  Future<void> stopBackgroundMusic() async {
    try {
      await _backgroundPlayer.stop();
      _backgroundStarted = false;
    } catch (_) {}
  }

  Future<void> setBackgroundVolume(double volume) async {
    try {
      _backgroundVolume = volume.clamp(0.0, 1.0);
      await _backgroundPlayer.setVolume(_backgroundVolume);
    } catch (_) {}
  }

  Future<void> stopEffects() async {
    try {
      await _effectPlayer.stop();
    } catch (_) {}
  }

  Future<void> stopPowerEffects() async {
    try {
      await _powerPlayer.stop();
    } catch (_) {}
  }

  Future<void> playCrowdCheer() async {
    /*
      AANWIJZING:
      Cheer was too loud.
      Lowered so it feels like result feedback, not a blast.
    */
    await _playEffect('crowd_cheer_short.mp3', volume: 0.15);
  }

  Future<void> playCrowdBoo() async {
    /*
      AANWIJZING:
      Boo was too loud.
      Lowered to keep the final screen comfortable.
    */
    await _playEffect('crowd_boo_short.mp3', volume: 0.10);
  }

  Future<void> playSpeakerDistortion() async {
    /*
      AANWIJZING:
      Distortion was way too loud.
      This should be a clear warning, but not overpower the player.
    */
    await _playEffect('speaker_distortion_krrrsh.mp3', volume: 0.08);
  }

  Future<void> playLightFlicker() async {
    await _playEffect('light_flicker.mp3', volume: 0.25);
  }

  Future<void> playPowerWarning() async {
    await _playPower('power_warning_beep.mp3', volume: 0.22);
  }

  Future<void> playPowerOverload() async {
    await _playPower('power_overload_zap.mp3', volume: 0.20);
  }

  Future<void> _playEffect(
    String fileName, {
    double volume = 0.30,
  }) async {
    try {
      final safeVolume = volume.clamp(0.0, 1.0);

      await _effectPlayer.stop();
      await _effectPlayer.setVolume(safeVolume);
      await _effectPlayer.play(
        AssetSource('$_audioBase/$fileName'),
        volume: safeVolume,
      );
    } catch (_) {}
  }

  Future<void> _playPower(
    String fileName, {
    double volume = 0.45,
  }) async {
    try {
      final safeVolume = volume.clamp(0.0, 1.0);

      await _powerPlayer.stop();
      await _powerPlayer.setVolume(safeVolume);
      await _powerPlayer.play(
        AssetSource('$_audioBase/$fileName'),
        volume: safeVolume,
      );
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _backgroundPlayer.dispose();
    await _effectPlayer.dispose();
    await _powerPlayer.dispose();
  }
}
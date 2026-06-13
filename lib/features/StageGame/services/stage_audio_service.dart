import 'package:audioplayers/audioplayers.dart';

class StageAudioService {
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final AudioPlayer _crowdPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _warningPlayer = AudioPlayer();

  bool _isInitialized = false;
  bool _isDisposed = false;

  Future<void> init() async {
    if (_isInitialized || _isDisposed) return;

    await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
    await _crowdPlayer.setReleaseMode(ReleaseMode.stop);
    await _effectPlayer.setReleaseMode(ReleaseMode.stop);
    await _warningPlayer.setReleaseMode(ReleaseMode.stop);

    await _backgroundPlayer.setVolume(0.20);
    await _crowdPlayer.setVolume(0.75);
    await _effectPlayer.setVolume(0.85);
    await _warningPlayer.setVolume(0.80);

    _isInitialized = true;
  }

  Future<void> startBackgroundMusic() async {
    if (_isDisposed) return;
    await init();

    await _backgroundPlayer.play(
      AssetSource('StageGameV2-audio/festival_background_cheap.mp3'),
      volume: 0.20,
    );
  }

  Future<void> stopBackgroundMusic() async {
    if (_isDisposed) return;

    await _backgroundPlayer.stop();
  }

  Future<void> setBackgroundVolume(double volume) async {
    if (_isDisposed) return;

    final safeVolume = volume.clamp(0.0, 1.0);
    await _backgroundPlayer.setVolume(safeVolume);
  }

  Future<void> playCrowdCheer() async {
    if (_isDisposed) return;
    await init();

    await _crowdPlayer.stop();
    await _crowdPlayer.play(
      AssetSource('StageGameV2-audio/crowd_cheer_short.mp3'),
    );
  }

  Future<void> playCrowdBoo() async {
    if (_isDisposed) return;
    await init();

    await _crowdPlayer.stop();
    await _crowdPlayer.play(
      AssetSource('StageGameV2-audio/crowd_boo_short.mp3'),
    );
  }

  Future<void> playCrowdMumble() async {
    if (_isDisposed) return;
    await init();

    await _crowdPlayer.stop();
    await _crowdPlayer.play(
      AssetSource('StageGameV2-audio/crowd_mumble_short.mp3'),
    );
  }

  Future<void> playLightFlicker() async {
    if (_isDisposed) return;
    await init();

    await _effectPlayer.stop();
    await _effectPlayer.play(
      AssetSource('StageGameV2-audio/light_flicker.mp3'),
    );
  }

  Future<void> playSpeakerDistortion() async {
    if (_isDisposed) return;
    await init();

    await _effectPlayer.stop();
    await _effectPlayer.play(
      AssetSource('StageGameV2-audio/speaker_distortion_krrrsh.mp3'),
    );
  }

  Future<void> stopEffects() async {
    if (_isDisposed) return;

    await _effectPlayer.stop();
  }

  Future<void> playPowerWarning() async {
    if (_isDisposed) return;
    await init();

    await _warningPlayer.stop();
    await _warningPlayer.play(
      AssetSource('StageGameV2-audio/power_warning_beep.mp3'),
    );
  }

  Future<void> playPowerOverload() async {
    if (_isDisposed) return;
    await init();

    await _warningPlayer.stop();
    await _warningPlayer.play(
      AssetSource('StageGameV2-audio/power_overload_zap.mp3'),
    );
  }

  Future<void> stopAllAudio() async {
    if (_isDisposed) return;

    await _backgroundPlayer.stop();
    await _crowdPlayer.stop();
    await _effectPlayer.stop();
    await _warningPlayer.stop();
  }

  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;

    await _backgroundPlayer.dispose();
    await _crowdPlayer.dispose();
    await _effectPlayer.dispose();
    await _warningPlayer.dispose();
  }
}
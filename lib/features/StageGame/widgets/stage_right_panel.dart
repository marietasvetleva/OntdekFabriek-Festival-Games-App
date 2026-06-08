import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/stage_game_models.dart';
import 'stage_panel_status.dart';

class StageRightPanel extends StatefulWidget {
  final StageGameState state;
  final StageGameConfig config;

  final void Function(StageControlLevel level)? onSoundLevelChanged;
  final void Function(StageControlLevel level)? onLightLevelChanged;

  final void Function(double progress)? onSoundSliderProgressChanged;
  final void Function(double progress)? onLightSliderProgressChanged;

  const StageRightPanel({
    super.key,
    required this.state,
    required this.config,
    this.onSoundLevelChanged,
    this.onLightLevelChanged,
    this.onSoundSliderProgressChanged,
    this.onLightSliderProgressChanged,
  });

  @override
  State<StageRightPanel> createState() => _StageRightPanelState();
}

class _StageRightPanelState extends State<StageRightPanel>
    with SingleTickerProviderStateMixin {
  static const String _assetBase = 'assets/StageGameV2-image/right_panel';

  late final AnimationController _loopController;

  double _soundSliderProgress = 0.5;
  double _lightSliderProgress = 0.0;

  bool _isDraggingSound = false;
  bool _isDraggingLight = false;

  StageControlLevel? _lastSoundLevelSent;
  StageControlLevel? _lastLightLevelSent;

  StageControlLevel? _pendingSoundLevel;
  StageControlLevel? _pendingLightLevel;

  @override
  void initState() {
    super.initState();

    _soundSliderProgress = _progressFromLevel(widget.state.soundControlLevel);
    _lightSliderProgress = _lightProgressFromState();

    _lastSoundLevelSent = widget.state.soundControlLevel;
    _lastLightLevelSent = widget.state.lightControlLevel;

    _pendingSoundLevel = widget.state.soundControlLevel;
    _pendingLightLevel = widget.state.lightControlLevel;

    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StageRightPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isDraggingSound &&
        oldWidget.state.soundControlLevel != widget.state.soundControlLevel) {
      _soundSliderProgress = _progressFromLevel(widget.state.soundControlLevel);
      _lastSoundLevelSent = widget.state.soundControlLevel;
      _pendingSoundLevel = widget.state.soundControlLevel;
    }

    if (!_isDraggingLight &&
        (oldWidget.state.lightControlLevel != widget.state.lightControlLevel ||
            oldWidget.state.selectedLight != widget.state.selectedLight)) {
      _lightSliderProgress = _lightProgressFromState();
      _lastLightLevelSent = widget.state.lightControlLevel;
      _pendingLightLevel = widget.state.lightControlLevel;
    }
  }

  @override
  void dispose() {
    _loopController.dispose();
    super.dispose();
  }

  double _progressFromLevel(StageControlLevel level) {
    switch (level) {
      case StageControlLevel.low:
        return 0.0;
      case StageControlLevel.medium:
        return 0.5;
      case StageControlLevel.high:
        return 1.0;
    }
  }

  double _lightProgressFromState() {
    if (widget.state.selectedLight == null) {
      return 0.0;
    }

    return _progressFromLevel(widget.state.lightControlLevel);
  }

  StageControlLevel _levelFromProgress(double progress) {
    if (progress < 0.34) {
      return StageControlLevel.low;
    }

    if (progress < 0.67) {
      return StageControlLevel.medium;
    }

    return StageControlLevel.high;
  }

  int _selectedSpeakerMaxDb() {
    switch (widget.state.selectedSound) {
      case SoundOption.cheap:
        return 75;
      case SoundOption.eco:
        return 98;
      case SoundOption.pro:
        return 110;
      default:
        return 100;
    }
  }

  String _soundTargetText() {
    switch (widget.state.selectedSound) {
      case SoundOption.cheap:
        return 'Cheap max: 75 dB • High distorts';
      case SoundOption.eco:
        return 'Eco max: 98 dB • Clean and stable';
      case SoundOption.pro:
        return 'Pro max: 110 dB • Festival power';
      default:
        return 'Choose speaker • Drag meter';
    }
  }

  String _soundLowLabel() {
    return '0';
  }

  String _soundHighLabel() {
    return '${_selectedSpeakerMaxDb()} dB';
  }

  String _soundMainText() {
    if (widget.state.selectedSound == SoundOption.cheap &&
        widget.state.soundControlLevel == StageControlLevel.high) {
      return 'Speaker Distortion';
    }

    return 'Sound (dB)';
  }

  String _lightTargetText() {
    if (widget.state.selectedLight == null) {
      return 'Choose a light first';
    }

    switch (widget.state.selectedLight) {
      case LightOption.led:
        return 'LED light • Drag meter';
      case LightOption.smart:
        return 'Smart light • Drag meter';
      case LightOption.halogen:
        return 'Halogen light • Drag meter';
      default:
        return 'Choose a light first';
    }
  }

  String _lightHighLabel() {
    switch (widget.state.selectedLight) {
      case LightOption.led:
        return '82';
      case LightOption.smart:
        return '85';
      case LightOption.halogen:
        return '94';
      default:
        return 'max';
    }
  }

  @override
  Widget build(BuildContext context) {
    final soundStatus = StagePanelStatusHelper.soundStatus(
      widget.state,
      widget.config,
    );

    final lightStatus = StagePanelStatusHelper.lightStatus(
      widget.state,
      widget.config,
    );

    final powerStatus = StagePanelStatusHelper.powerStatus(widget.state);

    final feedbackStatus = _mainStatus(
      soundStatus,
      lightStatus,
      powerStatus,
    );

    final feedbackMessage = StagePanelStatusHelper.feedbackMessage(
      widget.state,
      widget.config,
    );

    final bool hasLightSelected = widget.state.selectedLight != null;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EA),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF435245),
          width: 2.4,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 54,
            child: _buildStageBuilderBar(),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: _buildControlCard(
              cardKey: 'power-card',
              title: 'POWER\nMANAGEMENT',
              icon: Icons.bolt_rounded,
              meterTrackPath: '$_assetBase/meter_track_power.png',
              mainText: 'Power Load',
              valueText: widget.state.currentPowerCapacity <= 0
                  ? '- W'
                  : '${widget.state.totalPowerLoad}/${widget.state.currentPowerCapacity} W',
              targetText: 'Do not overload',
              lowLabel: 'safe',
              highLabel: 'max',
              progress: _powerProgress(),
              status: powerStatus,
              meterType: _MeterType.power,
            ),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: _buildControlCard(
              cardKey:
                  'light-card-${widget.state.selectedLight}-${widget.state.lightControlLevel}',
              title: 'LIGHT\nCONTROL',
              icon: hasLightSelected
                  ? Icons.lightbulb_outline_rounded
                  : Icons.lightbulb_outline,
              meterTrackPath: '$_assetBase/meter_track_light.png',
              mainText: hasLightSelected ? 'Light Intensity' : 'Choose Light',
              valueText: !hasLightSelected ||
                      widget.state.currentLightIntensity <= 0
                  ? '-'
                  : widget.state.currentLightIntensity.toStringAsFixed(0),
              targetText: _lightTargetText(),
              lowLabel: '0',
              highLabel: _lightHighLabel(),
              progress: hasLightSelected ? _lightSliderProgress : 0.0,
              status: hasLightSelected ? lightStatus : StagePanelStatus.neutral,
              meterType: _MeterType.light,
              onMeterLevelChanged:
                  hasLightSelected ? widget.onLightLevelChanged : null,
              onSliderProgressChanged:
                  hasLightSelected ? widget.onLightSliderProgressChanged : null,
            ),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: _buildControlCard(
              cardKey:
                  'sound-card-${widget.state.selectedSound}-${widget.state.soundControlLevel}',
              title: 'SOUND\nCONTROL',
              icon: widget.state.selectedSound == SoundOption.cheap &&
                      widget.state.soundControlLevel == StageControlLevel.high
                  ? Icons.warning_rounded
                  : Icons.volume_up_rounded,
              meterTrackPath: '$_assetBase/meter_track_sound.png',
              mainText: _soundMainText(),
              valueText: widget.state.currentSoundDb <= 0
                  ? '- dB'
                  : '${widget.state.currentSoundDb.toStringAsFixed(0)} dB',
              targetText: _soundTargetText(),
              lowLabel: _soundLowLabel(),
              highLabel: _soundHighLabel(),
              progress: _soundSliderProgress,
              status: soundStatus,
              meterType: _MeterType.sound,
              onMeterLevelChanged: widget.onSoundLevelChanged,
              onSliderProgressChanged: widget.onSoundSliderProgressChanged,
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 64,
            child: _buildFeedbackBar(
              message: feedbackMessage,
              status: feedbackStatus,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageBuilderBar() {
    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, child) {
        final pulse = _loopController.value;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFDFCF7),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFD8D0C2),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF435245).withOpacity(0.04 + pulse * 0.05),
                blurRadius: 7 + pulse * 3,
                spreadRadius: 0.2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Center(
        child: Text(
          'STAGE BUILDER',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.caveat(
            fontSize: 28,
            height: 0.9,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2F2F35),
          ),
        ),
      ),
    );
  }

  Widget _buildControlCard({
    required String cardKey,
    required String title,
    required IconData icon,
    required String meterTrackPath,
    required String mainText,
    required String valueText,
    required String targetText,
    required String lowLabel,
    required String highLabel,
    required double progress,
    required StagePanelStatus status,
    required _MeterType meterType,
    void Function(StageControlLevel level)? onMeterLevelChanged,
    void Function(double progress)? onSliderProgressChanged,
  }) {
    final statusColor = StagePanelStatusHelper.statusColor(status);
    final cardBackground = StagePanelStatusHelper.cardBackground(status);

    return TweenAnimationBuilder<double>(
      key: ValueKey(cardKey),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, popValue, child) {
        final popScale = 1.0 + math.sin(popValue * math.pi) * 0.014;

        return Transform.scale(
          scale: popScale,
          child: child,
        );
      },
      child: _WarningShake(
        enabled: status == StagePanelStatus.warning,
        child: AnimatedBuilder(
          animation: _loopController,
          builder: (context, child) {
            final pulse = _loopController.value;
            final isActive = status != StagePanelStatus.neutral;

            return ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(8, 7, 22, 7),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(cardBackground),
                    fit: BoxFit.fill,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: statusColor.withOpacity(
                      status == StagePanelStatus.neutral ? 0.35 : 0.95,
                    ),
                    width: status == StagePanelStatus.warning ? 2.0 : 1.35,
                  ),
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: statusColor.withOpacity(
                          status == StagePanelStatus.warning
                              ? 0.13 + pulse * 0.09
                              : 0.05 + pulse * 0.04,
                        ),
                        blurRadius: status == StagePanelStatus.warning
                            ? 10 + pulse * 5
                            : 7 + pulse * 3,
                        spreadRadius:
                            status == StagePanelStatus.warning ? 0.8 : 0.2,
                      ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: child ?? const SizedBox.shrink(),
                    ),
                    if (isActive)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _buildScanLine(status),
                        ),
                      ),
                    if (status == StagePanelStatus.good)
                      Positioned(
                        right: 14,
                        top: 10,
                        child: _buildGoodSparkle(),
                      ),
                  ],
                ),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLabelBox(
                title: title,
                icon: icon,
                status: status,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _buildCompactInfoBlock(
                  mainText: mainText,
                  valueText: valueText,
                  targetText: targetText,
                  lowLabel: lowLabel,
                  highLabel: highLabel,
                  progress: progress,
                  meterTrackPath: meterTrackPath,
                  status: status,
                  meterType: meterType,
                  onMeterLevelChanged: onMeterLevelChanged,
                  onSliderProgressChanged: onSliderProgressChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanLine(StagePanelStatus status) {
    final color = StagePanelStatusHelper.statusColor(status);

    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, child) {
        final x = _loopController.value;

        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned(
                  left: constraints.maxWidth * x - 16,
                  top: 6,
                  bottom: 6,
                  child: Container(
                    width: 9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.12),
                          color.withOpacity(0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGoodSparkle() {
    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, child) {
        final pulse = 1.0 + _loopController.value * 0.13;

        return Transform.scale(
          scale: pulse,
          child: Text(
            '✦',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF79A982).withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabelBox({
    required String title,
    required IconData icon,
    required StagePanelStatus status,
  }) {
    final statusColor = StagePanelStatusHelper.statusColor(status);

    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, child) {
        final pulse = _loopController.value;
        final iconScale =
            status == StagePanelStatus.neutral ? 1.0 : 1.0 + (pulse * 0.05);

        return Container(
          width: 100,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE9F0F3).withOpacity(0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: status == StagePanelStatus.neutral
                  ? const Color(0xFFC9D4D8)
                  : statusColor.withOpacity(0.45 + pulse * 0.18),
              width: 1.1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Transform.scale(
                    scale: iconScale,
                    child: Icon(
                      icon,
                      size: 25,
                      color: status == StagePanelStatus.warning
                          ? statusColor
                          : const Color(0xFF5F6E64),
                    ),
                  ),
                  Positioned(
                    right: -6,
                    top: -4,
                    child: _buildStatusDot(status),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.caveat(
                        fontSize: 17,
                        height: 0.84,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2F2F35),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusDot(StagePanelStatus status) {
    if (status == StagePanelStatus.neutral) {
      return const SizedBox.shrink();
    }

    final color = StagePanelStatusHelper.statusColor(status);

    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, child) {
        final pulse = 1.0 + (_loopController.value * 0.10);

        return Transform.scale(
          scale: pulse,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactInfoBlock({
    required String mainText,
    required String valueText,
    required String targetText,
    required String lowLabel,
    required String highLabel,
    required double progress,
    required String meterTrackPath,
    required StagePanelStatus status,
    required _MeterType meterType,
    void Function(StageControlLevel level)? onMeterLevelChanged,
    void Function(double progress)? onSliderProgressChanged,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final blockWidth = constraints.maxWidth.clamp(295.0, 360.0).toDouble();

        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: blockWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleAndValueRow(
                  mainText: mainText,
                  valueText: valueText,
                  status: status,
                ),
                const SizedBox(height: 3),
                _buildMeterRow(
                  lowLabel: lowLabel,
                  highLabel: highLabel,
                  progress: progress,
                  meterTrackPath: meterTrackPath,
                  status: status,
                  meterType: meterType,
                  onMeterLevelChanged: onMeterLevelChanged,
                  onSliderProgressChanged: onSliderProgressChanged,
                ),
                const SizedBox(height: 3),
                Text(
                  targetText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.caveat(
                    fontSize: onMeterLevelChanged == null ? 16 : 14,
                    height: 0.9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF63655E),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitleAndValueRow({
    required String mainText,
    required String valueText,
    required StagePanelStatus status,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            mainText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.caveat(
              fontSize: 22,
              height: 0.9,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2F3A32),
            ),
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 96,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: FittedBox(
              key: ValueKey(valueText),
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                valueText,
                maxLines: 1,
                style: GoogleFonts.caveat(
                  fontSize: 20,
                  height: 0.9,
                  fontWeight: FontWeight.w900,
                  color: status == StagePanelStatus.warning
                      ? const Color(0xFFD26455)
                      : const Color(0xFF2F3A32),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeterRow({
    required String lowLabel,
    required String highLabel,
    required double progress,
    required String meterTrackPath,
    required StagePanelStatus status,
    required _MeterType meterType,
    void Function(StageControlLevel level)? onMeterLevelChanged,
    void Function(double progress)? onSliderProgressChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              lowLabel,
              maxLines: 1,
              style: GoogleFonts.caveat(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF63655E),
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: _buildAssetMeter(
            progress: progress,
            meterTrackPath: meterTrackPath,
            status: status,
            meterType: meterType,
            onMeterLevelChanged: onMeterLevelChanged,
            onSliderProgressChanged: onSliderProgressChanged,
          ),
        ),
        const SizedBox(width: 2),
        SizedBox(
          width: 48,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              highLabel,
              maxLines: 1,
              style: GoogleFonts.caveat(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF63655E),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetMeter({
    required double progress,
    required String meterTrackPath,
    required StagePanelStatus status,
    required _MeterType meterType,
    void Function(StageControlLevel level)? onMeterLevelChanged,
    void Function(double progress)? onSliderProgressChanged,
  }) {
    final safeProgress = progress.clamp(0.0, 1.0);
    final isDraggable = onMeterLevelChanged != null &&
        (meterType == _MeterType.sound || meterType == _MeterType.light);

    return LayoutBuilder(
      builder: (context, constraints) {
        const knobWidth = 20.0;
        const knobHeight = 28.0;

        final usableWidth =
            math.max(1.0, constraints.maxWidth - knobWidth).toDouble();

        final knobLeft = (usableWidth * safeProgress).clamp(0.0, usableWidth);

        void updateFromDx(double dx) {
          if (!isDraggable) return;

          final newProgress =
              ((dx - knobWidth / 2) / usableWidth).clamp(0.0, 1.0);

          final newLevel = _levelFromProgress(newProgress);

          setState(() {
            if (meterType == _MeterType.sound) {
              _isDraggingSound = true;
              _soundSliderProgress = newProgress;
              _pendingSoundLevel = newLevel;
            }

            if (meterType == _MeterType.light) {
              _isDraggingLight = true;
              _lightSliderProgress = newProgress;
              _pendingLightLevel = newLevel;
            }
          });

          onSliderProgressChanged?.call(newProgress);
        }

        void finishDragOrTap() {
          if (!isDraggable) return;

          if (meterType == _MeterType.sound) {
            final level =
                _pendingSoundLevel ?? _levelFromProgress(_soundSliderProgress);

            setState(() {
              _isDraggingSound = false;
            });

            if (_lastSoundLevelSent != level) {
              _lastSoundLevelSent = level;
              onMeterLevelChanged?.call(level);
            }
          }

          if (meterType == _MeterType.light) {
            final level =
                _pendingLightLevel ?? _levelFromProgress(_lightSliderProgress);

            setState(() {
              _isDraggingLight = false;
            });

            if (_lastLightLevelSent != level) {
              _lastLightLevelSent = level;
              onMeterLevelChanged?.call(level);
            }
          }
        }

        final meterContent = AnimatedBuilder(
          animation: _loopController,
          builder: (context, child) {
            final pulse = _loopController.value;
            final knobScale =
                status == StagePanelStatus.neutral ? 1.0 : 1.0 + (pulse * 0.06);

            return SizedBox(
              height: 34,
              child: Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 11,
                    child: Image.asset(
                      meterTrackPath,
                      height: 15,
                      fit: BoxFit.fill,
                    ),
                  ),
                  if (isDraggable)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 1,
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  if (isDraggable)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 8,
                      child: Container(
                        height: 21,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: const Color(0xFF6B9E66).withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  if (status != StagePanelStatus.neutral)
                    Positioned(
                      left: (constraints.maxWidth - 16) * pulse,
                      top: 12,
                      child: Container(
                        width: 14,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  AnimatedPositioned(
                    duration: isDraggable
                        ? const Duration(milliseconds: 35)
                        : const Duration(milliseconds: 420),
                    curve: Curves.easeOut,
                    left: knobLeft,
                    top: 3,
                    child: Transform.scale(
                      scale: knobScale,
                      child: Image.asset(
                        '$_assetBase/meter_knob.png',
                        width: knobWidth,
                        height: knobHeight,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );

        if (!isDraggable) {
          return meterContent;
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              updateFromDx(details.localPosition.dx);
            },
            onTapUp: (_) {
              finishDragOrTap();
            },
            onPanStart: (details) {
              updateFromDx(details.localPosition.dx);
            },
            onPanUpdate: (details) {
              updateFromDx(details.localPosition.dx);
            },
            onPanEnd: (_) {
              finishDragOrTap();
            },
            onPanCancel: () {
              finishDragOrTap();
            },
            child: meterContent,
          ),
        );
      },
    );
  }

  Widget _buildFeedbackBar({
    required String message,
    required StagePanelStatus status,
  }) {
    final isWarning = status == StagePanelStatus.warning;
    final isReady =
        status == StagePanelStatus.good && widget.state.hasAllSelections;
    final statusColor = StagePanelStatusHelper.statusColor(status);

    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, child) {
        final pulse = _loopController.value;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  isReady
                      ? '$_assetBase/card_bg_good.png'
                      : '$_assetBase/card_bg_caution.png',
                ),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isWarning
                    ? const Color(0xFFD26455)
                    : isReady
                        ? const Color(0xFF79A982)
                        : const Color(0xFFE0D39E),
                width: isWarning ? 1.8 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(
                    isWarning ? 0.15 + pulse * 0.10 : 0.05 + pulse * 0.04,
                  ),
                  blurRadius: isWarning ? 10 + pulse * 4 : 7 + pulse * 3,
                  spreadRadius: isWarning ? 0.6 : 0.2,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isReady)
              Positioned.fill(
                child: IgnorePointer(
                  child: _buildReadySparkles(),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _loopController,
                  builder: (context, child) {
                    final scale = 1.0 + _loopController.value * 0.07;

                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Image.asset(
                    isWarning
                        ? '$_assetBase/warning_badge.png'
                        : '$_assetBase/icon_feedback.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      _consoleFeedbackMessage(message),
                      key: ValueKey(_consoleFeedbackMessage(message)),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.caveat(
                        fontSize: 21,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2F3A32),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadySparkles() {
    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, child) {
        final pulse = _loopController.value;

        return Stack(
          children: [
            Positioned(
              left: 12 + pulse * 10,
              top: 7,
              child: _sparkle(8),
            ),
            Positioned(
              right: 16 + pulse * 8,
              bottom: 7,
              child: _sparkle(7),
            ),
          ],
        );
      },
    );
  }

  Widget _sparkle(double size) {
    return Text(
      '✦',
      style: TextStyle(
        fontSize: size,
        color: const Color(0xFF79A982).withOpacity(0.65),
      ),
    );
  }

  String _consoleFeedbackMessage(String message) {
    if (message.contains('Power overload')) {
      return 'POWER OVERLOAD!';
    }
    if (message.contains('Power is getting risky')) {
      return 'POWER RISKY!';
    }
    if (message.contains('Almost full')) {
      return 'POWER ALMOST FULL!';
    }

    if (message.contains('distorted') ||
        message.contains('breaking') ||
        message.contains('cracks')) {
      return 'SPEAKER DISTORTED!';
    }

    if (message.contains('too loud')) {
      return 'SOUND TOO LOUD!';
    }
    if (message.contains('too low') ||
        message.contains('barely hear') ||
        message.contains('soft')) {
      return 'SOUND TOO LOW!';
    }

    if (message.contains('huge sound') ||
        message.contains('festival sound') ||
        message.contains('powerful')) {
      return 'BIG FESTIVAL SOUND!';
    }

    if (message.contains('clean sound') ||
        message.contains('good balance') ||
        message.contains('clear sound') ||
        message.contains('loud and still stable') ||
        message.contains('usable')) {
      return 'NICE SOUND BALANCE!';
    }

    if (message.contains('too hot')) {
      return 'LIGHT TOO HOT!';
    }
    if (message.contains('too dark')) {
      return 'LIGHT TOO LOW!';
    }
    if (message.contains('too bright')) {
      return 'LIGHT TOO HIGH!';
    }
    if (message.contains('nice light') ||
        message.contains('nice vibe') ||
        message.contains('wow effect') ||
        message.contains('bright and safe')) {
      return 'NICE BALANCE!';
    }
    if (message.contains('Nice balance')) {
      return 'STAGE READY!';
    }
    return 'KEEP TUNING!';
  }

  StagePanelStatus _mainStatus(
    StagePanelStatus sound,
    StagePanelStatus light,
    StagePanelStatus power,
  ) {
    if (power == StagePanelStatus.warning ||
        sound == StagePanelStatus.warning ||
        light == StagePanelStatus.warning) {
      return StagePanelStatus.warning;
    }

    if (power == StagePanelStatus.caution ||
        sound == StagePanelStatus.caution ||
        light == StagePanelStatus.caution) {
      return StagePanelStatus.caution;
    }

    if (widget.state.hasAllSelections) {
      return StagePanelStatus.good;
    }

    return StagePanelStatus.neutral;
  }

  double _powerProgress() {
    if (widget.state.currentPowerCapacity <= 0) {
      return 0;
    }

    return widget.state.powerUsageRatio.clamp(0.0, 1.0);
  }
}

enum _MeterType {
  power,
  sound,
  light,
}

class _WarningShake extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const _WarningShake({
    required this.enabled,
    required this.child,
  });

  @override
  State<_WarningShake> createState() => _WarningShakeState();
}

class _WarningShakeState extends State<_WarningShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void didUpdateWidget(_WarningShake oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enabled && !oldWidget.enabled) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shake = math.sin(_controller.value * math.pi * 8) * 2.4;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
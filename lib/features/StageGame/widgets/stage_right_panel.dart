import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/stage_game_models.dart';

class StageRightPanel extends StatefulWidget {
  final StageGameState state;
  final StageGameConfig config;
  final ValueChanged<double> onSoundSliderProgressChanged;
  final ValueChanged<double> onLightSliderProgressChanged;
  final ValueChanged<StageControlLevel> onSoundLevelChanged;
  final ValueChanged<StageControlLevel> onLightLevelChanged;

  const StageRightPanel({
    super.key,
    required this.state,
    required this.config,
    required this.onSoundSliderProgressChanged,
    required this.onLightSliderProgressChanged,
    required this.onSoundLevelChanged,
    required this.onLightLevelChanged,
  });

  @override
  State<StageRightPanel> createState() => _StageRightPanelState();
}

class _StageRightPanelState extends State<StageRightPanel>
    with SingleTickerProviderStateMixin {
  static const Color _ink = Color(0xFF25252B);
  static const Color _paper = Color(0xFFF8F4EA);

  static const Color _green = Color(0xFF8BC29A);
  static const Color _greenDark = Color(0xFF456B52);
  static const Color _greenSoft = Color(0xFFE8F4EA);

  static const Color _yellow = Color(0xFFE9BF4E);
  static const Color _yellowDark = Color(0xFFB98923);
  static const Color _yellowSoft = Color(0xFFFFF2BF);

  static const Color _red = Color(0xFFD86055);
  static const Color _redSoft = Color(0xFFFFE4E1);

  static const Color _orange = Color(0xFFE79A4F);

  late final AnimationController _pulseController;

  double _soundDragProgress = 0.5;
  double _lightDragProgress = 0.0;

  SoundOption? _lastSoundOption;
  LightOption? _lastLightOption;

  StageGameState get state => widget.state;

  @override
  void initState() {
    super.initState();

    _lastSoundOption = state.selectedSound;
    _lastLightOption = state.selectedLight;

    _soundDragProgress = _progressFromLevel(state.soundControlLevel);
    _lightDragProgress = state.selectedLight == null
        ? 0.0
        : _progressFromLevel(state.lightControlLevel);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant StageRightPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    /*
      IMPORTANT:
      Do not reset the slider every time the parent updates the low/medium/high level.
      Otherwise the slider jumps back to 0 / 0.5 / 1.0 and does not feel smooth.

      We only reset the visual drag position when the selected sound/light option changes.
    */
    if (_lastSoundOption != state.selectedSound) {
      _lastSoundOption = state.selectedSound;

      _soundDragProgress = state.selectedSound == null
          ? 0.5
          : _progressFromLevel(state.soundControlLevel);
    }

    if (_lastLightOption != state.selectedLight) {
      _lastLightOption = state.selectedLight;

      _lightDragProgress = state.selectedLight == null
          ? 0.0
          : _progressFromLevel(state.lightControlLevel);
    }

    if (state.selectedLight == null) {
      _lightDragProgress = 0.0;
    }

    if (state.selectedSound == null) {
      _soundDragProgress = 0.5;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mainAlert = _mainAlertLevel;
    final powerAlert = _powerAlertLevel;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF2F352F),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 7),
          _buildFeedbackBanner(
            messages: _mainFeedbackMessages,
            alertLevel: mainAlert,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildPowerCard()),
                const SizedBox(width: 9),
                Expanded(child: _buildLightCard()),
                const SizedBox(width: 9),
                Expanded(child: _buildSoundCard()),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildBottomStatusBar(
            text: _powerFeedbackMessage,
            alertLevel: powerAlert,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 40,
      child: Center(
        child: Text(
          'STAGE BUILDER',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.caveat(
            fontSize: 33,
            height: 0.95,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
            color: _ink,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackBanner({
    required List<String> messages,
    required _PanelAlertLevel alertLevel,
  }) {
    final colors = _colorsForAlert(alertLevel);
    final shouldPulse =
        alertLevel == _PanelAlertLevel.warning ||
        alertLevel == _PanelAlertLevel.danger;

    final visibleMessages = messages.isEmpty
        ? ['Stage looks ready!']
        : messages.take(2).toList();

    final joinedMessage = visibleMessages.join('   •   ');

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = shouldPulse ? _pulseController.value : 0.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 41,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Color.lerp(
              colors.background,
              colors.pulseBackground,
              pulse,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Color.lerp(colors.border, colors.pulseBorder, pulse)!,
              width: 1.6 + (pulse * 1.0),
            ),
            boxShadow: [
              if (shouldPulse)
                BoxShadow(
                  color: colors.border.withOpacity(0.18 + pulse * 0.22),
                  blurRadius: 9 + pulse * 10,
                  spreadRadius: pulse * 1.7,
                ),
            ],
          ),
          child: child,
        );
      },
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _animatedFeedbackIcon(
                icon: _feedbackIconForMessage(joinedMessage),
                alertLevel: alertLevel,
              ),
              const SizedBox(width: 8),
              Text(
                joinedMessage.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: GoogleFonts.caveat(
                  fontSize: 25,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.65,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _animatedFeedbackIcon({
    required IconData icon,
    required _PanelAlertLevel alertLevel,
  }) {
    final colors = _colorsForAlert(alertLevel);
    final shouldAnimate =
        alertLevel == _PanelAlertLevel.warning ||
        alertLevel == _PanelAlertLevel.danger;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = shouldAnimate ? _pulseController.value : 0.0;
        final angle = shouldAnimate ? math.sin(pulse * math.pi * 2) * 0.12 : 0.0;
        final scale = 1.0 + (pulse * 0.12);

        return Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: scale,
            child: Icon(
              icon,
              size: 20,
              color: colors.icon,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPowerCard() {
    final capacity = state.currentPowerCapacity;

    final valueLabel = capacity > 0
        ? '${state.totalPowerLoad}/${state.currentPowerCapacity} W'
        : '${state.totalPowerLoad}/0 W';

    final progress = capacity <= 0
        ? 0.0
        : (state.totalPowerLoad / capacity).clamp(0.0, 1.0);

    return _controlCard(
      title: 'Power',
      subtitle: 'Management',
      icon: Icons.bolt_rounded,
      value: valueLabel,
      accentColor: _greenDark,
      backgroundColor: _greenSoft,
      borderColor: _green,
      alertLevel: _powerAlertLevel,
      meter: _stageMeter(
        progress: progress,
        minLabel: '0',
        maxLabel: 'Max',
        enabled: false,
        alertLevel: _powerAlertLevel,
        onChanged: null,
        onChangeEnd: null,
      ),
    );
  }

  Widget _buildLightCard() {
    final hasLight = state.selectedLight != null;
    final max = _lightMaxValue;
    final value = hasLight ? _lightPreviewValue.round() : 0;

    return _controlCard(
      title: 'Light',
      subtitle: 'Control',
      icon: Icons.lightbulb_rounded,
      value: '$value',
      accentColor: _yellowDark,
      backgroundColor: _yellowSoft,
      borderColor: _yellow,
      alertLevel: _lightAlertLevel,
      meter: _stageMeter(
        progress: _lightDragProgress,
        minLabel: '0',
        maxLabel: max.round().toString(),
        enabled: hasLight,
        alertLevel: _lightAlertLevel,
        onChanged: (progress) {
          setState(() {
            _lightDragProgress = progress;
          });

          widget.onLightSliderProgressChanged(progress);
        },
        onChangeEnd: (progress) {
          setState(() {
            _lightDragProgress = progress;
          });

          widget.onLightLevelChanged(_levelFromProgress(progress));
        },
      ),
    );
  }

  Widget _buildSoundCard() {
    final hasSound = state.selectedSound != null;
    final max = _soundMaxValue;
    final value = hasSound ? _soundPreviewValue.round() : 0;

    return _controlCard(
      title: 'Sound',
      subtitle: 'Control',
      icon: Icons.volume_up_rounded,
      value: '$value dB',
      accentColor: _greenDark,
      backgroundColor: _greenSoft,
      borderColor: _green,
      alertLevel: _soundAlertLevel,
      meter: _stageMeter(
        progress: _soundDragProgress,
        minLabel: '0 dB',
        maxLabel: '${max.round()} dB',
        enabled: hasSound,
        alertLevel: _soundAlertLevel,
        onChanged: (progress) {
          setState(() {
            _soundDragProgress = progress;
          });

          widget.onSoundSliderProgressChanged(progress);
        },
        onChangeEnd: (progress) {
          setState(() {
            _soundDragProgress = progress;
          });

          widget.onSoundLevelChanged(_levelFromProgress(progress));
        },
      ),
    );
  }

  Widget _controlCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required Color accentColor,
    required Color backgroundColor,
    required Color borderColor,
    required _PanelAlertLevel alertLevel,
    required Widget meter,
  }) {
    final alertColors = _colorsForAlert(alertLevel);
    final shouldPulse =
        alertLevel == _PanelAlertLevel.warning ||
        alertLevel == _PanelAlertLevel.danger;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = shouldPulse ? _pulseController.value : 0.0;
        final shake = alertLevel == _PanelAlertLevel.danger
            ? math.sin(pulse * math.pi * 2) * 1.8
            : 0.0;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
            decoration: BoxDecoration(
              color: Color.lerp(
                backgroundColor,
                alertColors.background,
                pulse * 0.70,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Color.lerp(borderColor, alertColors.border, pulse)!,
                width: 1.8 + (pulse * 0.95),
              ),
              boxShadow: [
                BoxShadow(
                  color: alertColors.border.withOpacity(
                    shouldPulse ? 0.15 + pulse * 0.20 : 0.07,
                  ),
                  blurRadius: shouldPulse ? 10 + pulse * 13 : 9,
                  spreadRadius: shouldPulse ? pulse * 0.9 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Stack(
        children: [
          Positioned(
            right: 6,
            top: 6,
            child: _cornerDoodle(
              color: accentColor.withOpacity(0.35),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _cardTop(
                  title: title,
                  subtitle: subtitle,
                  icon: icon,
                  accentColor: accentColor,
                  alertLevel: alertLevel,
                ),
                const SizedBox(height: 7),
                _valueBadge(
                  value: value,
                  color: accentColor,
                  alertLevel: alertLevel,
                ),
                const SizedBox(height: 6),
                meter,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardTop({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required _PanelAlertLevel alertLevel,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _doodleIcon(
          icon: icon,
          color: accentColor,
          background: Colors.white.withOpacity(0.66),
          size: 38,
          iconSize: 23,
          alertLevel: alertLevel,
        ),
        const SizedBox(height: 7),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.caveat(
            fontSize: 27,
            height: 0.78,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.caveat(
            fontSize: 21,
            height: 0.75,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
      ],
    );
  }

  Widget _stageMeter({
    required double progress,
    required String minLabel,
    required String maxLabel,
    required bool enabled,
    required _PanelAlertLevel alertLevel,
    required ValueChanged<double>? onChanged,
    required ValueChanged<double>? onChangeEnd,
  }) {
    const knobWidth = 30.0;
    final safeProgress = progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth.clamp(128.0, 240.0);
        final usableWidth = trackWidth - knobWidth;
        final knobLeft = safeProgress * usableWidth;

        double progressFromDx(double dx) {
          return ((dx - knobWidth / 2) / usableWidth).clamp(0.0, 1.0);
        }

        void updateFromDx(double dx, {bool end = false}) {
          if (!enabled) return;

          final p = progressFromDx(dx);
          onChanged?.call(p);

          if (end) {
            onChangeEnd?.call(p);
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: !enabled
                  ? null
                  : (details) {
                      updateFromDx(details.localPosition.dx, end: true);
                    },
              onHorizontalDragStart: !enabled
                  ? null
                  : (details) {
                      updateFromDx(details.localPosition.dx);
                    },
              onHorizontalDragUpdate: !enabled
                  ? null
                  : (details) {
                      updateFromDx(details.localPosition.dx);
                    },
              onHorizontalDragEnd: !enabled
                  ? null
                  : (_) {
                      onChangeEnd?.call(safeProgress);
                    },
              child: SizedBox(
                width: trackWidth,
                height: 48,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 20,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: Size(trackWidth, 14),
                            painter: _SketchMeterPainter(
                              progress: safeProgress,
                              alertLevel: alertLevel,
                              pulse: _pulseController.value,
                              enabled: enabled,
                            ),
                          );
                        },
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 80),
                      curve: Curves.easeOut,
                      left: knobLeft.clamp(0.0, usableWidth),
                      top: 8,
                      child: _meterKnob(
                        enabled: enabled,
                        alertLevel: alertLevel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
              child: Row(
                children: [
                  Text(
                    minLabel,
                    style: GoogleFonts.caveat(
                      fontSize: 18,
                      height: 0.78,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    maxLabel,
                    style: GoogleFonts.caveat(
                      fontSize: 18,
                      height: 0.78,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _meterKnob({
    required bool enabled,
    required _PanelAlertLevel alertLevel,
  }) {
    final colors = _colorsForAlert(alertLevel);
    final shouldPulse =
        alertLevel == _PanelAlertLevel.warning ||
        alertLevel == _PanelAlertLevel.danger;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = shouldPulse ? _pulseController.value : 0.0;
        final scale = 1.0 + (pulse * 0.07);

        return Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 30,
            height: 38,
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFFFFF7D9) : const Color(0xFFE6E0D3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: shouldPulse
                    ? Color.lerp(_ink, colors.border, pulse)!
                    : _ink.withOpacity(enabled ? 0.88 : 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: shouldPulse
                      ? colors.border.withOpacity(0.20 + pulse * 0.28)
                      : Colors.black.withOpacity(enabled ? 0.16 : 0.07),
                  blurRadius: shouldPulse ? 6 + pulse * 13 : 5,
                  spreadRadius: shouldPulse ? pulse * 1.2 : 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 23,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.46),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _valueBadge({
    required String value,
    required Color color,
    required _PanelAlertLevel alertLevel,
  }) {
    final alertColors = _colorsForAlert(alertLevel);
    final shouldPulse =
        alertLevel == _PanelAlertLevel.warning ||
        alertLevel == _PanelAlertLevel.danger;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = shouldPulse ? _pulseController.value : 0.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(
            minWidth: 78,
            maxWidth: 145,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.white.withOpacity(0.42),
              alertColors.background,
              pulse * 0.55,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Color.lerp(
                color.withOpacity(0.82),
                alertColors.border,
                pulse,
              )!,
              width: 1.5,
            ),
            boxShadow: [
              if (shouldPulse)
                BoxShadow(
                  color: alertColors.border.withOpacity(0.10 + pulse * 0.12),
                  blurRadius: 5 + pulse * 6,
                  spreadRadius: pulse * 0.5,
                ),
            ],
          ),
          child: child,
        );
      },
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: GoogleFonts.caveat(
          fontSize: 22,
          height: 0.86,
          fontWeight: FontWeight.w900,
          color: _ink,
        ),
      ),
    );
  }

  Widget _buildBottomStatusBar({
    required String text,
    required _PanelAlertLevel alertLevel,
  }) {
    final colors = _colorsForAlert(alertLevel);
    final shouldPulse =
        alertLevel == _PanelAlertLevel.warning ||
        alertLevel == _PanelAlertLevel.danger;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = shouldPulse ? _pulseController.value : 0.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 41,
          decoration: BoxDecoration(
            color: Color.lerp(
              colors.background,
              colors.pulseBackground,
              pulse,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Color.lerp(colors.border, colors.pulseBorder, pulse)!,
              width: 1.6 + (pulse * 0.8),
            ),
            boxShadow: [
              if (shouldPulse)
                BoxShadow(
                  color: colors.border.withOpacity(0.14 + pulse * 0.18),
                  blurRadius: 9 + pulse * 9,
                  spreadRadius: pulse * 1.2,
                ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _animatedFeedbackIcon(
            icon: _feedbackIconForMessage(text),
            alertLevel: alertLevel,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.caveat(
                fontSize: 25,
                height: 0.9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doodleIcon({
    required IconData icon,
    required Color color,
    required Color background,
    required double size,
    required double iconSize,
    _PanelAlertLevel alertLevel = _PanelAlertLevel.safe,
  }) {
    final colors = _colorsForAlert(alertLevel);
    final shouldPulse =
        alertLevel == _PanelAlertLevel.warning ||
        alertLevel == _PanelAlertLevel.danger;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = shouldPulse ? _pulseController.value : 0.0;
        final scale = 1.0 + (pulse * 0.06);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Color.lerp(background, colors.background, pulse * 0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: Color.lerp(
                  color.withOpacity(0.45),
                  colors.border,
                  pulse,
                )!,
                width: 1.4,
              ),
              boxShadow: [
                if (shouldPulse)
                  BoxShadow(
                    color: colors.border.withOpacity(0.10 + pulse * 0.12),
                    blurRadius: 5 + pulse * 8,
                    spreadRadius: pulse * 0.7,
                  ),
              ],
            ),
            child: Icon(
              icon,
              color: Color.lerp(color, colors.icon, pulse),
              size: iconSize,
            ),
          ),
        );
      },
    );
  }

  Widget _cornerDoodle({
    required Color color,
  }) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _CornerSketchPainter(color: color),
      ),
    );
  }

  StageControlLevel _levelFromProgress(double progress) {
    if (progress < 0.34) return StageControlLevel.low;
    if (progress < 0.67) return StageControlLevel.medium;
    return StageControlLevel.high;
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

  double get _soundMaxValue {
    switch (state.selectedSound) {
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

  double get _lightMaxValue {
    switch (state.selectedLight) {
      case LightOption.led:
        return 82;
      case LightOption.smart:
        return 85;
      case LightOption.halogen:
        return 94;
      default:
        return 85;
    }
  }

  double get _soundPreviewValue {
    if (state.selectedSound == null) return 0;

    switch (state.selectedSound!) {
      case SoundOption.cheap:
        return _lerpByProgress(
          progress: _soundDragProgress,
          low: 35,
          medium: 58,
          high: 75,
        );

      case SoundOption.eco:
        return _lerpByProgress(
          progress: _soundDragProgress,
          low: 55,
          medium: 82,
          high: 98,
        );

      case SoundOption.pro:
        return _lerpByProgress(
          progress: _soundDragProgress,
          low: 82,
          medium: 98,
          high: 110,
        );
    }
  }

  double get _lightPreviewValue {
    if (state.selectedLight == null) return 0;

    switch (state.selectedLight!) {
      case LightOption.led:
        return _lerpByProgress(
          progress: _lightDragProgress,
          low: 55,
          medium: 75,
          high: 82,
        );

      case LightOption.smart:
        return _lerpByProgress(
          progress: _lightDragProgress,
          low: 60,
          medium: 82,
          high: 85,
        );

      case LightOption.halogen:
        return _lerpByProgress(
          progress: _lightDragProgress,
          low: 65,
          medium: 82,
          high: 94,
        );
    }
  }

  double _lerpByProgress({
    required double progress,
    required double low,
    required double medium,
    required double high,
  }) {
    final p = progress.clamp(0.0, 1.0);

    if (p <= 0.5) {
      return low + ((medium - low) * (p / 0.5));
    }

    return medium + ((high - medium) * ((p - 0.5) / 0.5));
  }

  bool get _isOverloaded {
    return state.currentPowerCapacity > 0 &&
        state.totalPowerLoad > state.currentPowerCapacity;
  }

  _PanelAlertLevel get _mainAlertLevel {
    if (_isOverloaded) return _PanelAlertLevel.danger;

    if (_soundAlertLevel == _PanelAlertLevel.danger ||
        _lightAlertLevel == _PanelAlertLevel.danger) {
      return _PanelAlertLevel.danger;
    }

    if (_soundAlertLevel == _PanelAlertLevel.warning ||
        _lightAlertLevel == _PanelAlertLevel.warning) {
      return _PanelAlertLevel.warning;
    }

    if (_soundAlertLevel == _PanelAlertLevel.neutral) {
      return _PanelAlertLevel.neutral;
    }

    return _PanelAlertLevel.safe;
  }

  _PanelAlertLevel get _powerAlertLevel {
    if (state.currentPowerCapacity <= 0) return _PanelAlertLevel.neutral;
    if (_isOverloaded) return _PanelAlertLevel.danger;

    if (state.powerUsageRatio >= 0.92) {
      return _PanelAlertLevel.danger;
    }

    if (state.powerUsageRatio >= 0.80) {
      return _PanelAlertLevel.warning;
    }

    return _PanelAlertLevel.safe;
  }

  _PanelAlertLevel get _soundAlertLevel {
    if (state.selectedSound == null) return _PanelAlertLevel.neutral;

    final level = _levelFromProgress(_soundDragProgress);

    if (state.selectedSound == SoundOption.cheap &&
        level == StageControlLevel.high) {
      return _PanelAlertLevel.danger;
    }

    if (_soundPreviewValue < 70) {
      return _PanelAlertLevel.warning;
    }

    if (state.selectedSound == SoundOption.pro &&
        _soundPreviewValue >= 105) {
      return _PanelAlertLevel.danger;
    }

    if (_soundPreviewValue >= 98) {
      return _PanelAlertLevel.warning;
    }

    return _PanelAlertLevel.safe;
  }

  _PanelAlertLevel get _lightAlertLevel {
    if (state.selectedLight == null) return _PanelAlertLevel.neutral;

    final level = _levelFromProgress(_lightDragProgress);

    if (state.selectedLight == LightOption.halogen &&
        level == StageControlLevel.high) {
      return _PanelAlertLevel.danger;
    }

    if (_lightPreviewValue < 60) {
      return _PanelAlertLevel.warning;
    }

    if (_lightPreviewValue >= 90) {
      return _PanelAlertLevel.danger;
    }

    if (_lightPreviewValue >= 85) {
      return _PanelAlertLevel.warning;
    }

    return _PanelAlertLevel.safe;
  }

  List<String> get _mainFeedbackMessages {
    final messages = <String>[];

    if (_isOverloaded) {
      return ['Power overload!'];
    }

    if (state.currentPowerCapacity <= 0) {
      return ['Choose power source'];
    }

    if (state.selectedSound == null) {
      return ['Choose sound setup'];
    }

    final soundLevel = _levelFromProgress(_soundDragProgress);

    if (state.selectedSound == SoundOption.cheap &&
        soundLevel == StageControlLevel.high) {
      messages.add('Speaker is breaking!');
    } else if (_soundPreviewValue < 70) {
      messages.add('Sound too low!');
    } else if (state.selectedSound == SoundOption.pro &&
        _soundPreviewValue >= 105) {
      messages.add('Sound super loud!');
    } else if (_soundPreviewValue >= 98) {
      messages.add('Sound is loud!');
    }

    if (state.selectedLight != null) {
      final lightLevel = _levelFromProgress(_lightDragProgress);

      if (state.selectedLight == LightOption.halogen &&
          lightLevel == StageControlLevel.high) {
        messages.add('Light is too hot!');
      } else if (_lightPreviewValue < 60) {
        messages.add('Light too low!');
      } else if (_lightPreviewValue >= 90) {
        messages.add('Light too hot!');
      } else if (_lightPreviewValue >= 85) {
        messages.add('Light is bright!');
      }
    }

    if (messages.isEmpty) {
      messages.add('Stage looks ready!');
    }

    return messages;
  }

  String get _powerFeedbackMessage {
    if (state.currentPowerCapacity <= 0) return 'Choose power source';
    if (_isOverloaded) return 'Power overload!';
    if (state.powerUsageRatio >= 0.92) return 'Power getting risky!';
    if (state.powerUsageRatio >= 0.80) return 'Almost full!';
    if (state.powerUsageRatio <= 0.40) return 'Power safe';
    return 'Stage stable';
  }

  IconData _feedbackIconForMessage(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('overload') ||
        lower.contains('risky') ||
        lower.contains('hot') ||
        lower.contains('breaking') ||
        lower.contains('distorted') ||
        lower.contains('loud') ||
        lower.contains('bright')) {
      return Icons.warning_amber_rounded;
    }

    if (lower.contains('sound') || lower.contains('speaker')) {
      return Icons.volume_up_rounded;
    }

    if (lower.contains('light')) {
      return Icons.lightbulb_rounded;
    }

    if (lower.contains('power')) {
      return Icons.bolt_rounded;
    }

    if (lower.contains('ready') || lower.contains('stable')) {
      return Icons.check_circle_rounded;
    }

    return Icons.info_rounded;
  }

  _AlertColors _colorsForAlert(_PanelAlertLevel level) {
    switch (level) {
      case _PanelAlertLevel.neutral:
        return const _AlertColors(
          background: Color(0xFFF6F1E6),
          border: Color(0xFFC8BFA9),
          icon: Color(0xFF6D6A5C),
          pulseBackground: Color(0xFFF6F1E6),
          pulseBorder: Color(0xFFC8BFA9),
        );

      case _PanelAlertLevel.safe:
        return const _AlertColors(
          background: Color(0xFFE9F4E7),
          border: _green,
          icon: _greenDark,
          pulseBackground: Color(0xFFE9F4E7),
          pulseBorder: _green,
        );

      case _PanelAlertLevel.warning:
        return const _AlertColors(
          background: Color(0xFFFFF2C4),
          border: _yellow,
          icon: _yellowDark,
          pulseBackground: Color(0xFFFFE6A8),
          pulseBorder: _orange,
        );

      case _PanelAlertLevel.danger:
        return const _AlertColors(
          background: _redSoft,
          border: _red,
          icon: _red,
          pulseBackground: Color(0xFFFFC8C0),
          pulseBorder: Color(0xFFB94138),
        );
    }
  }
}

enum _PanelAlertLevel {
  neutral,
  safe,
  warning,
  danger,
}

class _AlertColors {
  final Color background;
  final Color border;
  final Color icon;
  final Color pulseBackground;
  final Color pulseBorder;

  const _AlertColors({
    required this.background,
    required this.border,
    required this.icon,
    required this.pulseBackground,
    required this.pulseBorder,
  });
}

class _SketchMeterPainter extends CustomPainter {
  final double progress;
  final _PanelAlertLevel alertLevel;
  final double pulse;
  final bool enabled;

  const _SketchMeterPainter({
    required this.progress,
    required this.alertLevel,
    required this.pulse,
    required this.enabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(99),
    );

    final basePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFCFAF2);

    canvas.drawRRect(trackRect, basePaint);

    final greenWidth = size.width * 0.33;
    final yellowWidth = size.width * 0.31;
    final orangeWidth = size.width * 0.18;
    final redWidth = size.width * 0.18;

    const segmentRadius = Radius.circular(99);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, greenWidth, size.height),
        segmentRadius,
      ),
      Paint()..color = const Color(0xFF67B884),
    );

    canvas.drawRect(
      Rect.fromLTWH(greenWidth, 0, yellowWidth, size.height),
      Paint()..color = const Color(0xFFF0D34E),
    );

    canvas.drawRect(
      Rect.fromLTWH(greenWidth + yellowWidth, 0, orangeWidth, size.height),
      Paint()..color = const Color(0xFFE79A4F),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          greenWidth + yellowWidth + orangeWidth,
          0,
          redWidth,
          size.height,
        ),
        segmentRadius,
      ),
      Paint()..color = const Color(0xFFD85D50),
    );

    if (!enabled) {
      final disabledPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withOpacity(0.18);

      canvas.drawRRect(trackRect, disabledPaint);
    }

    if (alertLevel == _PanelAlertLevel.warning ||
        alertLevel == _PanelAlertLevel.danger) {
      final alertColor = alertLevel == _PanelAlertLevel.danger
          ? const Color(0xFFD85D50)
          : const Color(0xFFE79A4F);

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0 + (pulse * 5.0)
        ..color = alertColor.withOpacity(0.11 + pulse * 0.17);

      canvas.drawRRect(trackRect, glowPaint);

      final alertPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + (pulse * 2.0)
        ..color = alertColor.withOpacity(0.38 + pulse * 0.52);

      canvas.drawRRect(trackRect, alertPaint);
    }

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF2F352F).withOpacity(0.65);

    canvas.drawRRect(trackRect, borderPaint);

    final progressX = size.width * progress.clamp(0.0, 1.0);

    final markerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withOpacity(0.58);

    for (var i = 1; i <= 5; i++) {
      final x = size.width * (i / 6);
      canvas.drawLine(
        Offset(x, 2),
        Offset(x, size.height - 2),
        markerPaint,
      );
    }

    final shinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withOpacity(0.48);

    canvas.drawLine(
      Offset(6, size.height * 0.33),
      Offset(progressX.clamp(6.0, size.width - 6), size.height * 0.33),
      shinePaint,
    );

    if (enabled &&
        (alertLevel == _PanelAlertLevel.warning ||
            alertLevel == _PanelAlertLevel.danger)) {
      final sparklePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.55 + pulse * 0.35);

      final sparkleX = (progressX + 10).clamp(10.0, size.width - 10);
      final centerY = size.height / 2;

      canvas.drawLine(
        Offset(sparkleX - 3, centerY),
        Offset(sparkleX + 3, centerY),
        sparklePaint,
      );

      canvas.drawLine(
        Offset(sparkleX, centerY - 3),
        Offset(sparkleX, centerY + 3),
        sparklePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SketchMeterPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.alertLevel != alertLevel ||
        oldDelegate.pulse != pulse ||
        oldDelegate.enabled != enabled;
  }
}

class _CornerSketchPainter extends CustomPainter {
  final Color color;

  const _CornerSketchPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.10,
        size.height * 0.10,
        size.width * 0.70,
        size.height * 0.70,
      ),
      -1.5,
      1.3,
      false,
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 0.70, size.height * 0.18),
      Offset(size.width * 0.92, size.height * 0.10),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 0.84, size.height * 0.36),
      Offset(size.width * 0.98, size.height * 0.36),
      paint,
    );

    final dotPaint = Paint()
      ..color = color.withOpacity(0.70)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.82),
      1.7,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerSketchPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
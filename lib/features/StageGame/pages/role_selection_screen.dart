import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'stage_game_page.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _leftPlayerReady = false;
  bool _rightPlayerReady = false;

  void _checkBothReady() {
    if (!_leftPlayerReady || !_rightPlayerReady) return;
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StageGamePage()),
      );
    });
  }

  void _setLeftReady() {
    if (_leftPlayerReady) return;
    setState(() => _leftPlayerReady = true);
    HapticFeedback.heavyImpact();
    _checkBothReady();
  }

  void _setRightReady() {
    if (_rightPlayerReady) return;
    setState(() => _rightPlayerReady = true);
    HapticFeedback.heavyImpact();
    _checkBothReady();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(
                'assets/StageGameV2-image/frame.png',
                fit: BoxFit.fill,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(54, 42, 54, 48),
              child: Row(
                children: [
                  Expanded(
                    child: _RotatedRoleSide(
                      quarterTurns: 1,
                      imagePath: 'assets/StageGameV2-image/firstcharacter.png',
                      initialText:
                          'Hello! I am Mike, nice to meet you.\n\nFor this game, I am your Personal Assistant for the festival stage.',
                      explainText:
                          'Don\u2019t worry \u2014 I\u2019ll help with the planning side.\n\nYour job is to choose the equipment, watch the choices and help keep the show organized.',
                      buttonText: _leftPlayerReady ? '\u2713 Ready' : 'Ready',
                      isReady: _leftPlayerReady,
                      onReady: _setLeftReady,
                    ),
                  ),
                  Container(width: 1.5, color: const Color(0xFF7FA889)),
                  Expanded(
                    child: _RotatedRoleSide(
                      quarterTurns: 3,
                      imagePath: 'assets/StageGameV2-image/secondcharacter.png',
                      initialText:
                          'Hi, I am Nick, what\u2019s up?\n\nFor this game, I am the Stage Builder for the festival stage.',
                      explainText:
                          'Now comes the hard part.\n\nYou must control the lights, sound and energy while the show is running smoothly.',
                      buttonText: _rightPlayerReady ? '\u2713 Ready' : 'Ready',
                      isReady: _rightPlayerReady,
                      onReady: _setRightReady,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RotatedRoleSide extends StatelessWidget {
  final int quarterTurns;
  final String imagePath;
  final String initialText;
  final String explainText;
  final String buttonText;
  final bool isReady;
  final VoidCallback onReady;

  const _RotatedRoleSide({
    required this.quarterTurns,
    required this.imagePath,
    required this.initialText,
    required this.explainText,
    required this.buttonText,
    required this.isReady,
    required this.onReady,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RotatedBox(
          quarterTurns: quarterTurns,
          child: SizedBox(
            width: constraints.maxHeight,
            height: constraints.maxWidth,
            child: _RoleSideContent(
              imagePath: imagePath,
              initialText: initialText,
              explainText: explainText,
              buttonText: buttonText,
              isReady: isReady,
              onReady: onReady,
            ),
          ),
        );
      },
    );
  }
}

class _RoleSideContent extends StatefulWidget {
  final String imagePath;
  final String initialText;
  final String explainText;
  final String buttonText;
  final bool isReady;
  final VoidCallback onReady;

  const _RoleSideContent({
    required this.imagePath,
    required this.initialText,
    required this.explainText,
    required this.buttonText,
    required this.isReady,
    required this.onReady,
  });

  @override
  State<_RoleSideContent> createState() => _RoleSideContentState();
}

class _RoleSideContentState extends State<_RoleSideContent>
    with TickerProviderStateMixin {
  bool _showExplain = false;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -7, end: 7).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String currentText = _showExplain
        ? widget.explainText
        : widget.initialText;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: SpeechCloud(
                key: ValueKey('${currentText}_${widget.isReady}'),
                text: widget.isReady
                    ? 'Ready!\nWaiting for the other player...'
                    : currentText,
                isReady: widget.isReady,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 5,
            child: Center(
              child: _ReadyGlow(
                isReady: widget.isReady,
                animation: _glowAnimation,
                child: AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: child,
                  ),
                  child: widget.isReady
                      ? AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            // Pulsează între 1.0 și 1.12 cât timp e Ready
                            final scale = 1.0 + (0.12 * _glowAnimation.value);
                            return Transform.scale(scale: scale, child: child);
                          },
                          child: Image.asset(
                            widget.imagePath,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Image.asset(widget.imagePath, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ExplainButton(
                isActive: _showExplain,
                onTap: widget.isReady
                    ? () {}
                    : () => setState(() => _showExplain = !_showExplain),
              ),
              const SizedBox(width: 12),
              _ReadyButton(
                text: widget.buttonText,
                isReady: widget.isReady,
                onTap: widget.isReady ? null : widget.onReady,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Speech Cloud (fără titlu) ──────────────────────────────────────────────
class SpeechCloud extends StatelessWidget {
  final String text;
  final bool isReady;

  const SpeechCloud({super.key, required this.text, required this.isReady});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: isReady
                  ? const Color(0xFFE8F5D0).withOpacity(0.96)
                  : Colors.white.withOpacity(0.96),
              borderRadius: BorderRadius.circular(55),
              border: Border.all(
                color: isReady
                    ? const Color(0xFF5F985F)
                    : const Color(0xFF111111),
                width: isReady ? 2.4 : 2,
              ),
            ),
            // ✅ Fără titlu — direct conținutul
            child: Center(
              child: isReady
                  ? Text(
                      text,
                      textAlign: TextAlign.center,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.caveat(
                        fontSize: 30,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111111),
                      ),
                    )
                  : _TypewriterHighlight(text: text),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 38, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bubble(3.8, isReady),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 9),
                  child: _bubble(5.5, isReady),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _bubble(8, isReady),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _bubble(double radius, bool isReady) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: isReady
            ? const Color(0xFFE8F5D0).withOpacity(0.96)
            : Colors.white.withOpacity(0.96),
        shape: BoxShape.circle,
        border: Border.all(
          color: isReady ? const Color(0xFF5F985F) : const Color(0xFF111111),
          width: 1.8,
        ),
      ),
    );
  }
}

// ── Typewriter cu highlight — text mai gros ──────────────────────────────────
class _TypewriterHighlight extends StatefulWidget {
  final String text;
  const _TypewriterHighlight({required this.text});
  @override
  State<_TypewriterHighlight> createState() => _TypewriterHighlightState();
}

class _TypewriterHighlightState extends State<_TypewriterHighlight> {
  int _visibleChars = 0;
  static const _highlights = ['Personal Assistant', 'Stage Builder'];

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(_TypewriterHighlight old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      setState(() => _visibleChars = 0);
      _startTyping();
    }
  }

  void _startTyping() {
    Future.doWhile(() async {
      if (!mounted || _visibleChars >= widget.text.length) return false;
      await Future.delayed(const Duration(milliseconds: 18));
      if (!mounted) return false;
      setState(() => _visibleChars++);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.text.substring(0, _visibleChars);
    final spans = <InlineSpan>[];
    String remaining = visible;
    while (remaining.isNotEmpty) {
      int earliestIndex = remaining.length;
      String? foundKeyword;
      for (final kw in _highlights) {
        final idx = remaining.indexOf(kw);
        if (idx != -1 && idx < earliestIndex) {
          earliestIndex = idx;
          foundKeyword = kw;
        }
      }
      if (foundKeyword == null) {
        spans.add(TextSpan(text: remaining));
        break;
      }
      if (earliestIndex > 0) {
        spans.add(TextSpan(text: remaining.substring(0, earliestIndex)));
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xff3d7a4a),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              foundKeyword,
              style: GoogleFonts.caveat(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ),
        ),
      );
      remaining = remaining.substring(earliestIndex + foundKeyword.length);
    }
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        // ✅ text mai gros (w900 în loc de w800) și mai mare (25 în loc de 22)
        style: GoogleFonts.caveat(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF111111),
          height: 1.2,
        ),
        children: spans,
      ),
    );
  }
}

class _ExplainButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  const _ExplainButton({required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 142,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4A7C59) : const Color(0xFFB9D7BE),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isActive ? const Color(0xFF2E5638) : const Color(0xFF8FB99A),
            width: 1.4,
          ),
        ),
        child: Text(
          isActive ? 'Show Less' : '? Explain',
          style: GoogleFonts.caveat(
            color: isActive ? Colors.white : const Color(0xFF111111),
            fontWeight: FontWeight.w900,
            fontSize: 22,
            height: 0.9,
          ),
        ),
      ),
    );
  }
}

class _ReadyButton extends StatelessWidget {
  final String text;
  final bool isReady;
  final VoidCallback? onTap;
  const _ReadyButton({
    required this.text,
    required this.isReady,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 142,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isReady ? const Color(0xFF3F6F4A) : const Color(0xFF529E68),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isReady ? const Color(0xFF2E5638) : const Color(0xFF418455),
            width: 1.4,
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.caveat(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 25,
            height: 0.9,
          ),
        ),
      ),
    );
  }
}

class _ReadyGlow extends StatelessWidget {
  final bool isReady;
  final Animation<double> animation;
  final Widget child;
  const _ReadyGlow({
    required this.isReady,
    required this.animation,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return child;
  }
}

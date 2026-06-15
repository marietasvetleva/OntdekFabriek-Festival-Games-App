import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'stage_game_page.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _leftReady = false;
  bool _rightReady = false;

  void _onPlayerReady(bool isLeft) {
    setState(() {
      if (isLeft)
        _leftReady = true;
      else
        _rightReady = true;
    });

    if (_leftReady && _rightReady) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StageGamePage()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffececec),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xffdce8dd),
              border: Border.all(color: Colors.grey.shade600),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _RoleSection(
                    isLeft: true,
                    characterImage:
                        'assets/StageGameV2-image/firstcharacter.png',
                    initialText:
                        'Hello! I am Mike, nice to meet you. '
                        'For this game, I am a Personal Assistant '
                        'for festival stage. Do you know what it means?',
                    explainText:
                        'Don\'t worry — I\'ll make sure no one misses a thing. '
                        'Your job is to organize the event timeline and keep things running smoothly.',
                    isReady: _leftReady,
                    onReady: () => _onPlayerReady(true),
                  ),
                ),
                Container(width: 1, color: Colors.black54),
                Expanded(
                  child: _RoleSection(
                    isLeft: false,
                    characterImage:
                        'assets/StageGameV2-image/secondcharacter.png',
                    initialText:
                        'Hi, I am Nick, what\'s up? '
                        'Also for this game I am Stage Builder for this '
                        'game stage. Do you know what it means?',
                    explainText:
                        'Now comes the hard part. As the stage builder, '
                        'you must control the lights, sound and energy '
                        'to keep the show running smoothly.',
                    isReady: _rightReady,
                    onReady: () => _onPlayerReady(false),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Confetti particle ─────────────────────────────────────────────────────────
class _ConfettiParticle {
  double x, y, angle, speed, size;
  Color color;

  _ConfettiParticle(Random rng, double width, double height)
    : x = rng.nextBool() ? -10 : width + 10,
      y = rng.nextDouble() * height * 0.5,
      angle = rng.nextDouble() * pi * 2,
      speed = 2 + rng.nextDouble() * 3,
      size = 6 + rng.nextDouble() * 8,
      color = [
        Colors.yellow,
        Colors.green,
        Colors.orange,
        Colors.white,
        const Color(0xff3d7a4a),
      ][rng.nextInt(5)];

  void update() {
    x += (x < 0 ? speed : -speed);
    y += sin(angle) * 2;
    angle += 0.05;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.angle);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.5,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

// ── Speech Cloud ──────────────────────────────────────────────────────────────
class SpeechCloud extends StatelessWidget {
  final String text;
  const SpeechCloud({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 500,
          padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(60),
            border: Border.all(color: Colors.black87, width: 3),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 24, top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bubble(10),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _bubble(7),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 18),
                child: _bubble(5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bubble(double r) => Container(
    width: r * 2,
    height: r * 2,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.black87, width: 2),
    ),
  );
}

// ── Typewriter Text ───────────────────────────────────────────────────────────
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _TypewriterText({required this.text, required this.style});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayed = '';
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(_TypewriterText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _displayed = '';
      _index = 0;
      _startTyping();
    }
  }

  void _startTyping() {
    Future.doWhile(() async {
      if (!mounted || _index >= widget.text.length) return false;
      await Future.delayed(const Duration(milliseconds: 38));
      if (!mounted) return false;
      setState(() {
        _displayed = widget.text.substring(0, ++_index);
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayed, textAlign: TextAlign.center, style: widget.style);
  }
}

// ── Role Section ──────────────────────────────────────────────────────────────
class _RoleSection extends StatefulWidget {
  final bool isLeft;
  final String characterImage;
  final String initialText;
  final String explainText;
  final bool isReady;
  final VoidCallback onReady;

  const _RoleSection({
    required this.isLeft,
    required this.characterImage,
    required this.initialText,
    required this.explainText,
    required this.isReady,
    required this.onReady,
  });

  @override
  State<_RoleSection> createState() => _RoleSectionState();
}

class _RoleSectionState extends State<_RoleSection>
    with TickerProviderStateMixin {
  bool _showExplain = false;

  // Glow
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Float
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  // Confetti
  late AnimationController _confettiController;
  final List<_ConfettiParticle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Confetti ticker
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _confettiController.addListener(() {
      setState(() {
        for (final p in _particles) {
          p.update();
        }
        _particles.removeWhere((p) => p.y > 800);
      });
    });
  }

  void _triggerConfetti(Size size) {
    // Spawn 60 particule
    for (int i = 0; i < 60; i++) {
      _particles.add(_ConfettiParticle(_rng, size.width, size.height));
    }
    _confettiController.repeat();
    // Opreste dupa 3 secunde
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _confettiController.stop();
    });
  }

  @override
  void didUpdateWidget(_RoleSection old) {
    super.didUpdateWidget(old);
    // Cand devine Ready, declanseaza confetti + vibratia
    if (!old.isReady && widget.isReady) {
      // Vibratie
      HapticFeedback.heavyImpact();
      // Confetti — nevoie de size, il luam in build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.size != null) {
          _triggerConfetti(context.size!);
        }
      });
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _floatController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String currentText = _showExplain
        ? widget.explainText
        : widget.initialText;

    // ── Buton START ──
    final Widget startButton = GestureDetector(
      onTap: widget.isReady ? null : widget.onReady,
      child: AnimatedScale(
        scale: widget.isReady ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Container(
          width: 58,
          padding: const EdgeInsets.symmetric(vertical: 24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isReady
                ? const Color(0xff2e5e38)
                : const Color(0xff3d7a4a),
            borderRadius: BorderRadius.circular(14),
          ),
          child: RotatedBox(
            quarterTurns: widget.isLeft ? 1 : 3,
            child: Text(
              widget.isReady ? 'Ready!' : 'Start',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );

    // ── Buton EXPLAIN MORE ──
    final Widget explainButton = GestureDetector(
      onTap: widget.isReady
          ? null
          : () => setState(() => _showExplain = !_showExplain),
      child: Container(
        width: 58,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _showExplain
              ? const Color(0xff4a7a54)
              : const Color(0xff5a8f64),
          borderRadius: BorderRadius.circular(14),
        ),
        child: RotatedBox(
          quarterTurns: widget.isLeft ? 1 : 3,
          child: Text(
            _showExplain ? '✕ Close' : '? Explain More',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );

    // ── Personaj cu float ──
    Widget character = RotatedBox(
      quarterTurns: widget.isLeft ? 1 : 3,
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        ),
        child: SizedBox(
          width: 480,
          child: Image.asset(widget.characterImage, fit: BoxFit.contain),
        ),
      ),
    );

    if (widget.isReady) {
      character = AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(120),
            boxShadow: [
              BoxShadow(
                color: Colors.yellowAccent.withOpacity(
                  0.7 * _glowAnimation.value,
                ),
                blurRadius: 60 * _glowAnimation.value,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        ),
        child: character,
      );
    }

    return Stack(
      children: [
        // 1. Personaj
        Positioned(
          left: widget.isLeft ? 0 : null,
          right: widget.isLeft ? null : 0,
          top: widget.isLeft ? 0 : null,
          bottom: widget.isLeft ? null : 0,
          child: character,
        ),

        // 2. Cloud cu typewriter
        Align(
          alignment: widget.isLeft
              ? const Alignment(0.3, 0.2)
              : const Alignment(-0.3, -0.2),
          child: RotatedBox(
            quarterTurns: widget.isLeft ? 1 : 3,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              // ← Typewriter în loc de Text simplu
              child: _CloudWithTypewriter(
                key: ValueKey(currentText),
                text: currentText,
              ),
            ),
          ),
        ),

        // 3. Confetti — deasupra tuturor
        if (_particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ConfettiPainter(_particles)),
            ),
          ),

        // 4. Butoane — ultimele = deasupra
        Positioned(
          left: widget.isLeft ? 8 : null,
          right: widget.isLeft ? null : 8,
          bottom: widget.isLeft ? 8 : null,
          top: widget.isLeft ? null : 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.isLeft
                ? [explainButton, const SizedBox(height: 10), startButton]
                : [startButton, const SizedBox(height: 10), explainButton],
          ),
        ),
      ],
    );
  }
}

// ── Cloud cu typewriter înăuntru ──────────────────────────────────────────────
class _CloudWithTypewriter extends StatelessWidget {
  final String text;
  const _CloudWithTypewriter({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 500,
          padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(60),
            border: Border.all(color: Colors.black87, width: 3),
          ),
          child: _TypewriterHighlight(text: text),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 24, top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _dot(10),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _dot(7),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 18),
                child: _dot(5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dot(double r) => Container(
    width: r * 2,
    height: r * 2,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.black87, width: 2),
    ),
  );
}

// ── Typewriter + Highlight combinat ──────────────────────────────────────────
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
      await Future.delayed(const Duration(milliseconds: 38));
      if (!mounted) return false;
      setState(() => _visibleChars++);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Textul vizibil pana la _visibleChars
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

      final kw = foundKeyword;
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
              kw,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),
        ),
      );

      remaining = remaining.substring(earliestIndex + kw.length);
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          height: 1.6,
        ),
        children: spans,
      ),
    );
  }
}

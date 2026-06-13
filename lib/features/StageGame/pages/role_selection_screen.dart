import 'package:flutter/material.dart';
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
          padding: const EdgeInsets.all(12),
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

// ── Cloud widget ──────────────────────────────────────────────────────────────
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
          width: 680, // mare
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 46),
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
        // Coada stil "thought bubble" — 3 cercuri descrescătoare
        Padding(
          padding: const EdgeInsets.only(left: 24, top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bubble(10),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: _bubble(7),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 18),
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
    with SingleTickerProviderStateMixin {
  bool _showExplain = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

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
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String currentText = _showExplain
        ? widget.explainText
        : widget.initialText;

    // ── Buton START — verde cu border radius si shadow ──
    final Widget startButton = GestureDetector(
      onTap: widget.isReady ? null : widget.onReady,
      child: Container(
        width: 58,
        padding: const EdgeInsets.symmetric(vertical: 24),
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
    );

    // ── Buton EXPLAIN MORE — verde deschis cu border radius ──
    final Widget explainButton = GestureDetector(
      onTap: () => setState(() => _showExplain = !_showExplain),
      child: Container(
        width: 58,
        padding: const EdgeInsets.symmetric(vertical: 16),
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );

    Widget character = RotatedBox(
      quarterTurns: widget.isLeft ? 1 : 3,
      child: SizedBox(
        width: 680,
        child: Image.asset(widget.characterImage, fit: BoxFit.contain),
      ),
    );

    if (widget.isReady) {
      character = AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.yellowAccent.withOpacity(
                  0.7 * _glowAnimation.value,
                ),
                blurRadius: 50 * _glowAnimation.value,
                spreadRadius: 20 * _glowAnimation.value,
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
        // ── Personaj — colț exterior, lipit sus/jos și stânga/dreapta ──
        Positioned(
          left: widget.isLeft ? 0 : null,
          right: widget.isLeft ? null : 0,
          top: widget.isLeft ? 0 : null,
          bottom: widget.isLeft ? null : 0,
          child: character,
        ),

        // ── Butoane — colț opus personajului, cu spațiu între ele ──
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

        // ── Cloud — aliniat spre CENTRUL panoului, departe de personaj ──
        // Mike (isLeft): personajul e sus-stânga → cloudul spre dreapta-jos = Alignment(0.4, 0.4)
        // Nick (isRight): personajul e jos-dreapta → cloudul spre stânga-sus = Alignment(-0.4, -0.4)
        Align(
          alignment: widget.isLeft
              ? const Alignment(0.4, 0.7)
              : const Alignment(-0.4, -0.7),
          child: RotatedBox(
            quarterTurns: widget.isLeft ? 1 : 3,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: SpeechCloud(key: ValueKey(currentText), text: currentText),
            ),
          ),
        ),
      ],
    );
  }
}

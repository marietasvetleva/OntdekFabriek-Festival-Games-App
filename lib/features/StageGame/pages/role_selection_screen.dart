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
                        'Hello! I am Mike, nice to meet you.'
                        'For this game, I am a Personal Assistant'
                        ' for festival stage. Do you what it means?',
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
                        'Hi, I am Nick, what’s up?'
                        'Also for this game I am Stage Builder for this'
                        'game stage.Do you know what it means?',
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
          width: 410,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(90),
            border: Border.all(color: Colors.black87, width: 2.5),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bubble(9),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _bubble(6),
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: _bubble(4),
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
    )..repeat(reverse: true); // pulsează continuu
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

    final Widget startButton = GestureDetector(
      onTap: widget.isReady ? null : widget.onReady,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: widget.isReady
            ? const Color(0xff6b0000) // mai închis când e apăsat
            : const Color(0xff9c0000),
        child: const Text(
          'Start',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    final Widget explainButton = GestureDetector(
      onTap: () => setState(() => _showExplain = !_showExplain),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        color: _showExplain ? const Color(0xff4a7a54) : const Color(0xff6d9f77),
        child: const Text(
          '? Explain More',
          style: TextStyle(color: Colors.black87, fontSize: 13),
        ),
      ),
    );

    // Personaj — pulsează dacă isReady, altfel normal
    Widget character = RotatedBox(
      quarterTurns: widget.isLeft ? 1 : 3,
      child: SizedBox(width: 300, child: Image.asset(widget.characterImage)),
    );

    if (widget.isReady) {
      character = AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.yellowAccent.withOpacity(
                    0.7 * _glowAnimation.value,
                  ),
                  blurRadius: 40 * _glowAnimation.value,
                  spreadRadius: 15 * _glowAnimation.value,
                ),
              ],
            ),
            child: child,
          );
        },
        child: character,
      );
    }

    return Stack(
      children: [
        /// Personaj
        Positioned(
          left: widget.isLeft ? 10 : null,
          right: widget.isLeft ? null : 10,
          top: widget.isLeft ? 10 : null,
          bottom: widget.isLeft ? null : 10,
          child: character,
        ),

        /// Butoane
        Positioned(
          left: widget.isLeft ? 15 : null,
          right: widget.isLeft ? null : 15,
          bottom: widget.isLeft ? 20 : null,
          top: widget.isLeft ? null : 20,
          child: RotatedBox(
            quarterTurns: widget.isLeft ? 1 : 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: widget.isLeft
                    ? [explainButton, startButton]
                    : [startButton, explainButton],
              ),
            ),
          ),
        ),

        /// Cloud
        Align(
          alignment: Alignment.center,
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

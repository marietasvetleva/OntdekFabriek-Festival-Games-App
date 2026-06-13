import 'package:flutter/material.dart';
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

  /*
    AANWIJZING:
    Beide spelers moeten eerst Ready drukken.
    Daarna gaat de game automatisch naar StageGamePage.
  */
  void _checkBothReady() {
    if (!_leftPlayerReady || !_rightPlayerReady) return;

    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const StageGamePage(),
        ),
      );
    });
  }

  void _setLeftReady() {
    if (_leftPlayerReady) return;

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
      backgroundColor: const Color(0xFFF5F0E8),
      body: Stack(
        children: [
          /*
            AANWIJZING:
            Achtergrond frame blijft hetzelfde als jullie design.
          */
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
              child: Column(
                children: [
                  /*
                    AANWIJZING:
                    Kleine header zoals de design style.
                  */
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'IMPACT MAKERS',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'Courier',
                          color: Color(0xFF8B9A85),
                          letterSpacing: 1.4,
                        ),
                      ),
                      Text(
                        'ANNUALLY ETC',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'Courier',
                          color: Color(0xFF8B9A85),
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCEFE4).withOpacity(0.92),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF8FB99A),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          /*
                            AANWIJZING:
                            Linker speler krijgt zijn eigen view.
                            De content is gedraaid zodat speler links het goed kan lezen.
                          */
                          Expanded(
                            child: _RotatedRoleSide(
                              quarterTurns: 1,
                              imagePath:
                                  'assets/StageGameV2-image/firstcharacter.png',
                              title: 'Personal Assistant',
                              description:
                                  'Don’t worry — I’ll guide your decisions.\n\nChoose the equipment. Control the power. Keep the show alive.\n\nAre you ready?',
                              buttonText:
                                  _leftPlayerReady ? '✓ Ready' : 'Ready',
                              isReady: _leftPlayerReady,
                              onReady: _setLeftReady,
                            ),
                          ),

                          Container(
                            width: 1.5,
                            color: const Color(0xFF7FA889),
                          ),

                          /*
                            AANWIJZING:
                            Rechter speler krijgt zijn eigen view.
                            Deze is de andere kant op gedraaid.
                          */
                          Expanded(
                            child: _RotatedRoleSide(
                              quarterTurns: 3,
                              imagePath:
                                  'assets/StageGameV2-image/secondcharacter.png',
                              title: 'Stage Builder',
                              description:
                                  'Now comes the hard part.\n\nControl the lights, sound and energy while the show is running.\n\nAre you ready?',
                              buttonText:
                                  _rightPlayerReady ? '✓ Ready' : 'Ready',
                              isReady: _rightPlayerReady,
                              onReady: _setRightReady,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /*
                    AANWIJZING:
                    Deze tekst blijft normaal onderaan het scherm.
                    Zo snappen spelers waarom de game nog niet start.
                  */
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _leftPlayerReady && _rightPlayerReady
                          ? 'Both players ready! Starting...'
                          : 'Both players must press Ready to start',
                      key: ValueKey(
                        '${_leftPlayerReady}_${_rightPlayerReady}',
                      ),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.caveat(
                        fontSize: 24,
                        height: 0.9,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2F2F35),
                      ),
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
  final String title;
  final String description;
  final String buttonText;
  final bool isReady;
  final VoidCallback onReady;

  const _RotatedRoleSide({
    required this.quarterTurns,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.isReady,
    required this.onReady,
  });

  @override
  Widget build(BuildContext context) {
    /*
      AANWIJZING:
      LayoutBuilder + RotatedBox zorgt dat elke speler zijn eigen kant heeft.
      De button zit onderaan binnen de gedraaide player view.
    */
    return LayoutBuilder(
      builder: (context, constraints) {
        return RotatedBox(
          quarterTurns: quarterTurns,
          child: SizedBox(
            width: constraints.maxHeight,
            height: constraints.maxWidth,
            child: _RoleSideContent(
              imagePath: imagePath,
              title: title,
              description: description,
              buttonText: buttonText,
              isReady: isReady,
              onReady: onReady,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleSideContent extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final String buttonText;
  final bool isReady;
  final VoidCallback onReady;

  const _RoleSideContent({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.isReady,
    required this.onReady,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
      child: Column(
        children: [
          /*
            AANWIJZING:
            Character staat bovenaan voor elke speler.
          */
          Expanded(
            flex: 5,
            child: Center(
              child: AnimatedScale(
                scale: isReady ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          /*
            AANWIJZING:
            Tekstbox onder de character.
            Wanneer speler ready is verandert de box naar ready feedback.
          */
          Expanded(
            flex: 4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: BoxDecoration(
                color: isReady
                    ? const Color(0xFFE8F5D0).withOpacity(0.95)
                    : const Color(0xFFDCEFE4).withOpacity(0.92),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isReady
                      ? const Color(0xFF5F985F)
                      : const Color(0xFF8FB99A),
                  width: isReady ? 2 : 1.2,
                ),
                boxShadow: [
                  if (isReady)
                    BoxShadow(
                      color: const Color(0xFF5F985F).withOpacity(0.16),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isReady ? '$title ✓' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.caveat(
                      fontSize: 31,
                      height: 0.9,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF111111),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Expanded(
                    child: Center(
                      child: Text(
                        isReady
                            ? 'Ready!\nWaiting for the other player...'
                            : description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.caveat(
                          fontSize: 25,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111111),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          /*
            AANWIJZING:
            Button staat onderaan per speler.
            Dus niet in het midden van het scherm, maar onder de eigen role card.
          */
          GestureDetector(
            onTap: isReady ? null : onReady,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 142,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isReady
                    ? const Color(0xFF3F6F4A)
                    : const Color(0xFF529E68),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isReady
                      ? const Color(0xFF2E5638)
                      : const Color(0xFF418455),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF529E68).withOpacity(
                      isReady ? 0.18 : 0.12,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                buttonText,
                style: GoogleFonts.caveat(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 25,
                  height: 0.9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

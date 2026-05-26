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
    Deze methode checkt of beide spelers ready zijn.

    Waarom?
    - De Personal Assistant moet eerst klaar zijn.
    - De Stage Builder moet ook klaar zijn.
    - Pas daarna start de echte build page.
  */
  void _checkBothReady() {
    if (!_leftPlayerReady || !_rightPlayerReady) return;

    Future.delayed(const Duration(milliseconds: 350), () {
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
      _leftPlayerReady = true;
    });

    _checkBothReady();
  }

  void _setRightReady() {
    if (_rightPlayerReady) return;

    setState(() {
      _rightPlayerReady = true;
    });

    _checkBothReady();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // FRAME
            Positioned(
              top: -60,
              left: -55,
              right: -84,
              bottom: -55,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/StageGameV2-image/frame.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),

            // CONTENT
            Positioned(
              top: size.height * 0.12,
              left: size.width * 0.05,
              right: size.width * 0.05,
              bottom: size.height * 0.08,
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'IMPACT MAKERS',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'Courier',
                          color: Colors.grey,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'ANNUALLY ETC',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'Courier',
                          color: Colors.grey,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // GREEN ROLE CONTAINER
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6EDE0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF9DC4A8),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // LEFT ROLE CARD
                          Expanded(
                            child: _RoleCard(
                              title: 'Personal Assistant',
                              description:
                                  'Choose the equipment and setup strategy for the stage.\nPick power sources, sound systems, lighting and effects while balancing performance and sustainability.',
                              imagePath:
                                  'assets/StageGameV2-image/firstcharacter.png',
                              isReady: _leftPlayerReady,
                              onStart: _setLeftReady,
                            ),
                          ),

                          // CENTER LINE
                          Container(
                            width: 1.5,
                            color: const Color(0xFF9DC4A8),
                          ),

                          // RIGHT ROLE CARD
                          Expanded(
                            child: _RoleCard(
                              title: 'Stage Builder',
                              description:
                                  'Control the technical performance of the stage. Adjust power load, sound levels, and lighting to keep everything running smoothly and avoid overload.',
                              imagePath:
                                  'assets/StageGameV2-image/secondcharacter.png',
                              isReady: _rightPlayerReady,
                              onStart: _setRightReady,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /*
              AANWIJZING:
              Kleine tekst onderin zodat spelers snappen waarom de game
              niet meteen start na één knop.
            */
            Positioned(
              bottom: 18,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _leftPlayerReady && _rightPlayerReady
                        ? 'Both players ready! Starting...'
                        : 'Both players must press Ready to start',
                    key: ValueKey(
                      '${_leftPlayerReady}_${_rightPlayerReady}',
                    ),
                    style: GoogleFonts.caveat(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2F2F35),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final bool isReady;
  final VoidCallback onStart;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.isReady,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CHARACTER
          Expanded(
            flex: 5,
            child: Center(
              child: AnimatedScale(
                scale: isReady ? 1.04 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // TEXT BOX
          Expanded(
            flex: 3,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isReady
                    ? const Color(0xFFE8F5D0)
                    : const Color(0xFFD6EDE0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isReady
                      ? const Color(0xFF6B9470)
                      : const Color(0xFF9DC4A8),
                  width: isReady ? 2 : 1,
                ),
                boxShadow: [
                  if (isReady)
                    BoxShadow(
                      color: const Color(0xFF6B9470).withOpacity(0.18),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  Center(
                    child: Text(
                      isReady ? '$title ✓' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.caveat(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // DESCRIPTION
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Text(
                        isReady
                            ? 'Ready!\nWaiting for the other player...'
                            : description,
                        textAlign: TextAlign.left,
                        style: GoogleFonts.caveat(
                          fontSize: 26,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // BUTTON
          Center(
            child: GestureDetector(
              onTap: isReady ? null : onStart,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 130,
                height: 44,
                decoration: BoxDecoration(
                  color: isReady
                      ? const Color(0xFF3F6F4A)
                      : const Color.fromARGB(255, 82, 158, 104),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isReady
                        ? const Color(0xFF2D5637)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    isReady ? '✓ Ready' : 'Ready',
                    style: GoogleFonts.caveat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
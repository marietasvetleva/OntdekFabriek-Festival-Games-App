import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../final_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

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
                  'assets/frame.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),

            // CONTINUT
            Positioned(
              top: size.height * 0.12,
              left: size.width * 0.05,
              right: size.width * 0.05,
              bottom: size.height * 0.08,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('IMPACT MAKERS',
                          style: TextStyle(
                              fontSize: 9,
                              fontFamily: 'Courier',
                              color: Colors.grey,
                              letterSpacing: 1.5)),
                      Text('ANNUALLY ETC',
                          style: TextStyle(
                              fontSize: 9,
                              fontFamily: 'Courier',
                              color: Colors.grey,
                              letterSpacing: 1.5)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // CONTAINER VERDE MARE
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6EDE0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF9DC4A8), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          // CARD STANGA
                          Expanded(
                            child: _RoleCard(
                              title: 'Personal Assistant',
                              description:
                                  'Choose the equipment and setup strategy for the stage.\nPick power sources, sound systems, lighting and effects while balancing performance and sustainability.',
                              imagePath: 'assets/firstcharacter.png',
                              onStart: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const FinalScreen()),
                                );
                              },
                            ),
                          ),

                          // LINIE VERTICALA
                          Container(
                            width: 1.5,
                            color: const Color(0xFF9DC4A8),
                          ),

                          // CARD DREAPTA
                          Expanded(
                            child: _RoleCard(
                              title: 'Stage Builder',
                              description:
                                  'Control the technical performance of the stage. Adjust power load, sound levels, and lighting to keep everything running smoothly and avoid overload.',
                              imagePath: 'assets/secondcharacter.png',
                              onStart: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
  final VoidCallback onStart;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PERSONAJ
          Expanded(
            flex: 5,
            child: Center(
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
          ),

          const SizedBox(height: 8),

          // UN SINGUR PATRAT cu titlu + descriere
          // UN SINGUR PATRAT
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD6EDE0), // verde
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF9DC4A8), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLU - centrat
                  Center(
                    child: Text(
                      title,
                      style: GoogleFonts.caveat(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // DESCRIERE - stanga, mare, groasa
                  Text(
                    description,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.caveat(
                      fontSize: 26,
                      height: 1.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // BUTON
          Center(
            child: GestureDetector(
              onTap: onStart,
              child: Container(
                width: 120,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 82, 158, 104),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    'Start',
                    style: GoogleFonts.caveat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
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

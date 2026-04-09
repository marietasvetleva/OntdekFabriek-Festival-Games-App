import 'package:flutter/material.dart';
import 'stage_page.dart';
import 'FoodGame.dart';
import 'FestivalCleanerApp.dart';
import 'features/hangout/presentation/pages/hangout_quiz_page.dart';
import 'features/toilet/toilet_page.dart';
import 'QR.dart';
import 'game_over_page.dart';

class MyHomePage extends StatefulWidget {
  final String festivalName;

  const MyHomePage({super.key, required this.festivalName});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _stageCompleted = false;
  bool _toiletCompleted = false;
  bool _hangoutCompleted = false;
  bool _foodCompleted = false;
  bool _wasteCompleted = false;

  Future<void> _navigateToStage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StagePage(
          festivalName: widget.festivalName,
          onMinigameCompleted: () {
            setState(() {
              _stageCompleted = true;
            });
            _checkAllGamesCompleted();
          },
        ),
      ),
    );

    if (!_stageCompleted) {
      setState(() => _stageCompleted = true);
      _checkAllGamesCompleted();
    }
  }

  Future<void> _navigateToFoodTruck() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FoodTruckPage()),
    );

    if (!_foodCompleted) {
      setState(() => _foodCompleted = true);
      _checkAllGamesCompleted();
    }
  }

  Future<void> _navigateToHangout() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HangoutQuizPage(
          festivalName: widget.festivalName,
        ),
      ),
    );

    if (!_hangoutCompleted) {
      setState(() => _hangoutCompleted = true);
      _checkAllGamesCompleted();
    }
  }

  Future<void> _navigateToCleaner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FestivalCleanerApp()),
    );

    if (!_wasteCompleted) {
      setState(() => _wasteCompleted = true);
      _checkAllGamesCompleted();
    }
  }

  Future<void> _navigateToToiletGame() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ToiletGamePage()),
    );

    if (!_toiletCompleted) {
      setState(() => _toiletCompleted = true);
      _checkAllGamesCompleted();
    }
  }

  Future<void> _navigateToQR() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QRScannerPage(
          festivalName: widget.festivalName,
        ),
      ),
    );
  }

  void _checkAllGamesCompleted() {
    if (_stageCompleted &&
        _toiletCompleted &&
        _hangoutCompleted &&
        _foodCompleted &&
        _wasteCompleted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => GameOverPage(
                ecoScore: 8,
                bandName: 'Your Band',
                festivalName: widget.festivalName,
                onMinigameCompleted: () {},
                isGoodEnding: true,
              ),
            ),
          );
        }
      });
    }
  }

  ColorFilter _gray(bool completed) {
    return completed
        ? const ColorFilter.mode(Colors.transparent, BlendMode.color)
        : const ColorFilter.matrix([
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]);
  }

  @override
  Widget build(BuildContext context) {
    final squareSize = MediaQuery.of(context).size.width * 0.25;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 139, 210, 142),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: ColorFiltered(
                colorFilter: _gray(_stageCompleted),
                child: GestureDetector(
                  onTap: _navigateToStage,
                  child: _buildSquare(
                    squareSize,
                    label: "stage",
                    image: "assets/Images/Festival_Colour.png",
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: ColorFiltered(
                colorFilter: _gray(_toiletCompleted),
                child: GestureDetector(
                  onTap: _navigateToToiletGame,
                  child: _buildSquare(
                    squareSize,
                    label: "toilet",
                    image: "assets/Images/toilet.jpeg",
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: ColorFiltered(
                  colorFilter: _gray(_wasteCompleted),
                  child: GestureDetector(
                    onTap: _navigateToCleaner,
                    child: _buildSquare(
                      squareSize,
                      label: "waste",
                      image: "assets/Images/waste.jpeg",
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: ColorFiltered(
                  colorFilter: _gray(_hangoutCompleted),
                  child: GestureDetector(
                    onTap: _navigateToHangout,
                    child: _buildSquare(
                      squareSize,
                      label: "hang out",
                      image: "assets/garden/Hangout_minigame.jpg",
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: ColorFiltered(
                colorFilter: _gray(_foodCompleted),
                child: GestureDetector(
                  onTap: _navigateToFoodTruck,
                  child: _buildSquare(
                    squareSize,
                    label: "food truck",
                    image: "assets/Images/food.jpeg",
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: GestureDetector(
                onTap: _navigateToQR,
                child: _buildSquare(
                  squareSize,
                  label: "QR",
                  image: "assets/Images/qr_placeholder.png",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquare(
    double size, {
    required String label,
    required String image,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: AssetImage(image),
          fit: BoxFit.cover,
        ),
      ),
      child: _labelOverlay(label, size),
    );
  }

  Widget _labelOverlay(String text, double size) {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.08,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
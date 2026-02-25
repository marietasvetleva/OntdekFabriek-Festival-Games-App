import 'package:flutter/material.dart';
import 'services/led_service.dart';
import 'result_page.dart';
import 'result_page_bad.dart';

class ScoresPage extends StatelessWidget {
  const ScoresPage({Key? key}) : super(key: key);

  static const Map<String, String> _minigameNames = {
    'toilet': 'Toilet Minigame',
    'hangout': 'Hangout Game',
    'food': 'Food Game',
    'stage': 'Stage Page',
    'festivalcleaner': 'Festival Cleaner',
  };

  @override
  Widget build(BuildContext context) {
    final scores = LedService.getAllScores();
    final completed = LedService.getCompletedStatus();
    final totalPoints = LedService.getTotalPoints();

    // Eco meter calculation (max 25 points for full meter)
    const maxPoints = 25;
    final ecoProgress = (totalPoints / maxPoints).clamp(0.0, 1.0);
    final ecoPercentage = (ecoProgress * 100).toInt();

    // Check if all minigames are completed
    final allCompleted = completed.values.every((v) => v);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eco Score Overzicht'),
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade300, Colors.teal.shade300],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Totaal Score Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade600,
                          Colors.lightGreen.shade500,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.eco, color: Colors.white, size: 28),
                            SizedBox(width: 10),
                            Text(
                              'TOTAAL ECO SCORE',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$totalPoints',
                          style: const TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'PUNTEN',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Eco Meter Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.energy_savings_leaf,
                              color: Colors.green.shade700,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'ECO METER',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Progress bar
                        Stack(
                          children: [
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 800),
                              height: 40,
                              width:
                                  MediaQuery.of(context).size.width *
                                  0.8 *
                                  ecoProgress,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.lightGreen.shade400,
                                    Colors.green.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '$ecoPercentage%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$totalPoints / $maxPoints punten',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _getEcoMessage(ecoPercentage),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Minigame Scores
                Expanded(
                  child: ListView.builder(
                    itemCount: scores.length,
                    itemBuilder: (context, index) {
                      final key = scores.keys.elementAt(index);
                      final score = scores[key] ?? 0;
                      final isCompleted = completed[key] ?? false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: isCompleted
                                ? Colors.green.shade600
                                : Colors.grey.shade300,
                            child: Icon(
                              isCompleted ? Icons.check_circle : Icons.lock,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          title: Text(
                            _minigameNames[key] ?? key,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? Colors.black : Colors.grey,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCompleted)
                                  Icon(
                                    Icons.eco,
                                    color: Colors.green.shade700,
                                    size: 16,
                                  ),
                                if (isCompleted) const SizedBox(width: 5),
                                Text(
                                  '$score punten',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted
                                        ? Colors.green.shade700
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                if (allCompleted)
                  ElevatedButton.icon(
                    onPressed: () {
                      _navigateToEnding(context, totalPoints);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                    icon: const Icon(Icons.movie),
                    label: const Text('Naar Ending'),
                  )
                else
                  Text(
                    'Voltooi alle minigames om de ending te zien',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToEnding(BuildContext context, int totalPoints) {
    late Widget endingPage;

    if (totalPoints <= 13) {
      // Bad ending
      endingPage = ResultPageBad(
        score: totalPoints,
        bandName: 'Festival',
        festivalName: 'Eco Festival',
        onMinigameCompleted: () {},
      );
    } else {
      // Good ending (14-25 points)
      endingPage = ResultPage(
        score: totalPoints,
        bandName: 'Festival',
        festivalName: 'Eco Festival',
        onMinigameCompleted: () {},
      );
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => endingPage));
  }

  String _getEcoMessage(int percentage) {
    if (percentage >= 100) return '🌟 Perfect! Maximum eco score bereikt!';
    if (percentage >= 80) return '🌱 Geweldig! Bijna op het maximum!';
    if (percentage >= 60) return '♻️ Goed bezig! Blijf zo doorgaan!';
    if (percentage >= 40) return '🌿 Prima! Je bent op de goede weg!';
    if (percentage >= 20) return '🌍 Begin gemaakt! Speel meer games!';
    return '';
  }
}

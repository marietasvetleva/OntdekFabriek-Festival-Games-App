class HangoutAnswer {
  final String label;
  final String feedback;

  const HangoutAnswer({
    required this.label,
    required this.feedback,
  });
}

class HangoutQuestion {
  final String prompt;
  final List<HangoutAnswer> answers;
  final int correctIndex;
  final int seconds;
  final int points;

  const HangoutQuestion({
    required this.prompt,
    required this.answers,
    required this.correctIndex,
    this.seconds = 8,
    this.points = 10,
  });
}
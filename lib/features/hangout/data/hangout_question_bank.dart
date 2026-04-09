import '../models/hangout_question.dart';

const List<HangoutQuestion> hangoutQuestions = [
  HangoutQuestion(
    prompt: 'How are you getting\nto the festival?',
    correctIndex: 2,
    answers: [
      HangoutAnswer(
        label: 'By car\nwith friends',
        feedback:
            'Cars still create CO₂ and pollution, even when multiple people share the ride.',
      ),
      HangoutAnswer(
        label: 'By public\ntransport',
        feedback:
            'Public transport is better than cars because many people share one vehicle.',
      ),
      HangoutAnswer(
        label: 'By bike\nor walking',
        feedback:
            'No pollution, healthier for you, and the most sustainable way to travel.',
      ),
    ],
  ),
  HangoutQuestion(
    prompt: 'What should you do\nwith a cigarette butt?',
    correctIndex: 0,
    answers: [
      HangoutAnswer(
        label: 'Put it in a pocket\nashtray or cigarette bin',
        feedback:
            'This keeps toxic waste out of the ground and helps keep the festival clean.',
      ),
      HangoutAnswer(
        label: 'Ignore it,\nit is just one',
        feedback:
            'Even one cigarette butt pollutes the area and can harm nature and animals.',
      ),
      HangoutAnswer(
        label: 'Push it into the\nsoil with your shoe',
        feedback:
            'That still leaves pollution behind and is harmful for the environment.',
      ),
    ],
  ),
  HangoutQuestion(
    prompt: 'Your water bottle is empty.\nWhat is the best choice?',
    correctIndex: 1,
    answers: [
      HangoutAnswer(
        label: 'Buy a new\nplastic bottle',
        feedback:
            'Single-use plastic creates extra waste and is not the best eco option.',
      ),
      HangoutAnswer(
        label: 'Refill your reusable\nbottle',
        feedback:
            'Refilling reduces plastic waste and is the smartest sustainable choice.',
      ),
      HangoutAnswer(
        label: 'Throw the bottle away\nand wait',
        feedback:
            'Throwing it away creates waste and does not help reduce festival litter.',
      ),
    ],
  ),
  HangoutQuestion(
    prompt: 'You finished your snack.\nWhat now?',
    correctIndex: 2,
    answers: [
      HangoutAnswer(
        label: 'Drop the wrapper\nnext to a bench',
        feedback:
            'Litter stays in the environment and makes the festival dirty.',
      ),
      HangoutAnswer(
        label: 'Leave it on the table\nfor someone else',
        feedback:
            'Someone else should not have to clean up your waste.',
      ),
      HangoutAnswer(
        label: 'Sort it in the\ncorrect bin',
        feedback:
            'Sorting waste correctly helps recycling and keeps the grounds clean.',
      ),
    ],
  ),
  HangoutQuestion(
    prompt: 'You are leaving the hangout area.\nWhat is the best final action?',
    correctIndex: 1,
    answers: [
      HangoutAnswer(
        label: 'Leave fast and let the\nstaff handle it',
        feedback:
            'Leaving your mess for others is not a sustainable festival habit.',
      ),
      HangoutAnswer(
        label: 'Take your waste and\ncheck the area',
        feedback:
            'A quick final check keeps the space clean and helps everyone after you.',
      ),
      HangoutAnswer(
        label: 'Hide your trash\nunder the table',
        feedback:
            'Hidden trash still pollutes and creates extra cleaning work.',
      ),
    ],
  ),
];
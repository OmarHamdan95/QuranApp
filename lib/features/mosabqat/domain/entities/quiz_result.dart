import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// Domain entity representing the result of a completed quiz session.
class QuizResult extends Equatable {
  final String id;
  final int score;
  final int totalQuestions;
  final QuizCategory category;
  final QuizDifficulty difficulty;
  final Duration timeTaken;
  final List<QuestionResult> questionResults;
  final int xpEarned;
  final DateTime completedAt;
  final bool isDailyChallenge;

  const QuizResult({
    required this.id,
    required this.score,
    required this.totalQuestions,
    required this.category,
    required this.difficulty,
    required this.timeTaken,
    required this.questionResults,
    required this.xpEarned,
    required this.completedAt,
    this.isDailyChallenge = false,
  });

  int get percentage =>
      totalQuestions > 0 ? (score / totalQuestions * 100).round() : 0;

  int get wrongAnswers => totalQuestions - score;

  bool get isPassing => percentage >= 50;

  bool get isExcellent => percentage >= 90;

  @override
  List<Object?> get props => [id, completedAt];
}

/// Result for a single answered question.
class QuestionResult extends Equatable {
  final String questionId;
  final int selectedIndex;
  final bool isCorrect;
  final int timeTakenSeconds;

  const QuestionResult({
    required this.questionId,
    required this.selectedIndex,
    required this.isCorrect,
    required this.timeTakenSeconds,
  });

  @override
  List<Object?> get props => [questionId, selectedIndex];
}

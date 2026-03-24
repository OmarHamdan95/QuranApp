import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// Domain entity for a single quiz question.
class QuizQuestion extends Equatable {
  final String id;
  final String questionText;
  final List<String> options;       // length 2 for true/false, 4 for MCQ
  final int correctIndex;
  final QuizCategory category;
  final QuizDifficulty difficulty;
  final String reference;           // e.g. "البقرة : ٢٥٥"
  final String? explanation;
  final bool isTrueFalse;

  const QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctIndex,
    required this.category,
    required this.difficulty,
    required this.reference,
    this.explanation,
    this.isTrueFalse = false,
  });

  String get correctAnswer => options[correctIndex];

  @override
  List<Object?> get props => [id];
}

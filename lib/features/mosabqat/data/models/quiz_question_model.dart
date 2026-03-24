import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/quiz_question.dart';

/// Data model for [QuizQuestion] with serialization.
class QuizQuestionModel extends QuizQuestion {
  const QuizQuestionModel({
    required super.id,
    required super.questionText,
    required super.options,
    required super.correctIndex,
    required super.category,
    required super.difficulty,
    required super.reference,
    super.explanation,
    super.isTrueFalse,
  });

  factory QuizQuestionModel.fromMap(Map<String, dynamic> map) {
    return QuizQuestionModel(
      id: map['id'] as String,
      questionText: map['question_text'] as String,
      options: List<String>.from(map['options'] as List),
      correctIndex: map['correct_index'] as int,
      category: QuizCategory.values[map['category'] as int],
      difficulty: QuizDifficulty.values[map['difficulty'] as int],
      reference: map['reference'] as String,
      explanation: map['explanation'] as String?,
      isTrueFalse: (map['is_true_false'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_text': questionText,
      'options': options,
      'correct_index': correctIndex,
      'category': category.index,
      'difficulty': difficulty.index,
      'reference': reference,
      'explanation': explanation,
      'is_true_false': isTrueFalse ? 1 : 0,
    };
  }
}

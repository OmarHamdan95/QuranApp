import '../../../../core/constants/app_constants.dart';
import '../entities/quiz_question.dart';
import '../entities/quiz_result.dart';

/// Abstract repository for mosabqat (quiz) data operations.
abstract class MosabqatRepository {
  /// Get questions filtered by category, difficulty, and count.
  Future<List<QuizQuestion>> getQuestions({
    required QuizCategory category,
    required QuizDifficulty difficulty,
    required int count,
  });

  /// Get mixed daily challenge questions.
  Future<List<QuizQuestion>> getDailyChallengeQuestions();

  /// Save a completed quiz result.
  Future<void> saveResult(QuizResult result);

  /// Get all saved results.
  Future<List<QuizResult>> getResults();

  /// Get results for a specific category.
  Future<List<QuizResult>> getResultsByCategory(QuizCategory category);

  /// Get accuracy percentage for a category.
  Future<double> getCategoryAccuracy(QuizCategory category);

  /// Get overall stats.
  Future<Map<String, dynamic>> getStats();

  /// Get current daily challenge streak.
  Future<int> getDailyChallengeStreak();

  /// Check if today's daily challenge is completed.
  Future<bool> isDailyChallengeCompleted();
}

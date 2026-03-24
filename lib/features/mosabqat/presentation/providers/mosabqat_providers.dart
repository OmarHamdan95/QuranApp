import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/models/quiz_seed_data.dart';
import '../../domain/entities/quiz_category_info.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/entities/quiz_result.dart';

// ─────────────────────────────────────────────
// Quiz Session State
// ─────────────────────────────────────────────

class QuizSessionState {
  final List<QuizQuestion> questions;
  final int currentIndex;
  final int score;
  final List<QuestionResult> results;
  final bool isFinished;
  final QuizCategory category;
  final QuizDifficulty difficulty;
  final DateTime startTime;

  const QuizSessionState({
    required this.questions,
    required this.currentIndex,
    required this.score,
    required this.results,
    required this.isFinished,
    required this.category,
    required this.difficulty,
    required this.startTime,
  });

  QuizQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  bool get isLast => currentIndex >= questions.length - 1;

  double get progressFraction =>
      questions.isEmpty ? 0 : currentIndex / questions.length;

  QuizSessionState copyWith({
    int? currentIndex,
    int? score,
    List<QuestionResult>? results,
    bool? isFinished,
  }) {
    return QuizSessionState(
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      results: results ?? this.results,
      isFinished: isFinished ?? this.isFinished,
      category: category,
      difficulty: difficulty,
      startTime: startTime,
    );
  }
}

class QuizSessionNotifier extends StateNotifier<QuizSessionState?> {
  QuizSessionNotifier() : super(null);

  void startQuiz({
    required QuizCategory category,
    required QuizDifficulty difficulty,
    required int questionCount,
  }) {
    final questions = getQuestionsByCategory(category, difficulty, questionCount);
    state = QuizSessionState(
      questions: questions,
      currentIndex: 0,
      score: 0,
      results: [],
      isFinished: false,
      category: category,
      difficulty: difficulty,
      startTime: DateTime.now(),
    );
  }

  void startDailyChallenge() {
    final questions = getDailyChallengeQuestions(
      AppConstants.dailyChallengeQuestionCount,
    );
    state = QuizSessionState(
      questions: questions,
      currentIndex: 0,
      score: 0,
      results: [],
      isFinished: false,
      category: QuizCategory.generalKnowledge,
      difficulty: QuizDifficulty.medium,
      startTime: DateTime.now(),
    );
  }

  /// Answer a question and advance. Returns true if answer was correct.
  bool answerQuestion(int selectedIndex, int timeTakenSeconds) {
    final current = state;
    if (current == null || current.currentQuestion == null) return false;

    final isCorrect =
        selectedIndex == current.currentQuestion!.correctIndex;
    final result = QuestionResult(
      questionId: current.currentQuestion!.id,
      selectedIndex: selectedIndex,
      isCorrect: isCorrect,
      timeTakenSeconds: timeTakenSeconds,
    );

    final newResults = [...current.results, result];
    final newScore = isCorrect ? current.score + 1 : current.score;
    final newIndex = current.currentIndex + 1;
    final isFinished = newIndex >= current.questions.length;

    state = current.copyWith(
      currentIndex: newIndex,
      score: newScore,
      results: newResults,
      isFinished: isFinished,
    );

    return isCorrect;
  }

  QuizResult? buildResult() {
    final current = state;
    if (current == null) return null;

    final duration = DateTime.now().difference(current.startTime);
    final xp = _calculateXP(current.score, current.questions.length,
        current.difficulty, duration);

    return QuizResult(
      id: 'result_${DateTime.now().millisecondsSinceEpoch}',
      score: current.score,
      totalQuestions: current.questions.length,
      category: current.category,
      difficulty: current.difficulty,
      timeTaken: duration,
      questionResults: current.results,
      xpEarned: xp,
      completedAt: DateTime.now(),
    );
  }

  int _calculateXP(int score, int total, QuizDifficulty diff, Duration time) {
    final baseXP = score * 10;
    final diffBonus = switch (diff) {
      QuizDifficulty.easy => 1.0,
      QuizDifficulty.medium => 1.5,
      QuizDifficulty.hard => 2.0,
      QuizDifficulty.expert => 3.0,
    };
    final speedBonus = time.inSeconds < total * 10 ? 1.2 : 1.0;
    return (baseXP * diffBonus * speedBonus).round();
  }

  void reset() => state = null;
}

// ─────────────────────────────────────────────
// Stats State
// ─────────────────────────────────────────────

class MosabqatStats {
  final int totalQuizzes;
  final int totalCorrect;
  final int totalAnswered;
  final int currentStreak;
  final int bestStreak;
  final double averageScore;
  final int dailyChallengesCompleted;
  final int totalXP;
  final Map<QuizCategory, double> categoryAccuracy;
  final List<QuizResult> recentResults;

  const MosabqatStats({
    required this.totalQuizzes,
    required this.totalCorrect,
    required this.totalAnswered,
    required this.currentStreak,
    required this.bestStreak,
    required this.averageScore,
    required this.dailyChallengesCompleted,
    required this.totalXP,
    required this.categoryAccuracy,
    required this.recentResults,
  });

  int get accuracy =>
      totalAnswered > 0 ? (totalCorrect / totalAnswered * 100).round() : 0;

  String get levelTitle {
    if (totalXP < 500) return 'مبتدئ';
    if (totalXP < 1500) return 'متعلم';
    if (totalXP < 3000) return 'متقدم';
    if (totalXP < 6000) return 'خبير';
    return 'عالم';
  }

  MosabqatStats copyWith({
    int? totalQuizzes,
    int? totalCorrect,
    int? totalAnswered,
    int? currentStreak,
    int? bestStreak,
    double? averageScore,
    int? dailyChallengesCompleted,
    int? totalXP,
    Map<QuizCategory, double>? categoryAccuracy,
    List<QuizResult>? recentResults,
  }) {
    return MosabqatStats(
      totalQuizzes: totalQuizzes ?? this.totalQuizzes,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalAnswered: totalAnswered ?? this.totalAnswered,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      averageScore: averageScore ?? this.averageScore,
      dailyChallengesCompleted:
          dailyChallengesCompleted ?? this.dailyChallengesCompleted,
      totalXP: totalXP ?? this.totalXP,
      categoryAccuracy: categoryAccuracy ?? this.categoryAccuracy,
      recentResults: recentResults ?? this.recentResults,
    );
  }
}

class MosabqatStatsNotifier extends StateNotifier<MosabqatStats> {
  MosabqatStatsNotifier()
      : super(
          MosabqatStats(
            totalQuizzes: 42,
            totalCorrect: 312,
            totalAnswered: 420,
            currentStreak: 5,
            bestStreak: 15,
            averageScore: 74.3,
            dailyChallengesCompleted: 12,
            totalXP: 1850,
            categoryAccuracy: {
              QuizCategory.ayahCompletion: 85.0,
              QuizCategory.surahIdentification: 72.0,
              QuizCategory.ayahOrder: 65.0,
              QuizCategory.wordMeaning: 58.0,
              QuizCategory.generalKnowledge: 80.0,
            },
            recentResults: [],
          ),
        );

  void recordResult(QuizResult result) {
    final newTotal = state.totalQuizzes + 1;
    final newCorrect = state.totalCorrect + result.score;
    final newAnswered = state.totalAnswered + result.totalQuestions;
    final newXP = state.totalXP + result.xpEarned;
    final newAvg = (state.averageScore * state.totalQuizzes + result.percentage) /
        newTotal;

    final updatedAccuracy =
        Map<QuizCategory, double>.from(state.categoryAccuracy);
    final prevAccuracy =
        updatedAccuracy[result.category] ?? 0.0;
    updatedAccuracy[result.category] =
        (prevAccuracy + result.percentage) / 2;

    final newDailyCount = result.isDailyChallenge
        ? state.dailyChallengesCompleted + 1
        : state.dailyChallengesCompleted;

    final newStreak = state.currentStreak + 1;
    final newBest =
        newStreak > state.bestStreak ? newStreak : state.bestStreak;

    state = state.copyWith(
      totalQuizzes: newTotal,
      totalCorrect: newCorrect,
      totalAnswered: newAnswered,
      totalXP: newXP,
      averageScore: newAvg,
      categoryAccuracy: updatedAccuracy,
      dailyChallengesCompleted: newDailyCount,
      currentStreak: newStreak,
      bestStreak: newBest,
      recentResults: [...state.recentResults.take(9), result],
    );
  }
}

// ─────────────────────────────────────────────
// Category Info Provider
// ─────────────────────────────────────────────

final quizCategoryInfoProvider = Provider<List<QuizCategoryInfo>>((ref) {
  final stats = ref.watch(mosabqatStatsProvider);
  return [
    QuizCategoryInfo(
      category: QuizCategory.ayahCompletion,
      titleAr: 'أكمل الآية',
      descriptionAr: 'اختبر حفظك بإكمال الآيات القرآنية',
      icon: Icons.format_quote_rounded,
      color: const Color(0xFF1B5E20),
      totalQuestions: kSeedQuestions
          .where((q) => q.category == QuizCategory.ayahCompletion)
          .length,
      accuracyPercent:
          stats.categoryAccuracy[QuizCategory.ayahCompletion] ?? 0.0,
    ),
    QuizCategoryInfo(
      category: QuizCategory.surahIdentification,
      titleAr: 'تعرف على السورة',
      descriptionAr: 'حدد السورة من الآية المعروضة',
      icon: Icons.menu_book_rounded,
      color: const Color(0xFF0277BD),
      totalQuestions: kSeedQuestions
          .where((q) => q.category == QuizCategory.surahIdentification)
          .length,
      accuracyPercent:
          stats.categoryAccuracy[QuizCategory.surahIdentification] ?? 0.0,
    ),
    QuizCategoryInfo(
      category: QuizCategory.ayahOrder,
      titleAr: 'ترتيب الآيات',
      descriptionAr: 'رتب الآيات وحدد أيها يأتي أولاً',
      icon: Icons.sort_rounded,
      color: const Color(0xFF00695C),
      totalQuestions: kSeedQuestions
          .where((q) => q.category == QuizCategory.ayahOrder)
          .length,
      accuracyPercent:
          stats.categoryAccuracy[QuizCategory.ayahOrder] ?? 0.0,
    ),
    QuizCategoryInfo(
      category: QuizCategory.wordMeaning,
      titleAr: 'معاني الكلمات',
      descriptionAr: 'تعلم معاني كلمات القرآن الكريم',
      icon: Icons.translate_rounded,
      color: const Color(0xFFBF8C30),
      totalQuestions: kSeedQuestions
          .where((q) => q.category == QuizCategory.wordMeaning)
          .length,
      accuracyPercent:
          stats.categoryAccuracy[QuizCategory.wordMeaning] ?? 0.0,
    ),
    QuizCategoryInfo(
      category: QuizCategory.generalKnowledge,
      titleAr: 'معلومات عامة',
      descriptionAr: 'أسئلة متنوعة عن القرآن وعلومه',
      icon: Icons.lightbulb_rounded,
      color: const Color(0xFFD84315),
      totalQuestions: kSeedQuestions
          .where((q) => q.category == QuizCategory.generalKnowledge)
          .length,
      accuracyPercent:
          stats.categoryAccuracy[QuizCategory.generalKnowledge] ?? 0.0,
    ),
  ];
});

// ─────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────

final quizSessionProvider =
    StateNotifierProvider<QuizSessionNotifier, QuizSessionState?>((ref) {
  return QuizSessionNotifier();
});

final mosabqatStatsProvider =
    StateNotifierProvider<MosabqatStatsNotifier, MosabqatStats>((ref) {
  return MosabqatStatsNotifier();
});

/// Selected quiz setup parameters.
final selectedCategoryProvider =
    StateProvider<QuizCategory>((ref) => QuizCategory.generalKnowledge);

final selectedDifficultyProvider =
    StateProvider<QuizDifficulty>((ref) => QuizDifficulty.medium);

final selectedQuestionCountProvider = StateProvider<int>((ref) => 10);

/// Last completed quiz result.
final lastQuizResultProvider = StateProvider<QuizResult?>((ref) => null);

/// Daily challenge completion flag for today.
final dailyChallengeCompletedProvider = StateProvider<bool>((ref) => false);

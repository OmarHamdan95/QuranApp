import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// Domain entity representing a quiz category with UI metadata.
class QuizCategoryInfo extends Equatable {
  final QuizCategory category;
  final String titleAr;
  final String descriptionAr;
  final IconData icon;
  final Color color;
  final int totalQuestions;
  final int attemptedQuestions;
  final double accuracyPercent;

  const QuizCategoryInfo({
    required this.category,
    required this.titleAr,
    required this.descriptionAr,
    required this.icon,
    required this.color,
    this.totalQuestions = 0,
    this.attemptedQuestions = 0,
    this.accuracyPercent = 0.0,
  });

  @override
  List<Object?> get props => [category];
}

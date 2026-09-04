import 'package:flutter/material.dart';

class LearningLesson {
  final String id;
  final String title;
  final String category;
  final String readTime;
  final String difficulty;
  final String content;
  final String? imageUrl;
  final List<String> redFlags;
  final String whatToDo;
  final double? latitude;
  final double? longitude;
  final bool isLocationBased;
  final bool isCompleted;

  LearningLesson({
    required this.id,
    required this.title,
    required this.category,
    required this.readTime,
    required this.difficulty,
    required this.content,
    this.imageUrl,
    required this.redFlags,
    required this.whatToDo,
    this.latitude,
    this.longitude,
    this.isLocationBased = false,
    this.isCompleted = false,
  });
}

class Scenario {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final String status; // 'Not Started', 'In Progress', 'Completed'
  final int xpReward;
  final List<ScenarioStep> steps;

  Scenario({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.status,
    required this.xpReward,
    required this.steps,
  });
}

class ScenarioStep {
  final String situation;
  final List<ScenarioOption> options;

  ScenarioStep({required this.situation, required this.options});
}

class ScenarioOption {
  final String text;
  final bool isCorrect;
  final String feedback;

  ScenarioOption({
    required this.text,
    required this.isCorrect,
    required this.feedback,
  });
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });
}

class RewardVoucher {
  final String id;
  final String partnerName;
  final String title;
  final String discountAmount;
  final DateTime expiryDate;
  final String? qrCodeUrl;
  final String? promoCode;
  final int requiredXp;
  final bool isUnlocked;
  final bool isClaimed;

  RewardVoucher({
    required this.id,
    required this.partnerName,
    required this.title,
    required this.discountAmount,
    required this.expiryDate,
    this.qrCodeUrl,
    this.promoCode,
    required this.requiredXp,
    this.isUnlocked = false,
    this.isClaimed = false,
  });
}

class UserLearningProfile {
  final String userId;
  final int totalXp;
  final int currentLevel;
  final int vouchersCount;
  final String rankTitle;

  UserLearningProfile({
    required this.userId,
    required this.totalXp,
    required this.currentLevel,
    required this.vouchersCount,
    required this.rankTitle,
  });

  int get xpForNextLevel => currentLevel * 200;
  double get progressToNextLevel => totalXp / xpForNextLevel;
}

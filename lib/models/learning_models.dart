class LearningLesson {
  final String id;
  final String referenceCode;
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
  final int hotspotRadiusMeters;
  final bool isCompleted;
  final int xpReward;
  final String? hotspotLabel;

  LearningLesson({
    required this.id,
    this.referenceCode = '',
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
    this.hotspotRadiusMeters = 250,
    this.isCompleted = false,
    this.xpReward = 20,
    this.hotspotLabel,
  });
}

class Scenario {
  final String id;
  final String referenceCode;
  final String title;
  final String description;
  final String difficulty;
  final String status; // 'Not Started', 'In Progress', 'Completed'
  final int xpReward;
  final List<ScenarioStep> steps;
  final String category;
  final String mediaType;
  final String? mediaUrl;
  final String? mediaCaption;

  Scenario({
    required this.id,
    this.referenceCode = '',
    required this.title,
    required this.description,
    required this.difficulty,
    required this.status,
    required this.xpReward,
    required this.steps,
    this.category = 'General',
    this.mediaType = 'none',
    this.mediaUrl,
    this.mediaCaption,
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
  final String referenceCode;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final String category;
  final String? imageUrl;
  final int timeLimitSeconds;

  QuizQuestion({
    required this.id,
    this.referenceCode = '',
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    this.category = 'General',
    this.imageUrl,
    this.timeLimitSeconds = 15,
  });
}

class LearningQuiz {
  const LearningQuiz({
    required this.id,
    required this.referenceCode,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.xpReward,
    required this.questions,
    this.isCompleted = false,
    this.completedToday = false,
  });

  final String id;
  final String referenceCode;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int xpReward;
  final List<QuizQuestion> questions;
  final bool isCompleted;
  final bool completedToday;
}

class RewardVoucher {
  final String id;
  final String referenceCode;
  final String partnerName;
  final String title;
  final String discountAmount;
  final DateTime expiryDate;
  final String? qrCodeUrl;
  final String? promoCode;
  final int requiredXp;
  final bool isUnlocked;
  final bool isClaimed;
  final int availableCodes;

  RewardVoucher({
    required this.id,
    this.referenceCode = '',
    required this.partnerName,
    required this.title,
    required this.discountAmount,
    required this.expiryDate,
    this.qrCodeUrl,
    this.promoCode,
    required this.requiredXp,
    this.isUnlocked = false,
    this.isClaimed = false,
    this.availableCodes = 0,
  });

  bool get isAvailable => isClaimed || availableCodes > 0;
}

class UserLearningProfile {
  final String userId;
  final int totalXp;
  final int currentLevel;
  final int vouchersCount;
  final String rankTitle;
  final int? availableXp;

  UserLearningProfile({
    required this.userId,
    required this.totalXp,
    required this.currentLevel,
    required this.vouchersCount,
    required this.rankTitle,
    this.availableXp,
  });

  int get spendableXp => availableXp ?? totalXp;
  int get xpLevelFloor => (currentLevel - 1) * 200;
  int get xpLevelCeiling => currentLevel * 200;

  int get xpForNextLevel => currentLevel * 200;
  int get xpIntoCurrentLevel => totalXp - ((currentLevel - 1) * 200);
  double get progressToNextLevel =>
      (xpIntoCurrentLevel / 200).clamp(0, 1).toDouble();
}

class LearningOverview {
  const LearningOverview({
    required this.lessons,
    required this.scenarios,
    required this.questions,
    required this.rewards,
  });

  final int lessons;
  final int scenarios;
  final int questions;
  final int rewards;
}

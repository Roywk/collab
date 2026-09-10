enum AwarenessContentType { lesson, quiz, scenario }

extension AwarenessContentTypeLabel on AwarenessContentType {
  String get label => switch (this) {
    AwarenessContentType.lesson => 'Lesson',
    AwarenessContentType.quiz => 'Quiz',
    AwarenessContentType.scenario => 'Scenario',
  };
}

class AwarenessContentSummary {
  const AwarenessContentSummary({
    required this.id,
    required this.referenceCode,
    required this.title,
    required this.type,
    required this.category,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String referenceCode;
  final String title;
  final AwarenessContentType type;
  final String category;
  final String status;
  final DateTime updatedAt;

  bool get isPublished => status == 'published';
}

class AwarenessCmsSnapshot {
  const AwarenessCmsSnapshot({required this.contents, required this.vouchers});

  final List<AwarenessContentSummary> contents;
  final List<AdminVoucherRecord> vouchers;

  int get lessons =>
      contents.where((item) => item.type == AwarenessContentType.lesson).length;
  int get quizzes =>
      contents.where((item) => item.type == AwarenessContentType.quiz).length;
  int get scenarios => contents
      .where((item) => item.type == AwarenessContentType.scenario)
      .length;
  int get drafts => contents.where((item) => item.status == 'draft').length;
  int get published =>
      contents.where((item) => item.status == 'published').length;
  int get availableCodes =>
      vouchers.fold(0, (sum, voucher) => sum + voucher.availableCodes);
}

class AdminLessonDraft {
  const AdminLessonDraft({
    this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.readTime,
    required this.content,
    required this.redFlags,
    required this.whatToDo,
    required this.xpReward,
    required this.status,
    this.imageUrl,
    this.hotspotLabel,
    this.latitude,
    this.longitude,
    this.isLocationBased = false,
  });

  final String? id;
  final String title;
  final String category;
  final String difficulty;
  final String readTime;
  final String content;
  final List<String> redFlags;
  final String whatToDo;
  final int xpReward;
  final String status;
  final String? imageUrl;
  final String? hotspotLabel;
  final double? latitude;
  final double? longitude;
  final bool isLocationBased;
}

class AdminQuizDraft {
  const AdminQuizDraft({
    this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.category,
    required this.difficulty,
    required this.timeLimitSeconds,
    required this.status,
    this.imageUrl,
  });

  final String? id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String category;
  final String difficulty;
  final int timeLimitSeconds;
  final String status;
  final String? imageUrl;
}

class AdminScenarioDraft {
  const AdminScenarioDraft({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.xpReward,
    required this.situation,
    required this.options,
    required this.correctIndex,
    required this.feedback,
    required this.status,
  });

  final String? id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int xpReward;
  final String situation;
  final List<String> options;
  final int correctIndex;
  final String feedback;
  final String status;
}

class AdminVoucherRecord {
  const AdminVoucherRecord({
    required this.id,
    required this.referenceCode,
    required this.partnerName,
    required this.title,
    required this.discountAmount,
    required this.requiredXp,
    required this.validUntil,
    required this.status,
    required this.totalCodes,
    required this.availableCodes,
    required this.claimedCodes,
  });

  final String id;
  final String referenceCode;
  final String partnerName;
  final String title;
  final String discountAmount;
  final int requiredXp;
  final DateTime validUntil;
  final String status;
  final int totalCodes;
  final int availableCodes;
  final int claimedCodes;
}

class AdminVoucherDraft {
  const AdminVoucherDraft({
    this.id,
    required this.partnerName,
    required this.title,
    required this.discountAmount,
    required this.requiredXp,
    required this.validUntil,
    required this.status,
    required this.codes,
  });

  final String? id;
  final String partnerName;
  final String title;
  final String discountAmount;
  final int requiredXp;
  final DateTime validUntil;
  final String status;
  final List<String> codes;
}

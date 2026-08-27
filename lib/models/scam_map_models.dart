enum ScamVerificationStatus { verified, pending }

extension ScamVerificationStatusExtension on ScamVerificationStatus {
  String get databaseValue {
    switch (this) {
      case ScamVerificationStatus.verified:
        return 'Verified';
      case ScamVerificationStatus.pending:
        return 'Pending';
    }
  }

  String get label => databaseValue;

  static ScamVerificationStatus fromValue(Object? value) {
    return value?.toString().trim().toLowerCase() == 'verified'
        ? ScamVerificationStatus.verified
        : ScamVerificationStatus.pending;
  }
}

class ScamMapReport {
  const ScamMapReport({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.reportedAt,
    this.reportCode,
    this.locationName,
    this.isOfficial = false,
    this.sourceReference,
  });

  final String id;
  final String? reportCode;
  final String title;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final ScamVerificationStatus status;
  final DateTime reportedAt;
  final String? locationName;
  final bool isOfficial;
  final String? sourceReference;

  bool get isVerified => status == ScamVerificationStatus.verified;

  factory ScamMapReport.fromMap(Map<String, dynamic> map) {
    return ScamMapReport(
      id: map['id']?.toString() ?? '',
      reportCode: map['report_code']?.toString(),
      title: _text(map['title'], fallback: 'Reported scam incident'),
      category: _text(map['category'], fallback: 'Other'),
      description: _text(map['description']),
      latitude: _double(map['latitude']),
      longitude: _double(map['longitude']),
      status: ScamVerificationStatusExtension.fromValue(
        map['verification_status'],
      ),
      reportedAt:
          DateTime.tryParse(map['reported_at']?.toString() ?? '') ??
          DateTime.now(),
      locationName: map['location_name']?.toString(),
      isOfficial: map['is_official'] == true,
      sourceReference: map['source_reference']?.toString(),
    );
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'id': id,
      'report_code': reportCode,
      'title': title,
      'category': category,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'verification_status': status.databaseValue,
      'reported_at': reportedAt.toIso8601String(),
      'location_name': locationName,
      'is_official': isOfficial,
      'source_reference': sourceReference,
    };
  }

  static String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static double _double(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ManualScamCase {
  const ManualScamCase({
    required this.title,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.sourceReference,
  });

  final String title;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final String? locationName;
  final String? sourceReference;
}

class ScamThreatAnalytics {
  const ScamThreatAnalytics({
    required this.totalReports,
    required this.verifiedReports,
    required this.pendingReports,
    required this.categoryCounts,
    required this.locationCounts,
  });

  final int totalReports;
  final int verifiedReports;
  final int pendingReports;
  final Map<String, int> categoryCounts;
  final Map<String, int> locationCounts;

  factory ScamThreatAnalytics.fromReports(List<ScamMapReport> reports) {
    final categoryCounts = <String, int>{};
    final locationCounts = <String, int>{};

    for (final report in reports) {
      categoryCounts.update(
        report.category,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      final location = (report.locationName ?? '').trim();
      if (location.isNotEmpty) {
        locationCounts.update(
          location,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    return ScamThreatAnalytics(
      totalReports: reports.length,
      verifiedReports: reports.where((report) => report.isVerified).length,
      pendingReports: reports.where((report) => !report.isVerified).length,
      categoryCounts: categoryCounts,
      locationCounts: locationCounts,
    );
  }
}

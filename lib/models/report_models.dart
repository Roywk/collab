class ScamReport {
  final String? id;
  final String title;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final String? locationName;
  final double? amountLost;
  final List<String> evidenceUrls;
  final String verificationStatus;
  final bool isAnonymous;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<ScamReportStatusHistory> statusHistory;

  ScamReport({
    this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.amountLost,
    this.evidenceUrls = const [],
    this.verificationStatus = 'Pending',
    this.isAnonymous = false,
    this.adminNotes,
    DateTime? createdAt,
    this.updatedAt,
    this.statusHistory = const [],
  }) : this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'location_name': locationName,
        'amount_lost': amountLost,
        'evidence_urls': evidenceUrls,
        'is_anonymous': isAnonymous,
        // Removed admin_notes and verification_status from toJson to fix PostgrestException.
        // These columns are either missing or should be handled by the database/admin only.
      };
}

class ScamReportStatusHistory {
  final String status;
  final String changedBy;
  final DateTime changedAt;
  final String? notes;

  ScamReportStatusHistory({
    required this.status,
    required this.changedBy,
    required this.changedAt,
    this.notes,
  });
}

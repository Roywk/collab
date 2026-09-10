class AdminBankRecord {
  const AdminBankRecord({
    required this.id,
    required this.slug,
    required this.name,
    required this.countryCode,
    required this.countryName,
    required this.hotlineNumber,
    required this.serviceType,
    required this.targetDepartment,
    required this.supportsKillSwitch,
    required this.availabilityLabel,
    required this.isActive,
  });

  final String id;
  final String slug;
  final String name;
  final String countryCode;
  final String countryName;
  final String hotlineNumber;
  final String serviceType;
  final String targetDepartment;
  final bool supportsKillSwitch;
  final String availabilityLabel;
  final bool isActive;

  bool get isMalaysian => countryCode.toUpperCase() == 'MY';

  factory AdminBankRecord.fromJson(Map<String, dynamic> json) {
    return AdminBankRecord(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed bank',
      countryCode: json['country_code']?.toString() ?? '',
      countryName: json['country_name']?.toString() ?? '',
      hotlineNumber: json['hotline_number']?.toString() ?? '',
      serviceType: json['service_type']?.toString() ?? '24/7 Hotline',
      targetDepartment: json['target_department']?.toString() ?? '',
      supportsKillSwitch: json['supports_kill_switch'] == true,
      availabilityLabel:
          json['availability_label']?.toString() ?? 'Emergency Hotline',
      isActive: json['is_active'] == true,
    );
  }
}

enum AdminBankDeleteResult { deleted, deactivatedBecauseLinked }

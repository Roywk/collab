class BankHotline {
  const BankHotline({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.countryName,
    required this.hotlineNumber,
    required this.serviceType,
    required this.targetDepartment,
    required this.supportsKillSwitch,
    required this.availabilityLabel,
    this.isPrimary = false,
  });

  final String id;
  final String name;
  final String countryCode;
  final String countryName;
  final String hotlineNumber;
  final String serviceType;
  final String targetDepartment;
  final bool supportsKillSwitch;
  final String availabilityLabel;
  final bool isPrimary;

  bool get isMalaysian => countryCode.toUpperCase() == 'MY';

  factory BankHotline.fromUserBankJson(Map<String, dynamic> json) {
    final relation = json['banks'];
    final bank = relation is Map
        ? Map<String, dynamic>.from(relation)
        : <String, dynamic>{};

    return BankHotline(
      id: bank['id']?.toString() ?? '',
      name: bank['name']?.toString() ?? 'Bank',
      countryCode: bank['country_code']?.toString() ?? '',
      countryName: bank['country_name']?.toString() ?? '',
      hotlineNumber: bank['hotline_number']?.toString() ?? '',
      serviceType: bank['service_type']?.toString() ?? '',
      targetDepartment: bank['target_department']?.toString() ?? '',
      supportsKillSwitch: bank['supports_kill_switch'] == true,
      availabilityLabel:
          bank['availability_label']?.toString() ?? 'Emergency Hotline',
      isPrimary: json['is_primary'] == true,
    );
  }
}

enum BankDirectoryFilter { all, malaysian, international }

extension BankDirectoryFilterLabel on BankDirectoryFilter {
  String get label {
    switch (this) {
      case BankDirectoryFilter.all:
        return 'All';
      case BankDirectoryFilter.malaysian:
        return 'Malaysian Banks';
      case BankDirectoryFilter.international:
        return 'International';
    }
  }
}

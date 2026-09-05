class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.nationality,
    required this.preferredLanguage,
    required this.role,
    this.primaryBankId = '',
    this.primaryBankName = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyContactRelationship = '',
    this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String nationality;
  final String preferredLanguage;
  final String role;
  final String primaryBankId;
  final String primaryBankName;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelationship;
  final DateTime? createdAt;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) return 'U';
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Visit 1MY User',
      phoneNumber: json['phone_number']?.toString() ?? '',
      nationality: json['nationality']?.toString() ?? '',
      preferredLanguage: json['preferred_language']?.toString() ?? 'English',
      role: json['role']?.toString() ?? 'user',
      primaryBankId: json['primary_bank_id']?.toString() ?? '',
      primaryBankName: json['primary_bank_name']?.toString() ?? '',
      emergencyContactName: json['emergency_contact_name']?.toString() ?? '',
      emergencyContactPhone: json['emergency_contact_phone']?.toString() ?? '',
      emergencyContactRelationship:
          json['emergency_contact_relationship']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class BankChoice {
  const BankChoice({required this.id, required this.name});

  final String id;
  final String name;

  factory BankChoice.fromJson(Map<String, dynamic> json) {
    return BankChoice(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed bank',
    );
  }
}

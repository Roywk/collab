class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.isPrimary,
    this.relationship,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String? relationship;
  final bool isPrimary;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Emergency contact',
      phoneNumber: json['phone_number']?.toString() ?? '',
      relationship: json['relationship']?.toString(),
      isPrimary: json['is_primary'] == true,
    );
  }
}

enum SosShareChannel { whatsapp, sms }

extension SosShareChannelValue on SosShareChannel {
  String get databaseValue => switch (this) {
    SosShareChannel.whatsapp => 'whatsapp',
    SosShareChannel.sms => 'sms',
  };
}

enum EmergencyFacilityType { police, fireRescue, rela }

extension EmergencyFacilityTypeDetails on EmergencyFacilityType {
  String get databaseValue {
    switch (this) {
      case EmergencyFacilityType.police:
        return 'police';
      case EmergencyFacilityType.fireRescue:
        return 'fire_rescue';
      case EmergencyFacilityType.rela:
        return 'rela';
    }
  }

  String get label {
    switch (this) {
      case EmergencyFacilityType.police:
        return 'Police';
      case EmergencyFacilityType.fireRescue:
        return 'Fire & Rescue';
      case EmergencyFacilityType.rela:
        return 'RELA';
    }
  }

  static EmergencyFacilityType fromDatabase(String value) {
    return switch (value) {
      'fire_rescue' => EmergencyFacilityType.fireRescue,
      'rela' => EmergencyFacilityType.rela,
      _ => EmergencyFacilityType.police,
    };
  }
}

class EmergencyFacility {
  const EmergencyFacility({
    required this.id,
    required this.name,
    required this.type,
    required this.agencyLabel,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.availabilityLabel,
    required this.isVerified,
    this.phoneNumber,
  });

  final String id;
  final String name;
  final EmergencyFacilityType type;
  final String agencyLabel;
  final String address;
  final String? phoneNumber;
  final double latitude;
  final double longitude;
  final String availabilityLabel;
  final bool isVerified;

  bool get hasPhone => phoneNumber?.trim().isNotEmpty == true;

  factory EmergencyFacility.fromJson(Map<String, dynamic> json) {
    return EmergencyFacility(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Emergency facility',
      type: EmergencyFacilityTypeDetails.fromDatabase(
        json['facility_type']?.toString() ?? '',
      ),
      agencyLabel: json['agency_label']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      availabilityLabel:
          json['availability_label']?.toString() ?? 'Hours unavailable',
      isVerified: json['is_verified'] == true,
    );
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return name.toLowerCase().contains(normalized) ||
        agencyLabel.toLowerCase().contains(normalized) ||
        address.toLowerCase().contains(normalized) ||
        type.label.toLowerCase().contains(normalized);
  }
}

class NearbyFacility {
  const NearbyFacility({required this.facility, required this.distanceMeters});

  final EmergencyFacility facility;
  final double distanceMeters;

  String get distanceLabel {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m away';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km away';
  }
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

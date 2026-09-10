import 'help_nearby_models.dart';

class AdminFacilityRecord {
  const AdminFacilityRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.agencyLabel,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.availabilityLabel,
    required this.isActive,
    required this.isVerified,
  });

  final String id;
  final String name;
  final EmergencyFacilityType type;
  final String agencyLabel;
  final String address;
  final double latitude;
  final double longitude;
  final String? phoneNumber;
  final String availabilityLabel;
  final bool isActive;
  final bool isVerified;

  factory AdminFacilityRecord.fromJson(Map<String, dynamic> json) {
    return AdminFacilityRecord(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed facility',
      type: EmergencyFacilityTypeDetails.fromDatabase(
        json['facility_type']?.toString() ?? '',
      ),
      agencyLabel: json['agency_label']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      phoneNumber: json['phone_number']?.toString(),
      availabilityLabel:
          json['availability_label']?.toString() ?? 'Hours unavailable',
      isActive: json['is_active'] == true,
      isVerified: json['is_verified'] == true,
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

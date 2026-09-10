import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_facility_models.dart';
import '../models/help_nearby_models.dart';

abstract interface class AdminFacilityRepository {
  Future<List<AdminFacilityRecord>> getFacilities();

  Future<void> saveFacility(AdminFacilityRecord facility);

  Future<void> deleteFacility(String facilityId);
}

class SupabaseAdminFacilityRepository implements AdminFacilityRepository {
  SupabaseAdminFacilityRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  @override
  Future<List<AdminFacilityRecord>> getFacilities() async {
    final response = await client
        .from('emergency_facilities')
        .select(
          'id, name, facility_type, agency_label, address, latitude, '
          'longitude, phone_number, availability_label, is_active, '
          'is_verified',
        )
        .order('name');

    return (response as List)
        .map(
          (row) => AdminFacilityRecord.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .where((facility) => facility.id.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> saveFacility(AdminFacilityRecord facility) async {
    final payload = <String, dynamic>{
      'name': facility.name.trim(),
      'facility_type': facility.type.databaseValue,
      'agency_label': facility.agencyLabel.trim(),
      'address': facility.address.trim(),
      'latitude': facility.latitude,
      'longitude': facility.longitude,
      'phone_number': _nullableText(facility.phoneNumber),
      'availability_label': facility.availabilityLabel.trim(),
      'is_active': facility.isActive,
      'is_verified': true,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (facility.id.isEmpty) {
      await client.from('emergency_facilities').insert(payload);
      return;
    }

    await client
        .from('emergency_facilities')
        .update(payload)
        .eq('id', facility.id);
  }

  @override
  Future<void> deleteFacility(String facilityId) async {
    await client.from('emergency_facilities').delete().eq('id', facilityId);
  }

  String? _nullableText(String? value) {
    final cleaned = value?.trim() ?? '';
    return cleaned.isEmpty ? null : cleaned;
  }
}

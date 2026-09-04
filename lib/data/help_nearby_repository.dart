import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/help_nearby_models.dart';

abstract interface class HelpNearbyRepository {
  Future<List<EmergencyFacility>> getActiveFacilities();
}

class SupabaseHelpNearbyRepository implements HelpNearbyRepository {
  SupabaseHelpNearbyRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  @override
  Future<List<EmergencyFacility>> getActiveFacilities() async {
    final response = await client
        .from('emergency_facilities')
        .select(
          'id, name, facility_type, agency_label, address, phone_number, '
          'latitude, longitude, availability_label, is_verified',
        )
        .eq('is_active', true)
        .order('name');

    return (response as List)
        .map(
          (row) =>
              EmergencyFacility.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .where(
          (facility) =>
              facility.id.isNotEmpty &&
              facility.latitude != 0 &&
              facility.longitude != 0,
        )
        .toList(growable: false);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sos_models.dart';

abstract interface class SosRepository {
  Future<EmergencyContact?> getPrimaryEmergencyContact();

  Future<void> recordShareOpened({
    required EmergencyContact contact,
    required SosShareChannel channel,
  });
}

class SupabaseSosRepository implements SosRepository {
  SupabaseSosRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  @override
  Future<EmergencyContact?> getPrimaryEmergencyContact() async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in before using SOS location sharing.');
    }

    final response = await client
        .from('emergency_contacts')
        .select('id, name, phone_number, relationship, is_primary')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .order('is_primary', ascending: false)
        .order('created_at')
        .limit(1);

    final rows = response as List;
    if (rows.isEmpty) return null;

    final contact = EmergencyContact.fromJson(
      Map<String, dynamic>.from(rows.first as Map),
    );
    if (contact.id.isEmpty || contact.phoneNumber.trim().isEmpty) return null;
    return contact;
  }

  @override
  Future<void> recordShareOpened({
    required EmergencyContact contact,
    required SosShareChannel channel,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    await client.from('sos_share_events').insert({
      'user_id': user.id,
      'emergency_contact_id': contact.id,
      'channel': channel.databaseValue,
      'status': 'composer_opened',
    });
  }
}

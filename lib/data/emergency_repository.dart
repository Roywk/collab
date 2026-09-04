import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/emergency_models.dart';

abstract interface class EmergencyRepository {
  Future<List<BankHotline>> getUserBanks();

  Future<void> recordKillSwitchCall(BankHotline bank);
}

class SupabaseEmergencyRepository implements EmergencyRepository {
  SupabaseEmergencyRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  @override
  Future<List<BankHotline>> getUserBanks() async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to load your registered banks.');
    }

    final response = await client
        .from('user_banks')
        .select(
          'is_primary, banks!inner('
          'id, name, country_code, country_name, hotline_number, '
          'service_type, target_department, supports_kill_switch, '
          'availability_label)',
        )
        .eq('user_id', user.id)
        .eq('banks.is_active', true)
        .order('is_primary', ascending: false)
        .order('created_at');

    return (response as List)
        .map(
          (row) => BankHotline.fromUserBankJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .where((bank) => bank.id.isNotEmpty && bank.hotlineNumber.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> recordKillSwitchCall(BankHotline bank) async {
    final user = client.auth.currentUser;
    if (user == null) {
      return;
    }

    await client.from('kill_switch_requests').insert({
      'user_id': user.id,
      'bank_id': bank.id,
      'hotline_number': bank.hotlineNumber,
      'status': 'dialer_opened',
    });
  }
}

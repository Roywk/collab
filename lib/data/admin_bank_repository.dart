import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_bank_models.dart';

abstract interface class AdminBankRepository {
  Future<List<AdminBankRecord>> getBanks();

  Future<void> saveBank(AdminBankRecord bank);

  Future<AdminBankDeleteResult> deleteBank(AdminBankRecord bank);
}

class SupabaseAdminBankRepository implements AdminBankRepository {
  SupabaseAdminBankRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  @override
  Future<List<AdminBankRecord>> getBanks() async {
    final response = await client
        .from('banks')
        .select(
          'id, slug, name, country_code, country_name, hotline_number, '
          'service_type, target_department, supports_kill_switch, '
          'availability_label, is_active',
        )
        .order('name');

    return (response as List)
        .map(
          (row) =>
              AdminBankRecord.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .where((bank) => bank.id.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> saveBank(AdminBankRecord bank) async {
    final payload = <String, dynamic>{
      'name': bank.name.trim(),
      'country_code': bank.countryCode.trim().toUpperCase(),
      'country_name': bank.countryName.trim(),
      'hotline_number': bank.hotlineNumber.trim(),
      'service_type': bank.serviceType.trim(),
      'target_department': bank.targetDepartment.trim(),
      'supports_kill_switch': bank.supportsKillSwitch,
      'availability_label': bank.availabilityLabel.trim(),
      'is_active': bank.isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (bank.id.isEmpty) {
      payload['slug'] = _slugify(bank.name);
      await client.from('banks').insert(payload);
      return;
    }

    await client.from('banks').update(payload).eq('id', bank.id);
  }

  @override
  Future<AdminBankDeleteResult> deleteBank(AdminBankRecord bank) async {
    final links = await client
        .from('user_banks')
        .select('bank_id')
        .eq('bank_id', bank.id)
        .limit(1);

    if ((links as List).isNotEmpty) {
      await client
          .from('banks')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bank.id);
      return AdminBankDeleteResult.deactivatedBecauseLinked;
    }

    await client.from('banks').delete().eq('id', bank.id);
    return AdminBankDeleteResult.deleted;
  }

  String _slugify(String name) {
    final slug = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    if (slug.isEmpty) {
      throw const FormatException('Enter a bank name containing letters.');
    }
    return slug;
  }
}

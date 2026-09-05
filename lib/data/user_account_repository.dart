import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

abstract interface class UserAccountRepository {
  SupabaseClient get client;

  Stream<AuthState> get authStateChanges;

  User? get currentUser;

  Future<bool> hasTouristAccess();

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String nationality,
    required List<String> bankIds,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String emergencyContactRelationship,
  });

  Future<List<BankChoice>> getAvailableBanks();

  Future<void> sendPasswordReset(String email);

  Future<UserProfile> getProfile();

  Future<void> updateProfile(UserProfile profile);

  Future<void> signOut();
}

class SupabaseUserAccountRepository implements UserAccountRepository {
  SupabaseUserAccountRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  @override
  final SupabaseClient client;

  @override
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  @override
  User? get currentUser => client.auth.currentUser;

  @override
  Future<bool> hasTouristAccess() async {
    final user = currentUser;
    if (user == null || user.isAnonymous) return false;

    final adminResponse = await client
        .from('admin_accounts')
        .select('id')
        .eq('id', user.id)
        .limit(1);
    if ((adminResponse as List).isNotEmpty) return false;

    final profileResponse = await client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .eq('role', 'tourist')
        .limit(1);

    return (profileResponse as List).isNotEmpty;
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (client.auth.currentUser?.isAnonymous == true) {
      await client.auth.signOut();
    }
    final response = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (!await hasTouristAccess()) {
      await client.auth.signOut();
      throw const AuthException(
        'Administrator accounts must use the Administrator Login page.',
      );
    }

    return response;
  }

  @override
  Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String nationality,
    required List<String> bankIds,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String emergencyContactRelationship,
  }) async {
    if (bankIds.isEmpty) {
      throw const AuthException('Select at least one bank.');
    }
    if (client.auth.currentUser?.isAnonymous == true) {
      await client.auth.signOut();
    }
    return client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'phone_number': phoneNumber.trim(),
        'nationality': nationality.trim(),
        // The database trigger creates one user_banks row per selected bank.
        // Keep bank_id during the transition for older trigger deployments.
        'bank_ids': bankIds,
        'bank_id': bankIds.first,
        'emergency_contact_name': emergencyContactName.trim(),
        'emergency_contact_phone': emergencyContactPhone.trim(),
        'emergency_contact_relationship': emergencyContactRelationship.trim(),
      },
    );
  }

  @override
  Future<List<BankChoice>> getAvailableBanks() async {
    final response = await client
        .from('banks')
        .select('id, name')
        .eq('is_active', true)
        .order('name');

    return (response as List)
        .map(
          (row) => BankChoice.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .where((bank) => bank.id.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return client.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<UserProfile> getProfile() async {
    final user = currentUser;
    if (user == null || user.isAnonymous) {
      throw const AuthException('Sign in to view your profile.');
    }

    final response = await client
        .from('profiles')
        .select(
          'id, email, display_name, phone_number, nationality, '
          'preferred_language, role, created_at',
        )
        .eq('id', user.id)
        .single();

    final profileData = Map<String, dynamic>.from(response);
    profileData['full_name'] = profileData['display_name'];

    final bankResponse = await client
        .from('user_banks')
        .select('bank_id, banks(name)')
        .eq('user_id', user.id)
        .order('is_primary', ascending: false)
        .limit(1);
    final bankRows = bankResponse as List;
    if (bankRows.isNotEmpty) {
      final bankRow = Map<String, dynamic>.from(bankRows.first as Map);
      final bank = bankRow['banks'];
      profileData['primary_bank_id'] = bankRow['bank_id'];
      if (bank is Map) profileData['primary_bank_name'] = bank['name'];
    }

    final contactResponse = await client
        .from('emergency_contacts')
        .select('name, phone_number, relationship')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .order('is_primary', ascending: false)
        .limit(1);
    final contactRows = contactResponse as List;
    if (contactRows.isNotEmpty) {
      final contact = Map<String, dynamic>.from(contactRows.first as Map);
      profileData['emergency_contact_name'] = contact['name'];
      profileData['emergency_contact_phone'] = contact['phone_number'];
      profileData['emergency_contact_relationship'] = contact['relationship'];
    }

    return UserProfile.fromJson(profileData);
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    final user = currentUser;
    if (user == null || user.id != profile.id) {
      throw const AuthException('You can update only your own profile.');
    }

    await client
        .from('profiles')
        .update({
          'display_name': profile.fullName.trim(),
          'phone_number': _nullableText(profile.phoneNumber),
          'nationality': _nullableText(profile.nationality),
          'preferred_language': profile.preferredLanguage,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);

    if (profile.primaryBankId.isNotEmpty) {
      await client
          .from('user_banks')
          .update({'is_primary': false})
          .eq('user_id', user.id);
      await client.from('user_banks').upsert({
        'user_id': user.id,
        'bank_id': profile.primaryBankId,
        'is_primary': true,
      }, onConflict: 'user_id,bank_id');
    }

    final contactResponse = await client
        .from('emergency_contacts')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_primary', true)
        .eq('is_active', true)
        .limit(1);
    final contactRows = contactResponse as List;
    final contactPayload = {
      'name': profile.emergencyContactName.trim(),
      'phone_number': profile.emergencyContactPhone.trim(),
      'relationship': _nullableText(profile.emergencyContactRelationship),
      'is_primary': true,
      'is_active': true,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (contactRows.isEmpty) {
      await client.from('emergency_contacts').insert({
        ...contactPayload,
        'user_id': user.id,
      });
    } else {
      await client
          .from('emergency_contacts')
          .update(contactPayload)
          .eq('id', (contactRows.first as Map)['id']);
    }
  }

  @override
  Future<void> signOut() => client.auth.signOut();

  String? _nullableText(String value) {
    final cleaned = value.trim();
    return cleaned.isEmpty ? null : cleaned;
  }
}

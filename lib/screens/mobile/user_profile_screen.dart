import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/incident_report_repository.dart';
import '../../data/user_account_repository.dart';
import '../../models/user_profile.dart';
import 'translated_report_history_screen.dart';
import 'scam_report_history_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    required this.repository,
    required this.incidentReportRepository,
    super.key,
  });

  final UserAccountRepository repository;
  final IncidentReportHistoryRepository incidentReportRepository;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactRelationshipController = TextEditingController();

  late Future<UserProfile> _profileFuture;
  late Future<List<BankChoice>> _banksFuture;
  String _language = 'English';
  String? _selectedBankId;
  bool _editing = false;
  bool _saving = false;
  bool _controllersLoaded = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.repository.getProfile();
    _banksFuture = widget.repository.getAvailableBanks();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalityController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactRelationshipController.dispose();
    super.dispose();
  }

  void _loadControllers(UserProfile profile) {
    if (_controllersLoaded) return;
    _nameController.text = profile.fullName;
    _phoneController.text = profile.phoneNumber;
    _nationalityController.text = profile.nationality;
    _contactNameController.text = profile.emergencyContactName;
    _contactPhoneController.text = profile.emergencyContactPhone;
    _contactRelationshipController.text = profile.emergencyContactRelationship;
    _language = profile.preferredLanguage;
    _selectedBankId = profile.primaryBankId.isEmpty
        ? null
        : profile.primaryBankId;
    _controllersLoaded = true;
  }

  Future<void> _save(UserProfile current) async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final updated = UserProfile(
      id: current.id,
      email: current.email,
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      nationality: _nationalityController.text.trim(),
      preferredLanguage: _language,
      role: current.role,
      primaryBankId: _selectedBankId ?? current.primaryBankId,
      primaryBankName: current.primaryBankName,
      emergencyContactName: _contactNameController.text.trim(),
      emergencyContactPhone: _contactPhoneController.text.trim(),
      emergencyContactRelationship: _contactRelationshipController.text.trim(),
      createdAt: current.createdAt,
    );

    try {
      await widget.repository.updateProfile(updated);
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saving = false;
        _profileFuture = Future<UserProfile>.value(updated);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile: $error')),
      );
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: AppColors.red),
        title: const Text('Sign out?'),
        content: const Text(
          'You will need your email and password to access your account again.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _retry() {
    setState(() {
      _controllersLoaded = false;
      _profileFuture = widget.repository.getProfile();
    });
  }

  void _openTranslatedReportRecords() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TranslatedReportHistoryScreen(
          repository: widget.incidentReportRepository,
        ),
      ),
    );
  }

  void _openScamReportHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ScamReportHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'My Profile',
      titleColor: AppColors.navy,
      currentNavigationIndex: 6,
      onProfile: () {},
      child: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _ProfileLoadError(
              message: snapshot.error?.toString() ?? 'Profile not found.',
              onRetry: _retry,
            );
          }

          final profile = snapshot.data!;
          _loadControllers(profile);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                _ProfileHeader(profile: profile),
                const SizedBox(height: 14),
                SurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Personal Information',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (!_editing)
                            TextButton.icon(
                              onPressed: () => setState(() => _editing = true),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Edit'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _ProfileFieldLabel('FULL NAME'),
                      TextFormField(
                        controller: _nameController,
                        enabled: _editing,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Enter your full name.'
                            : null,
                      ),
                      const SizedBox(height: 11),
                      _ProfileFieldLabel('EMAIL ADDRESS'),
                      TextFormField(
                        initialValue: profile.email,
                        enabled: false,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 11),
                      _ProfileFieldLabel('PHONE NUMBER'),
                      TextFormField(
                        controller: _phoneController,
                        enabled: _editing,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '+60123456789',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 11),
                      _ProfileFieldLabel('NATIONALITY'),
                      TextFormField(
                        controller: _nationalityController,
                        enabled: _editing,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.public_outlined),
                        ),
                      ),
                      const SizedBox(height: 11),
                      _ProfileFieldLabel('PREFERRED LANGUAGE'),
                      DropdownButtonFormField<String>(
                        key: ValueKey('profile-language-$_language'),
                        initialValue: _language,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.translate_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'English',
                            child: Text('English'),
                          ),
                          DropdownMenuItem(
                            value: 'Bahasa Melayu',
                            child: Text('Bahasa Melayu'),
                          ),
                          DropdownMenuItem(value: '中文', child: Text('中文')),
                          DropdownMenuItem(
                            value: 'தமிழ்',
                            child: Text('தமிழ்'),
                          ),
                        ],
                        onChanged: !_editing
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _language = value);
                                }
                              },
                      ),
                      const SizedBox(height: 11),
                      _ProfileFieldLabel('PRIMARY BANK'),
                      FutureBuilder<List<BankChoice>>(
                        future: _banksFuture,
                        builder: (context, snapshot) {
                          final banks = snapshot.data ?? const <BankChoice>[];
                          final selectedIsAvailable = banks.any(
                            (bank) => bank.id == _selectedBankId,
                          );
                          return DropdownButtonFormField<String>(
                            key: ValueKey(
                              'profile-bank-${selectedIsAvailable ? _selectedBankId : 'none'}',
                            ),
                            initialValue: selectedIsAvailable
                                ? _selectedBankId
                                : null,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.account_balance_outlined),
                            ),
                            items: banks
                                .map(
                                  (bank) => DropdownMenuItem(
                                    value: bank.id,
                                    child: Text(
                                      bank.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: !_editing
                                ? null
                                : (value) =>
                                      setState(() => _selectedBankId = value),
                            validator: (value) => value == null
                                ? 'Select your primary bank.'
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text(
                        'Primary Emergency Contact',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'This contact is used by Share My Location / SOS.',
                        style: TextStyle(color: AppColors.slate, fontSize: 9),
                      ),
                      const SizedBox(height: 11),
                      _ProfileFieldLabel('CONTACT NAME'),
                      TextFormField(
                        controller: _contactNameController,
                        enabled: _editing,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.contact_emergency_outlined),
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Enter the contact name.'
                            : null,
                      ),
                      const SizedBox(height: 11),
                      _ProfileFieldLabel('CONTACT PHONE'),
                      TextFormField(
                        controller: _contactPhoneController,
                        enabled: _editing,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '+60123456789',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) =>
                            RegExp(
                              r'^\+[1-9][0-9]{7,14}$',
                            ).hasMatch((value ?? '').trim())
                            ? null
                            : 'Use international format, e.g. +60123456789.',
                      ),
                      const SizedBox(height: 11),
                      _ProfileFieldLabel('RELATIONSHIP'),
                      TextFormField(
                        controller: _contactRelationshipController,
                        enabled: _editing,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Enter your relationship.'
                            : null,
                      ),
                      if (_editing) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () {
                                        setState(() {
                                          _controllersLoaded = false;
                                          _loadControllers(profile);
                                          _editing = false;
                                        });
                                      },
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: _saving
                                    ? null
                                    : () => _save(profile),
                                child: _saving
                                    ? const SizedBox(
                                        width: 17,
                                        height: 17,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Save Changes'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: _openScamReportHistory,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _ProfileActionIcon(
                            icon: Icons.history_rounded,
                            color: AppColors.red,
                            backgroundColor: AppColors.redSoft,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scam Report History',
                                  style: TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'View your submitted scam reports',
                                  style: TextStyle(
                                    color: AppColors.slate,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: _openTranslatedReportRecords,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _ProfileActionIcon(
                            icon: Icons.translate_rounded,
                            color: AppColors.blue,
                            backgroundColor: AppColors.blueSoft,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Translate Report Record',
                                  style: TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'View your past translated incident reports',
                                  style: TextStyle(
                                    color: AppColors.slate,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AccountRow(
                        icon: Icons.badge_outlined,
                        label: 'Account type',
                        value: profile.role == 'admin'
                            ? 'Administrator'
                            : 'Tourist',
                      ),
                      if (profile.createdAt != null)
                        _AccountRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Member since',
                          value: DateFormat(
                            'd MMM yyyy',
                          ).format(profile.createdAt!),
                        ),
                      const Divider(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _confirmSignOut,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.red,
                            side: const BorderSide(color: AppColors.red),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 17),
                          label: const Text('Sign Out'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileActionIcon extends StatelessWidget {
  const _ProfileActionIcon({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.blueSoft,
            child: Text(
              profile.initials,
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile.email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.slate, fontSize: 10),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'Verified Account',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileFieldLabel extends StatelessWidget {
  const _ProfileFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.slate,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: AppColors.slate, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.slate, fontSize: 11),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              color: AppColors.red,
              size: 42,
            ),
            const SizedBox(height: 10),
            const Text(
              'Profile unavailable',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate, fontSize: 11),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

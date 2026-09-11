import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/admin_repository.dart';
import '../../data/awareness_admin_repository.dart';
import '../../models/awareness_admin_models.dart';
import 'admin_shell.dart';
import 'awareness_content_editor_screen.dart';
import 'awareness_management_dialogs.dart';

class AwarenessCmsScreen extends StatefulWidget {
  const AwarenessCmsScreen({
    required this.repository,
    required this.onSignOut,
    this.onOpenDashboard,
    this.onOpenReports,
    this.onOpenHeatmap,
    this.onOpenVerifiedMerchants,
    this.onOpenThreatDatabase,
    this.onOpenAwarenessCms,
    this.onOpenSettings,
    this.onOpenPublishScamCase,
    super.key,
  });

  final AdminRepository repository;
  final Future<void> Function() onSignOut;
  final VoidCallback? onOpenDashboard;
  final VoidCallback? onOpenReports;
  final VoidCallback? onOpenHeatmap;
  final VoidCallback? onOpenVerifiedMerchants;
  final VoidCallback? onOpenThreatDatabase;
  final VoidCallback? onOpenAwarenessCms;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenPublishScamCase;

  @override
  State<AwarenessCmsScreen> createState() => _AwarenessCmsScreenState();
}

class _AwarenessCmsScreenState extends State<AwarenessCmsScreen> {
  late final AwarenessAdminRepository _cmsRepository;
  late Future<AwarenessCmsSnapshot> _snapshot;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _cmsRepository = AwarenessAdminRepository(client: widget.repository.client);
    _refresh();
  }

  void _refresh() => _snapshot = _cmsRepository.getSnapshot();

  Future<void> _reload() async {
    setState(_refresh);
    await _snapshot;
  }

  Future<void> _openEditor(
    AwarenessContentType type, [
    AwarenessContentSummary? item,
  ]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AwarenessContentEditorScreen(
          repository: _cmsRepository,
          type: type,
          item: item,
        ),
      ),
    );
    if (changed == true && mounted) await _reload();
  }

  Future<void> _newContent() async {
    final type = await showDialog<AwarenessContentType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Create learning content'),
        children: AwarenessContentType.values
            .map(
              (type) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, type),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _typeColor(type).withValues(alpha: .1),
                    child: Icon(_typeIcon(type), color: _typeColor(type)),
                  ),
                  title: Text(type.label),
                  subtitle: Text(_typeDescription(type)),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (type != null && mounted) await _openEditor(type);
  }

  Future<void> _changeStatus(
    AwarenessContentSummary item,
    String status,
  ) async {
    try {
      await _cmsRepository.setContentStatus(item, status);
      if (mounted) await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status could not be updated: $error')),
      );
    }
  }

  Future<void> _editPartner([AdminPartnerRecord? partner]) async {
    final draft = await showDialog<AdminPartnerDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PartnerEditorDialog(partner: partner),
    );
    if (draft == null || !mounted) return;
    try {
      await _cmsRepository.savePartner(draft);
      if (mounted) await _reload();
    } catch (error) {
      if (mounted) _showError('Partner could not be saved', error);
    }
  }

  Future<void> _archivePartner(AdminPartnerRecord partner) async {
    final approved = await _confirm(
      'Suspend this partner?',
      'Their vouchers will remain auditable, but new rewards cannot be published for ${partner.displayName}.',
    );
    if (!approved) return;
    try {
      await _cmsRepository.archivePartner(partner.id);
      if (mounted) await _reload();
    } catch (error) {
      if (mounted) _showError('Partner could not be suspended', error);
    }
  }

  Future<void> _editVoucher(
    AwarenessCmsSnapshot data, [
    AdminVoucherRecord? voucher,
  ]) async {
    final verified = data.partners
        .where((partner) => partner.isVerified)
        .toList();
    if (verified.isEmpty) {
      _showError(
        'A verified partner is required',
        'Review and verify a merchant partnership before deploying a voucher.',
      );
      return;
    }
    AdminVoucherDraft? existing;
    if (voucher != null) {
      try {
        existing = await _cmsRepository.getVoucher(voucher.id);
      } catch (error) {
        if (mounted) _showError('Voucher could not be loaded', error);
        return;
      }
    }
    if (!mounted) return;
    final draft = await showDialog<AdminVoucherDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => VoucherEditorDialog(partners: verified, draft: existing),
    );
    if (draft == null || !mounted) return;
    try {
      await _cmsRepository.saveVoucher(draft);
      if (mounted) await _reload();
    } catch (error) {
      if (mounted) _showError('Voucher could not be saved', error);
    }
  }

  Future<void> _archiveVoucher(AdminVoucherRecord voucher) async {
    final approved = await _confirm(
      'Archive this voucher?',
      'It will disappear from the traveller app. Existing claims and audit history stay intact.',
    );
    if (!approved) return;
    try {
      await _cmsRepository.archiveVoucher(voucher.id);
      if (mounted) await _reload();
    } catch (error) {
      if (mounted) _showError('Voucher could not be archived', error);
    }
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;

  void _showError(String title, Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title: $error')));
  }

  @override
  Widget build(BuildContext context) => AdminShell(
    selectedMenuItem: 'Awareness CMS',
    headerTitle: 'Educational Content Management',
    onSignOut: widget.onSignOut,
    onOpenDashboard: widget.onOpenDashboard,
    onOpenReports: widget.onOpenReports,
    onOpenHeatmap: widget.onOpenHeatmap,
    onOpenVerifiedMerchants: widget.onOpenVerifiedMerchants,
    onOpenThreatDatabase: widget.onOpenThreatDatabase,
    onOpenAwarenessCms: widget.onOpenAwarenessCms,
    onOpenSettings: widget.onOpenSettings,
    onOpenPublishScamCase: widget.onOpenPublishScamCase,
    child: FutureBuilder<AwarenessCmsSnapshot>(
      future: _snapshot,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return _CmsError(error: snapshot.error, onRetry: _reload);
        }
        final data = snapshot.data!;
        final items = _filter == 'all'
            ? data.contents
            : data.contents.where((item) => item.status == _filter).toList();
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _Heading(onCreate: _newContent),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Metric(
                    label: 'Lessons',
                    value: '${data.lessons}',
                    icon: Icons.menu_book_outlined,
                  ),
                  _Metric(
                    label: 'Active quizzes',
                    value: '${data.quizzes}',
                    icon: Icons.quiz_outlined,
                  ),
                  _Metric(
                    label: 'Scenarios',
                    value: '${data.scenarios}',
                    icon: Icons.alt_route,
                  ),
                  _Metric(
                    label: 'Draft items',
                    value: '${data.drafts}',
                    icon: Icons.edit_note_outlined,
                    accent: AppColors.amber,
                  ),
                  _Metric(
                    label: 'Voucher stock',
                    value: '${data.availableCodes}',
                    icon: Icons.confirmation_number_outlined,
                    accent: AppColors.green,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SurfaceCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified reward partners',
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'A merchant must pass partnership review before any voucher can be deployed.',
                                style: TextStyle(
                                  color: AppColors.slate,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _editPartner(),
                          icon: const Icon(Icons.add_business_outlined),
                          label: const Text('Add merchant'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (data.partners.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.amberSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'No partnership registry found. Apply the latest Module 5 migration, then add or review a merchant.',
                          style: TextStyle(color: AppColors.navy, fontSize: 10),
                        ),
                      )
                    else
                      ...data.partners.map(
                        (partner) => _PartnerRow(
                          partner: partner,
                          onEdit: () => _editPartner(partner),
                          onArchive: () => _archivePartner(partner),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SurfaceCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Learning content',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        DropdownButton<String>(
                          value: _filter,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('All statuses'),
                            ),
                            DropdownMenuItem(
                              value: 'published',
                              child: Text('Published'),
                            ),
                            DropdownMenuItem(
                              value: 'draft',
                              child: Text('Draft'),
                            ),
                            DropdownMenuItem(
                              value: 'archived',
                              child: Text('Archived'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _filter = value ?? 'all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 34),
                        child: Center(
                          child: Text('No content matches this filter.'),
                        ),
                      )
                    else
                      ...items.map(
                        (item) => _ContentRow(
                          item: item,
                          onEdit: () => _openEditor(item.type, item),
                          onStatus: (status) => _changeStatus(item, status),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SurfaceCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Reward inventory',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _editVoucher(data),
                          icon: const Icon(Icons.add_card_outlined),
                          label: const Text('Deploy voucher'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Published rewards are redeemable only while unique sponsor codes remain.',
                      style: TextStyle(color: AppColors.slate, fontSize: 10),
                    ),
                    const SizedBox(height: 12),
                    if (data.vouchers.isEmpty)
                      const Text('No rewards configured.')
                    else
                      ...data.vouchers.map(
                        (voucher) => _VoucherRow(
                          voucher: voucher,
                          onEdit: () => _editVoucher(data, voucher),
                          onArchive: () => _archiveVoucher(voucher),
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

class _Heading extends StatelessWidget {
  const _Heading({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Awareness CMS',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Publish lessons, visual quizzes, and scenario simulations to the traveller app.',
              style: TextStyle(color: AppColors.slate, fontSize: 11),
            ),
          ],
        ),
      ),
      FilledButton.icon(
        onPressed: onCreate,
        icon: const Icon(Icons.add),
        label: const Text('Add content'),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppColors.blue,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  @override
  Widget build(BuildContext context) => Container(
    width: 190,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: accent.withValues(alpha: .1),
          child: Icon(icon, color: accent, size: 19),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.slate, fontSize: 9),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ContentRow extends StatelessWidget {
  const _ContentRow({
    required this.item,
    required this.onEdit,
    required this.onStatus,
  });
  final AwarenessContentSummary item;
  final VoidCallback onEdit;
  final ValueChanged<String> onStatus;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: _typeColor(item.type).withValues(alpha: .1),
          child: Icon(
            _typeIcon(item.type),
            color: _typeColor(item.type),
            size: 18,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${item.referenceCode.isEmpty ? item.type.label : item.referenceCode} · ${item.category} · ${DateFormat('dd MMM yyyy, HH:mm').format(item.updatedAt.toLocal())}',
                style: const TextStyle(color: AppColors.slate, fontSize: 9),
              ),
            ],
          ),
        ),
        _Status(status: item.status),
        IconButton(
          tooltip: 'Edit',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, color: AppColors.blue),
        ),
        PopupMenuButton<String>(
          tooltip: 'Change status',
          onSelected: onStatus,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'published', child: Text('Publish')),
            PopupMenuItem(value: 'draft', child: Text('Move to draft')),
            PopupMenuItem(value: 'archived', child: Text('Archive')),
          ],
        ),
      ],
    ),
  );
}

class _VoucherRow extends StatelessWidget {
  const _VoucherRow({
    required this.voucher,
    required this.onEdit,
    required this.onArchive,
  });
  final AdminVoucherRecord voucher;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const CircleAvatar(
      backgroundColor: AppColors.greenSoft,
      child: Icon(Icons.redeem_outlined, color: AppColors.green),
    ),
    title: Text(
      '${voucher.referenceCode} · ${voucher.title}',
      style: const TextStyle(
        color: AppColors.navy,
        fontWeight: FontWeight.w800,
      ),
    ),
    subtitle: Text(
      '${voucher.partnerName} · costs ${voucher.requiredXp} XP · ${voucher.claimedCodes}/${voucher.totalCodes} redeemed',
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: voucher.availableCodes > 0
                ? AppColors.greenSoft
                : AppColors.redSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${voucher.availableCodes} available',
            style: TextStyle(
              color: voucher.availableCodes > 0
                  ? AppColors.green
                  : AppColors.red,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Edit voucher',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, color: AppColors.blue),
        ),
        IconButton(
          tooltip: 'Archive voucher',
          onPressed: onArchive,
          icon: const Icon(Icons.archive_outlined, color: AppColors.slate),
        ),
      ],
    ),
  );
}

class _PartnerRow extends StatelessWidget {
  const _PartnerRow({
    required this.partner,
    required this.onEdit,
    required this.onArchive,
  });
  final AdminPartnerRecord partner;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final verified = partner.isVerified;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: verified
                ? AppColors.greenSoft
                : AppColors.amberSoft,
            child: Icon(
              verified ? Icons.verified_outlined : Icons.fact_check_outlined,
              color: verified ? AppColors.green : AppColors.amber,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${partner.partnerCode} · ${partner.displayName}',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${partner.legalName} · ${partner.registrationNumber ?? 'Registration pending'} · ${partner.category}',
                  style: const TextStyle(color: AppColors.slate, fontSize: 9),
                ),
              ],
            ),
          ),
          _Status(status: partner.verificationStatus),
          IconButton(
            tooltip: 'Review or edit',
            onPressed: onEdit,
            icon: const Icon(
              Icons.manage_search_outlined,
              color: AppColors.blue,
            ),
          ),
          if (partner.isActive)
            IconButton(
              tooltip: 'Suspend partner',
              onPressed: onArchive,
              icon: const Icon(Icons.block_outlined, color: AppColors.red),
            ),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final positive = status == 'published' || status == 'verified';
    final negative =
        status == 'archived' || status == 'rejected' || status == 'suspended';
    final color = positive
        ? AppColors.green
        : negative
        ? AppColors.red
        : AppColors.amber;
    final background = positive
        ? AppColors.greenSoft
        : negative
        ? AppColors.redSoft
        : AppColors.amberSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CmsError extends StatelessWidget {
  const _CmsError({required this.error, required this.onRetry});
  final Object? error;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.red),
          const SizedBox(height: 12),
          const Text(
            'Awareness content could not be loaded',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Confirm the Module 5 Supabase migrations are installed, then retry.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.red, fontSize: 10),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

Color _typeColor(AwarenessContentType type) => switch (type) {
  AwarenessContentType.lesson => AppColors.blue,
  AwarenessContentType.quiz => const Color(0xFF7C3AED),
  AwarenessContentType.scenario => const Color(0xFFDB2777),
};

IconData _typeIcon(AwarenessContentType type) => switch (type) {
  AwarenessContentType.lesson => Icons.menu_book_outlined,
  AwarenessContentType.quiz => Icons.quiz_outlined,
  AwarenessContentType.scenario => Icons.alt_route,
};

String _typeDescription(AwarenessContentType type) => switch (type) {
  AwarenessContentType.lesson => 'Local safety guidance and hotspot tips',
  AwarenessContentType.quiz => 'Timed visual fraud-recognition question',
  AwarenessContentType.scenario => 'Choice-and-consequence simulation',
};

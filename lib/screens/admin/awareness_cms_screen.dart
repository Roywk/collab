import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/admin_repository.dart';
import '../../data/awareness_admin_repository.dart';
import '../../models/awareness_admin_models.dart';
import '../../services/awareness_report_export_service.dart';
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
  AwarenessContentType? _typeFilter;
  RealtimeChannel? _realtimeChannel;
  Timer? _reloadDebounce;
  bool _showAnalytics = false;
  Future<AwarenessAnalytics>? _analytics;
  final _reportExporter = AwarenessReportExportService();
  DateTime? _analyticsDate;
  String? _analyticsType;

  @override
  void initState() {
    super.initState();
    _cmsRepository = AwarenessAdminRepository(client: widget.repository.client);
    _refresh();
    _subscribeToChanges();
  }

  void _subscribeToChanges() {
    var channel = widget.repository.client.channel(
      'awareness-cms-${identityHashCode(this)}',
    );
    for (final table in const [
      'learning_lessons',
      'quiz_sets',
      'quiz_questions',
      'scenarios',
      'reward_partners',
      'reward_vouchers',
      'voucher_codes',
      'reward_partner_evidence',
      'user_completed_lessons',
      'user_completed_scenarios',
      'quiz_attempts',
      'user_claimed_vouchers',
    ]) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => _scheduleRealtimeReload(),
      );
    }
    _realtimeChannel = channel..subscribe();
  }

  void _scheduleRealtimeReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (_showAnalytics) {
        final nextAnalytics = _loadAnalytics();
        setState(() {
          _analytics = nextAnalytics;
        });
      }
      unawaited(_reload());
    });
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    final channel = _realtimeChannel;
    if (channel != null) {
      unawaited(widget.repository.client.removeChannel(channel));
    }
    super.dispose();
  }

  void _refresh() {
    _snapshot = _cmsRepository.getSnapshot();
  }

  Future<void> _reload() async {
    final nextSnapshot = _cmsRepository.getSnapshot();
    if (mounted) {
      setState(() {
        _snapshot = nextSnapshot;
      });
    }
    await nextSnapshot;
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

  Future<void> _deleteContent(AwarenessContentSummary item) async {
    final approved = await _confirm(
      'Delete ${item.type.label.toLowerCase()} permanently?',
      '“${item.title}” and its progress records will be permanently removed. This cannot be undone.',
    );
    if (!approved || !mounted) return;
    try {
      await _cmsRepository.deleteContent(item);
      if (mounted) await _reload();
    } catch (error) {
      if (mounted) _showError('Content could not be deleted', error);
    }
  }

  Future<void> _editPartner([AdminPartnerRecord? partner]) async {
    final draft = await showDialog<AdminPartnerDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          PartnerEditorDialog(repository: _cmsRepository, partner: partner),
    );
    if (draft == null || !mounted) return;
    try {
      await _cmsRepository.savePartner(draft);
      if (mounted) {
        await _reload();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Partner saved in the partnership registry. Deploy a voucher separately to publish a reward.',
              ),
            ),
          );
        }
      }
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

  Future<void> _deletePartner(AdminPartnerRecord partner) async {
    final approved = await _confirm(
      'Delete reward partner permanently?',
      '${partner.displayName}, its vouchers, codes and related claims will be permanently removed. This cannot be undone.',
    );
    if (!approved || !mounted) return;
    try {
      await _cmsRepository.deletePartner(partner.id);
      if (mounted) await _reload();
    } catch (error) {
      if (mounted) _showError('Partner could not be deleted', error);
    }
  }

  Future<void> _editVoucher([AdminVoucherRecord? voucher]) async {
    List<AdminPartnerRecord> verified;
    try {
      // Fetch at the moment the editor opens so a newly verified sponsor is
      // never omitted by the dashboard Future's older snapshot.
      final currentPartners = await _cmsRepository.getPartners();
      verified = currentPartners
          .where((partner) => partner.isVerified)
          .toList();
    } catch (error) {
      if (mounted) _showError('Verified sponsors could not be loaded', error);
      return;
    }
    if (!mounted) return;
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

  Future<void> _deleteVoucher(AdminVoucherRecord voucher) async {
    final approved = await _confirm(
      'Delete voucher permanently?',
      '${voucher.title}, all inventory codes and redemption records will be permanently removed. This cannot be undone.',
    );
    if (!approved || !mounted) return;
    try {
      await _cmsRepository.deleteVoucher(voucher.id);
      if (mounted) await _reload();
    } catch (error) {
      if (mounted) _showError('Voucher could not be deleted', error);
    }
  }

  Future<void> _showVoucherAudit(
    AdminVoucherRecord voucher,
  ) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${voucher.referenceCode} code inventory'),
      content: SizedBox(
        width: 560,
        child: voucher.codeInventory.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No unique voucher codes have been uploaded.'),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: voucher.codeInventory.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final item = voucher.codeInventory[index];
                  return ListTile(
                    leading: Icon(
                      item.status == 'claimed'
                          ? Icons.check_circle
                          : item.status == 'available'
                          ? Icons.confirmation_number_outlined
                          : Icons.block_outlined,
                      color: item.status == 'claimed'
                          ? AppColors.green
                          : item.status == 'available'
                          ? AppColors.blue
                          : AppColors.slate,
                    ),
                    title: SelectableText(item.code),
                    subtitle: item.claimedAt == null
                        ? null
                        : Text(
                            'Redeemed ${DateFormat('dd MMM yyyy, HH:mm').format(item.claimedAt!.toLocal())}',
                          ),
                    trailing: _Status(status: item.status),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

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

  void _openAnalytics() {
    setState(() {
      _showAnalytics = true;
      _analytics = _loadAnalytics();
    });
  }

  void _closeAnalytics() => setState(() => _showAnalytics = false);

  void _refreshAnalytics() {
    final nextAnalytics = _loadAnalytics();
    setState(() {
      _analytics = nextAnalytics;
    });
  }

  Future<AwarenessAnalytics> _loadAnalytics() {
    final from = _analyticsDate == null
        ? null
        : DateTime(
            _analyticsDate!.year,
            _analyticsDate!.month,
            _analyticsDate!.day,
          );
    return _cmsRepository.getAnalytics(
      from: from,
      to: from?.add(const Duration(days: 1)),
      activityType: _analyticsType,
    );
  }

  void _setAnalyticsFilters(DateTime? date, String? activityType) {
    _analyticsDate = date;
    _analyticsType = activityType;
    _refreshAnalytics();
  }

  Future<void> _exportAnalytics(
    AwarenessAnalytics data,
    List<AwarenessActivityEvent> activities,
  ) async {
    try {
      await _reportExporter.exportPdf(
        data: data,
        period: _analyticsDate == null
            ? 'All dates'
            : DateFormat('dd MMM yyyy').format(_analyticsDate!),
        category: _analyticsType ?? 'All activity types',
        activities: activities,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Awareness report PDF exported.')),
        );
      }
    } catch (error) {
      if (mounted) _showError('PDF could not be exported', error);
    }
  }

  @override
  Widget build(BuildContext context) => AdminShell(
    selectedMenuItem: 'Awareness CMS',
    headerTitle: _showAnalytics
        ? 'Awareness Performance & Audit'
        : 'Educational Content Management',
    onSignOut: widget.onSignOut,
    onOpenDashboard: widget.onOpenDashboard,
    onOpenReports: widget.onOpenReports,
    onOpenHeatmap: widget.onOpenHeatmap,
    onOpenVerifiedMerchants: widget.onOpenVerifiedMerchants,
    onOpenThreatDatabase: widget.onOpenThreatDatabase,
    onOpenAwarenessCms: widget.onOpenAwarenessCms,
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
        if (_showAnalytics) {
          return _AnalyticsView(
            future: _analytics ??= _loadAnalytics(),
            onBack: _closeAnalytics,
            onRefresh: _refreshAnalytics,
            selectedDate: _analyticsDate,
            activityType: _analyticsType,
            onFiltersChanged: _setAnalyticsFilters,
            onExport: _exportAnalytics,
          );
        }
        final items = data.contents.where((item) {
          final matchesStatus = _filter == 'all' || item.status == _filter;
          final matchesType = _typeFilter == null || item.type == _typeFilter;
          return matchesStatus && matchesType;
        }).toList();
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _Heading(onCreate: _newContent, onInsights: _openAnalytics),
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
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
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
                          onDelete: () => _deletePartner(partner),
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
                        const SizedBox(width: 12),
                        DropdownButton<AwarenessContentType?>(
                          value: _typeFilter,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('All content types'),
                            ),
                            DropdownMenuItem(
                              value: AwarenessContentType.lesson,
                              child: Text('Lessons'),
                            ),
                            DropdownMenuItem(
                              value: AwarenessContentType.quiz,
                              child: Text('Quizzes'),
                            ),
                            DropdownMenuItem(
                              value: AwarenessContentType.scenario,
                              child: Text('Scenarios'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _typeFilter = value),
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
                          onDelete: () => _deleteContent(item),
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
                          onPressed: _editVoucher,
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
                          onEdit: () => _editVoucher(voucher),
                          onArchive: () => _archiveVoucher(voucher),
                          onDelete: () => _deleteVoucher(voucher),
                          onAudit: () => _showVoucherAudit(voucher),
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
  const _Heading({required this.onCreate, required this.onInsights});
  final VoidCallback onCreate;
  final VoidCallback onInsights;
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
      Wrap(
        spacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: onInsights,
            icon: const Icon(Icons.insights_outlined),
            label: const Text('Performance report'),
          ),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Add content'),
          ),
        ],
      ),
    ],
  );
}

class _AnalyticsView extends StatefulWidget {
  const _AnalyticsView({
    required this.future,
    required this.onBack,
    required this.onRefresh,
    required this.selectedDate,
    required this.activityType,
    required this.onFiltersChanged,
    required this.onExport,
  });
  final Future<AwarenessAnalytics> future;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final DateTime? selectedDate;
  final String? activityType;
  final void Function(DateTime? date, String? activityType) onFiltersChanged;
  final Future<void> Function(
    AwarenessAnalytics data,
    List<AwarenessActivityEvent> activities,
  )
  onExport;

  @override
  State<_AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<_AnalyticsView> {
  final _userSearch = TextEditingController();
  bool _latestFirst = true;

  @override
  void dispose() {
    _userSearch.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) widget.onFiltersChanged(picked, widget.activityType);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AwarenessAnalytics>(
    future: widget.future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }
      if (snapshot.hasError) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.query_stats, size: 42, color: AppColors.red),
              const SizedBox(height: 10),
              const Text('Performance data is unavailable.'),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: widget.onRefresh,
                child: const Text('Try again'),
              ),
            ],
          ),
        );
      }
      final data = snapshot.data!;
      final query = _userSearch.text.trim().toLowerCase();
      final activities =
          data.activities
              .where(
                (event) =>
                    query.isEmpty ||
                    event.userName.toLowerCase().contains(query),
              )
              .toList()
            ..sort(
              (a, b) => _latestFirst
                  ? b.occurredAt.compareTo(a.occurredAt)
                  : a.occurredAt.compareTo(b.occurredAt),
            );
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back to Awareness CMS',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance report',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Learning engagement, outcomes, XP and reward audit trail.',
                      style: TextStyle(color: AppColors.slate),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh report',
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  widget.selectedDate == null
                      ? 'All dates'
                      : DateFormat('dd MMM yyyy').format(widget.selectedDate!),
                ),
              ),
              if (widget.selectedDate != null)
                IconButton(
                  tooltip: 'Clear date',
                  onPressed: () =>
                      widget.onFiltersChanged(null, widget.activityType),
                  icon: const Icon(Icons.clear),
                ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String?>(
                  initialValue: widget.activityType,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Activity type'),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text(
                        'All activity types',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(value: 'Lesson', child: Text('Lessons')),
                    DropdownMenuItem(value: 'Quiz', child: Text('Quiz')),
                    DropdownMenuItem(
                      value: 'Scenario',
                      child: Text('Scenario'),
                    ),
                    DropdownMenuItem(value: 'Voucher', child: Text('Voucher')),
                  ],
                  onChanged: (value) =>
                      widget.onFiltersChanged(widget.selectedDate, value),
                ),
              ),
              SizedBox(
                width: 230,
                child: TextField(
                  controller: _userSearch,
                  decoration: const InputDecoration(
                    labelText: 'Search user name',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: 145,
                child: DropdownButtonFormField<bool>(
                  initialValue: _latestFirst,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Sort by'),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Latest')),
                    DropdownMenuItem(value: false, child: Text('Oldest')),
                  ],
                  onChanged: (value) =>
                      setState(() => _latestFirst = value ?? true),
                ),
              ),
              FilledButton.icon(
                onPressed: () => widget.onExport(data, activities),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Export PDF'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(
                label: 'Active learners',
                value: '${data.activeLearners}',
                icon: Icons.groups_outlined,
              ),
              _Metric(
                label: 'Lesson completions',
                value: '${data.lessonCompletions}',
                icon: Icons.menu_book_outlined,
              ),
              _Metric(
                label: 'Scenario completions',
                value: '${data.scenarioCompletions}',
                icon: Icons.alt_route,
              ),
              _Metric(
                label: 'Quiz attempts',
                value: '${data.quizAttempts}',
                icon: Icons.quiz_outlined,
              ),
              _Metric(
                label: 'XP awarded',
                value: '${data.xpAwarded}',
                icon: Icons.bolt_outlined,
                accent: AppColors.amber,
              ),
              _Metric(
                label: 'Voucher claims',
                value: '${data.voucherClaims}',
                icon: Icons.redeem_outlined,
                accent: AppColors.green,
              ),
              _Metric(
                label: 'Voucher uses',
                value: '${data.voucherUses}',
                icon: Icons.task_alt,
                accent: AppColors.green,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quiz graduation rate',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: data.quizPassRate,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(12),
                  backgroundColor: AppColors.line,
                  color: AppColors.green,
                ),
                const SizedBox(height: 7),
                Text(
                  '${(data.quizPassRate * 100).round()}% · ${data.quizPasses} of ${data.quizAttempts} attempts graduated',
                  style: const TextStyle(color: AppColors.slate),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detailed activity audit',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                if (activities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('No activity matches these filters.'),
                    ),
                  )
                else
                  for (final event in activities)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.greenSoft,
                        child: Icon(
                          event.activityType == 'Voucher'
                              ? Icons.redeem_outlined
                              : event.activityType == 'Lesson'
                              ? Icons.menu_book_outlined
                              : event.activityType == 'Scenario'
                              ? Icons.alt_route
                              : Icons.quiz_outlined,
                          color: AppColors.green,
                        ),
                      ),
                      title: Text('${event.userName} · ${event.activityType}'),
                      subtitle: Text(
                        '${event.contentTitle} · ${event.category} · ${DateFormat('dd MMM yyyy, HH:mm').format(event.occurredAt.toLocal())}',
                      ),
                      trailing: event.activityType == 'Voucher'
                          ? _Status(
                              status: event.voucherUsed ? 'used' : 'claimed',
                            )
                          : null,
                    ),
              ],
            ),
          ),
        ],
      );
    },
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
    required this.onDelete,
  });
  final AwarenessContentSummary item;
  final VoidCallback onEdit;
  final ValueChanged<String> onStatus;
  final VoidCallback onDelete;
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
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'published', child: Text('Publish')),
            const PopupMenuItem(value: 'draft', child: Text('Move to draft')),
            const PopupMenuItem(value: 'archived', child: Text('Archive')),
            PopupMenuItem(
              onTap: onDelete,
              child: const Row(
                children: [
                  Icon(Icons.delete_outline, color: AppColors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Delete permanently'),
                ],
              ),
            ),
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
    required this.onAudit,
    required this.onDelete,
  });
  final AdminVoucherRecord voucher;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onAudit;
  final VoidCallback onDelete;
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
        _Status(status: voucher.status),
        const SizedBox(width: 8),
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
          tooltip: 'View code inventory and claims',
          onPressed: onAudit,
          icon: const Icon(Icons.inventory_2_outlined, color: AppColors.blue),
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
        IconButton(
          tooltip: 'Delete voucher permanently',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_forever_outlined, color: AppColors.red),
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
    required this.onDelete,
  });
  final AdminPartnerRecord partner;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final verified = partner.verificationStatus == 'verified';
    final identity = Row(
      children: [
        CircleAvatar(
          backgroundColor: verified ? AppColors.greenSoft : AppColors.amberSoft,
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
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.slate, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
    final actions = <Widget>[
      _Status(status: partner.verificationStatus),
      IconButton(
        tooltip: 'Review, view evidence, or edit',
        onPressed: onEdit,
        icon: const Icon(Icons.manage_search_outlined, color: AppColors.blue),
      ),
      if (partner.isActive)
        IconButton(
          tooltip: 'Suspend partner',
          onPressed: onArchive,
          icon: const Icon(Icons.block_outlined, color: AppColors.red),
        ),
      IconButton(
        tooltip: 'Delete partner permanently',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_forever_outlined, color: AppColors.red),
      ),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 620) {
            return Row(
              children: [
                Expanded(child: identity),
                ...actions,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              identity,
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              ),
            ],
          );
        },
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

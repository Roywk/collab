import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/admin_repository.dart';
import 'admin_shell.dart';
import 'awareness_article_editor_screen.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../data/admin_bank_repository.dart';
import '../../data/admin_facility_repository.dart';
import '../../data/admin_repository.dart';
import '../../data/awareness_admin_repository.dart';
import '../../data/scam_map_repository.dart';
import '../../models/awareness_admin_models.dart';
import 'admin_bank_hotline_screen.dart';
import 'admin_emergency_facility_screen.dart';
import 'admin_shell.dart';
import 'awareness_content_editor_screen.dart';
import 'threat_database_screen.dart';
import 'threat_heatmap_screen.dart';

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
    super.key,
  });

  final AwarenessAdminRepository repository;
  final Future<void> Function() onSignOut;

  @override
  State<AwarenessCmsScreen> createState() => _AwarenessCmsScreenState();
}

class _AwarenessCmsScreenState extends State<AwarenessCmsScreen> {
  late Future<List<Map<String, dynamic>>> _contentFuture;
  final TextEditingController _searchController = TextEditingController();
  late Future<AwarenessCmsSnapshot> _snapshot;
  AwarenessContentType? _typeFilter;
  String _statusFilter = 'all';
  int _section = 0;
  String? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshContent();
  }

  void _refreshContent() {
    setState(() {
      _contentFuture = widget.repository.getAwarenessContent();
    });
  }

  void _openEditor([String? articleId]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AwarenessArticleEditorScreen(
          articleId: articleId,
          repository: widget.repository,
        ),
      ),
    );
    if (result == true) {
      _refreshContent();
    }
  }

    _snapshot = widget.repository.getSnapshot();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _snapshot = widget.repository.getSnapshot();
    });
  }

  Future<void> _openEditor({
    required AwarenessContentType type,
    AwarenessContentSummary? item,
  }) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AwarenessContentEditorScreen(
          repository: widget.repository,
          type: type,
          item: item,
        ),
      ),
    );
    if (changed == true) {
      _message = item == null
          ? 'Content created successfully.'
          : 'Changes saved.';
      _reload();
    }
  }

  Future<void> _changeStatus(
    AwarenessContentSummary item,
    String status,
  ) async {
    final verb = status == 'published' ? 'Publish' : 'Move to draft';
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Align(
          alignment: Alignment.centerLeft,
          child: CircleAvatar(
            backgroundColor: status == 'published'
                ? AppColors.greenSoft
                : AppColors.amberSoft,
            child: Icon(
              status == 'published'
                  ? Icons.rocket_launch_outlined
                  : Icons.edit_note,
              color: status == 'published' ? AppColors.green : AppColors.amber,
            ),
          ),
        ),
        title: Text('$verb content?'),
        content: Text(
          status == 'published'
              ? '“${item.title}” will immediately become available in the tourist app.'
              : '“${item.title}” will no longer be visible to tourists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              status == 'published' ? 'Publish now' : 'Save as draft',
            ),
          ),
        ],
      ),
    );
    if (approved != true) return;
    await _run(
      () => widget.repository.setContentStatus(item, status),
      success: status == 'published'
          ? 'Published to the tourist app.'
          : 'Content returned to drafts.',
    );
  }

  Future<void> _archive(AwarenessContentSummary item) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive content?'),
        content: Text(
          '“${item.title}” will be hidden from tourists and removed from the active list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (approved == true) {
      await _run(
        () => widget.repository.archiveContent(item),
        success: 'Content archived.',
      );
    }
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String success,
  }) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _message = success);
      _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Changes could not be saved: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openVoucher([AdminVoucherRecord? voucher]) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _VoucherEditorDialog(repository: widget.repository, voucher: voucher),
    );
    if (changed == true) {
      _message = voucher == null ? 'Reward created.' : 'Reward updated.';
      _reload();
    }
  }

  void _replace(Widget screen) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenuItem: 'Awareness CMS',
      onSignOut: widget.onSignOut,
      onOpenDashboard: widget.onOpenDashboard,
      onOpenReports: widget.onOpenReports,
      onOpenHeatmap: widget.onOpenHeatmap,
      onOpenVerifiedMerchants: widget.onOpenVerifiedMerchants,
      onOpenThreatDatabase: widget.onOpenThreatDatabase,
      onOpenAwarenessCms: widget.onOpenAwarenessCms,
      onOpenSettings: widget.onOpenSettings,
      onOpenPublishScamCase: widget.onOpenPublishScamCase,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final content = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Awareness CMS',
                        style: TextStyle(color: AppColors.navy, fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      Text('Manage educational articles and emergency alerts.',
                          style: TextStyle(color: AppColors.slate, fontSize: 13)),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Article'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 350),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Article Title')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Last Updated')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: content.map((item) {
                        return DataRow(
                          cells: [
                            DataCell(Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(item['category'] ?? '')),
                            DataCell(_buildStatusBadge(item['status'] ?? 'Draft')),
                            DataCell(Text(item['updated_at'] ?? '—')),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppColors.blue, size: 20),
                                    onPressed: () => _openEditor(item['id']?.toString()),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () {
                                      // Add delete confirmation
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isPublished = status == 'Published';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(color: isPublished ? Colors.green : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
      headerTitle: 'Educational Content Management',
      showTopBar: false,
      onSignOut: widget.onSignOut,
      onOpenAwareness: () {},
      onOpenThreatDatabase: () => _replace(
        ThreatDatabaseScreen(
          repository: AdminRepository(client: widget.repository.client),
          onSignOut: widget.onSignOut,
        ),
      ),
      onOpenHeatmap: () => _replace(
        ThreatHeatmapScreen(
          repository: ScamMapRepository(client: widget.repository.client),
        ),
      ),
      onOpenBankHotlines: () => _replace(
        AdminBankHotlineScreen(
          repository: SupabaseAdminBankRepository(
            client: widget.repository.client,
          ),
          onSignOut: widget.onSignOut,
        ),
      ),
      onOpenEmergencyFacilities: () => _replace(
        AdminEmergencyFacilityScreen(
          repository: SupabaseAdminFacilityRepository(
            client: widget.repository.client,
          ),
          onSignOut: widget.onSignOut,
        ),
      ),
      child: Stack(
        children: [
          FutureBuilder<AwarenessCmsSnapshot>(
            future: _snapshot,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snapshot.hasError) {
                return _CmsError(error: snapshot.error, onRetry: _reload);
              }
              return _buildDashboard(snapshot.data!);
            },
          ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x330F172A),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboard(AwarenessCmsSnapshot data) {
    final query = _searchController.text.trim().toLowerCase();
    final items = data.contents.where((item) {
      final matchesSearch =
          query.isEmpty ||
          item.referenceCode.toLowerCase().contains(query) ||
          item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      final matchesType = _typeFilter == null || item.type == _typeFilter;
      final matchesStatus =
          _statusFilter == 'all' || item.status == _statusFilter;
      return matchesSearch && matchesType && matchesStatus;
    }).toList();

    return Column(
      children: [
        _CmsHeader(
          selectedSection: _section,
          onSectionChanged: (value) => setState(() => _section = value),
          onAdd: () {
            if (_section == 1) {
              _openVoucher();
            } else {
              _showContentTypePicker();
            }
          },
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              if (_message != null) ...[
                _SuccessBanner(
                  message: _message!,
                  onClose: () => setState(() => _message = null),
                ),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard(
                    label: 'TOTAL LESSONS',
                    value: '${data.lessons}',
                    detail: 'Safety guides',
                    icon: Icons.menu_book_outlined,
                    color: AppColors.blue,
                  ),
                  _MetricCard(
                    label: 'ACTIVE QUIZZES',
                    value: '${data.quizzes}',
                    detail: 'Recognition checks',
                    icon: Icons.quiz_outlined,
                    color: const Color(0xFF7C3AED),
                  ),
                  _MetricCard(
                    label: 'SCENARIOS',
                    value: '${data.scenarios}',
                    detail: 'Choice & consequence',
                    icon: Icons.alt_route,
                    color: const Color(0xFFDB2777),
                  ),
                  _MetricCard(
                    label: 'DRAFT ITEMS',
                    value: '${data.drafts}',
                    detail: '${data.published} live',
                    icon: Icons.edit_note,
                    color: AppColors.amber,
                  ),
                  _MetricCard(
                    label: 'VOUCHER STOCK',
                    value: '${data.availableCodes}',
                    detail: 'Codes available',
                    icon: Icons.confirmation_number_outlined,
                    color: AppColors.green,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (_section == 0)
                _ContentPanel(
                  items: items,
                  searchController: _searchController,
                  typeFilter: _typeFilter,
                  statusFilter: _statusFilter,
                  onSearch: (_) => setState(() {}),
                  onTypeChanged: (value) => setState(() => _typeFilter = value),
                  onStatusChanged: (value) =>
                      setState(() => _statusFilter = value),
                  onEdit: (item) => _openEditor(type: item.type, item: item),
                  onStatus: _changeStatus,
                  onArchive: _archive,
                )
              else
                _RewardsPanel(
                  vouchers: data.vouchers,
                  onAdd: () => _openVoucher(),
                  onEdit: _openVoucher,
                  onStatus: (voucher, status) => _run(
                    () =>
                        widget.repository.setVoucherStatus(voucher.id, status),
                    success: status == 'published'
                        ? 'Reward published.'
                        : 'Reward paused.',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showContentTypePicker() async {
    final type = await showModalBottomSheet<AwarenessContentType>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What would you like to create?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a learning format for the tourist app.',
                style: TextStyle(color: AppColors.slate, fontSize: 12),
              ),
              const SizedBox(height: 18),
              for (final option in AwarenessContentType.values)
                ListTile(
                  onTap: () => Navigator.pop(context, option),
                  leading: CircleAvatar(
                    backgroundColor: _typeColor(option).withValues(alpha: .12),
                    child: Icon(_typeIcon(option), color: _typeColor(option)),
                  ),
                  title: Text(
                    option.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(switch (option) {
                    AwarenessContentType.lesson =>
                      'A structured guide with red flags and hotspot tips',
                    AwarenessContentType.quiz =>
                      'A timed visual fraud recognition question',
                    AwarenessContentType.scenario =>
                      'A branching choice-and-consequence simulation',
                  }),
                  trailing: const Icon(Icons.chevron_right),
                ),
            ],
          ),
        ),
      ),
    );
    if (type != null && mounted) _openEditor(type: type);
  }
}

class _CmsHeader extends StatelessWidget {
  const _CmsHeader({
    required this.selectedSection,
    required this.onSectionChanged,
    required this.onAdd,
  });

  final int selectedSection;
  final ValueChanged<int> onSectionChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 15, 24, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.auto_stories_outlined,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Educational Content Management',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Publish scam-awareness training directly to the tourist experience',
                  style: TextStyle(color: AppColors.slate, fontSize: 10),
                ),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width > 740) ...[
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Learning content'),
                  icon: Icon(Icons.library_books_outlined, size: 17),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Rewards'),
                  icon: Icon(Icons.card_giftcard, size: 17),
                ),
              ],
              selected: {selectedSection},
              onSelectionChanged: (value) => onSectionChanged(value.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
            const SizedBox(width: 12),
          ],
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 17),
            label: Text(selectedSection == 0 ? 'Add content' : 'Add reward'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            backgroundColor: color.withValues(alpha: .1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(color: AppColors.muted, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentPanel extends StatelessWidget {
  const _ContentPanel({
    required this.items,
    required this.searchController,
    required this.typeFilter,
    required this.statusFilter,
    required this.onSearch,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onEdit,
    required this.onStatus,
    required this.onArchive,
  });

  final List<AwarenessContentSummary> items;
  final TextEditingController searchController;
  final AwarenessContentType? typeFilter;
  final String statusFilter;
  final ValueChanged<String> onSearch;
  final ValueChanged<AwarenessContentType?> onTypeChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<AwarenessContentSummary> onEdit;
  final void Function(AwarenessContentSummary, String) onStatus;
  final ValueChanged<AwarenessContentSummary> onArchive;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const SizedBox(
                  width: 190,
                  child: Text(
                    'Content library',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearch,
                    decoration: const InputDecoration(
                      hintText: 'Search title or category...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                  ),
                ),
                _FilterDropdown<AwarenessContentType?>(
                  value: typeFilter,
                  hint: 'All formats',
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All formats')),
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
                  onChanged: onTypeChanged,
                ),
                _FilterDropdown<String>(
                  value: statusFilter,
                  hint: 'Status',
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All statuses')),
                    DropdownMenuItem(
                      value: 'published',
                      child: Text('Published'),
                    ),
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(
                      value: 'archived',
                      child: Text('Archived'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onStatusChanged(value);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (items.isEmpty)
            const _EmptyState(
              icon: Icons.search_off,
              title: 'No matching content',
              subtitle: 'Try changing the search or filter selection.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 760) {
                  return Column(
                    children: [
                      for (final item in items)
                        _ContentMobileTile(
                          item: item,
                          onEdit: onEdit,
                          onStatus: onStatus,
                          onArchive: onArchive,
                        ),
                    ],
                  );
                }
                return _ContentTable(
                  items: items,
                  onEdit: onEdit,
                  onStatus: onStatus,
                  onArchive: onArchive,
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Showing ${items.length} content item${items.length == 1 ? '' : 's'}',
              style: const TextStyle(color: AppColors.muted, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentTable extends StatelessWidget {
  const _ContentTable({
    required this.items,
    required this.onEdit,
    required this.onStatus,
    required this.onArchive,
  });
  final List<AwarenessContentSummary> items;
  final ValueChanged<AwarenessContentSummary> onEdit;
  final void Function(AwarenessContentSummary, String) onStatus;
  final ValueChanged<AwarenessContentSummary> onArchive;

  @override
  Widget build(BuildContext context) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
      columnSpacing: 22,
      columns: const [
        DataColumn(label: Text('TITLE')),
        DataColumn(label: Text('FORMAT')),
        DataColumn(label: Text('CATEGORY')),
        DataColumn(label: Text('STATUS')),
        DataColumn(label: Text('UPDATED')),
        DataColumn(label: Text('ACTIONS')),
      ],
      rows: items
          .map(
            (item) => DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 230,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.referenceCode,
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(_TypeBadge(type: item.type)),
                DataCell(
                  Text(
                    item.category,
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 10,
                    ),
                  ),
                ),
                DataCell(_StatusBadge(status: item.status)),
                DataCell(
                  Text(
                    DateFormat(
                      'dd MMM yyyy\nHH:mm',
                    ).format(item.updatedAt.toLocal()),
                    style: const TextStyle(color: AppColors.slate, fontSize: 9),
                  ),
                ),
                DataCell(
                  _ContentActions(
                    item: item,
                    onEdit: onEdit,
                    onStatus: onStatus,
                    onArchive: onArchive,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _ContentMobileTile extends StatelessWidget {
  const _ContentMobileTile({
    required this.item,
    required this.onEdit,
    required this.onStatus,
    required this.onArchive,
  });
  final AwarenessContentSummary item;
  final ValueChanged<AwarenessContentSummary> onEdit;
  final void Function(AwarenessContentSummary, String) onStatus;
  final ValueChanged<AwarenessContentSummary> onArchive;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.referenceCode,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                children: [
                  _TypeBadge(type: item.type),
                  _StatusBadge(status: item.status),
                ],
              ),
            ],
          ),
        ),
        _ContentActions(
          item: item,
          onEdit: onEdit,
          onStatus: onStatus,
          onArchive: onArchive,
        ),
      ],
    ),
  );
}

class _ContentActions extends StatelessWidget {
  const _ContentActions({
    required this.item,
    required this.onEdit,
    required this.onStatus,
    required this.onArchive,
  });
  final AwarenessContentSummary item;
  final ValueChanged<AwarenessContentSummary> onEdit;
  final void Function(AwarenessContentSummary, String) onStatus;
  final ValueChanged<AwarenessContentSummary> onArchive;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Edit',
        visualDensity: VisualDensity.compact,
        onPressed: () => onEdit(item),
        icon: const Icon(Icons.edit_outlined, size: 18),
      ),
      PopupMenuButton<String>(
        tooltip: 'More actions',
        icon: const Icon(Icons.more_horiz, size: 18),
        onSelected: (value) {
          if (value == 'archive') {
            onArchive(item);
          } else {
            onStatus(item, value);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: item.isPublished ? 'draft' : 'published',
            child: Text(item.isPublished ? 'Move to draft' : 'Publish now'),
          ),
          const PopupMenuItem(value: 'archive', child: Text('Archive')),
        ],
      ),
    ],
  );
}

class _RewardsPanel extends StatelessWidget {
  const _RewardsPanel({
    required this.vouchers,
    required this.onAdd,
    required this.onEdit,
    required this.onStatus,
  });
  final List<AdminVoucherRecord> vouchers;
  final VoidCallback onAdd;
  final ValueChanged<AdminVoucherRecord> onEdit;
  final void Function(AdminVoucherRecord, String) onStatus;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reward inventory',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Manage partner vouchers and monitor live code stock.',
                      style: TextStyle(color: AppColors.slate, fontSize: 10),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New reward'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (vouchers.isEmpty)
          const _EmptyState(
            icon: Icons.card_giftcard,
            title: 'No rewards yet',
            subtitle:
                'Create a partner reward and upload unique voucher codes.',
          )
        else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: vouchers
                  .map(
                    (voucher) => _VoucherCard(
                      voucher: voucher,
                      onEdit: onEdit,
                      onStatus: onStatus,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    ),
  );
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.voucher,
    required this.onEdit,
    required this.onStatus,
  });
  final AdminVoucherRecord voucher;
  final ValueChanged<AdminVoucherRecord> onEdit;
  final void Function(AdminVoucherRecord, String) onStatus;
  @override
  Widget build(BuildContext context) {
    final ratio = voucher.totalCodes == 0
        ? 0.0
        : voucher.availableCodes / voucher.totalCodes;
    return Container(
      width: 315,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.greenSoft,
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${voucher.referenceCode} · ${voucher.partnerName}',
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      voucher.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: voucher.status),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            voucher.discountAmount,
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '${voucher.requiredXp} XP required · ends ${DateFormat('dd MMM yyyy').format(voucher.validUntil)}',
            style: const TextStyle(color: AppColors.slate, fontSize: 10),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AVAILABLE STOCK',
                style: TextStyle(
                  color: AppColors.slate,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${voucher.availableCodes} / ${voucher.totalCodes}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: AppColors.line,
            color: ratio < .2 ? AppColors.red : AppColors.green,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onEdit(voucher),
                  child: const Text('Edit & add codes'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: voucher.status == 'published'
                    ? 'Pause reward'
                    : 'Publish reward',
                onPressed: () => onStatus(
                  voucher,
                  voucher.status == 'published' ? 'draft' : 'published',
                ),
                icon: Icon(
                  voucher.status == 'published'
                      ? Icons.pause_circle_outline
                      : Icons.publish_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoucherEditorDialog extends StatefulWidget {
  const _VoucherEditorDialog({required this.repository, this.voucher});
  final AwarenessAdminRepository repository;
  final AdminVoucherRecord? voucher;
  @override
  State<_VoucherEditorDialog> createState() => _VoucherEditorDialogState();
}

class _VoucherEditorDialogState extends State<_VoucherEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _partner;
  late final TextEditingController _title;
  late final TextEditingController _discount;
  late final TextEditingController _xp;
  late final TextEditingController _codes;
  late DateTime _validUntil;
  String _status = 'draft';
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final item = widget.voucher;
    _partner = TextEditingController(text: item?.partnerName ?? '');
    _title = TextEditingController(text: item?.title ?? '');
    _discount = TextEditingController(text: item?.discountAmount ?? '');
    _xp = TextEditingController(text: '${item?.requiredXp ?? 400}');
    _codes = TextEditingController();
    _validUntil =
        item?.validUntil ?? DateTime.now().add(const Duration(days: 90));
    _status = item?.status ?? 'draft';
  }

  @override
  void dispose() {
    for (final controller in [_partner, _title, _discount, _xp, _codes]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.repository.saveVoucher(
        AdminVoucherDraft(
          id: widget.voucher?.id,
          partnerName: _partner.text.trim(),
          title: _title.text.trim(),
          discountAmount: _discount.text.trim(),
          requiredXp: int.parse(_xp.text),
          validUntil: _validUntil,
          status: _status,
          codes: _codes.text.split(RegExp(r'[\n,;]+')),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reward could not be saved: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.voucher == null
          ? 'Create partner reward'
          : 'Edit reward inventory',
    ),
    content: SizedBox(
      width: 620,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reward details',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _partner,
                      decoration: const InputDecoration(
                        labelText: 'Partner name',
                      ),
                      validator: _required,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _discount,
                      decoration: const InputDecoration(
                        labelText: 'Benefit (e.g. 15% OFF)',
                      ),
                      validator: _required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Reward title'),
                validator: _required,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _xp,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Required XP',
                      ),
                      validator: (value) => int.tryParse(value ?? '') == null
                          ? 'Enter a number'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 1825),
                          ),
                          initialDate: _validUntil,
                        );
                        if (picked != null) {
                          setState(() => _validUntil = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: Text(
                        'Valid until ${DateFormat('dd MMM yyyy').format(_validUntil)}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Add unique voucher codes',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _codes,
                minLines: 4,
                maxLines: 7,
                decoration: InputDecoration(
                  hintText: 'HOTEL-7M4K\nHOTEL-P9Q2\nHOTEL-X3BD',
                  helperText: widget.voucher == null
                      ? 'One code per line. Codes must be unique.'
                      : 'Only new codes are added; claimed codes remain protected.',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _status == 'published',
                onChanged: (value) =>
                    setState(() => _status = value ? 'published' : 'draft'),
                title: const Text(
                  'Publish to eligible tourists',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Only published rewards with available codes can be claimed.',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_outlined, size: 17),
        label: const Text('Save reward'),
      ),
    ],
  );
}

class _CmsError extends StatelessWidget {
  const _CmsError({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 560,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.redSoft),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.redSoft,
            child: Icon(Icons.storage_outlined, color: AppColors.red),
          ),
          const SizedBox(height: 12),
          const Text(
            'Awareness CMS needs its database migration',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Run the Module 5 SQL migration in Supabase, then retry. Existing teammate tables are preserved.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.red, fontSize: 9),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 17),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message, required this.onClose});
  final String message;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.greenCanvas,
      border: Border.all(color: AppColors.greenSoft),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: AppColors.green,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: onClose,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close, size: 16),
        ),
      ],
    ),
  );
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final AwarenessContentType type;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _typeColor(type).withValues(alpha: .1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      type.label,
      style: TextStyle(
        color: _typeColor(type),
        fontSize: 8,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'published' => AppColors.green,
      'draft' => AppColors.amber,
      _ => AppColors.slate,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });
  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 155,
    child: DropdownButtonFormField<T>(
      initialValue: value,
      isDense: true,
      decoration: InputDecoration(hintText: hint),
      items: items,
      onChanged: onChanged,
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(38),
    child: Center(
      child: Column(
        children: [
          Icon(icon, color: AppColors.muted, size: 34),
          const SizedBox(height: 9),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.slate, fontSize: 10),
          ),
        ],
      ),
    ),
  );
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Required' : null;

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

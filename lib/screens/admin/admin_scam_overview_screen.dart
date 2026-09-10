import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/admin_bank_repository.dart';
import '../../data/admin_facility_repository.dart';
import '../../data/admin_repository.dart';
import '../../data/scam_map_repository.dart';
import '../../models/scam_map_models.dart';
import 'admin_bank_hotline_screen.dart';
import 'admin_emergency_facility_screen.dart';
import 'admin_shell.dart';
import 'manual_scam_case_screen.dart';
import 'threat_database_screen.dart';
import 'threat_heatmap_screen.dart';

class AdminScamOverviewScreen extends StatefulWidget {
  const AdminScamOverviewScreen({
    required this.repository,
    required this.onSignOut,
    super.key,
  });

  final AdminRepository repository;
  final Future<void> Function() onSignOut;

  @override
  State<AdminScamOverviewScreen> createState() =>
      _AdminScamOverviewScreenState();
}

class _AdminScamOverviewScreenState extends State<AdminScamOverviewScreen> {
  late final ScamMapRepository _scamRepository;
  late Future<ScamMapLoadResult> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _scamRepository = ScamMapRepository(client: widget.repository.client);
    _reload();
  }

  void _reload() {
    _reportsFuture = _scamRepository.getThreatAnalyticsReports();
  }

  Future<void> _openThreatDatabase() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ThreatDatabaseScreen(
          repository: widget.repository,
          onSignOut: widget.onSignOut,
          onOpenDashboard: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _openHeatmap() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ThreatHeatmapScreen(repository: _scamRepository),
      ),
    );
  }

  Future<void> _openManualCase() async {
    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => ManualScamCaseScreen(repository: _scamRepository),
      ),
    );
    if (published == true && mounted) setState(_reload);
  }

  Future<void> _openBankHotlines() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AdminBankHotlineScreen(
          repository: SupabaseAdminBankRepository(
            client: widget.repository.client,
          ),
          onSignOut: widget.onSignOut,
        ),
      ),
    );
  }

  Future<void> _openEmergencyFacilities() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AdminEmergencyFacilityScreen(
          repository: SupabaseAdminFacilityRepository(
            client: widget.repository.client,
          ),
          onSignOut: widget.onSignOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenuItem: 'Dashboard Overview',
      headerTitle: 'Scam Alert & Map Overview',
      onOpenDashboard: () {},
      onOpenThreatDatabase: _openThreatDatabase,
      onOpenHeatmap: _openHeatmap,
      onPublishScamCase: _openManualCase,
      onOpenBankHotlines: _openBankHotlines,
      onOpenEmergencyFacilities: _openEmergencyFacilities,
      onSignOut: widget.onSignOut,
      child: FutureBuilder<ScamMapLoadResult>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: _OverviewPanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 42),
                    const SizedBox(height: 10),
                    const Text('Could not load scam-map analytics.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(_reload),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final reports = snapshot.data?.reports ?? const <ScamMapReport>[];
          final analytics = ScamThreatAnalytics.fromReports(reports);
          final officialCount = reports
              .where((report) => report.isOfficial)
              .length;
          final categories = analytics.categoryCounts.entries.toList()
            ..sort((left, right) => right.value.compareTo(left.value));
          final recentReports = reports.take(5).toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _reportsFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Module 1 Safety Overview',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Live summary of scam reports and map-ready hotspots.',
                          style: TextStyle(color: AppColors.slate),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _openHeatmap,
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Open Heatmap'),
                        ),
                        FilledButton.icon(
                          onPressed: _openManualCase,
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: const Text('Publish Official Case'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _OverviewMetric(
                      label: 'Map-ready reports',
                      value: '${analytics.totalReports}',
                      icon: Icons.location_on_outlined,
                      color: AppColors.blue,
                    ),
                    _OverviewMetric(
                      label: 'Verified public',
                      value: '${analytics.verifiedReports}',
                      icon: Icons.verified_outlined,
                      color: AppColors.green,
                    ),
                    _OverviewMetric(
                      label: 'Pending review',
                      value: '${analytics.pendingReports}',
                      icon: Icons.pending_actions_outlined,
                      color: AppColors.amber,
                    ),
                    _OverviewMetric(
                      label: 'Official cases',
                      value: '$officialCount',
                      icon: Icons.gavel_outlined,
                      color: AppColors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final categoryPanel = _OverviewPanel(
                      title: 'Top scam categories',
                      child: categories.isEmpty
                          ? const Text('No map-ready category data yet.')
                          : Column(
                              children: [
                                for (final entry in categories.take(6))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        Expanded(child: Text(entry.key)),
                                        Text(
                                          '${entry.value}',
                                          style: const TextStyle(
                                            color: AppColors.navy,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                    );
                    final recentPanel = _OverviewPanel(
                      title: 'Recent map cases',
                      child: recentReports.isEmpty
                          ? const Text(
                              'No reports have coordinates yet. Publish an official case to create the first marker.',
                            )
                          : Column(
                              children: [
                                for (final report in recentReports)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      report.isVerified
                                          ? Icons.verified
                                          : Icons.schedule,
                                      color: report.isVerified
                                          ? AppColors.green
                                          : AppColors.amber,
                                    ),
                                    title: Text(
                                      report.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '${report.category} • ${report.locationName ?? 'Coordinates provided'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                    );

                    if (constraints.maxWidth < 850) {
                      return Column(
                        children: [
                          categoryPanel,
                          const SizedBox(height: 14),
                          recentPanel,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: categoryPanel),
                        const SizedBox(width: 14),
                        Expanded(flex: 2, child: recentPanel),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: AppColors.slate, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.child, this.title});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

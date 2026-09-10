import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/scam_map_repository.dart';
import '../../models/scam_map_models.dart';
import '../../services/threat_export_service.dart';
import 'admin_shell.dart';

class ThreatHeatmapScreen extends StatefulWidget {
  const ThreatHeatmapScreen({
    required this.repository,
    required this.onSignOut,
    this.onOpenReports,
    this.onOpenThreatDatabase,
    this.onOpenDashboard,
    this.onOpenVerifiedMerchants,
    this.onOpenAwarenessCms,
    this.onOpenSettings,
    this.onOpenPublishScamCase,
    this.onOpenHeatmap,
    super.key,
  });

  final ScamMapRepository repository;
  final Future<void> Function() onSignOut;
  final VoidCallback? onOpenReports;
  final VoidCallback? onOpenThreatDatabase;
  final VoidCallback? onOpenDashboard;
  final VoidCallback? onOpenVerifiedMerchants;
  final VoidCallback? onOpenAwarenessCms;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenPublishScamCase;
  final VoidCallback? onOpenHeatmap;

  @override
  State<ThreatHeatmapScreen> createState() => _ThreatHeatmapScreenState();
}

class _ThreatHeatmapScreenState extends State<ThreatHeatmapScreen> {
  final ThreatExportService _exportService = ThreatExportService();
  late Future<ScamMapLoadResult> _reportsFuture;
  int _days = 30;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _reportsFuture = widget.repository.getThreatAnalyticsReports();
  }

  List<ScamMapReport> _filterByDate(List<ScamMapReport> reports) {
    final cutoff = DateTime.now().subtract(Duration(days: _days));
    return reports
        .where((report) => report.reportedAt.isAfter(cutoff))
        .toList();
  }

  Future<void> _export(
    List<ScamMapReport> reports, {
    required bool asPdf,
  }) async {
    setState(() => _exporting = true);
    try {
      final path = asPdf
          ? await _exportService.exportPdf(reports)
          : await _exportService.exportCsv(reports);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Threat report exported successfully: $path')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenuItem: 'Geospatial Heatmap',
      onBack: () => Navigator.of(context).pop(),
      onSignOut: widget.onSignOut,
      onOpenReports: widget.onOpenReports,
      onOpenThreatDatabase: widget.onOpenThreatDatabase,
      onOpenDashboard: widget.onOpenDashboard,
      onOpenVerifiedMerchants: widget.onOpenVerifiedMerchants,
      onOpenAwarenessCms: widget.onOpenAwarenessCms,
      onOpenSettings: widget.onOpenSettings,
      onOpenPublishScamCase: widget.onOpenPublishScamCase,
      onOpenHeatmap: widget.onOpenHeatmap,
      child: FutureBuilder<ScamMapLoadResult>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SurfaceCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        color: AppColors.red,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      const Text('Threat analytics could not be loaded.'),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _reportsFuture = widget.repository
                                .getThreatAnalyticsReports();
                          });
                        },
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final allReports = snapshot.data?.reports ?? const <ScamMapReport>[];
          final reports = _filterByDate(allReports);
          final analytics = ScamThreatAnalytics.fromReports(reports);
          final hotspots = analytics.locationCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Threat Heatmap Analytics',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Nationwide scam density visualization from active incident data.',
                style: TextStyle(color: AppColors.slate, fontSize: 12),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _AnalyticsCard(
                    label: 'TOTAL REPORTS',
                    value: '${analytics.totalReports}',
                    color: AppColors.blue,
                  ),
                  _AnalyticsCard(
                    label: 'VERIFIED REPORTS',
                    value: '${analytics.verifiedReports}',
                    color: AppColors.red,
                  ),
                  _AnalyticsCard(
                    label: 'PENDING REPORTS',
                    value: '${analytics.pendingReports}',
                    color: AppColors.amber,
                  ),
                  _AnalyticsCard(
                    label: 'HIGH-DENSITY ZONES',
                    value:
                        '${hotspots.where((entry) => entry.value >= 2).length}',
                    color: AppColors.green,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final map = _HeatmapPanel(
                    reports: reports,
                    days: _days,
                    exporting: _exporting,
                    onDaysChanged: (days) => setState(() => _days = days),
                    onExportCsv: () => _export(reports, asPdf: false),
                    onExportPdf: () => _export(reports, asPdf: true),
                  );
                  final leaderboard = _HotspotLeaderboard(
                    entries: hotspots.take(8).toList(),
                  );

                  if (constraints.maxWidth < 850) {
                    return Column(
                      children: [map, const SizedBox(height: 16), leaderboard],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: map),
                      const SizedBox(width: 16),
                      Expanded(child: leaderboard),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.slate, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapPanel extends StatelessWidget {
  const _HeatmapPanel({
    required this.reports,
    required this.days,
    required this.exporting,
    required this.onDaysChanged,
    required this.onExportCsv,
    required this.onExportPdf,
  });

  final List<ScamMapReport> reports;
  final int days;
  final bool exporting;
  final ValueChanged<int> onDaysChanged;
  final VoidCallback onExportCsv;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Geospatial Density Map',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Visualization of reported scam clusters across Malaysia.',
                    style: TextStyle(color: AppColors.slate, fontSize: 11),
                  ),
                ],
              ),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7d')),
                  ButtonSegment(value: 30, label: Text('30d')),
                  ButtonSegment(value: 90, label: Text('90d')),
                ],
                selected: {days},
                onSelectionChanged: (selection) =>
                    onDaysChanged(selection.first),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 470,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(4.2105, 101.9758),
                  initialZoom: 6,
                  minZoom: 5,
                  maxZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.collab',
                  ),
                  CircleLayer(
                    circles: [
                      for (final report in reports)
                        CircleMarker(
                          point: LatLng(report.latitude, report.longitude),
                          radius: report.isVerified ? 30 : 18,
                          color: report.isVerified
                              ? AppColors.red.withOpacity(0.3)
                              : AppColors.amber.withOpacity(0.25),
                          borderColor: report.isVerified
                              ? AppColors.red.withOpacity(0.6)
                              : AppColors.amber.withOpacity(0.55),
                          borderStrokeWidth: 1,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Last synced: ${DateFormat('HH:mm').format(DateTime.now())}',
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: exporting ? null : onExportCsv,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('CSV'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: exporting ? null : onExportPdf,
                style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                icon: exporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: const Text('PDF Report'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HotspotLeaderboard extends StatelessWidget {
  const _HotspotLeaderboard({required this.entries});

  final List<MapEntry<String, int>> entries;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'High-Risk Hotspots',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text('No hotspot data available.')
          else
            for (int index = 0; index < entries.length; index++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: index < 3 ? AppColors.redSoft : AppColors.canvas,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: index < 3 ? AppColors.red : AppColors.slate,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entries[index].key,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${entries[index].value} alerts',
                      style: const TextStyle(
                        color: AppColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < entries.length - 1) const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../core/haversine.dart';
import '../../data/scam_map_repository.dart';
import '../../models/scam_map_models.dart';
import '../../services/threat_export_service.dart';
import 'admin_shell.dart';

class ThreatHeatmapScreen extends StatefulWidget {
  const ThreatHeatmapScreen({required this.repository, super.key});

  final ScamMapRepository repository;

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
      onOpenThreatDatabase: () => Navigator.of(context).pop(),
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
          final categories = analytics.categoryCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Threat Heatmap Analytics',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Verified and pending scam activity within Kuala Lumpur.',
                style: TextStyle(color: AppColors.slate, fontSize: 12),
              ),
              if (snapshot.data?.loadedFromCache == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  color: AppColors.blueSoft,
                  child: const Text(
                    'Network offline. Analytics are using cached SQLite data.',
                    style: TextStyle(color: AppColors.blue, fontSize: 11),
                  ),
                ),
              ],
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              _InsightStrip(
                analytics: analytics,
                topCategory: categories.firstOrNull,
                topHotspot: hotspots.firstOrNull,
              ),
              const SizedBox(height: 12),
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
                  final analyticsPanels = Column(
                    children: [
                      _HotspotLeaderboard(entries: hotspots.take(5).toList()),
                      const SizedBox(height: 12),
                      _BreakdownChart(
                        title: 'Scams by Category',
                        entries: categories.take(5).toList(),
                        total: analytics.totalReports,
                      ),
                    ],
                  );

                  if (constraints.maxWidth < 850) {
                    return Column(
                      children: [
                        map,
                        const SizedBox(height: 12),
                        analyticsPanels,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: map),
                      const SizedBox(width: 16),
                      SizedBox(width: 330, child: analyticsPanels),
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

class _InsightStrip extends StatelessWidget {
  const _InsightStrip({
    required this.analytics,
    required this.topCategory,
    required this.topHotspot,
  });

  final ScamThreatAnalytics analytics;
  final MapEntry<String, int>? topCategory;
  final MapEntry<String, int>? topHotspot;

  @override
  Widget build(BuildContext context) {
    final verificationRate = analytics.totalReports == 0
        ? 0
        : (analytics.verifiedReports / analytics.totalReports * 100).round();
    return SurfaceCard(
      child: Wrap(
        spacing: 28,
        runSpacing: 10,
        children: [
          _Insight(
            icon: Icons.verified_outlined,
            label: 'Verification rate',
            value: '$verificationRate%',
          ),
          _Insight(
            icon: Icons.location_on_outlined,
            label: 'Highest activity area',
            value: topHotspot?.key ?? 'No data',
          ),
          _Insight(
            icon: Icons.category_outlined,
            label: 'Most reported category',
            value: topCategory?.key ?? 'No data',
          ),
        ],
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  const _Insight({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Row(
        children: [
          Icon(icon, color: AppColors.blue, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.slate, fontSize: 10),
                ),
                Text(
                  value,
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
        ],
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
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
            style: const TextStyle(color: AppColors.slate, fontSize: 9),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownChart extends StatelessWidget {
  const _BreakdownChart({
    required this.title,
    required this.entries,
    required this.total,
  });

  final String title;
  final List<MapEntry<String, int>> entries;
  final int total;

  @override
  Widget build(BuildContext context) {
    final maximum = entries.isEmpty ? 1 : entries.first.value;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$total reports in selected period',
            style: const TextStyle(color: AppColors.slate, fontSize: 10),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text('No category data are available.')
          else
            for (final entry in entries) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: entry.value / maximum,
                  backgroundColor: AppColors.canvas,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(height: 10),
            ],
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
                    'Kuala Lumpur Threat Density Map',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Dark red indicates higher verified-report density.',
                    style: TextStyle(color: AppColors.slate, fontSize: 10),
                  ),
                ],
              ),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7 Days')),
                  ButtonSegment(value: 30, label: Text('30 Days')),
                  ButtonSegment(value: 90, label: Text('90 Days')),
                ],
                selected: {days},
                onSelectionChanged: (selection) =>
                    onDaysChanged(selection.first),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 360,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(3.1390, 101.6869),
                  initialZoom: 12,
                  minZoom: 11,
                  maxZoom: 15,
                  cameraConstraint: CameraConstraint.contain(
                    bounds: LatLngBounds(
                      const LatLng(
                        kualaLumpurMinimumLatitude,
                        kualaLumpurMinimumLongitude,
                      ),
                      const LatLng(
                        kualaLumpurMaximumLatitude,
                        kualaLumpurMaximumLongitude,
                      ),
                    ),
                  ),
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
                          radius: report.isVerified ? 34 : 22,
                          color: report.isVerified
                              ? AppColors.red.withValues(alpha: 0.30)
                              : AppColors.amber.withValues(alpha: 0.25),
                          borderColor: report.isVerified
                              ? AppColors.red.withValues(alpha: 0.55)
                              : AppColors.amber.withValues(alpha: 0.55),
                          borderStrokeWidth: 1,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Updated ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                style: const TextStyle(color: AppColors.muted, fontSize: 9),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: exporting ? null : onExportCsv,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('Export CSV'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: exporting ? null : onExportPdf,
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
                label: const Text('Export PDF'),
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
            'Top Hotspot Leaderboard',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Ranked by report volume',
            style: TextStyle(color: AppColors.slate, fontSize: 10),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text('No location analytics are available.')
          else
            for (int index = 0; index < entries.length; index++) ...[
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: index < 3
                      ? AppColors.redSoft
                      : AppColors.canvas,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: index < 3 ? AppColors.red : AppColors.slate,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: Text(
                  entries[index].key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  '${entries[index].value}',
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (index < entries.length - 1) const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

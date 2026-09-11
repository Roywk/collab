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

enum _HeatmapPeriod { lastSevenDays, monthly, yearly }

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
  final MapController _mapController = MapController();
  late Future<ScamMapLoadResult> _reportsFuture;
  _HeatmapPeriod _period = _HeatmapPeriod.lastSevenDays;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _reportsFuture = widget.repository.getThreatAnalyticsReports();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<ScamMapReport> _filterByDate(List<ScamMapReport> reports) {
    final now = DateTime.now();
    return reports.where((report) {
      final date = report.reportedAt.toLocal();
      switch (_period) {
        case _HeatmapPeriod.lastSevenDays:
          final start = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 6));
          return !date.isBefore(start);
        case _HeatmapPeriod.monthly:
          return date.year == _selectedYear && date.month == _selectedMonth;
        case _HeatmapPeriod.yearly:
          return date.year == _selectedYear;
      }
    }).toList();
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
      headerTitle: 'Geospatial Heatmap Analytics',
      onBack: widget.onOpenDashboard ?? () => Navigator.of(context).maybePop(),
      onSignOut: widget.onSignOut,
      onOpenReports: widget.onOpenReports,
      onOpenThreatDatabase: widget.onOpenThreatDatabase,
      onOpenDashboard: widget.onOpenDashboard,
      onOpenVerifiedMerchants: widget.onOpenVerifiedMerchants,
      onOpenAwarenessCms: widget.onOpenAwarenessCms,
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
          final availableYears = <int>{
            DateTime.now().year,
            ...allReports.map((report) => report.reportedAt.toLocal().year),
          }.toList()..sort((first, second) => second.compareTo(first));
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
                    mapController: _mapController,
                    reports: reports,
                    period: _period,
                    selectedMonth: _selectedMonth,
                    selectedYear: _selectedYear,
                    availableYears: availableYears,
                    exporting: _exporting,
                    onPeriodChanged: (period) =>
                        setState(() => _period = period),
                    onMonthChanged: (month) =>
                        setState(() => _selectedMonth = month),
                    onYearChanged: (year) =>
                        setState(() => _selectedYear = year),
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
                      Expanded(flex: 4, child: map),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: (constraints.maxWidth * 0.23).clamp(300, 360),
                        child: analyticsPanels,
                      ),
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
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
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
    required this.mapController,
    required this.reports,
    required this.period,
    required this.selectedMonth,
    required this.selectedYear,
    required this.availableYears,
    required this.exporting,
    required this.onPeriodChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onExportCsv,
    required this.onExportPdf,
  });

  final MapController mapController;
  final List<ScamMapReport> reports;
  final _HeatmapPeriod period;
  final int selectedMonth;
  final int selectedYear;
  final List<int> availableYears;
  final bool exporting;
  final ValueChanged<_HeatmapPeriod> onPeriodChanged;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;
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
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Visualization of reported scam clusters across Kuala Lumpur.',
                    style: TextStyle(color: AppColors.slate, fontSize: 11),
                  ),
                ],
              ),
              SegmentedButton<_HeatmapPeriod>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: _HeatmapPeriod.lastSevenDays,
                    label: Text('7 Days'),
                  ),
                  ButtonSegment(
                    value: _HeatmapPeriod.monthly,
                    label: Text('Monthly'),
                  ),
                  ButtonSegment(
                    value: _HeatmapPeriod.yearly,
                    label: Text('Yearly'),
                  ),
                ],
                selected: {period},
                onSelectionChanged: (selection) =>
                    onPeriodChanged(selection.first),
              ),
              if (period == _HeatmapPeriod.monthly)
                DropdownButton<int>(
                  value: selectedMonth,
                  items: [
                    for (var month = 1; month <= 12; month++)
                      DropdownMenuItem(
                        value: month,
                        child: Text(
                          DateFormat('MMM').format(DateTime(2024, month)),
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) onMonthChanged(value);
                  },
                ),
              if (period != _HeatmapPeriod.lastSevenDays)
                DropdownButton<int>(
                  value: selectedYear,
                  items: [
                    for (final year in availableYears)
                      DropdownMenuItem(value: year, child: Text('$year')),
                  ],
                  onChanged: (value) {
                    if (value != null) onYearChanged(value);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 520,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(3.1390, 101.6869),
                      initialZoom: 11.3,
                      minZoom: 9,
                      maxZoom: 18,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
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
                              radius: report.isVerified ? 30 : 18,
                              color: report.isVerified
                                  ? AppColors.red.withValues(alpha: 0.3)
                                  : AppColors.amber.withValues(alpha: 0.25),
                              borderColor: report.isVerified
                                  ? AppColors.red.withValues(alpha: 0.6)
                                  : AppColors.amber.withValues(alpha: 0.55),
                              borderStrokeWidth: 1,
                            ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _MapZoomControls(controller: mapController),
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

class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls({required this.controller});

  final MapController controller;

  void _changeZoom(double amount) {
    final camera = controller.camera;
    controller.move(camera.center, (camera.zoom + amount).clamp(9.0, 18.0));
  }

  void _showAllKualaLumpur() {
    controller.move(const LatLng(3.1390, 101.6869), 11.3);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Zoom in',
            onPressed: () => _changeZoom(1),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 38, child: Divider(height: 1)),
          IconButton(
            tooltip: 'Zoom out',
            onPressed: () => _changeZoom(-1),
            icon: const Icon(Icons.remove),
          ),
          const SizedBox(width: 38, child: Divider(height: 1)),
          IconButton(
            tooltip: 'Show all Kuala Lumpur',
            onPressed: _showAllKualaLumpur,
            icon: const Icon(Icons.center_focus_strong_outlined, size: 20),
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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
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

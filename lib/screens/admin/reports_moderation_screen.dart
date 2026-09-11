import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/admin_repository.dart';
import '../../models/report_models.dart';
import 'admin_shell.dart';
import 'report_detail_screen.dart';

class ReportsModerationScreen extends StatefulWidget {
  const ReportsModerationScreen({
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
  State<ReportsModerationScreen> createState() =>
      _ReportsModerationScreenState();
}

class _ReportsModerationScreenState extends State<ReportsModerationScreen> {
  late Future<List<ScamReport>> _reportsFuture;
  String _statusFilter = 'All Statuses';
  String _categoryFilter = 'All Categories';
  String _searchQuery = '';
  bool _highRiskOnly = false;

  @override
  void initState() {
    super.initState();
    _refreshReports();
  }

  void _refreshReports() {
    setState(() {
      _reportsFuture = widget.repository.getAllScamReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenuItem: 'Reports Moderation',
      onSignOut: widget.onSignOut,
      onOpenDashboard: widget.onOpenDashboard,
      onOpenReports: widget.onOpenReports,
      onOpenHeatmap: widget.onOpenHeatmap,
      onOpenVerifiedMerchants: widget.onOpenVerifiedMerchants,
      onOpenThreatDatabase: widget.onOpenThreatDatabase,
      onOpenAwarenessCms: widget.onOpenAwarenessCms,
      onOpenSettings: widget.onOpenSettings,
      onOpenPublishScamCase: widget.onOpenPublishScamCase,
      onSearchChanged: (val) =>
          setState(() => _searchQuery = val.toLowerCase()),
      child: FutureBuilder<List<ScamReport>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allReports = snapshot.data ?? [];
          final filteredReports = allReports.where((r) {
            final matchesStatus =
                _statusFilter == 'All Statuses' ||
                r.verificationStatus == _statusFilter;
            final matchesCategory =
                _categoryFilter == 'All Categories' ||
                r.category == _categoryFilter;
            final matchesSearch =
                _searchQuery.isEmpty ||
                (r.id?.toLowerCase().contains(_searchQuery) ?? false) ||
                r.title.toLowerCase().contains(_searchQuery) ||
                r.category.toLowerCase().contains(_searchQuery) ||
                (r.locationName?.toLowerCase().contains(_searchQuery) ?? false);
            final matchesRisk = !_highRiskOnly || (r.amountLost ?? 0) > 200;

            return matchesStatus &&
                matchesCategory &&
                matchesSearch &&
                matchesRisk;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatCards(allReports),
              const SizedBox(height: 24),
              _buildFilters(allReports),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: SurfaceCard(
                      padding: EdgeInsets.zero,
                      child: _buildReportsTable(filteredReports),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _buildMiniMap(filteredReports)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Reports Moderation',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        _buildSystemStatusBadge(),
      ],
    );
  }

  Widget _buildSystemStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Row(
        children: [
          CircleAvatar(radius: 3, backgroundColor: AppColors.green),
          SizedBox(width: 8),
          Text(
            'System Live & Syncing',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(List<ScamReport> reports) {
    final pending = reports
        .where((r) => r.verificationStatus == 'Pending')
        .length;
    final total = reports.length;

    return Row(
      children: [
        _buildStatCard(
          'TOTAL SCAM REPORTS',
          '$total',
          'Across Malaysia',
          Icons.description_outlined,
          AppColors.blue,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'PENDING REVIEW',
          '$pending',
          'Requires attention',
          Icons.warning_amber_rounded,
          Colors.orange,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'VERIFIED FALSE / FAKE',
          '${reports.where((r) => r.verificationStatus == 'Fake').length}',
          'Accuracy Filter',
          Icons.delete_outline,
          Colors.red,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'COMMUNITY REACH',
          '23.3K',
          'Users protected',
          Icons.people_outline,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(List<ScamReport> reports) {
    final categories = [
      'All Categories',
      ...reports.map((r) => r.category).toSet(),
    ];
    return Row(
      children: [
        _buildFilterDropdown('Status: $_statusFilter', [
          'All Statuses',
          'Pending',
          'Verified',
          'Resolved',
          'Fake',
        ], (v) => setState(() => _statusFilter = v!)),
        const SizedBox(width: 12),
        _buildFilterDropdown(
          'Category: $_categoryFilter',
          categories,
          (v) => setState(() => _categoryFilter = v!),
        ),
        const Spacer(),
        const Text(
          'Suspicious Only',
          style: TextStyle(
            color: AppColors.slate,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: _highRiskOnly,
          onChanged: (v) => setState(() => _highRiskOnly = v),
          activeTrackColor: AppColors.blue.withOpacity(0.5),
          activeColor: AppColors.blue,
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    String label,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          items: items
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildReportsTable(List<ScamReport> reports) {
    if (reports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: Text('No reports found.')),
      );
    }
    return DataTable(
      headingTextStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.slate,
        fontSize: 11,
      ),
      columns: const [
        DataColumn(label: Text('REPORT ID')),
        DataColumn(label: Text('CATEGORY')),
        DataColumn(label: Text('LOCATION')),
        DataColumn(label: Text('DATE')),
        DataColumn(label: Text('STATUS')),
        DataColumn(label: Text('RISK')),
        DataColumn(label: Text('ACTIONS')),
      ],
      rows: reports
          .map(
            (r) => DataRow(
              cells: [
                DataCell(
                  Text(
                    '#${r.id?.substring(0, 4).toUpperCase() ?? "0000"}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _openDetail(r),
                ),
                DataCell(Text(r.category)),
                DataCell(Text(r.locationName ?? 'Unknown')),
                DataCell(Text(DateFormat('MMM dd, yyyy').format(r.createdAt))),
                DataCell(_buildTableStatusBadge(r.verificationStatus)),
                DataCell(
                  Icon(
                    Icons.flag_outlined,
                    color: (r.amountLost ?? 0) > 200
                        ? Colors.red
                        : AppColors.muted,
                    size: 18,
                  ),
                ),
                DataCell(
                  FilledButton.icon(
                    onPressed: () => _openDetail(r),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 32),
                    ),
                    icon: const Icon(Icons.rate_review_outlined, size: 14),
                    label: const Text('Review', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildTableStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'Verified') color = Colors.green;
    if (status == 'Fake') color = Colors.red;
    if (status == 'Resolved') color = Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMiniMap(List<ScamReport> reports) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Area Hotspot Heatmap',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(3.1390, 101.6869),
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  CircleLayer(
                    circles: reports
                        .map(
                          (r) => CircleMarker(
                            point: LatLng(r.latitude, r.longitude),
                            radius: 8,
                            color: Colors.red.withOpacity(0.5),
                            borderColor: Colors.white,
                            borderStrokeWidth: 2,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'LEGEND',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _LegendItem(color: Colors.orange, label: 'Pending'),
              _LegendItem(color: Colors.green, label: 'Verified'),
              _LegendItem(color: Colors.red, label: 'Fake'),
            ],
          ),
        ],
      ),
    );
  }

  void _openDetail(ScamReport report) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => ReportDetailScreen(
          report: report,
          repository: widget.repository,
          onOpenDashboard: widget.onOpenDashboard,
          onOpenReports: widget.onOpenReports,
          onOpenHeatmap: widget.onOpenHeatmap,
          onOpenVerifiedMerchants: widget.onOpenVerifiedMerchants,
          onOpenThreatDatabase: widget.onOpenThreatDatabase,
          onOpenAwarenessCms: widget.onOpenAwarenessCms,
          onOpenSettings: widget.onOpenSettings,
          onOpenPublishScamCase: widget.onOpenPublishScamCase,
          onSignOut: widget.onSignOut,
        ),
      ),
    );
    if (updated == true) _refreshReports();
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

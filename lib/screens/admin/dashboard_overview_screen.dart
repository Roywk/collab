import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/app_theme.dart';
import '../../data/admin_repository.dart';
import 'admin_shell.dart';

class DashboardOverviewScreen extends StatefulWidget {
  const DashboardOverviewScreen({
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
  State<DashboardOverviewScreen> createState() => _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState extends State<DashboardOverviewScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = widget.repository.getModerationStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenuItem: 'Dashboard Overview',
      onSignOut: widget.onSignOut,
      onOpenDashboard: widget.onOpenDashboard,
      onOpenReports: widget.onOpenReports,
      onOpenHeatmap: widget.onOpenHeatmap,
      onOpenVerifiedMerchants: widget.onOpenVerifiedMerchants,
      onOpenThreatDatabase: widget.onOpenThreatDatabase,
      onOpenAwarenessCms: widget.onOpenAwarenessCms,
      onOpenSettings: widget.onOpenSettings,
      onOpenPublishScamCase: widget.onOpenPublishScamCase,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading dashboard: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshStats,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final stats = snapshot.data ?? {};

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dashboard Overview',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: widget.onOpenReports,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Moderate Reports'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - (16 * 3)) / 4;
                final isSmall = cardWidth < 180;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStatCard(
                      isSmall ? (constraints.maxWidth - 16) / 2 : cardWidth,
                      'Total Scam Reports',
                      '${stats['total_reports'] ?? 0}',
                      Icons.description_outlined,
                      AppColors.blue,
                      onTap: widget.onOpenReports,
                    ),
                    _buildStatCard(
                      isSmall ? (constraints.maxWidth - 16) / 2 : cardWidth,
                      'Pending Verification',
                      '${stats['pending_review'] ?? 0}',
                      Icons.hourglass_empty,
                      Colors.orange,
                      onTap: widget.onOpenReports,
                    ),
                    _buildStatCard(
                      isSmall ? (constraints.maxWidth - 16) / 2 : cardWidth,
                      'System Accuracy',
                      '${stats['accuracy_rate'] ?? 0}%',
                      Icons.check_circle_outline,
                      Colors.green,
                    ),
                    _buildStatCard(
                      isSmall ? (constraints.maxWidth - 16) / 2 : cardWidth,
                      'Community Reach',
                      '${stats['community_reach'] ?? '0'}',
                      Icons.people_outline,
                      Colors.purple,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildTrendChart()),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _buildRecentActivity()),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    double width,
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap != null ? color.withValues(alpha: 0.3) : AppColors.line,
            width: onTap != null ? 1.5 : 1,
          ),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (onTap != null)
                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.muted),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              const Text(
                'Incident Trends (Daily)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.navy,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export Data'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          AspectRatio(
            aspectRatio: 2,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: const TextStyle(color: AppColors.slate, fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 1),
                      FlSpot(2, 4),
                      FlSpot(3, 2),
                      FlSpot(4, 5),
                      FlSpot(5, 3),
                      FlSpot(6, 4),
                    ],
                    isCurved: true,
                    color: AppColors.blue,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.blue.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Notifications',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 24),
          _buildActivityItem(
            'High volume of Taxi Tout reports in Bukit Bintang.',
            '2 mins ago',
            Icons.warning_amber_rounded,
            Colors.orange,
          ),
          _buildActivityItem(
            'New official scam case published by Admin Mercer.',
            '15 mins ago',
            Icons.check_circle_outline,
            Colors.green,
          ),
          _buildActivityItem(
            'System identified a potential bot-reporting cluster.',
            '1 hour ago',
            Icons.security,
            Colors.red,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('View All Notifications'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String text, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

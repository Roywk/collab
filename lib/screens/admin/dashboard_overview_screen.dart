import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../data/admin_repository.dart';
import '../../services/dashboard_report_export_service.dart';
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
  State<DashboardOverviewScreen> createState() =>
      _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState extends State<DashboardOverviewScreen> {
  final DashboardReportExportService _reportExportService =
      DashboardReportExportService();
  late Future<Map<String, dynamic>> _statsFuture;
  _TrendRange _trendRange = _TrendRange.lastSevenDays;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _exportingReport = false;

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

  List<DateTime> _reportDates(Map<String, dynamic> stats) {
    return ((stats['report_dates'] as List?) ?? const [])
        .map((value) => DateTime.tryParse(value.toString())?.toLocal())
        .whereType<DateTime>()
        .toList();
  }

  _TrendData _buildTrendData(Map<String, dynamic> stats) {
    final dates = _reportDates(stats);
    final now = DateTime.now();

    switch (_trendRange) {
      case _TrendRange.lastSevenDays:
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        final counts = List<int>.filled(7, 0);
        for (final date in dates) {
          final day = DateTime(date.year, date.month, date.day);
          final index = day.difference(start).inDays;
          if (index >= 0 && index < counts.length) counts[index]++;
        }
        return _TrendData(
          title: 'Last 7 Days',
          labels: List.generate(
            7,
            (index) =>
                DateFormat('EEE').format(start.add(Duration(days: index))),
          ),
          counts: counts,
        );
      case _TrendRange.monthly:
        final numberOfDays = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
        final counts = List<int>.filled(numberOfDays, 0);
        for (final date in dates) {
          if (date.year == _selectedYear && date.month == _selectedMonth) {
            counts[date.day - 1]++;
          }
        }
        return _TrendData(
          title: DateFormat(
            'MMMM yyyy',
          ).format(DateTime(_selectedYear, _selectedMonth)),
          labels: List.generate(numberOfDays, (index) => '${index + 1}'),
          counts: counts,
        );
      case _TrendRange.yearly:
        final counts = List<int>.filled(12, 0);
        for (final date in dates) {
          if (date.year == _selectedYear) counts[date.month - 1]++;
        }
        return _TrendData(
          title: 'Year $_selectedYear',
          labels: List.generate(
            12,
            (index) => DateFormat('MMM').format(DateTime(2024, index + 1)),
          ),
          counts: counts,
        );
    }
  }

  Future<void> _exportTrend(_TrendData data, {required bool asPdf}) async {
    setState(() => _exportingReport = true);
    try {
      final path = asPdf
          ? await _reportExportService.exportPdf(
              periodTitle: data.title,
              labels: data.labels,
              counts: data.counts,
            )
          : await _reportExportService.exportCsv(
              periodTitle: data.title,
              labels: data.labels,
              counts: data.counts,
            );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Analytics exported: $path')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export analytics: $error')),
      );
    } finally {
      if (mounted) setState(() => _exportingReport = false);
    }
  }

  Future<_NotificationDraft?> _showNotificationDialog({
    Map<dynamic, dynamic>? notification,
  }) async {
    final isEditing = notification != null;
    final titleController = TextEditingController(
      text: notification?['title']?.toString() ?? '',
    );
    final messageController = TextEditingController(
      text: notification?['message']?.toString() ?? '',
    );
    var severity = notification?['severity']?.toString() ?? 'Information';
    String? validationMessage;

    final draft = await showDialog<_NotificationDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEditing
                ? 'Edit Traveller Notification'
                : 'Publish Traveller Notification',
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Taxi scam warning in Setapak',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  maxLength: 500,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText:
                        'Write a short safety announcement for travellers.',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: severity,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Information',
                      child: Text('Information'),
                    ),
                    DropdownMenuItem(value: 'Warning', child: Text('Warning')),
                    DropdownMenuItem(
                      value: 'Critical',
                      child: Text('Critical'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => severity = value);
                    }
                  },
                ),
                if (validationMessage != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      validationMessage!,
                      style: const TextStyle(color: AppColors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                final title = titleController.text.trim();
                final message = messageController.text.trim();
                if (title.length < 3 || message.length < 3) {
                  setDialogState(() {
                    validationMessage =
                        'Title and message must contain at least 3 characters.';
                  });
                  return;
                }
                Navigator.of(
                  dialogContext,
                ).pop(_NotificationDraft(title, message, severity));
              },
              icon: Icon(
                isEditing ? Icons.save_outlined : Icons.send_outlined,
                size: 17,
              ),
              label: Text(isEditing ? 'Save Changes' : 'Publish'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    messageController.dispose();
    return draft;
  }

  Future<void> _publishNotification() async {
    final draft = await _showNotificationDialog();
    if (draft == null || !mounted) return;

    try {
      await widget.repository.publishTravellerNotification(
        title: draft.title,
        message: draft.message,
        severity: draft.severity,
      );
      if (!mounted) return;
      _refreshStats();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Traveller notification published.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish notification: $error')),
      );
    }
  }

  Future<void> _editNotification(Map<dynamic, dynamic> notification) async {
    final id = notification['id']?.toString();
    if (id == null || id.isEmpty) return;
    final draft = await _showNotificationDialog(notification: notification);
    if (draft == null || !mounted) return;

    try {
      await widget.repository.updateTravellerNotification(
        id: id,
        title: draft.title,
        message: draft.message,
        severity: draft.severity,
      );
      if (!mounted) return;
      _refreshStats();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Traveller notification updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update notification: $error')),
      );
    }
  }

  Future<void> _removeNotification(Map<dynamic, dynamic> notification) async {
    final id = notification['id']?.toString();
    if (id == null || id.isEmpty) return;
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Notification?'),
        content: Text(
          '“${notification['title'] ?? 'This notification'}” will no longer '
          'appear in the traveller app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (shouldRemove != true || !mounted) return;

    try {
      await widget.repository.removeTravellerNotification(id);
      if (!mounted) return;
      _refreshStats();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Traveller notification removed.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove notification: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenuItem: 'Dashboard Overview',
      headerTitle: 'Dashboard Overview',
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
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  const Text(
                    'Dashboard Overview',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _publishNotification,
                        icon: const Icon(
                          Icons.notifications_active_outlined,
                          size: 18,
                        ),
                        label: const Text('Publish Notification'),
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
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
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
                        'Verified Reports',
                        '${stats['verified_reports'] ?? 0}',
                        Icons.check_circle_outline,
                        Colors.green,
                        onTap: widget.onOpenReports,
                      ),
                      _buildStatCard(
                        isSmall ? (constraints.maxWidth - 16) / 2 : cardWidth,
                        'Official Cases',
                        '${stats['official_cases'] ?? 0}',
                        Icons.gavel_outlined,
                        Colors.purple,
                        onTap: widget.onOpenPublishScamCase,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildTrendChart(stats)),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _buildRecentActivity(stats)),
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
            color: onTap != null
                ? color.withValues(alpha: 0.3)
                : AppColors.line,
            width: onTap != null ? 1.5 : 1,
          ),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
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
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: AppColors.muted,
                  ),
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

  Widget _buildTrendChart(Map<String, dynamic> stats) {
    final data = _buildTrendData(stats);
    final years = <int>{
      DateTime.now().year,
      ..._reportDates(stats).map((date) => date.year),
    }.toList()..sort((first, second) => second.compareTo(first));
    final maximum = data.counts.fold<int>(
      0,
      (current, value) => value > current ? value : current,
    );
    final yInterval = maximum <= 4 ? 1.0 : (maximum / 4).ceilToDouble();
    final maxY = maximum == 0
        ? 1.0
        : (maximum / yInterval).ceil() * yInterval + yInterval;
    final bottomInterval = _trendRange == _TrendRange.monthly ? 5.0 : 1.0;
    const chartColor = Color(0xFF0EA5E9);

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
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports Created',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.navy,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Real counts grouped by reported date.',
                      style: TextStyle(color: AppColors.slate, fontSize: 11),
                    ),
                  ],
                ),
              ),
              SegmentedButton<_TrendRange>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: _TrendRange.lastSevenDays,
                    label: Text('7 Days'),
                  ),
                  ButtonSegment(
                    value: _TrendRange.monthly,
                    label: Text('Monthly'),
                  ),
                  ButtonSegment(
                    value: _TrendRange.yearly,
                    label: Text('Yearly'),
                  ),
                ],
                selected: {_trendRange},
                onSelectionChanged: (selection) {
                  setState(() => _trendRange = selection.first);
                },
              ),
              if (_trendRange == _TrendRange.monthly)
                DropdownButton<int>(
                  value: _selectedMonth,
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
                    if (value != null) setState(() => _selectedMonth = value);
                  },
                ),
              if (_trendRange != _TrendRange.lastSevenDays)
                DropdownButton<int>(
                  value: _selectedYear,
                  items: [
                    for (final year in years)
                      DropdownMenuItem(value: year, child: Text('$year')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedYear = value);
                  },
                ),
              OutlinedButton.icon(
                onPressed: _exportingReport
                    ? null
                    : () => _exportTrend(data, asPdf: false),
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('CSV'),
              ),
              FilledButton.icon(
                onPressed: _exportingReport
                    ? null
                    : () => _exportTrend(data, asPdf: true),
                icon: _exportingReport
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: const Text('PDF'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.title,
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          AspectRatio(
            aspectRatio: 2,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (data.labels.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.line, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: bottomInterval,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (value == index.toDouble() &&
                            index >= 0 &&
                            index < data.labels.length) {
                          return Text(
                            data.labels[index],
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yInterval,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int index = 0; index < data.counts.length; index++)
                        FlSpot(index.toDouble(), data.counts[index].toDouble()),
                    ],
                    isCurved: false,
                    color: chartColor,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: chartColor.withValues(alpha: 0.12),
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

  Widget _buildRecentActivity(Map<String, dynamic> stats) {
    final notifications =
        (stats['recent_notifications'] as List?)?.cast<Map>() ?? const [];
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
            'Traveller Notifications',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 24),
          if (notifications.isEmpty)
            const Text(
              'No traveller notifications published yet.',
              style: TextStyle(color: AppColors.slate),
            )
          else
            for (final notification in notifications)
              _buildNotificationItem(notification),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<dynamic, dynamic> notification) {
    final severity = notification['severity']?.toString() ?? 'Information';
    final color = severity == 'Critical'
        ? AppColors.red
        : severity == 'Warning'
        ? AppColors.amber
        : AppColors.blue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.campaign_outlined, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title']?.toString() ?? 'Safety update',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification['message']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.slate),
                ),
                const SizedBox(height: 5),
                Text(
                  '$severity • '
                  '${_formatNotificationTime(notification['published_at'])}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit notification',
            visualDensity: VisualDensity.compact,
            onPressed: () => _editNotification(notification),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            tooltip: 'Remove notification',
            visualDensity: VisualDensity.compact,
            color: AppColors.red,
            onPressed: () => _removeNotification(notification),
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
        ],
      ),
    );
  }

  String _formatNotificationTime(Object? value) {
    final publishedAt = DateTime.tryParse(value?.toString() ?? '');
    if (publishedAt == null) return '';
    final difference = DateTime.now().difference(publishedAt);
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hr ago';
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }
}

class _NotificationDraft {
  const _NotificationDraft(this.title, this.message, this.severity);

  final String title;
  final String message;
  final String severity;
}

enum _TrendRange { lastSevenDays, monthly, yearly }

class _TrendData {
  const _TrendData({
    required this.title,
    required this.labels,
    required this.counts,
  });

  final String title;
  final List<String> labels;
  final List<int> counts;
}

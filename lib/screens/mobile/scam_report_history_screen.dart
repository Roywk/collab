import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../models/report_models.dart';
import '../../services/report_service.dart';

class ScamReportHistoryScreen extends StatefulWidget {
  const ScamReportHistoryScreen({super.key});

  @override
  State<ScamReportHistoryScreen> createState() => _ScamReportHistoryScreenState();
}

class _ScamReportHistoryScreenState extends State<ScamReportHistoryScreen> {
  final ReportService _reportService = ReportService();
  late Future<List<ScamReport>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _reportService.getMyReportHistory();
  }

  void _refresh() {
    setState(() {
      _historyFuture = _reportService.getMyReportHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Scam Report History',
      onBack: () => Navigator.pop(context),
      currentNavigationIndex: 6, // Profile index
      child: FutureBuilder<List<ScamReport>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _refresh, child: const Text('Try Again')),
                  ],
                ),
              ),
            );
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, color: AppColors.slate.withOpacity(0.3), size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'No reports found',
                    style: TextStyle(color: AppColors.slate, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your submitted scam reports will appear here.',
                    style: TextStyle(color: AppColors.slate, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final report = reports[index];
                return _ReportHistoryCard(report: report);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReportHistoryCard extends StatelessWidget {
  const _ReportHistoryCard({required this.report});

  final ScamReport report;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return AppColors.green;
      case 'fake':
        return AppColors.red;
      case 'resolved':
        return AppColors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(report.verificationStatus);

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.category,
                    style: const TextStyle(color: AppColors.slate, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.title,
                    style: const TextStyle(color: AppColors.navy, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                report.verificationStatus.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            DateFormat('d MMM yyyy, hh:mm a').format(report.createdAt),
            style: const TextStyle(color: AppColors.slate, fontSize: 11),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                const Text('DESCRIPTION', style: TextStyle(color: AppColors.slate, fontSize: 9, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(report.description, style: const TextStyle(color: AppColors.navy, fontSize: 13)),
                if (report.amountLost != null && report.amountLost! > 0) ...[
                  const SizedBox(height: 12),
                  const Text('AMOUNT LOST', style: TextStyle(color: AppColors.slate, fontSize: 9, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('RM ${report.amountLost!.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.red, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
                if (report.evidenceUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('EVIDENCE', style: TextStyle(color: AppColors.slate, fontSize: 9, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: report.evidenceUrls.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            report.evidenceUrls[index],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 80,
                              height: 80,
                              color: AppColors.canvas,
                              child: const Icon(Icons.broken_image_outlined, size: 20, color: AppColors.slate),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (report.adminNotes != null && report.adminNotes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.blueSoft.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.blueSoft),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ADMIN NOTES', style: TextStyle(color: AppColors.blue, fontSize: 9, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(report.adminNotes!, style: const TextStyle(color: AppColors.navy, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

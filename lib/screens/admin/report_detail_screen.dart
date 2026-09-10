import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_theme.dart';
import '../../data/admin_repository.dart';
import '../../models/report_models.dart';
import 'admin_shell.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({
    required this.report,
    required this.repository,
    this.onOpenDashboard,
    this.onOpenReports,
    this.onOpenHeatmap,
    this.onOpenVerifiedMerchants,
    this.onOpenThreatDatabase,
    this.onOpenAwarenessCms,
    this.onOpenSettings,
    this.onOpenPublishScamCase,
    this.onSignOut,
    super.key,
  });

  final ScamReport report;
  final AdminRepository repository;
  final VoidCallback? onOpenDashboard;
  final VoidCallback? onOpenReports;
  final VoidCallback? onOpenHeatmap;
  final VoidCallback? onOpenVerifiedMerchants;
  final VoidCallback? onOpenThreatDatabase;
  final VoidCallback? onOpenAwarenessCms;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenPublishScamCase;
  final Future<void> Function()? onSignOut;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late String _currentStatus;
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.report.verificationStatus;
    _notesController.text = widget.report.adminNotes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await widget.repository.updateReportStatus(
        reportId: widget.report.id!,
        status: _currentStatus,
        adminNotes: _notesController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated and changes saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.redSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Report #${widget.report.id?.substring(0, 4).toUpperCase()}?',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'This action is permanent. The report will be removed from the public database and the map pin will be deleted. This cannot be undone.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.slate, fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.slate),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.repository.deleteScamReport(widget.report.id!);
        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Report #${widget.report.id?.substring(0, 4).toUpperCase()} Deleted Successfully!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );

        if (!mounted) return;
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenuItem: 'Reports',
      onBack: () => Navigator.of(context).pop(),
      onOpenDashboard: widget.onOpenDashboard,
      onOpenReports: widget.onOpenReports,
      onOpenHeatmap: widget.onOpenHeatmap,
      onOpenVerifiedMerchants: widget.onOpenVerifiedMerchants,
      onOpenThreatDatabase: widget.onOpenThreatDatabase,
      onOpenAwarenessCms: widget.onOpenAwarenessCms,
      onOpenSettings: widget.onOpenSettings,
      onOpenPublishScamCase: widget.onOpenPublishScamCase,
      onSignOut: widget.onSignOut,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 1000;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildBreadcrumbs(),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildIncidentCard(),
                        if (!isWide) ...[
                          const SizedBox(height: 24),
                          _buildStatusManagementCard(),
                        ],
                      ],
                    ),
                  ),
                  if (isWide) ...[
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildStatusManagementCard(),
                          const SizedBox(height: 24),
                          _buildLocationCard(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        Text(
          'Scam Moderation',
          style: TextStyle(color: AppColors.slate, fontSize: 12),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, size: 14, color: AppColors.slate),
        const SizedBox(width: 4),
        Text(
          'Report #${widget.report.id?.substring(0, 4).toUpperCase()}',
          style: TextStyle(color: AppColors.slate, fontSize: 12),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, size: 14, color: AppColors.slate),
        const Text(
          'Update Status',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentCard() {
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
                'Incident Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
              ),
              Text(
                'RM ${widget.report.amountLost?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  color: AppColors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStatusBadge(widget.report.verificationStatus),
          const SizedBox(height: 32),

          Wrap(
            spacing: 40,
            runSpacing: 24,
            children: [
              _buildInfoColumn(
                'REPORT ID',
                'RPT-2024-${widget.report.id?.substring(0, 4).toUpperCase()}',
              ),
              _buildInfoColumn(
                'SCAM CATEGORY',
                widget.report.category.toUpperCase(),
              ),
              _buildInfoColumn(
                'DATE REPORTED',
                DateFormat(
                  'MMM dd, yyyy at h:mm a',
                ).format(widget.report.createdAt),
              ),
              _buildInfoColumn(
                'REPORTER',
                widget.report.isAnonymous
                    ? 'Anonymous (UUID: ${widget.report.id?.substring(0, 4)})'
                    : 'User_${widget.report.id?.substring(0, 3)}',
              ),
              _buildInfoColumn(
                'LOCATION',
                widget.report.locationName ?? 'Unknown Location',
              ),
              _buildInfoColumn(
                'GPS COORDINATES',
                '${widget.report.latitude.toStringAsFixed(4)}° N, ${widget.report.longitude.toStringAsFixed(4)}° E',
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Text(
            'DETAILED DESCRIPTION',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.report.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF4A4E69),
            ),
          ),

          const SizedBox(height: 32),
          const Text(
            'EVIDENCE ATTACHED (2 PHOTOS)',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildEvidenceThumbnail('evidence_plate_img.jpg'),
              const SizedBox(width: 16),
              _buildEvidenceThumbnail('evidence_receipt_img.jpg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceThumbnail(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.line),
          ),
          child: const Center(
            child: Icon(Icons.image_outlined, color: AppColors.slate),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildStatusManagementCard() {
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
            'Status Management',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'CHANGE STATUS VERIFICATION',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _currentStatus,
            items: ['Pending', 'Verified', 'Resolved', 'Fake']
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 4,
                          backgroundColor: _getStatusColor(s),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          s,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _currentStatus = v!),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'STATUS HISTORY',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildHistoryTimeline(),
          const SizedBox(height: 24),
          const Text(
            'ADMINISTRATIVE VERIFICATION NOTES',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Add notes about this status change...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    minimumSize: const Size(0, 44),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _confirmDelete,
              child: const Text(
                'Delete Report',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTimeline() {
    return Column(
      children: [
        _buildTimelineItem(
          'Under Review',
          'Jul 15, 2026 4:10 PM by Admin Sarah',
          true,
        ),
        _buildTimelineItem('Created', 'Jul 15, 2026 3:42 PM by System', false),
      ],
    );
  }

  Widget _buildTimelineItem(String title, String time, bool isActive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isActive ? AppColors.blue : AppColors.slate,
                shape: BoxShape.circle,
              ),
            ),
            Container(width: 1, height: 30, color: AppColors.line),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isActive ? AppColors.navy : AppColors.slate,
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Precise Incident Location',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.redSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE CLUSTERS',
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    widget.report.latitude,
                    widget.report.longitude,
                  ),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          widget.report.latitude,
                          widget.report.longitude,
                        ),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.red,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'fake':
        return Colors.red;
      case 'resolved':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

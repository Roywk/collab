import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_theme.dart';
import '../../data/admin_repository.dart';
import '../../models/report_models.dart';
import '../../services/address_lookup_service.dart';
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
  final VoidCallback? onOpenPublishScamCase;
  final Future<void> Function()? onSignOut;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late String _currentStatus;
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;
  String? _resolvedAddress;

  bool _isLocationUnknown(String? loc) {
    if (loc == null || loc.trim().isEmpty) return true;
    final lower = loc.toLowerCase().trim();
    return lower.contains('unknown') || 
           lower.contains('unknow') || 
           lower == 'n/a' || 
           lower == 'null';
  }

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.report.verificationStatus;
    _notesController.text = widget.report.adminNotes ?? '';
    
    if (_isLocationUnknown(widget.report.locationName)) {
      _resolveLocation();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _resolveLocation() async {
    final service = AddressLookupService();
    try {
      final address = await service.addressFromCoordinates(
        latitude: widget.report.latitude,
        longitude: widget.report.longitude,
      );
      if (mounted && address != null) {
        setState(() {
          _resolvedAddress = address;
        });
      }
    } finally {
      service.dispose();
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _currentStatus = newStatus;
      _isSaving = true;
    });
    
    try {
      await widget.repository.updateReportStatus(
        reportId: widget.report.id!,
        status: newStatus,
        adminNotes: _notesController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report marked as $newStatus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report?'),
        content: const Text('This action cannot be undone. The report will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.repository.deleteScamReport(widget.report.id!);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenuItem: 'Reports Moderation',
      onBack: () => Navigator.of(context).pop(),
      onOpenDashboard: widget.onOpenDashboard,
      onOpenReports: widget.onOpenReports,
      onOpenHeatmap: widget.onOpenHeatmap,
      onOpenVerifiedMerchants: widget.onOpenVerifiedMerchants,
      onOpenThreatDatabase: widget.onOpenThreatDatabase,
      onOpenAwarenessCms: widget.onOpenAwarenessCms,
      onOpenPublishScamCase: widget.onOpenPublishScamCase,
      onSignOut: widget.onSignOut,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildReportDetails()),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _buildModerationPanel()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report #${widget.report.id?.substring(0, 8).toUpperCase()}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            Text(
              'Submitted on ${DateFormat('MMM dd, yyyy HH:mm').format(widget.report.createdAt)}',
              style: const TextStyle(color: AppColors.slate, fontSize: 13),
            ),
          ],
        ),
        const Spacer(),
        _buildStatusBadge(widget.report.verificationStatus),
      ],
    );
  }

  Widget _buildReportDetails() {
    final bool isLocUnknown = _isLocationUnknown(widget.report.locationName);
    final String locationDisplay = !isLocUnknown 
        ? widget.report.locationName! 
        : _resolvedAddress ?? 'Resolving address...';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('INCIDENT SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.report.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
                  if (widget.report.amountLost != null)
                    Text('RM ${widget.report.amountLost!.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.red, fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 40,
                runSpacing: 24,
                children: [
                  _buildInfoColumn('REPORT ID', '#${widget.report.id?.toUpperCase() ?? "N/A"}'),
                  _buildInfoColumn('CATEGORY', widget.report.category.toUpperCase()),
                  _buildInfoColumn('REPORTER', widget.report.isAnonymous ? 'Anonymous' : 'Registered User'),
                  _buildInfoColumn('LOCATION', locationDisplay),
                  _buildInfoColumn('COORDINATES', '${widget.report.latitude.toStringAsFixed(5)}, ${widget.report.longitude.toStringAsFixed(5)}'),
                ],
              ),
              const SizedBox(height: 32),
              const Text('DETAILED DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted)),
              const SizedBox(height: 8),
              Text(widget.report.description, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF4A4E69))),
              const SizedBox(height: 32),
              const Text('MAP VIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted)),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FlutterMap(
                    options: MapOptions(initialCenter: LatLng(widget.report.latitude, widget.report.longitude), initialZoom: 15),
                    children: [
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                      MarkerLayer(markers: [
                        Marker(
                          point: LatLng(widget.report.latitude, widget.report.longitude),
                          child: const Icon(Icons.location_on, color: AppColors.red, size: 30),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (widget.report.evidenceUrls.isNotEmpty) _buildEvidenceCard(),
      ],
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildEvidenceCard() {
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
          const Text('EVIDENCE MEDIA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.report.evidenceUrls.map((url) => _buildEvidenceThumbnail(url)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceThumbnail(String url) {
    return InkWell(
      onTap: () => _showFullScreenImage(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 120,
            height: 120,
            color: AppColors.canvas,
            child: const Icon(Icons.broken_image_outlined, color: AppColors.slate),
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(child: Image.network(url, fit: BoxFit.contain)),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModerationPanel() {
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
          const Text('MODERATION CONTROL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 24),
          const Text('ADMIN NOTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Add internal notes or feedback...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('QUICK ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : () => _updateStatus('Verified'),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Approve as Verified'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : () => _updateStatus('Fake'),
              icon: const Icon(Icons.block),
              label: const Text('Reject as Fake'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.red, padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : () => _updateStatus('Resolved'),
              icon: const Icon(Icons.done_all),
              label: const Text('Mark as Resolved'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
          const Divider(height: 48),
          Center(
            child: TextButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline, color: AppColors.red),
              label: const Text('Delete Report', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(100), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified': return Colors.green;
      case 'fake': return Colors.red;
      case 'resolved': return Colors.blue;
      default: return Colors.orange;
    }
  }
}

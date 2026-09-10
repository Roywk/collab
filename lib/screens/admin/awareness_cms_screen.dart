import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/admin_repository.dart';
import 'admin_shell.dart';
import 'awareness_article_editor_screen.dart';

class AwarenessCmsScreen extends StatefulWidget {
  const AwarenessCmsScreen({
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
  State<AwarenessCmsScreen> createState() => _AwarenessCmsScreenState();
}

class _AwarenessCmsScreenState extends State<AwarenessCmsScreen> {
  late Future<List<Map<String, dynamic>>> _contentFuture;

  @override
  void initState() {
    super.initState();
    _refreshContent();
  }

  void _refreshContent() {
    setState(() {
      _contentFuture = widget.repository.getAwarenessContent();
    });
  }

  void _openEditor([String? articleId]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AwarenessArticleEditorScreen(
          articleId: articleId,
          repository: widget.repository,
        ),
      ),
    );
    if (result == true) {
      _refreshContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenuItem: 'Awareness CMS',
      onSignOut: widget.onSignOut,
      onOpenDashboard: widget.onOpenDashboard,
      onOpenReports: widget.onOpenReports,
      onOpenHeatmap: widget.onOpenHeatmap,
      onOpenVerifiedMerchants: widget.onOpenVerifiedMerchants,
      onOpenThreatDatabase: widget.onOpenThreatDatabase,
      onOpenAwarenessCms: widget.onOpenAwarenessCms,
      onOpenSettings: widget.onOpenSettings,
      onOpenPublishScamCase: widget.onOpenPublishScamCase,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final content = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Awareness CMS',
                        style: TextStyle(color: AppColors.navy, fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      Text('Manage educational articles and emergency alerts.',
                          style: TextStyle(color: AppColors.slate, fontSize: 13)),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Article'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 350),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Article Title')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Last Updated')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: content.map((item) {
                        return DataRow(
                          cells: [
                            DataCell(Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(item['category'] ?? '')),
                            DataCell(_buildStatusBadge(item['status'] ?? 'Draft')),
                            DataCell(Text(item['updated_at'] ?? '—')),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppColors.blue, size: 20),
                                    onPressed: () => _openEditor(item['id']?.toString()),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () {
                                      // Add delete confirmation
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isPublished = status == 'Published';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(color: isPublished ? Colors.green : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

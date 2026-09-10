import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/admin_repository.dart';

class AwarenessArticleEditorScreen extends StatefulWidget {
  const AwarenessArticleEditorScreen({
    this.articleId,
    required this.repository,
    super.key,
  });

  final String? articleId;
  final AdminRepository repository;

  @override
  State<AwarenessArticleEditorScreen> createState() =>
      _AwarenessArticleEditorScreenState();
}

class _AwarenessArticleEditorScreenState
    extends State<AwarenessArticleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _category = 'Education';
  String _status = 'Draft';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.articleId != null) {
      _loadArticle();
    }
  }

  void _loadArticle() {
    // Mock loading existing data
    _titleController.text = 'Common Taxi Scams in KL';
    _contentController.text = 'Always ensure the meter is running...';
    _category = 'Education';
    _status = 'Published';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    // In a real app, you would call repository.saveAwarenessArticle
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          widget.articleId == null ? 'Create Article' : 'Edit Article',
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Article Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Article Title',
                      hintText: 'e.g. How to spot fake tour guides',
                    ),
                    validator: (v) => v!.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          items: ['Education', 'Alert', 'Emergency', 'Guide']
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _category = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: 'Publication Status',
                          ),
                          items: ['Draft', 'Published', 'Archived']
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _status = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _contentController,
                    maxLines: 15,
                    decoration: const InputDecoration(
                      labelText: 'Content (Markdown Supported)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Content is required' : null,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'SEO & Metadata',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Tags (Comma separated)',
                      hintText: 'taxi, kuala lumpur, safety',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

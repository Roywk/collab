import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_theme.dart';
import '../../data/awareness_admin_repository.dart';
import '../../models/awareness_admin_models.dart';
import '../../services/address_lookup_service.dart';
import 'admin_shell.dart';

class AwarenessContentEditorScreen extends StatefulWidget {
  const AwarenessContentEditorScreen({
    required this.repository,
    required this.type,
    this.item,
    super.key,
  });

  final AwarenessAdminRepository repository;
  final AwarenessContentType type;
  final AwarenessContentSummary? item;

  @override
  State<AwarenessContentEditorScreen> createState() =>
      _AwarenessContentEditorScreenState();
}

class _AwarenessContentEditorScreenState
    extends State<AwarenessContentEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _secondary = TextEditingController();
  final _image = TextEditingController();
  final _redFlags = TextEditingController();
  final _hotspot = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _hotspotRadius = TextEditingController(text: '250');
  final _readTime = TextEditingController(text: '3 min');
  final _xp = TextEditingController(text: '20');
  final _timeLimit = TextEditingController(text: '15');
  final _mediaCaption = TextEditingController();
  final List<TextEditingController> _options = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<_QuizQuestionFields> _quizQuestions = [_QuizQuestionFields()];

  late final Future<void> _loadFuture;
  String _category = 'Transport Scams';
  String _difficulty = 'Beginner';
  String _status = 'draft';
  bool _locationBased = false;
  int _correctIndex = 0;
  bool _saving = false;
  bool _uploading = false;
  String? _error;
  String _scenarioMediaType = 'none';

  static const categories = [
    'Transport Scams',
    'Payment & QR Fraud',
    'Phishing & Online Scams',
    'Street Scams',
    'Tour Guide Scams',
    'Shopping Scams',
    'Religious Site Scams',
    'Physical Safety',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final id = widget.item?.id;
    if (id == null) {
      if (widget.type == AwarenessContentType.scenario) _xp.text = '50';
      if (widget.type == AwarenessContentType.quiz) _xp.text = '80';
      return;
    }
    switch (widget.type) {
      case AwarenessContentType.lesson:
        final item = await widget.repository.getLesson(id);
        _title.text = item.title;
        _body.text = item.content;
        _secondary.text = item.whatToDo;
        _image.text = item.imageUrl ?? '';
        _redFlags.text = item.redFlags.join('\n');
        _hotspot.text = item.hotspotLabel ?? '';
        _latitude.text = item.latitude?.toString() ?? '';
        _longitude.text = item.longitude?.toString() ?? '';
        _hotspotRadius.text = '${item.hotspotRadiusMeters}';
        _readTime.text = item.readTime;
        _xp.text = '${item.xpReward}';
        _category = item.category;
        _difficulty = item.difficulty;
        _status = item.status;
        _locationBased = item.isLocationBased;
        break;
      case AwarenessContentType.quiz:
        final item = await widget.repository.getQuiz(id);
        _title.text = item.title;
        _body.text = item.description;
        _xp.text = '${item.xpReward}';
        _category = item.category;
        _difficulty = item.difficulty;
        _status = item.status;
        for (final question in _quizQuestions) {
          question.dispose();
        }
        _quizQuestions
          ..clear()
          ..addAll(item.questions.map(_QuizQuestionFields.fromDraft));
        if (_quizQuestions.isEmpty) _quizQuestions.add(_QuizQuestionFields());
        break;
      case AwarenessContentType.scenario:
        final item = await widget.repository.getScenario(id);
        _title.text = item.title;
        _body.text = item.description;
        _secondary.text = item.situation;
        for (var i = 0; i < item.options.length && i < _options.length; i++) {
          _options[i].text = item.options[i];
        }
        _correctIndex = item.correctIndex.clamp(0, 3);
        _redFlags.text = item.feedback;
        _xp.text = '${item.xpReward}';
        _category = item.category;
        _difficulty = item.difficulty;
        _status = item.status;
        _scenarioMediaType = item.mediaType;
        _image.text = item.mediaUrl ?? '';
        _mediaCaption.text = item.mediaCaption ?? '';
        break;
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _body,
      _secondary,
      _image,
      _redFlags,
      _hotspot,
      _latitude,
      _longitude,
      _hotspotRadius,
      _readTime,
      _xp,
      _timeLimit,
      _mediaCaption,
      ..._options,
    ]) {
      controller.dispose();
    }
    for (final question in _quizQuestions) {
      question.dispose();
    }
    super.dispose();
  }

  Future<void> _save(String status) async {
    if (!_formKey.currentState!.validate()) return;
    if (status == 'published') {
      final approved = await _confirmPublish();
      if (!approved) return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final cleanOptions = _options
          .map((controller) => controller.text.trim())
          .where((option) => option.isNotEmpty)
          .toList();
      switch (widget.type) {
        case AwarenessContentType.lesson:
          await widget.repository.saveLesson(
            AdminLessonDraft(
              id: widget.item?.id,
              title: _title.text.trim(),
              category: _category,
              difficulty: _difficulty,
              readTime: _readTime.text.trim(),
              content: _body.text.trim(),
              redFlags: _redFlags.text
                  .split(RegExp(r'[\n;]+'))
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toList(),
              whatToDo: _secondary.text.trim(),
              xpReward: int.parse(_xp.text.trim()),
              status: status,
              imageUrl: _image.text.trim(),
              hotspotLabel: _hotspot.text.trim(),
              latitude: double.tryParse(_latitude.text.trim()),
              longitude: double.tryParse(_longitude.text.trim()),
              hotspotRadiusMeters: int.parse(_hotspotRadius.text.trim()),
              isLocationBased: _locationBased,
            ),
          );
          break;
        case AwarenessContentType.quiz:
          final questions = _quizQuestions
              .map((fields) => fields.toDraft())
              .toList();
          if (questions.isEmpty) throw Exception('Add at least one question.');
          await widget.repository.saveQuiz(
            AdminQuizDraft(
              id: widget.item?.id,
              title: _title.text.trim(),
              description: _body.text.trim(),
              category: _category,
              difficulty: _difficulty,
              xpReward: int.parse(_xp.text.trim()),
              status: status,
              questions: questions,
            ),
          );
          break;
        case AwarenessContentType.scenario:
          if (cleanOptions.length < 2 || _correctIndex >= cleanOptions.length) {
            throw Exception(
              'Add at least two choices and select a valid answer.',
            );
          }
          await widget.repository.saveScenario(
            AdminScenarioDraft(
              id: widget.item?.id,
              title: _title.text.trim(),
              description: _body.text.trim(),
              category: _category,
              difficulty: _difficulty,
              xpReward: int.parse(_xp.text.trim()),
              situation: _secondary.text.trim(),
              options: cleanOptions,
              correctIndex: _correctIndex,
              feedback: _redFlags.text.trim(),
              status: status,
              mediaType: _scenarioMediaType,
              mediaUrl: _image.text.trim(),
              mediaCaption: _mediaCaption.text.trim(),
            ),
          );
          break;
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        final message = error.toString();
        setState(() {
          _error =
              message.contains('23505') ||
                  message.toLowerCase().contains('duplicate')
              ? 'A ${widget.type.label.toLowerCase()} with the same title or question already exists. Edit the existing item instead of publishing a duplicate.'
              : message;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadMedia(
    TextEditingController target, {
    required String mediaType,
    required String folder,
  }) async {
    final picker = ImagePicker();
    final file = mediaType == 'video'
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final extension = file.name.split('.').last.toLowerCase();
    final allowed = mediaType == 'video'
        ? const {'mp4'}
        : const {'jpg', 'jpeg', 'png'};
    if (!allowed.contains(extension)) {
      setState(
        () => _error = mediaType == 'video'
            ? 'Choose an MP4 video.'
            : 'Choose a JPG, JPEG, or PNG image.',
      );
      return;
    }
    final bytes = await file.readAsBytes();
    final limit = mediaType == 'video' ? 50 * 1024 * 1024 : 10 * 1024 * 1024;
    if (bytes.length > limit) {
      setState(
        () => _error = mediaType == 'video'
            ? 'Video must be 50 MB or smaller.'
            : 'Image must be 10 MB or smaller.',
      );
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final contentType = mediaType == 'video'
          ? 'video/mp4'
          : extension == 'png'
          ? 'image/png'
          : 'image/jpeg';
      final url = await widget.repository.uploadAwarenessMedia(
        bytes: bytes,
        fileName: file.name,
        folder: folder,
        contentType: contentType,
      );
      if (mounted) setState(() => target.text = url);
    } catch (error) {
      if (mounted) setState(() => _error = 'Upload failed: $error');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<bool> _confirmPublish() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Align(
              alignment: Alignment.centerLeft,
              child: CircleAvatar(
                backgroundColor: AppColors.blueSoft,
                child: Icon(
                  Icons.rocket_launch_outlined,
                  color: AppColors.blue,
                ),
              ),
            ),
            title: const Text('Publish content?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This content will be immediately available to tourists using Visit 1MY.',
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.type.label.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _title.text,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Category: $_category',
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.publish, size: 17),
                label: const Text('Publish now'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenuItem: 'Awareness CMS',
      headerTitle: 'Content Editor',
      onBack: () => Navigator.of(context).pop(),
      child: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Content could not be loaded: ${snapshot.error}'),
            );
          }
          return _buildEditor();
        },
      ),
    );
  }

  Widget _buildEditor() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _EditorHeading(type: widget.type, editing: widget.item != null),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: Column(
                children: [
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.redSoft,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: AppColors.red,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 850;
                      final Widget primary =
                          widget.type == AwarenessContentType.quiz
                          ? _QuizSetPrimaryEditor(
                              title: _title,
                              description: _body,
                              questions: _quizQuestions,
                              uploading: _uploading,
                              onAddQuestion: () => setState(
                                () => _quizQuestions.add(_QuizQuestionFields()),
                              ),
                              onRemoveQuestion: (index) {
                                if (_quizQuestions.length == 1) return;
                                setState(() {
                                  _quizQuestions.removeAt(index).dispose();
                                });
                              },
                              onChanged: () => setState(() {}),
                              onUpload: (fields) => _uploadMedia(
                                fields.image,
                                mediaType: 'image',
                                folder: 'quiz',
                              ),
                            )
                          : _PrimaryEditor(
                              type: widget.type,
                              title: _title,
                              body: _body,
                              secondary: _secondary,
                              redFlags: _redFlags,
                              options: _options,
                              correctIndex: _correctIndex,
                              onCorrectChanged: (value) =>
                                  setState(() => _correctIndex = value),
                            );
                      final settings = _EditorSettings(
                        type: widget.type,
                        category: _category,
                        difficulty: _difficulty,
                        image: _image,
                        hotspot: _hotspot,
                        latitude: _latitude,
                        longitude: _longitude,
                        hotspotRadius: _hotspotRadius,
                        readTime: _readTime,
                        xp: _xp,
                        timeLimit: _timeLimit,
                        locationBased: _locationBased,
                        mediaType: _scenarioMediaType,
                        mediaCaption: _mediaCaption,
                        uploading: _uploading,
                        onCategoryChanged: (value) =>
                            setState(() => _category = value),
                        onDifficultyChanged: (value) =>
                            setState(() => _difficulty = value),
                        onLocationChanged: (value) =>
                            setState(() => _locationBased = value),
                        onMediaTypeChanged: (value) =>
                            setState(() => _scenarioMediaType = value),
                        onUpload: (mediaType) => _uploadMedia(
                          _image,
                          mediaType: mediaType,
                          folder: widget.type.name,
                        ),
                      );
                      if (!wide) {
                        return Column(
                          children: [
                            primary,
                            const SizedBox(height: 14),
                            settings,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: primary),
                          const SizedBox(width: 14),
                          Expanded(flex: 3, child: settings),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          _EditorActions(
            saving: _saving,
            currentStatus: _status,
            onCancel: () => Navigator.of(context).pop(),
            onDraft: () => _save('draft'),
            onArchive: () => _save('archived'),
            onPublish: () => _save('published'),
          ),
        ],
      ),
    );
  }
}

class _EditorHeading extends StatelessWidget {
  const _EditorHeading({required this.type, required this.editing});
  final AwarenessContentType type;
  final bool editing;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: _accent(type).withValues(alpha: .1),
          child: Icon(_icon(type), color: _accent(type), size: 19),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${editing ? 'Edit' : 'Create'} ${type.label}',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              _subtitle(type),
              style: const TextStyle(color: AppColors.slate, fontSize: 9),
            ),
          ],
        ),
      ],
    ),
  );
}

class _QuizSetPrimaryEditor extends StatelessWidget {
  const _QuizSetPrimaryEditor({
    required this.title,
    required this.description,
    required this.questions,
    required this.uploading,
    required this.onAddQuestion,
    required this.onRemoveQuestion,
    required this.onChanged,
    required this.onUpload,
  });

  final TextEditingController title;
  final TextEditingController description;
  final List<_QuizQuestionFields> questions;
  final bool uploading;
  final VoidCallback onAddQuestion;
  final ValueChanged<int> onRemoveQuestion;
  final VoidCallback onChanged;
  final ValueChanged<_QuizQuestionFields> onUpload;

  @override
  Widget build(BuildContext context) => _EditorCard(
    title: 'Quiz builder',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('QUIZ TITLE'),
        TextFormField(
          controller: title,
          decoration: const InputDecoration(
            hintText: 'e.g. QR Payment Safety Challenge',
          ),
          validator: _required,
        ),
        const SizedBox(height: 12),
        const _Label('QUIZ BRIEFING'),
        TextFormField(
          controller: description,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Tell travellers what this short challenge teaches.',
          ),
          validator: _required,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              '${questions.length} ${questions.length == 1 ? 'QUESTION' : 'QUESTIONS'}',
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: questions.length >= 20 ? null : onAddQuestion,
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Add question'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(questions.length, (index) {
          final fields = questions[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFEDE9FE),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Question card',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      tooltip: questions.length == 1
                          ? 'A quiz needs at least one question'
                          : 'Remove question',
                      onPressed: questions.length == 1
                          ? null
                          : () => onRemoveQuestion(index),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                TextFormField(
                  controller: fields.question,
                  decoration: const InputDecoration(labelText: 'Question'),
                  validator: _required,
                ),
                const SizedBox(height: 9),
                for (
                  var optionIndex = 0;
                  optionIndex < fields.options.length;
                  optionIndex++
                )
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Mark as correct answer',
                          onPressed: () {
                            fields.correctIndex = optionIndex;
                            onChanged();
                          },
                          icon: Icon(
                            fields.correctIndex == optionIndex
                                ? Icons.check_circle
                                : Icons.radio_button_off,
                            color: fields.correctIndex == optionIndex
                                ? AppColors.green
                                : AppColors.slate,
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: fields.options[optionIndex],
                            decoration: InputDecoration(
                              labelText:
                                  'Answer ${String.fromCharCode(65 + optionIndex)}',
                            ),
                            validator: optionIndex < 2 ? _required : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                TextFormField(
                  controller: fields.explanation,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Correct-answer explanation',
                    hintText: 'Explain why this answer is safest.',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 9),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        controller: fields.timeLimit,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Seconds',
                          prefixIcon: Icon(Icons.timer_outlined, size: 17),
                        ),
                        validator: _positiveNumber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: fields.image,
                        decoration: const InputDecoration(
                          labelText: 'Image URL (optional)',
                          prefixIcon: Icon(Icons.link, size: 17),
                        ),
                        validator: _optionalHttpUrl,
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      onPressed: uploading ? null : () => onUpload(fields),
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text('Upload'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );
}

class _PrimaryEditor extends StatelessWidget {
  const _PrimaryEditor({
    required this.type,
    required this.title,
    required this.body,
    required this.secondary,
    required this.redFlags,
    required this.options,
    required this.correctIndex,
    required this.onCorrectChanged,
  });
  final AwarenessContentType type;
  final TextEditingController title;
  final TextEditingController body;
  final TextEditingController secondary;
  final TextEditingController redFlags;
  final List<TextEditingController> options;
  final int correctIndex;
  final ValueChanged<int> onCorrectChanged;
  @override
  Widget build(BuildContext context) => _EditorCard(
    title: switch (type) {
      AwarenessContentType.lesson => 'Lesson content',
      AwarenessContentType.quiz => 'Question & answers',
      AwarenessContentType.scenario => 'Simulation narrative',
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(switch (type) {
          AwarenessContentType.lesson => 'LESSON TITLE',
          AwarenessContentType.quiz => 'QUESTION',
          AwarenessContentType.scenario => 'SCENARIO TITLE',
        }),
        TextFormField(
          controller: title,
          decoration: InputDecoration(
            hintText: switch (type) {
              AwarenessContentType.lesson => 'e.g. KL taxi meter scams',
              AwarenessContentType.quiz =>
                'What is suspicious about this QR stand?',
              AwarenessContentType.scenario => 'e.g. Taxi tout at KLIA',
            },
          ),
          validator: _required,
        ),
        const SizedBox(height: 14),
        if (type != AwarenessContentType.quiz) ...[
          _Label(
            type == AwarenessContentType.lesson
                ? 'CONTENT BODY'
                : 'SCENARIO OVERVIEW',
          ),
          TextFormField(
            controller: body,
            minLines: type == AwarenessContentType.lesson ? 8 : 3,
            maxLines: type == AwarenessContentType.lesson ? 14 : 6,
            decoration: InputDecoration(
              hintText: type == AwarenessContentType.lesson
                  ? 'Write clear, practical safety guidance for tourists...'
                  : 'Set the scene and explain the learning objective...',
            ),
            validator: _required,
          ),
          const SizedBox(height: 14),
        ],
        _Label(switch (type) {
          AwarenessContentType.lesson => 'WHAT TO DO',
          AwarenessContentType.quiz => 'EXPLANATION AFTER ANSWER',
          AwarenessContentType.scenario => 'THE SITUATION',
        }),
        TextFormField(
          controller: secondary,
          minLines: 3,
          maxLines: 7,
          decoration: InputDecoration(
            hintText: switch (type) {
              AwarenessContentType.lesson =>
                'Give direct, memorable actions...',
              AwarenessContentType.quiz =>
                'Explain why the correct signal matters...',
              AwarenessContentType.scenario =>
                'Describe what the scammer says or does...',
            },
          ),
          validator: _required,
        ),
        const SizedBox(height: 14),
        if (type == AwarenessContentType.lesson) ...[
          const _Label('RED FLAGS · ONE PER LINE'),
          TextFormField(
            controller: redFlags,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(
              hintText:
                  'Driver refuses to use the meter\nPrice changes after luggage is loaded',
            ),
          ),
        ] else ...[
          const _Label('CHOICES'),
          for (var index = 0; index < options.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Mark as correct answer',
                    onPressed: () => onCorrectChanged(index),
                    icon: Icon(
                      index == correctIndex
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: index == correctIndex
                          ? AppColors.green
                          : AppColors.slate,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: options[index],
                      decoration: InputDecoration(
                        hintText:
                            'Option ${String.fromCharCode(65 + index)}${index == 0 ? ' · mark the correct answer' : ''}',
                      ),
                      validator: index < 2 ? _required : null,
                    ),
                  ),
                ],
              ),
            ),
          if (type == AwarenessContentType.scenario) ...[
            const SizedBox(height: 5),
            const _Label('FEEDBACK SHOWN AFTER CHOICE'),
            TextFormField(
              controller: redFlags,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText:
                    'Explain the consequence and reinforce the safest response...',
              ),
              validator: _required,
            ),
          ],
        ],
      ],
    ),
  );
}

class _EditorSettings extends StatelessWidget {
  const _EditorSettings({
    required this.type,
    required this.category,
    required this.difficulty,
    required this.image,
    required this.hotspot,
    required this.latitude,
    required this.longitude,
    required this.hotspotRadius,
    required this.readTime,
    required this.xp,
    required this.timeLimit,
    required this.locationBased,
    required this.onCategoryChanged,
    required this.onDifficultyChanged,
    required this.onLocationChanged,
    required this.mediaType,
    required this.mediaCaption,
    required this.onMediaTypeChanged,
    required this.uploading,
    required this.onUpload,
  });
  final AwarenessContentType type;
  final String category;
  final String difficulty;
  final TextEditingController image;
  final TextEditingController hotspot;
  final TextEditingController latitude;
  final TextEditingController longitude;
  final TextEditingController hotspotRadius;
  final TextEditingController readTime;
  final TextEditingController xp;
  final TextEditingController timeLimit;
  final bool locationBased;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onDifficultyChanged;
  final ValueChanged<bool> onLocationChanged;
  final String mediaType;
  final TextEditingController mediaCaption;
  final ValueChanged<String> onMediaTypeChanged;
  final bool uploading;
  final ValueChanged<String> onUpload;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _EditorCard(
        title: 'Classification',
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue:
                  AwarenessContentEditorScreenStateHelper.safeCategory(
                    category,
                  ),
              decoration: const InputDecoration(labelText: 'Category'),
              items: AwarenessContentEditorScreenStateHelper.categories
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onCategoryChanged(value);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue:
                  ['Beginner', 'Intermediate', 'Advanced'].contains(difficulty)
                  ? difficulty
                  : 'Beginner',
              decoration: const InputDecoration(labelText: 'Difficulty'),
              items: const [
                DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                DropdownMenuItem(
                  value: 'Intermediate',
                  child: Text('Intermediate'),
                ),
                DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
              ],
              onChanged: (value) {
                if (value != null) onDifficultyChanged(value);
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: xp,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'XP reward'),
                    validator: _positiveNumber,
                  ),
                ),
                if (type == AwarenessContentType.lesson) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: readTime,
                      decoration: const InputDecoration(labelText: 'Read time'),
                      validator: _required,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      if (type == AwarenessContentType.lesson)
        _EditorCard(
          title: type == AwarenessContentType.lesson
              ? 'Cover media'
              : 'Question image',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_outlined,
                      color: AppColors.blue,
                      size: 28,
                    ),
                    const SizedBox(height: 5),
                    OutlinedButton.icon(
                      onPressed: uploading ? null : () => onUpload('image'),
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: Text(uploading ? 'Uploading…' : 'Upload image'),
                    ),
                    const Text(
                      'JPG, JPEG or PNG · or paste a URL below',
                      style: TextStyle(color: AppColors.slate, fontSize: 9),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              TextFormField(
                controller: image,
                decoration: const InputDecoration(
                  hintText: 'https://.../cover.jpg',
                  prefixIcon: Icon(Icons.link, size: 17),
                ),
                validator: _optionalHttpUrl,
              ),
            ],
          ),
        ),
      if (type == AwarenessContentType.scenario)
        _EditorCard(
          title: 'Scenario media',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: ['none', 'image', 'video'].contains(mediaType)
                    ? mediaType
                    : 'none',
                decoration: const InputDecoration(labelText: 'Media type'),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('No media')),
                  DropdownMenuItem(value: 'image', child: Text('Photo')),
                  DropdownMenuItem(value: 'video', child: Text('Video')),
                ],
                onChanged: (value) {
                  if (value != null) onMediaTypeChanged(value);
                },
              ),
              if (mediaType != 'none') ...[
                const SizedBox(height: 9),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: uploading ? null : () => onUpload(mediaType),
                    icon: const Icon(Icons.upload_file, size: 17),
                    label: Text(
                      uploading
                          ? 'Uploading…'
                          : mediaType == 'video'
                          ? 'Upload MP4 video'
                          : 'Upload JPG, JPEG or PNG',
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                TextFormField(
                  controller: image,
                  decoration: InputDecoration(
                    labelText: mediaType == 'video'
                        ? 'Public video URL'
                        : 'Public image URL',
                    prefixIcon: Icon(
                      mediaType == 'video'
                          ? Icons.play_circle_outline
                          : Icons.image_outlined,
                    ),
                    helperText: 'Upload a file or paste a public URL.',
                  ),
                  validator: (value) =>
                      _required(value) ?? _optionalHttpUrl(value),
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: mediaCaption,
                  decoration: const InputDecoration(
                    labelText: 'Accessible caption',
                    hintText: 'Explain what the traveller should notice',
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
        ),
      if (type == AwarenessContentType.lesson) ...[
        const SizedBox(height: 14),
        _EditorCard(
          title: 'Just-in-time hotspot',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: locationBased,
                onChanged: onLocationChanged,
                title: const Text(
                  'Location-triggered lesson',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Marks content for geofenced delivery.',
                  style: TextStyle(fontSize: 9),
                ),
              ),
              if (locationBased) ...[
                TextFormField(
                  controller: hotspot,
                  decoration: const InputDecoration(
                    labelText: 'Hotspot label',
                    hintText: 'Bukit Bintang',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: latitude,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                        validator: _coordinate,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: TextFormField(
                        controller: longitude,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                        validator: _coordinate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: hotspotRadius,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Trigger radius (metres)',
                    prefixIcon: Icon(Icons.radar, size: 18),
                    helperText: 'Recommended: 100–1000 metres',
                  ),
                  validator: (value) {
                    final radiusValue = int.tryParse(value ?? '');
                    if (radiusValue == null ||
                        radiusValue < 50 ||
                        radiusValue > 5000) {
                      return 'Use a radius from 50 to 5000 metres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 9),
                _HotspotMapPicker(
                  hotspot: hotspot,
                  latitude: latitude,
                  longitude: longitude,
                  radius: hotspotRadius,
                ),
              ],
            ],
          ),
        ),
      ],
    ],
  );
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _HotspotMapPicker extends StatefulWidget {
  const _HotspotMapPicker({
    required this.hotspot,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  final TextEditingController hotspot;
  final TextEditingController latitude;
  final TextEditingController longitude;
  final TextEditingController radius;

  @override
  State<_HotspotMapPicker> createState() => _HotspotMapPickerState();
}

class _HotspotMapPickerState extends State<_HotspotMapPicker> {
  final _addressLookup = AddressLookupService();
  LatLng? _selected;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final latitude = double.tryParse(widget.latitude.text);
    final longitude = double.tryParse(widget.longitude.text);
    if (latitude != null && longitude != null) {
      _selected = LatLng(latitude, longitude);
    }
  }

  @override
  void dispose() {
    _addressLookup.dispose();
    super.dispose();
  }

  Future<void> _selectArea(LatLng point) async {
    if (_locating) return;
    setState(() {
      _selected = point;
      _locating = true;
    });
    final area = await _addressLookup.areaFromCoordinates(
      latitude: point.latitude,
      longitude: point.longitude,
    );
    if (!mounted) return;
    final label = area?.trim().isNotEmpty == true
        ? area!.trim()
        : 'Selected area';
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.location_on, color: AppColors.blue),
            title: const Text('Is this the area region?'),
            content: Text(
              '$label\n\nCentre: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}\nRadius: ${widget.radius.text} metres',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No, choose again'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, use this area'),
              ),
            ],
          ),
        ) ??
        false;
    if (!mounted) return;
    setState(() => _locating = false);
    if (!confirmed) return;
    widget.hotspot.text = label;
    widget.latitude.text = point.latitude.toStringAsFixed(6);
    widget.longitude.text = point.longitude.toStringAsFixed(6);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tap the map to choose the centre of the trigger area. The place name is filled automatically.',
          style: TextStyle(color: AppColors.slate, fontSize: 9),
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 260,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: selected ?? const LatLng(3.1390, 101.6869),
                    initialZoom: selected == null ? 12.5 : 15,
                    onTap: (_, point) => _selectArea(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.visit1my.collab',
                    ),
                    if (selected != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: selected,
                            radius: 42,
                            color: AppColors.blue.withValues(alpha: .16),
                            borderColor: AppColors.blue,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    if (selected != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selected,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: AppColors.red,
                              size: 38,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_locating)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x66FFFFFF),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizQuestionFields {
  _QuizQuestionFields({
    this.id,
    String question = '',
    String explanation = '',
    String image = '',
    int timeLimitSeconds = 15,
    List<String> options = const [],
    this.correctIndex = 0,
  }) : question = TextEditingController(text: question),
       explanation = TextEditingController(text: explanation),
       image = TextEditingController(text: image),
       timeLimit = TextEditingController(text: '$timeLimitSeconds'),
       options = List.generate(
         4,
         (index) => TextEditingController(
           text: index < options.length ? options[index] : '',
         ),
       );

  factory _QuizQuestionFields.fromDraft(AdminQuizQuestionDraft draft) =>
      _QuizQuestionFields(
        id: draft.id,
        question: draft.question,
        explanation: draft.explanation,
        image: draft.imageUrl ?? '',
        timeLimitSeconds: draft.timeLimitSeconds,
        options: draft.options,
        correctIndex: draft.correctIndex.clamp(0, 3),
      );

  final String? id;
  final TextEditingController question;
  final TextEditingController explanation;
  final TextEditingController image;
  final TextEditingController timeLimit;
  final List<TextEditingController> options;
  int correctIndex;

  AdminQuizQuestionDraft toDraft() {
    final selectedAnswer = options[correctIndex].text.trim();
    final cleanOptions = options
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (cleanOptions.length < 2 || selectedAnswer.isEmpty) {
      throw StateError(
        'Every question needs at least two answers and one marked correct answer.',
      );
    }
    final seconds = int.parse(timeLimit.text.trim());
    if (seconds < 5 || seconds > 300) {
      throw StateError('Question time limits must be from 5 to 300 seconds.');
    }
    return AdminQuizQuestionDraft(
      id: id,
      question: question.text.trim(),
      options: cleanOptions,
      correctIndex: cleanOptions.indexOf(selectedAnswer),
      explanation: explanation.text.trim(),
      timeLimitSeconds: seconds,
      imageUrl: image.text.trim(),
    );
  }

  void dispose() {
    question.dispose();
    explanation.dispose();
    image.dispose();
    timeLimit.dispose();
    for (final controller in options) {
      controller.dispose();
    }
  }
}

class _EditorActions extends StatelessWidget {
  const _EditorActions({
    required this.saving,
    required this.currentStatus,
    required this.onCancel,
    required this.onDraft,
    required this.onArchive,
    required this.onPublish,
  });
  final bool saving;
  final String currentStatus;
  final VoidCallback onCancel;
  final VoidCallback onDraft;
  final VoidCallback onArchive;
  final VoidCallback onPublish;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: AppColors.line)),
    ),
    child: Row(
      children: [
        OutlinedButton(
          onPressed: saving ? null : onCancel,
          child: const Text('Discard changes'),
        ),
        const Spacer(),
        if (saving)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        OutlinedButton.icon(
          onPressed: saving ? null : onDraft,
          icon: const Icon(Icons.save_outlined, size: 16),
          label: Text(
            currentStatus == 'draft' ? 'Save draft' : 'Unpublish to draft',
          ),
        ),
        const SizedBox(width: 9),
        OutlinedButton.icon(
          onPressed: saving ? null : onArchive,
          icon: const Icon(Icons.archive_outlined, size: 16),
          label: const Text('Keep as archived'),
        ),
        const SizedBox(width: 9),
        FilledButton.icon(
          onPressed: saving ? null : onPublish,
          icon: const Icon(Icons.publish, size: 16),
          label: Text(
            currentStatus == 'published'
                ? 'Save & keep published'
                : 'Save & publish',
          ),
        ),
      ],
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.slate,
        fontSize: 8,
        fontWeight: FontWeight.w800,
        letterSpacing: .4,
      ),
    ),
  );
}

abstract final class AwarenessContentEditorScreenStateHelper {
  static const categories = _AwarenessContentEditorScreenState.categories;
  static String safeCategory(String value) =>
      categories.contains(value) ? value : 'General';
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Required' : null;
String? _positiveNumber(String? value) {
  final number = int.tryParse(value ?? '');
  return number == null || number <= 0 ? 'Enter a positive number' : null;
}

String? _optionalHttpUrl(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final uri = Uri.tryParse(text);
  if (uri == null ||
      !{'http', 'https'}.contains(uri.scheme) ||
      uri.host.isEmpty) {
    return 'Enter a complete http:// or https:// URL.';
  }
  return null;
}

String? _coordinate(String? value) =>
    double.tryParse(value ?? '') == null ? 'Required' : null;

Color _accent(AwarenessContentType type) => switch (type) {
  AwarenessContentType.lesson => AppColors.blue,
  AwarenessContentType.quiz => const Color(0xFF7C3AED),
  AwarenessContentType.scenario => const Color(0xFFDB2777),
};
IconData _icon(AwarenessContentType type) => switch (type) {
  AwarenessContentType.lesson => Icons.menu_book_outlined,
  AwarenessContentType.quiz => Icons.quiz_outlined,
  AwarenessContentType.scenario => Icons.alt_route,
};
String _subtitle(AwarenessContentType type) => switch (type) {
  AwarenessContentType.lesson =>
    'Create a practical safety guide or location-triggered insider tip',
  AwarenessContentType.quiz => 'Build a timed fraud-recognition challenge',
  AwarenessContentType.scenario =>
    'Rehearse a high-pressure scam encounter safely',
};

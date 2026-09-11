import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/awareness_admin_repository.dart';
import '../../models/awareness_admin_models.dart';
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
  final _readTime = TextEditingController(text: '3 min');
  final _xp = TextEditingController(text: '20');
  final _timeLimit = TextEditingController(text: '15');
  final _mediaCaption = TextEditingController();
  final List<TextEditingController> _options = List.generate(
    4,
    (_) => TextEditingController(),
  );

  late final Future<void> _loadFuture;
  String _category = 'Transport Scams';
  String _difficulty = 'Beginner';
  String _status = 'draft';
  bool _locationBased = false;
  int _correctIndex = 0;
  bool _saving = false;
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
        _readTime.text = item.readTime;
        _xp.text = '${item.xpReward}';
        _category = item.category;
        _difficulty = item.difficulty;
        _status = item.status;
        _locationBased = item.isLocationBased;
        break;
      case AwarenessContentType.quiz:
        final item = await widget.repository.getQuiz(id);
        _title.text = item.question;
        _secondary.text = item.explanation;
        _image.text = item.imageUrl ?? '';
        for (var i = 0; i < item.options.length && i < _options.length; i++) {
          _options[i].text = item.options[i];
        }
        _correctIndex = item.correctIndex.clamp(0, 3);
        _timeLimit.text = '${item.timeLimitSeconds}';
        _category = item.category;
        _difficulty = item.difficulty;
        _status = item.status;
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
      _readTime,
      _xp,
      _timeLimit,
      _mediaCaption,
      ..._options,
    ]) {
      controller.dispose();
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
              isLocationBased: _locationBased,
            ),
          );
          break;
        case AwarenessContentType.quiz:
          if (cleanOptions.length < 2 || _correctIndex >= cleanOptions.length) {
            throw Exception(
              'Add at least two options and select a valid answer.',
            );
          }
          await widget.repository.saveQuiz(
            AdminQuizDraft(
              id: widget.item?.id,
              question: _title.text.trim(),
              options: cleanOptions,
              correctIndex: _correctIndex,
              explanation: _secondary.text.trim(),
              category: _category,
              difficulty: _difficulty,
              timeLimitSeconds: int.parse(_timeLimit.text.trim()),
              status: status,
              imageUrl: _image.text.trim(),
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
                      final primary = _PrimaryEditor(
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
                        readTime: _readTime,
                        xp: _xp,
                        timeLimit: _timeLimit,
                        locationBased: _locationBased,
                        mediaType: _scenarioMediaType,
                        mediaCaption: _mediaCaption,
                        onCategoryChanged: (value) =>
                            setState(() => _category = value),
                        onDifficultyChanged: (value) =>
                            setState(() => _difficulty = value),
                        onLocationChanged: (value) =>
                            setState(() => _locationBased = value),
                        onMediaTypeChanged: (value) =>
                            setState(() => _scenarioMediaType = value),
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
  });
  final AwarenessContentType type;
  final String category;
  final String difficulty;
  final TextEditingController image;
  final TextEditingController hotspot;
  final TextEditingController latitude;
  final TextEditingController longitude;
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
            if (type == AwarenessContentType.quiz)
              TextFormField(
                controller: timeLimit,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Time limit (seconds)',
                  prefixIcon: Icon(Icons.timer_outlined, size: 18),
                ),
                validator: _positiveNumber,
              )
            else
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
                        decoration: const InputDecoration(
                          labelText: 'Read time',
                        ),
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
      if (type != AwarenessContentType.scenario)
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
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, color: AppColors.blue, size: 28),
                    SizedBox(height: 5),
                    Text(
                      'Paste a public Supabase Storage URL',
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
                  ),
                  validator: _required,
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

class _EditorActions extends StatelessWidget {
  const _EditorActions({
    required this.saving,
    required this.currentStatus,
    required this.onCancel,
    required this.onDraft,
    required this.onPublish,
  });
  final bool saving;
  final String currentStatus;
  final VoidCallback onCancel;
  final VoidCallback onDraft;
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

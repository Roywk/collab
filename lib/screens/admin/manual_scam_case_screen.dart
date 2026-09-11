import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_theme.dart';
import '../../core/haversine.dart';
import '../../data/scam_map_repository.dart';
import '../../models/scam_map_models.dart';
import 'admin_shell.dart';

class ManualScamCaseScreen extends StatefulWidget {
  const ManualScamCaseScreen({
    required this.repository,
    this.onBack,
    this.onPublished,
    this.popOnSuccess = true,
    this.onSignOut,
    this.onOpenDashboard,
    this.onOpenReports,
    this.onOpenHeatmap,
    this.onOpenVerifiedMerchants,
    this.onOpenThreatDatabase,
    this.onOpenAwarenessCms,
    this.onOpenSettings,
    this.onOpenBankHotlines,
    this.onOpenEmergencyFacilities,
    super.key,
  });

  final ScamMapRepository repository;
  final VoidCallback? onBack;
  final VoidCallback? onPublished;
  final bool popOnSuccess;
  final Future<void> Function()? onSignOut;
  final VoidCallback? onOpenDashboard;
  final VoidCallback? onOpenReports;
  final VoidCallback? onOpenHeatmap;
  final VoidCallback? onOpenVerifiedMerchants;
  final VoidCallback? onOpenThreatDatabase;
  final VoidCallback? onOpenAwarenessCms;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenBankHotlines;
  final VoidCallback? onOpenEmergencyFacilities;

  @override
  State<ManualScamCaseScreen> createState() => _ManualScamCaseScreenState();
}

class _ManualScamCaseScreenState extends State<ManualScamCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _locationController = TextEditingController();
  final _sourceController = TextEditingController();

  late Future<List<String>> _categoriesFuture;
  String _category = ScamCategories.taxi;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = widget.repository.getActiveCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _locationController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  double? get _latitude => double.tryParse(_latitudeController.text.trim());
  double? get _longitude => double.tryParse(_longitudeController.text.trim());

  bool get _coordinatesAreInKualaLumpur {
    final latitude = _latitude;
    final longitude = _longitude;
    return latitude != null &&
        longitude != null &&
        isCoordinateInKualaLumpur(latitude, longitude);
  }

  String? _validateCoordinate(String? value, {required bool latitude}) {
    final coordinate = double.tryParse(value?.trim() ?? '');
    if (coordinate == null) {
      return 'Enter a valid decimal coordinate';
    }

    if (latitude && (coordinate < -90 || coordinate > 90)) {
      return 'Latitude must be between -90 and 90';
    }
    if (!latitude && (coordinate < -180 || coordinate > 180)) {
      return 'Longitude must be between -180 and 180';
    }
    return null;
  }

  String? _validatePublicSource(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final uri = Uri.tryParse(text);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return 'Enter a public http:// or https:// URL';
    }
    return null;
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_coordinatesAreInKualaLumpur) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Coordinates must be within the Kuala Lumpur pilot area '
            '(3.03°N-3.25°N, 101.60°E-101.80°E).',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.repository.publishOfficialCase(
        ManualScamCase(
          title: _titleController.text,
          category: _category,
          description: _descriptionController.text,
          latitude: _latitude!,
          longitude: _longitude!,
          locationName: _locationController.text,
          sourceReference: _sourceController.text,
        ),
      );

      if (!mounted) return;
      if (widget.popOnSuccess) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Official scam case published successfully.'),
          ),
        );
        widget.onPublished?.call();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish the official case: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenuItem: 'Publish Official Cases',
      onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
      onSignOut: widget.onSignOut,
      onOpenDashboard: widget.onOpenDashboard,
      onOpenReports: widget.onOpenReports,
      onOpenHeatmap: widget.onOpenHeatmap,
      onOpenVerifiedMerchants: widget.onOpenVerifiedMerchants,
      onOpenThreatDatabase: widget.onOpenThreatDatabase,
      onOpenAwarenessCms: widget.onOpenAwarenessCms,
      onOpenBankHotlines: widget.onOpenBankHotlines,
      onOpenEmergencyFacilities: widget.onOpenEmergencyFacilities,
      headerTitle: 'Publish Official Cases',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Publish Official Scam Case',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add a verified PDRM or official incident to the public scam map.',
                style: TextStyle(color: AppColors.slate, fontSize: 12),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PDRM INCIDENT DOCUMENTATION FORM',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AdminFormField(
                      label: 'SCAM CASE TITLE *',
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText:
                              'e.g. Unauthorized taxi surcharge at Bukit Bintang',
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Title is required'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 15),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final category = _AdminFormField(
                          label: 'CATEGORY *',
                          child: FutureBuilder<List<String>>(
                            future: _categoriesFuture,
                            builder: (context, snapshot) {
                              final categories =
                                  snapshot.data ?? ScamCategories.values;
                              if (!categories.contains(_category)) {
                                _category = categories.first;
                              }

                              return DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _category,
                                items: categories
                                    .map(
                                      (category) => DropdownMenuItem(
                                        value: category,
                                        child: Text(
                                          category,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _category = value);
                                  }
                                },
                              );
                            },
                          ),
                        );
                        final source = _AdminFormField(
                          label: 'PUBLIC SOURCE URL',
                          child: TextFormField(
                            controller: _sourceController,
                            decoration: const InputDecoration(
                              hintText: 'https://www.rmp.gov.my/...',
                              helperText:
                                  'Public news or official-source links only',
                            ),
                            keyboardType: TextInputType.url,
                            validator: _validatePublicSource,
                          ),
                        );

                        if (constraints.maxWidth < 700) {
                          return Column(
                            children: [
                              category,
                              const SizedBox(height: 15),
                              source,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: category),
                            const SizedBox(width: 15),
                            Expanded(child: source),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    _AdminFormField(
                      label: 'DETAILED CASE DESCRIPTION *',
                      child: TextFormField(
                        controller: _descriptionController,
                        minLines: 4,
                        maxLines: 7,
                        decoration: const InputDecoration(
                          hintText:
                              'Describe the scam tactics and identifying details.',
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Description is required'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _AdminFormField(
                      label: 'LOCATION NAME',
                      child: TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Bukit Bintang, Kuala Lumpur',
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _AdminFormField(
                            label: 'LATITUDE *',
                            child: TextFormField(
                              controller: _latitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: '3.1478',
                              ),
                              validator: (value) =>
                                  _validateCoordinate(value, latitude: true),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _AdminFormField(
                            label: 'LONGITUDE *',
                            child: TextFormField(
                              controller: _longitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: '101.7134',
                              ),
                              validator: (value) =>
                                  _validateCoordinate(value, latitude: false),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _coordinatesAreInKualaLumpur
                          ? '● Valid — within Kuala Lumpur'
                          : 'KL bounds: 3.03°N-3.25°N, 101.60°E-101.80°E',
                      style: TextStyle(
                        color: _coordinatesAreInKualaLumpur
                            ? AppColors.green
                            : AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_coordinatesAreInKualaLumpur) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 220,
                          child: FlutterMap(
                            key: ValueKey('$_latitude,$_longitude'),
                            options: MapOptions(
                              initialCenter: LatLng(_latitude!, _longitude!),
                              initialZoom: 15,
                              interactionOptions: const InteractionOptions(
                                flags:
                                    InteractiveFlag.all &
                                    ~InteractiveFlag.rotate,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.collab',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(_latitude!, _longitude!),
                                    width: 44,
                                    height: 44,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: AppColors.red,
                                      size: 42,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Map preview confirms the selected publication point.',
                        style: TextStyle(color: AppColors.slate, fontSize: 10),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.blueSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            color: AppColors.blue,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Manual official cases are published automatically as Verified and display an official badge.',
                              style: TextStyle(
                                color: AppColors.blue,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 10,
                        children: [
                          OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          FilledButton.icon(
                            onPressed: _saving ? null : _publish,
                            icon: _saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.publish_outlined),
                            label: const Text('Publish Case'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminFormField extends StatelessWidget {
  const _AdminFormField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.slate,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

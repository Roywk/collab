import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../core/haversine.dart';
import '../../data/scam_map_repository.dart';
import '../../models/scam_map_models.dart';
import '../../services/location_service.dart';
import '../../services/scam_alert_notification_service.dart';

class ScamMapScreen extends StatefulWidget {
  const ScamMapScreen({
    required this.repository,
    this.onOpenVerification,
    super.key,
  });

  final ScamMapRepository repository;
  final VoidCallback? onOpenVerification;

  @override
  State<ScamMapScreen> createState() => _ScamMapScreenState();
}

class _ScamMapScreenState extends State<ScamMapScreen> {
  static const LatLng _kualaLumpur = LatLng(3.1390, 101.6869);

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  final ScamAlertNotificationService _notificationService =
      ScamAlertNotificationService();

  StreamSubscription<Position>? _positionSubscription;
  List<ScamMapReport> _reports = const [];
  Position? _position;
  String _selectedCategory = 'All';
  String? _locationMessage;
  String? _loadError;
  ScamMapReport? _nearbyReport;
  double? _nearbyDistance;
  bool _loading = true;
  bool _loadedFromCache = false;
  final Set<String> _alertedHotspots = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final result = await widget.repository.getActiveScamReports();
      if (!mounted) return;

      setState(() {
        _reports = result.reports;
        _loadedFromCache = result.loadedFromCache;
        _loading = false;
      });

      if (_position != null) {
        _evaluateProximity(_position!);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _startLocationTracking() async {
    await _positionSubscription?.cancel();

    try {
      final current = await _locationService.currentPosition();
      if (!mounted) return;

      _updatePosition(current, moveCamera: true);
      _positionSubscription = _locationService.watchPosition().listen(
        _updatePosition,
        onError: (Object error) {
          if (!mounted) return;
          setState(() {
            _locationMessage = error.toString();
          });
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationMessage = error.toString();
      });
    }
  }

  void _updatePosition(Position position, {bool moveCamera = false}) {
    if (!mounted) return;
    setState(() {
      _position = position;
      _locationMessage = null;
    });

    if (moveCamera) {
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    }

    _evaluateProximity(position);
  }

  void _evaluateProximity(Position position) {
    ScamMapReport? nearest;
    double? nearestDistance;

    for (final report in _reports.where((report) => report.isVerified)) {
      final distance = haversineDistanceMeters(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        endLatitude: report.latitude,
        endLongitude: report.longitude,
      );

      if (nearestDistance == null || distance < nearestDistance) {
        nearest = report;
        nearestDistance = distance;
      }

      if (distance > 250) {
        _alertedHotspots.remove(report.id);
      }
    }

    final isWithinAlertRange = nearest != null && nearestDistance! <= 200;
    setState(() {
      _nearbyReport = isWithinAlertRange ? nearest : null;
      _nearbyDistance = isWithinAlertRange ? nearestDistance : null;
    });

    if (isWithinAlertRange && _alertedHotspots.add(nearest.id)) {
      _notificationService.showNearbyHotspot(nearest, nearestDistance);
    }
  }

  List<ScamMapReport> get _filteredReports {
    if (_selectedCategory == 'All') {
      return _reports;
    }
    return _reports
        .where((report) => report.category == _selectedCategory)
        .toList();
  }

  List<String> get _categories {
    final values = _reports.map((report) => report.category).toSet().toList()
      ..sort();
    return ['All', ...values];
  }

  void _searchLocation() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return;

    final matches = _reports.where((report) {
      return report.title.toLowerCase().contains(query) ||
          report.category.toLowerCase().contains(query) ||
          (report.locationName?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No recorded scams found for this location.'),
        ),
      );
      return;
    }

    final report = matches.first;
    _mapController.move(LatLng(report.latitude, report.longitude), 16);
    _showReportDetails(report);
  }

  void _showReportDetails(ScamMapReport report) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => ScamMapDetailSheet(report: report),
    );
  }

  List<Marker> _buildMarkers() {
    return _filteredReports.map((report) {
      return Marker(
        point: LatLng(report.latitude, report.longitude),
        width: 46,
        height: 54,
        child: Semantics(
          button: true,
          label: '${report.status.label} scam: ${report.title}',
          child: GestureDetector(
            onTap: () => _showReportDetails(report),
            child: ScamMapMarker(report: report),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Scam Map',
      currentNavigationIndex: 1,
      onVerify:
          widget.onOpenVerification ??
          () => Navigator.of(context).pushNamed('/verify'),
      gpsActive: _position != null,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchLocation(),
              decoration: InputDecoration(
                hintText: 'Search landmark or street name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Search map',
                  onPressed: _searchLocation,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return FilterChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              },
            ),
          ),
          if (_nearbyReport != null)
            NearbyScamWarning(
              report: _nearbyReport!,
              distanceMeters: _nearbyDistance!,
              onViewDetails: () => _showReportDetails(_nearbyReport!),
            ),
          if (_locationMessage != null)
            MapMessageBanner(
              icon: Icons.location_off_outlined,
              color: AppColors.amber,
              message: _locationMessage!,
              actionLabel: 'Retry',
              onAction: _startLocationTracking,
            ),
          if (_loadedFromCache)
            const MapMessageBanner(
              icon: Icons.offline_bolt_outlined,
              color: AppColors.blue,
              message: 'Network offline. Showing cached scam-map data.',
            ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: _kualaLumpur,
                    initialZoom: 12,
                    minZoom: 5,
                    maxZoom: 19,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.collab',
                    ),
                    if (_position != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(
                              _position!.latitude,
                              _position!.longitude,
                            ),
                            radius: 9,
                            color: AppColors.blue.withValues(alpha: 0.25),
                            borderColor: Colors.white,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 48,
                        size: const Size(44, 44),
                        markers: _buildMarkers(),
                        builder: (context, markers) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${markers.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: const ScamStatusLegend(),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: FloatingActionButton.small(
                    heroTag: 'locate-user',
                    tooltip: 'My location',
                    onPressed: _startLocationTracking,
                    child: const Icon(Icons.my_location),
                  ),
                ),
                if (_loading)
                  const ColoredBox(
                    color: Color(0x55FFFFFF),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_loadError != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SurfaceCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off, color: AppColors.red),
                            const SizedBox(height: 8),
                            const Text(
                              'Scam map data could not be loaded.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: _loadReports,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScamMapMarker extends StatelessWidget {
  const ScamMapMarker({required this.report, super.key});

  final ScamMapReport report;

  @override
  Widget build(BuildContext context) {
    final color = report.isVerified ? AppColors.red : AppColors.amber;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 7),
            ],
          ),
          child: Icon(
            report.isOfficial
                ? Icons.verified_user_outlined
                : Icons.warning_amber_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        Container(width: 3, height: 7, color: color),
      ],
    );
  }
}

class ScamStatusLegend extends StatelessWidget {
  const ScamStatusLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 5)],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scam Status',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4),
          _LegendRow(color: AppColors.red, label: 'Verified Alerts'),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 8)),
      ],
    );
  }
}

class NearbyScamWarning extends StatelessWidget {
  const NearbyScamWarning({
    required this.report,
    required this.distanceMeters,
    required this.onViewDetails,
    super.key,
  });

  final ScamMapReport report;
  final double distanceMeters;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.redSoft,
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.red,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Scam Alert: ${report.title} is ${distanceMeters.round()}m away.',
              style: const TextStyle(
                color: AppColors.red,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onViewDetails, child: const Text('View')),
        ],
      ),
    );
  }
}

class MapMessageBanner extends StatelessWidget {
  const MapMessageBanner({
    required this.icon,
    required this.color,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      color: color.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 10)),
          ),
          if (onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel ?? 'Open')),
        ],
      ),
    );
  }
}

class ScamMapDetailSheet extends StatelessWidget {
  const ScamMapDetailSheet({required this.report, super.key});

  final ScamMapReport report;

  @override
  Widget build(BuildContext context) {
    final statusColor = report.isVerified ? AppColors.red : AppColors.amber;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    report.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (report.isOfficial)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blueSoft,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      'Official case',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.title,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${report.category} • ${DateFormat('dd MMM yyyy').format(report.reportedAt)}',
              style: const TextStyle(color: AppColors.slate, fontSize: 11),
            ),
            if ((report.locationName ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 17,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(report.locationName!)),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Text(
              report.description.isEmpty
                  ? 'No additional description was provided.'
                  : report.description,
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            if ((report.sourceReference ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Source: ${report.sourceReference}',
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
              style: const TextStyle(color: AppColors.muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

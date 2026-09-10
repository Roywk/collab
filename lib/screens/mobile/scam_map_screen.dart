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
import '../../data/learning_repository.dart';
import '../../models/scam_map_models.dart';
import '../../services/location_service.dart';
import '../../services/landmark_search_service.dart';
import '../../services/scam_alert_notification_service.dart';
import 'learning/learning_home_screen.dart';

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
  static final LatLngBounds _kualaLumpurBounds = LatLngBounds(
    const LatLng(kualaLumpurMinimumLatitude, kualaLumpurMinimumLongitude),
    const LatLng(kualaLumpurMaximumLatitude, kualaLumpurMaximumLongitude),
  );

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  final LandmarkSearchService _landmarkSearchService = LandmarkSearchService();
  final ScamAlertNotificationService _notificationService =
      ScamAlertNotificationService();

  StreamSubscription<Position>? _positionSubscription;
  List<ScamMapReport> _reports = const [];
  Position? _position;
  String _selectedCategory = 'All';
  String? _locationMessage;
  String? _loadError;
  List<_NearbyHotspot> _nearbyHotspots = const [];
  bool _dangerAlertActive = false;
  bool _loading = true;
  bool _loadedFromCache = false;
  bool _searching = false;
  bool _showList = false;
  LandmarkSearchResult? _searchedLocation;

  @override
  void initState() {
    super.initState();
    _loadReports();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _landmarkSearchService.close();
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
    final isInKualaLumpur = isCoordinateInKualaLumpur(
      position.latitude,
      position.longitude,
    );
    setState(() {
      _position = position;
      _locationMessage = isInKualaLumpur
          ? null
          : 'Your location is outside the Kuala Lumpur map area.';
    });

    if (moveCamera && isInKualaLumpur) {
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    }

    if (isInKualaLumpur) {
      _evaluateProximity(position);
    } else {
      setState(() {
        _nearbyHotspots = const [];
        _dangerAlertActive = false;
      });
    }
  }

  void _evaluateProximity(Position position) {
    final nearby = <_NearbyHotspot>[];
    var remainsInDangerArea = false;

    for (final report in _reports.where((report) => report.isVerified)) {
      final distance = haversineDistanceMeters(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        endLatitude: report.latitude,
        endLongitude: report.longitude,
      );

      if (distance <= 200) nearby.add(_NearbyHotspot(report, distance));
      if (distance <= 250) remainsInDangerArea = true;
    }

    nearby.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    setState(() => _nearbyHotspots = nearby);

    if (nearby.isNotEmpty && !_dangerAlertActive) {
      _dangerAlertActive = true;
      final nearest = nearby.first;
      unawaited(
        _notificationService.showNearbyHotspots(
          count: nearby.length,
          nearestReport: nearest.report,
          nearestDistanceMeters: nearest.distanceMeters,
        ),
      );
    } else if (nearby.isEmpty && !remainsInDangerArea) {
      _dangerAlertActive = false;
    }
  }

  void _showNearbyHotspots() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_nearbyHotspots.length} verified hotspot${_nearbyHotspots.length == 1 ? '' : 's'} within 200m',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _nearbyHotspots.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final hotspot = _nearbyHotspots[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.redSoft,
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.red,
                        ),
                      ),
                      title: Text(hotspot.report.title),
                      subtitle: Text(
                        '${hotspot.report.category} • ${hotspot.distanceMeters.round()}m away',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _showReportDetails(hotspot.report);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  List<_ScamReportDistance> get _sortedReportsForList {
    final items = _filteredReports.map((report) {
      final position = _position;
      final distance = position == null
          ? null
          : haversineDistanceMeters(
              startLatitude: position.latitude,
              startLongitude: position.longitude,
              endLatitude: report.latitude,
              endLongitude: report.longitude,
            );
      return _ScamReportDistance(report, distance);
    }).toList();

    items.sort((a, b) {
      if (a.distanceMeters != null && b.distanceMeters != null) {
        return a.distanceMeters!.compareTo(b.distanceMeters!);
      }
      return b.report.reportedAt.compareTo(a.report.reportedAt);
    });
    return items;
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return;

    final matches = _reports.where((report) {
      return report.title.toLowerCase().contains(query) ||
          report.category.toLowerCase().contains(query) ||
          (report.locationName?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (matches.isNotEmpty) {
      final report = matches.first;
      _mapController.move(LatLng(report.latitude, report.longitude), 16);
      _showReportDetails(report);
      return;
    }

    setState(() => _searching = true);
    try {
      final places = await _landmarkSearchService.searchKualaLumpur(query);
      if (!mounted) return;
      if (places.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No Kuala Lumpur landmark or location found.'),
          ),
        );
        return;
      }

      final place = places.first;
      setState(() => _searchedLocation = place);
      _mapController.move(LatLng(place.latitude, place.longitude), 16);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Showing ${place.name}')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
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
      onLearn: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LearningHomeScreen(
              repository: LearningRepository(client: widget.repository.client),
            ),
          ),
        );
      },
      gpsActive: _position != null,
      child: Column(
        children: [
          if (!_showList)
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
                    onPressed: _searching ? null : _searchLocation,
                    icon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_rounded),
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
          if (_nearbyHotspots.isNotEmpty)
            _NearbyScamWarning(
              hotspots: _nearbyHotspots,
              onViewDetails: _showNearbyHotspots,
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
                Positioned.fill(
                  child: _showList
                      ? _ScamReportList(
                          reports: _sortedReportsForList,
                          loading: _loading,
                          error: _loadError,
                          onRetry: _loadReports,
                          onOpenReport: _showReportDetails,
                        )
                      : Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _kualaLumpur,
                                initialZoom: 12,
                                minZoom: 11,
                                maxZoom: 19,
                                cameraConstraint: CameraConstraint.contain(
                                  bounds: _kualaLumpurBounds,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.collab',
                                ),
                                if (_position != null &&
                                    isCoordinateInKualaLumpur(
                                      _position!.latitude,
                                      _position!.longitude,
                                    ))
                                  CircleLayer(
                                    circles: [
                                      CircleMarker(
                                        point: LatLng(
                                          _position!.latitude,
                                          _position!.longitude,
                                        ),
                                        radius: 9,
                                        color: AppColors.blue.withValues(
                                          alpha: 0.25,
                                        ),
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
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
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
                                if (_searchedLocation != null)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(
                                          _searchedLocation!.latitude,
                                          _searchedLocation!.longitude,
                                        ),
                                        width: 46,
                                        height: 46,
                                        child: const Tooltip(
                                          message: 'Searched location',
                                          child: Icon(
                                            Icons.place,
                                            color: AppColors.blue,
                                            size: 42,
                                          ),
                                        ),
                                      ),
                                    ],
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
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            if (_loadError != null)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: SurfaceCard(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.cloud_off,
                                          color: AppColors.red,
                                        ),
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
                Positioned(
                  top: 10,
                  right: 10,
                  child: FloatingActionButton.small(
                    heroTag: 'toggle-map-list',
                    tooltip: _showList ? 'Show map' : 'Show scam list',
                    onPressed: () => setState(() => _showList = !_showList),
                    child: Icon(
                      _showList ? Icons.map_outlined : Icons.list_alt_rounded,
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

class _ScamReportDistance {
  const _ScamReportDistance(this.report, this.distanceMeters);

  final ScamMapReport report;
  final double? distanceMeters;
}

class _ScamReportList extends StatelessWidget {
  const _ScamReportList({
    required this.reports,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onOpenReport,
  });

  final List<_ScamReportDistance> reports;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<ScamMapReport> onOpenReport;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
        ),
      );
    }
    if (reports.isEmpty) {
      return const Center(child: Text('No verified scams in this category.'));
    }

    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 64, 12, 24),
        itemCount: reports.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = reports[index];
          final report = item.report;
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onOpenReport(report),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 78,
                        height: 78,
                        child: report.evidenceUrls.isEmpty
                            ? const ColoredBox(
                                color: AppColors.redSoft,
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.red,
                                  size: 32,
                                ),
                              )
                            : Image.network(
                                report.evidenceUrls.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const ColoredBox(
                                  color: AppColors.redSoft,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: AppColors.red,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  report.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.verified,
                                color: AppColors.red,
                                size: 17,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.category,
                            style: const TextStyle(
                              color: AppColors.slate,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              if (item.distanceMeters != null)
                                _ScamListFact(
                                  icon: Icons.near_me_outlined,
                                  text: _formatDistance(item.distanceMeters!),
                                ),
                              if ((report.amountLost ?? 0) > 0)
                                _ScamListFact(
                                  icon: Icons.payments_outlined,
                                  text: NumberFormat.currency(
                                    locale: 'en_MY',
                                    symbol: 'RM ',
                                    decimalDigits: 2,
                                  ).format(report.amountLost),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m away';
    return '${(meters / 1000).toStringAsFixed(1)}km away';
  }
}

class _ScamListFact extends StatelessWidget {
  const _ScamListFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.blue),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.blue,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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

class _NearbyScamWarning extends StatelessWidget {
  const _NearbyScamWarning({
    required this.hotspots,
    required this.onViewDetails,
  });

  final List<_NearbyHotspot> hotspots;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final nearest = hotspots.first;
    final message = hotspots.length == 1
        ? '${nearest.report.title} is ${nearest.distanceMeters.round()}m away.'
        : '${hotspots.length} verified scam hotspots within 200m. Nearest: ${nearest.distanceMeters.round()}m.';
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
              'Scam Alert: $message',
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

class _NearbyHotspot {
  const _NearbyHotspot(this.report, this.distanceMeters);

  final ScamMapReport report;
  final double distanceMeters;
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
      child: SingleChildScrollView(
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
            if (report.evidenceUrls.isNotEmpty) ...[
              SizedBox(
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: PageView.builder(
                    itemCount: report.evidenceUrls.length,
                    itemBuilder: (context, index) => Image.network(
                      report.evidenceUrls[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.blueSoft,
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.slate,
                              size: 34,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Photo unavailable',
                              style: TextStyle(color: AppColors.slate),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
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
            if ((report.amountLost ?? 0) > 0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments_outlined, color: AppColors.red),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reported amount lost',
                          style: TextStyle(
                            color: AppColors.slate,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'en_MY',
                            symbol: 'RM ',
                            decimalDigits: 2,
                          ).format(report.amountLost),
                          style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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

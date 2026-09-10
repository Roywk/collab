import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../services/address_lookup_service.dart';

class IncidentMapLocation {
  const IncidentMapLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final double latitude;
  final double longitude;
  final String? address;

  String get coordinateLabel =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  String get reportLabel {
    final readableAddress = address?.trim();
    if (readableAddress == null || readableAddress.isEmpty) {
      return 'Selected map location ($coordinateLabel)';
    }
    return '$readableAddress ($coordinateLabel)';
  }
}

class IncidentLocationPickerScreen extends StatefulWidget {
  const IncidentLocationPickerScreen({
    required this.initialLatitude,
    required this.initialLongitude,
    super.key,
  });

  final double initialLatitude;
  final double initialLongitude;

  @override
  State<IncidentLocationPickerScreen> createState() =>
      _IncidentLocationPickerScreenState();
}

class _IncidentLocationPickerScreenState
    extends State<IncidentLocationPickerScreen> {
  final AddressLookupService _addressLookupService = AddressLookupService();

  late LatLng _selectedPoint;
  String? _address;
  bool _findingAddress = true;
  int _selectionVersion = 0;

  @override
  void initState() {
    super.initState();
    _selectedPoint = LatLng(widget.initialLatitude, widget.initialLongitude);
    unawaited(_resolveAddress(_selectedPoint, delay: Duration.zero));
  }

  @override
  void dispose() {
    _selectionVersion++;
    _addressLookupService.dispose();
    super.dispose();
  }

  void _selectPoint(TapPosition _, LatLng point) {
    setState(() {
      _selectedPoint = point;
      _address = null;
      _findingAddress = true;
    });
    unawaited(_resolveAddress(point));
  }

  Future<void> _resolveAddress(
    LatLng point, {
    Duration delay = const Duration(milliseconds: 650),
  }) async {
    final version = ++_selectionVersion;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (!mounted || version != _selectionVersion) return;

    final address = await _addressLookupService.addressFromCoordinates(
      latitude: point.latitude,
      longitude: point.longitude,
    );
    if (!mounted || version != _selectionVersion) return;
    setState(() {
      _address = address;
      _findingAddress = false;
    });
  }

  void _confirmSelection() {
    Navigator.of(context).pop(
      IncidentMapLocation(
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
        address: _address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coordinateLabel =
        '${_selectedPoint.latitude.toStringAsFixed(6)}, '
        '${_selectedPoint.longitude.toStringAsFixed(6)}';

    return MobileShell(
      title: 'Select Incident Location',
      titleColor: AppColors.navy,
      statusLabel: 'KL: Active',
      currentNavigationIndex: 4,
      emergencyNavigation: true,
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _selectedPoint,
                initialZoom: 16,
                minZoom: 5,
                maxZoom: 19,
                onTap: _selectPoint,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.collab',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint,
                      width: 52,
                      height: 52,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_pin,
                        color: AppColors.red,
                        size: 46,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 5)],
                      ),
                    ),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            elevation: 10,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Selected location',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.blue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_findingAddress)
                                const Row(
                                  children: [
                                    SizedBox.square(
                                      dimension: 13,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Finding full address...'),
                                  ],
                                )
                              else
                                Text(
                                  _address ??
                                      'Full address unavailable. GPS coordinates will be used.',
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                coordinateLabel,
                                style: const TextStyle(
                                  color: AppColors.slate,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        key: const Key('confirm-incident-map-location'),
                        onPressed: _findingAddress ? null : _confirmSelection,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 19),
                        label: const Text(
                          'Use This Location',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'Tap anywhere on the map to move the location pin.',
                        style: TextStyle(color: AppColors.slate, fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

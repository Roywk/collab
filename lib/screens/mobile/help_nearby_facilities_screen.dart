import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../core/haversine.dart';
import '../../data/help_nearby_repository.dart';
import '../../models/help_nearby_models.dart';
import '../../services/address_lookup_service.dart';
import 'help_nearby_detail_screen.dart';
import 'help_nearby_widgets.dart';

class HelpNearbyFacilitiesScreen extends StatefulWidget {
  const HelpNearbyFacilitiesScreen({
    required this.repository,
    required this.position,
    super.key,
  });

  final HelpNearbyRepository repository;
  final Position position;

  @override
  State<HelpNearbyFacilitiesScreen> createState() =>
      _HelpNearbyFacilitiesScreenState();
}

class _HelpNearbyFacilitiesScreenState
    extends State<HelpNearbyFacilitiesScreen> {
  final AddressLookupService _addressLookupService = AddressLookupService();
  final TextEditingController _searchController = TextEditingController();
  List<NearbyFacility> _facilities = const [];
  EmergencyFacilityType? _selectedType;
  String _query = '';
  String? _error;
  String? _currentAddress;
  bool _loadingAddress = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFacilities();
    unawaited(_loadCurrentAddress());
  }

  @override
  void dispose() {
    _addressLookupService.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentAddress() async {
    final address = await _addressLookupService.addressFromCoordinates(
      latitude: widget.position.latitude,
      longitude: widget.position.longitude,
    );
    if (!mounted) return;
    setState(() {
      _currentAddress = address;
      _loadingAddress = false;
    });
  }

  Future<void> _loadFacilities() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final facilities = await widget.repository.getActiveFacilities();
      final nearby =
          facilities
              .map(
                (facility) => NearbyFacility(
                  facility: facility,
                  distanceMeters: haversineDistanceMeters(
                    startLatitude: widget.position.latitude,
                    startLongitude: widget.position.longitude,
                    endLatitude: facility.latitude,
                    endLongitude: facility.longitude,
                  ),
                ),
              )
              .toList()
            ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

      if (!mounted) return;
      setState(() {
        _facilities = nearby;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<NearbyFacility> get _filteredFacilities {
    return _facilities
        .where((nearby) {
          final matchesType =
              _selectedType == null || nearby.facility.type == _selectedType;
          return matchesType && nearby.facility.matches(_query);
        })
        .toList(growable: false);
  }

  void _openFacility(NearbyFacility nearby) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            HelpNearbyDetailScreen(nearby: nearby, position: widget.position),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final facilities = _filteredFacilities;
    return MobileShell(
      title: 'Help Nearby',
      titleColor: AppColors.navy,
      statusLabel: 'KL: Active',
      currentNavigationIndex: 4,
      emergencyNavigation: true,
      onBack: () => Navigator.of(context).pop(),
      child: RefreshIndicator(
        onRefresh: _loadFacilities,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.greenCanvas,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.green),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(Icons.circle, color: AppColors.green, size: 8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _loadingAddress
                              ? 'Finding your current address...'
                              : _currentAddress ?? 'Current GPS location',
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.position.latitude.toStringAsFixed(6)}, '
                          '${widget.position.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: AppColors.slate,
                            fontSize: 8,
                          ),
                        ),
                        if (!_loadingAddress && _currentAddress != null) ...[
                          const SizedBox(height: 2),
                          const Text(
                            'Address © OpenStreetMap contributors',
                            style: TextStyle(
                              color: AppColors.slate,
                              fontSize: 7,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search location...',
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FacilityFilterChip(
                    label: 'All',
                    selected: _selectedType == null,
                    onTap: () => setState(() => _selectedType = null),
                  ),
                  for (final type in EmergencyFacilityType.values) ...[
                    const SizedBox(width: 7),
                    _FacilityFilterChip(
                      label: type.label,
                      selected: _selectedType == type,
                      onTap: () => setState(() => _selectedType = type),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 11),
            const Text(
              'Nearest Facilities',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _FacilityMap(
              position: widget.position,
              facilities: facilities,
              onFacilityTap: _openFacility,
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(36),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_error != null)
              _FacilitiesMessage(
                icon: Icons.cloud_off_outlined,
                message: 'Could not load nearby facilities.\n$_error',
                action: _loadFacilities,
              )
            else if (facilities.isEmpty)
              const _FacilitiesMessage(
                icon: Icons.location_off_outlined,
                message: 'No facilities match this search or category.',
              )
            else
              for (int index = 0; index < facilities.length; index++) ...[
                _FacilityCard(
                  nearby: facilities[index],
                  onOpen: () => _openFacility(facilities[index]),
                ),
                if (index != facilities.length - 1) const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

class _FacilityMap extends StatelessWidget {
  const _FacilityMap({
    required this.position,
    required this.facilities,
    required this.onFacilityTap,
  });

  final Position position;
  final List<NearbyFacility> facilities;
  final ValueChanged<NearbyFacility> onFacilityTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 185,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(position.latitude, position.longitude),
            initialZoom: 14,
            minZoom: 5,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.collab',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: LatLng(position.latitude, position.longitude),
                  radius: 8,
                  color: AppColors.blue.withValues(alpha: 0.28),
                  borderColor: Colors.white,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (final nearby in facilities)
                  Marker(
                    point: LatLng(
                      nearby.facility.latitude,
                      nearby.facility.longitude,
                    ),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => onFacilityTap(nearby),
                      child: FacilityMapMarker(type: nearby.facility.type),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({required this.nearby, required this.onOpen});

  final NearbyFacility nearby;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final facility = nearby.facility;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(10),
      child: SurfaceCard(
        padding: const EdgeInsets.all(10),
        radius: 10,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: facilitySoftColor(facility.type),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                facilityIcon(facility.type),
                color: facilityColor(facility.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facility.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      FacilityTypeBadge(facility: facility),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          nearby.distanceLabel,
                          style: const TextStyle(
                            color: AppColors.slate,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 34,
              child: FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  'Navigate',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacilityFilterChip extends StatelessWidget {
  const _FacilityFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? AppColors.blue : AppColors.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.slate,
            fontSize: 9,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FacilitiesMessage extends StatelessWidget {
  const _FacilitiesMessage({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Future<void> Function()? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(icon, color: AppColors.slate, size: 34),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: action, child: const Text('Try Again')),
          ],
        ],
      ),
    );
  }
}

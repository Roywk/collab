import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../models/help_nearby_models.dart';
import '../../services/help_nearby_navigation_service.dart';
import 'help_nearby_widgets.dart';

class HelpNearbyDetailScreen extends StatelessWidget {
  const HelpNearbyDetailScreen({
    required this.nearby,
    required this.position,
    super.key,
  });

  final NearbyFacility nearby;
  final Position position;

  Future<void> _navigate(BuildContext context) async {
    final facility = nearby.facility;
    final uri = buildGoogleMapsDirectionsUri(
      originLatitude: position.latitude,
      originLongitude: position.longitude,
      destination: facility,
    );

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Google Maps.')),
      );
    }
  }

  Future<void> _call(BuildContext context) async {
    final phone = nearby.facility.phoneNumber;
    if (phone == null || phone.trim().isEmpty) return;
    final opened = await launchUrl(
      buildTelephoneUri(phone),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the phone dialer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final facility = nearby.facility;
    return MobileShell(
      title: 'Facility Details',
      titleColor: AppColors.navy,
      statusLabel: 'KL: Active',
      currentNavigationIndex: 3,
      emergencyNavigation: true,
      onBack: () => Navigator.of(context).pop(),
      onMap: () => Navigator.of(context).popUntil((route) => route.isFirst),
      onVerify: () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 225,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(facility.latitude, facility.longitude),
                  initialZoom: 15,
                  minZoom: 5,
                  maxZoom: 19,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.collab',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          LatLng(position.latitude, position.longitude),
                          LatLng(facility.latitude, facility.longitude),
                        ],
                        color: AppColors.blue,
                        strokeWidth: 4,
                      ),
                    ],
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
                      Marker(
                        point: LatLng(facility.latitude, facility.longitude),
                        width: 44,
                        height: 44,
                        child: FacilityMapMarker(type: facility.type),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FacilityTypeBadge(facility: facility),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greenSoft,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        facility.availabilityLabel,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  facility.name,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${nearby.distanceLabel} from your location',
                  style: const TextStyle(color: AppColors.slate, fontSize: 10),
                ),
                const Divider(height: 24),
                _FacilityInfoRow(
                  icon: Icons.location_on_outlined,
                  value: facility.address,
                ),
                if (facility.hasPhone) ...[
                  const SizedBox(height: 10),
                  _FacilityInfoRow(
                    icon: Icons.phone_outlined,
                    value: facility.phoneNumber!,
                    color: AppColors.blue,
                  ),
                ],
                if (!facility.isVerified) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.amberSoft,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: AppColors.amber,
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Prototype directory entry. Confirm the address '
                            'and contact details before production use.',
                            style: TextStyle(
                              color: AppColors.slate,
                              fontSize: 9,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                PrimaryActionButton(
                  label: 'Navigate Now',
                  icon: Icons.open_in_new_rounded,
                  onPressed: () => _navigate(context),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: facility.hasPhone ? () => _call(context) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.blue,
                      side: const BorderSide(color: AppColors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    icon: const Icon(Icons.phone_outlined, size: 17),
                    label: Text(
                      facility.hasPhone ? 'Call Station' : 'Phone Unavailable',
                      style: const TextStyle(fontWeight: FontWeight.w800),
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

class _FacilityInfoRow extends StatelessWidget {
  const _FacilityInfoRow({
    required this.icon,
    required this.value,
    this.color = AppColors.slate,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color == AppColors.blue ? color : AppColors.navy,
              fontSize: 11,
              height: 1.35,
              fontWeight: color == AppColors.blue
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

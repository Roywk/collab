import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/sos_repository.dart';
import '../../models/sos_models.dart';
import '../../services/address_lookup_service.dart';
import '../../services/location_service.dart';
import '../../services/sos_share_service.dart';

class SosLocationScreen extends StatefulWidget {
  const SosLocationScreen({
    required this.repository,
    this.locationService,
    super.key,
  });

  final SosRepository repository;
  final LocationService? locationService;

  @override
  State<SosLocationScreen> createState() => _SosLocationScreenState();
}

class _SosLocationScreenState extends State<SosLocationScreen> {
  final AddressLookupService _addressLookupService = AddressLookupService();
  late final LocationService _locationService =
      widget.locationService ?? LocationService();

  EmergencyContact? _contact;
  Position? _position;
  String? _address;
  String? _error;
  bool _loadingAddress = true;
  bool _loading = true;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadReadyState());
  }

  @override
  void dispose() {
    _addressLookupService.dispose();
    super.dispose();
  }

  Future<void> _loadReadyState() async {
    setState(() {
      _loading = true;
      _error = null;
      _address = null;
      _loadingAddress = true;
    });

    try {
      final results = await Future.wait<Object?>([
        widget.repository.getPrimaryEmergencyContact(),
        _locationService.currentPosition(),
      ]);
      final contact = results[0] as EmergencyContact?;
      final position = results[1] as Position;

      if (!mounted) return;
      setState(() {
        _contact = contact;
        _position = position;
        _loading = false;
        _loadingAddress = true;
        if (contact == null) {
          _error =
              'No emergency contact was found. Add a primary emergency '
              'contact to your account before using SOS.';
        }
      });
      unawaited(_loadAddress(position));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadAddress(Position position) async {
    final address = await _addressLookupService.addressFromCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (!mounted || _position != position) return;
    setState(() {
      _address = address;
      _loadingAddress = false;
    });
  }

  Future<void> _shareLocation() async {
    final contact = _contact;
    final position = _position;
    if (contact == null || position == null || _sharing) return;

    setState(() => _sharing = true);
    final message = buildSosMessage(
      latitude: position.latitude,
      longitude: position.longitude,
      address: _address,
    );

    try {
      var channel = SosShareChannel.whatsapp;
      var opened = await launchUrl(
        buildWhatsAppSosUri(contact: contact, message: message),
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        channel = SosShareChannel.sms;
        opened = await launchUrl(
          buildSmsSosUri(contact: contact, message: message),
          mode: LaunchMode.externalApplication,
        );
      }

      if (!opened) {
        throw const SosShareException(
          'Unable to open WhatsApp or the SMS application.',
        );
      }

      try {
        await widget.repository.recordShareOpened(
          contact: contact,
          channel: channel,
        );
      } catch (_) {
        // Opening the emergency message is more important than audit logging.
      }

      if (!mounted) return;
      final backToMenu = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => SosShareOpenedScreen(
            contact: contact,
            position: position,
            address: _address,
            channel: channel,
            openedAt: DateTime.now(),
          ),
        ),
      );
      if (backToMenu == true && mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('SOS share failed: $error')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Share My Location',
      titleColor: AppColors.navy,
      statusLabel: 'KL: Active',
      currentNavigationIndex: 4,
      emergencyNavigation: true,
      onBack: () => Navigator.of(context).pop(),
      child: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null || _contact == null || _position == null
          ? _SosLoadError(
              message: _error ?? 'SOS information is unavailable.',
              onRetry: _loadReadyState,
              onOpenSettings: _locationService.openAppSettings,
            )
          : _SosReadyContent(
              contact: _contact!,
              position: _position!,
              address: _address,
              loadingAddress: _loadingAddress,
              sharing: _sharing,
              onShare: _shareLocation,
            ),
    );
  }
}

class SosShareException implements Exception {
  const SosShareException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _SosReadyContent extends StatelessWidget {
  const _SosReadyContent({
    required this.contact,
    required this.position,
    required this.address,
    required this.loadingAddress,
    required this.sharing,
    required this.onShare,
  });

  final EmergencyContact contact;
  final Position position;
  final String? address;
  final bool loadingAddress;
  final bool sharing;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final message = buildSosMessage(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
    );
    final coordinateLabel =
        '${position.latitude.toStringAsFixed(6)}, '
        '${position.longitude.toStringAsFixed(6)}';

    return ListView(
      key: const Key('sos-ready-scroll'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        SurfaceCard(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.blue,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EMERGENCY CONTACT',
                      style: TextStyle(
                        color: AppColors.slate,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.name,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      contact.phoneNumber,
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  contact.isPrimary ? 'Primary' : 'Emergency',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.all(13),
          child: Column(
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your Location Status',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _GpsActiveBadge(),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.home_work_outlined,
                    color: AppColors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      loadingAddress
                          ? 'Finding full address...'
                          : address ?? 'Full address unavailable',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              if (!loadingAddress && address != null) ...[
                const SizedBox(height: 3),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Address © OpenStreetMap contributors',
                    style: TextStyle(color: AppColors.slate, fontSize: 7),
                  ),
                ),
              ],
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      coordinateLabel,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 150,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(position.latitude, position.longitude),
                initialZoom: 16,
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
                      radius: 16,
                      color: AppColors.red.withValues(alpha: 0.24),
                      borderColor: Colors.white,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(position.latitude, position.longitude),
                      width: 42,
                      height: 42,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sos_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFE9EFF7),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AUTO-GENERATED SOS MESSAGE',
                style: TextStyle(
                  color: AppColors.slate,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        SizedBox(
          height: 49,
          child: FilledButton(
            key: const Key('share-location-sos-button'),
            onPressed: sharing ? null : onShare,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              disabledBackgroundColor: AppColors.redSoft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: sharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Share My Location / SOS',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '* Opens WhatsApp with your SOS message. Tap Send to deliver it.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.slate, fontSize: 9),
        ),
      ],
    );
  }
}

class _GpsActiveBadge extends StatelessWidget {
  const _GpsActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          Icon(Icons.circle, size: 7, color: AppColors.green),
          SizedBox(width: 5),
          Text(
            'GPS Active',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SosLoadError extends StatelessWidget {
  const _SosLoadError({
    required this.message,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final String message;
  final Future<void> Function() onRetry;
  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SurfaceCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Icon(
                Icons.contact_emergency_outlined,
                color: AppColors.red,
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                'SOS is not ready',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.slate,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              PrimaryActionButton(label: 'Try Again', onPressed: onRetry),
              TextButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined, size: 17),
                label: const Text('Open Location Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SosShareOpenedScreen extends StatelessWidget {
  const SosShareOpenedScreen({
    required this.contact,
    required this.position,
    required this.address,
    required this.channel,
    required this.openedAt,
    super.key,
  });

  final EmergencyContact contact;
  final Position position;
  final String? address;
  final SosShareChannel channel;
  final DateTime openedAt;

  @override
  Widget build(BuildContext context) {
    final channelLabel = channel == SosShareChannel.whatsapp
        ? 'WhatsApp'
        : 'SMS';
    return MobileShell(
      statusLabel: 'KL: Active',
      currentNavigationIndex: 4,
      emergencyNavigation: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 24),
        children: [
          Center(
            child: Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.greenSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.green,
                size: 31,
              ),
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'SOS Message Opened',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$channelLabel opened for ${contact.name}. Confirm the message '
            'by tapping Send in $channelLabel.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 10,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          SurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SOS SHARE DETAILS',
                  style: TextStyle(
                    color: AppColors.slate,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 11),
                KeyValueRow(label: 'Opened For', value: contact.name),
                if (address != null)
                  KeyValueRow(label: 'Address', value: address!),
                KeyValueRow(
                  label: 'GPS Coordinates',
                  value:
                      '${position.latitude.toStringAsFixed(5)}, '
                      '${position.longitude.toStringAsFixed(5)}',
                ),
                KeyValueRow(
                  label: 'Time',
                  value: DateFormat('d MMM yyyy, HH:mm').format(openedAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryActionButton(
            label: 'Back to Emergency Menu',
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue,
                side: const BorderSide(color: AppColors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                'Share Again',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: AppColors.blue, size: 17),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Stay in a safe, public area and keep your phone charged.',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontSize: 9,
                      height: 1.3,
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

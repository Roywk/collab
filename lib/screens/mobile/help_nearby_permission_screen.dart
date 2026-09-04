import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/help_nearby_repository.dart';
import '../../services/location_service.dart';
import 'help_nearby_facilities_screen.dart';

class HelpNearbyPermissionScreen extends StatefulWidget {
  const HelpNearbyPermissionScreen({
    required this.repository,
    this.locationService,
    super.key,
  });

  final HelpNearbyRepository repository;
  final LocationService? locationService;

  @override
  State<HelpNearbyPermissionScreen> createState() =>
      _HelpNearbyPermissionScreenState();
}

class _HelpNearbyPermissionScreenState extends State<HelpNearbyPermissionScreen>
    with WidgetsBindingObserver {
  late final LocationService _locationService =
      widget.locationService ?? LocationService();

  bool _checking = true;
  bool _routing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_checkExistingPermission());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_routing) {
      unawaited(_checkExistingPermission());
    }
  }

  Future<void> _checkExistingPermission() async {
    try {
      final granted = await _locationService.hasLocationPermission();
      if (!mounted) return;
      if (granted) {
        await _openFacilities();
      } else {
        setState(() => _checking = false);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _message = error.toString();
      });
    }
  }

  Future<void> _openFacilities() async {
    if (_routing) return;
    setState(() {
      _routing = true;
      _checking = true;
      _message = null;
    });

    try {
      final position = await _locationService.currentPosition();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HelpNearbyFacilitiesScreen(
            repository: widget.repository,
            position: position,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _routing = false;
        _checking = false;
        _message = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Help Nearby',
      titleColor: AppColors.navy,
      statusLabel: 'KL: Active',
      currentNavigationIndex: 3,
      emergencyNavigation: true,
      onBack: () => Navigator.of(context).pop(),
      onMap: () => Navigator.of(context).popUntil((route) => route.isFirst),
      onVerify: () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: _checking
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                SurfaceCard(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Column(
                    children: [
                      Container(
                        height: 145,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 82,
                          height: 82,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDDE5F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.blue,
                            size: 38,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Enable Location Services',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'To find the nearest emergency facilities, we need '
                        'access to your GPS location.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 10,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      PrimaryActionButton(
                        label: 'Allow Location Access',
                        onPressed: _openFacilities,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Not Now'),
                      ),
                      if (_message != null)
                        TextButton.icon(
                          onPressed: _locationService.openAppSettings,
                          icon: const Icon(Icons.settings_outlined, size: 17),
                          label: const Text('Open App Settings'),
                        ),
                      const Divider(height: 30),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: AppColors.slate,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Your location is only used to find nearby '
                              'services and is never stored.',
                              style: TextStyle(
                                color: AppColors.slate,
                                fontSize: 10,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

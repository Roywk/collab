import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../services/location_service.dart';

class EmergencyLocationGate extends StatefulWidget {
  const EmergencyLocationGate({
    required this.title,
    required this.description,
    required this.child,
    this.locationService,
    super.key,
  });

  final String title;
  final String description;
  final Widget child;
  final LocationService? locationService;

  @override
  State<EmergencyLocationGate> createState() => _EmergencyLocationGateState();
}

class _EmergencyLocationGateState extends State<EmergencyLocationGate>
    with WidgetsBindingObserver {
  late final LocationService _locationService =
      widget.locationService ?? LocationService();

  LocationAccessStatus? _status;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_checkAccess());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_checkAccess());
  }

  Future<void> _checkAccess() async {
    try {
      final status = await _locationService.accessStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _working = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _requestAccess() async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });

    try {
      switch (_status) {
        case LocationAccessStatus.serviceDisabled:
          if (!kIsWeb) await _locationService.openLocationSettings();
          break;
        case LocationAccessStatus.deniedForever:
          if (!kIsWeb) await _locationService.openAppSettings();
          break;
        case LocationAccessStatus.denied:
        case null:
          await _locationService.ensurePermission();
          break;
        case LocationAccessStatus.granted:
          break;
      }
      await _checkAccess();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status == LocationAccessStatus.granted) return widget.child;

    final serviceOff = _status == LocationAccessStatus.serviceDisabled;
    final permanentlyDenied = _status == LocationAccessStatus.deniedForever;
    final buttonLabel = serviceOff
        ? kIsWeb
              ? 'Check Location Again'
              : 'Open Location Settings'
        : permanentlyDenied
        ? kIsWeb
              ? 'Check Permission Again'
              : 'Open App Settings'
        : 'Allow Location Access';

    return MobileShell(
      title: widget.title,
      titleColor: AppColors.navy,
      statusLabel: serviceOff ? 'GPS Paused' : 'KL: Active',
      gpsActive: !serviceOff,
      currentNavigationIndex: 4,
      emergencyNavigation: true,
      onBack: () => Navigator.of(context).pop(),
      child: _status == null && _error == null
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                SurfaceCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: AppColors.blueSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          serviceOff
                              ? Icons.location_disabled_outlined
                              : Icons.location_on_outlined,
                          color: AppColors.blue,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        serviceOff
                            ? 'Turn On Location Services'
                            : 'Allow Location Access',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        serviceOff
                            ? 'Turn on your device location service before '
                                  'using ${widget.title}.'
                            : permanentlyDenied && kIsWeb
                            ? 'Location is blocked for this website. Use the '
                                  'site controls beside the browser address '
                                  'bar to allow Location, then check again.'
                            : widget.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 10,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      PrimaryActionButton(
                        label: _working ? 'Checking Location...' : buttonLabel,
                        onPressed: _working ? null : _requestAccess,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Not Now'),
                      ),
                      const Divider(height: 28),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: AppColors.slate,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Location is requested only when this emergency '
                              'service needs it.',
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

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/emergency_repository.dart';
import '../../data/help_nearby_repository.dart';
import '../../data/incident_report_repository.dart';
import '../../data/sos_repository.dart';
import 'bank_hotline_directory_screen.dart';
import 'emergency_location_gate.dart';
import 'help_nearby_permission_screen.dart';
import 'incident_report_form_screen.dart';
import 'sos_location_screen.dart';

class EmergencyDashboardScreen extends StatelessWidget {
  const EmergencyDashboardScreen({
    required this.repository,
    required this.incidentReportRepository,
    required this.helpNearbyRepository,
    required this.sosRepository,
    super.key,
  });

  final EmergencyRepository repository;
  final IncidentReportRepository incidentReportRepository;
  final HelpNearbyRepository helpNearbyRepository;
  final SosRepository sosRepository;

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      currentNavigationIndex: 4,
      emergencyNavigation: true,
      statusLabel: 'KL: Active',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'Emergency Assistance',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 3),
          const Text(
            'Immediate tourist rescue and risk management services',
            style: TextStyle(color: AppColors.slate, fontSize: 12),
          ),
          const SizedBox(height: 14),
          const _EmergencyCallCard(),
          const SizedBox(height: 14),
          _EmergencyMenuCard(
            icon: Icons.security_rounded,
            title: 'Bank Hotline & Kill Switch',
            subtitle: 'Freeze cards & contact bank emergency lines',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      BankHotlineDirectoryScreen(repository: repository),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _EmergencyMenuCard(
            icon: Icons.insert_drive_file_outlined,
            title: 'Incident Report Generator',
            subtitle: 'Create translated police reports for PDRM',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EmergencyLocationGate(
                    title: 'Incident Report Generator',
                    description:
                        'Location permission is required to confirm where the '
                        'incident occurred and assist local authorities.',
                    child: IncidentReportFormScreen(
                      repository: incidentReportRepository,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _EmergencyMenuCard(
            icon: Icons.location_on_outlined,
            title: 'Help Nearby',
            subtitle: 'Find nearest police, fire & rescue stations',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => HelpNearbyPermissionScreen(
                    repository: helpNearbyRepository,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _EmergencyMenuCard(
            icon: Icons.share_location_outlined,
            title: 'Share My Location SOS',
            subtitle: 'Send your GPS location to emergency contacts',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EmergencyLocationGate(
                    title: 'Share My Location',
                    description:
                        'Allow location access so your live position can be '
                        'included in the emergency message.',
                    child: SosLocationScreen(repository: sosRepository),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const SurfaceCard(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAFETY TIP',
                  style: TextStyle(
                    color: AppColors.slate,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Always keep your digital token or card freeze reference '
                  'safe. You can securely unfreeze your card once safety is '
                  'confirmed.',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    height: 1.3,
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

class _EmergencyCallCard extends StatelessWidget {
  const _EmergencyCallCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.redSoft,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.red),
      ),
      child: const Row(
        children: [
          _SoftIcon(
            icon: Icons.shield_outlined,
            foreground: AppColors.red,
            background: Colors.white,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'If you are in immediate danger\n',
                    style: TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: 'Call 999 (National Emergency)',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              style: TextStyle(fontSize: 12, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyMenuCard extends StatelessWidget {
  const _EmergencyMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        child: Row(
          children: [
            _SoftIcon(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 10,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.slate,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({
    required this.icon,
    this.foreground = AppColors.blue,
    this.background = AppColors.greenSoft,
  });

  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: foreground, size: 20),
    );
  }
}

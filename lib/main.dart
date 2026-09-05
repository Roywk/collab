import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'data/admin_repository.dart';
import 'data/emergency_repository.dart';
import 'data/help_nearby_repository.dart';
import 'data/incident_report_repository.dart';
import 'data/scam_map_repository.dart';
import 'data/sos_repository.dart';
import 'data/user_account_repository.dart';
import 'data/verification_repository.dart';
import 'screens/admin/admin_gate.dart';
import 'screens/mobile/emergency_dashboard_screen.dart';
import 'screens/mobile/mobile_auth_gate.dart';
import 'screens/mobile/scam_map_screen.dart';
import 'screens/mobile/user_profile_screen.dart';
import 'screens/mobile/verification_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    runApp(
      const StartupErrorApp(
        message:
            'Supabase configuration was not loaded.\n'
            'Check config/dev.json and the run arguments.',
      ),
    );
    return;
  }

  try {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);

    final client = Supabase.instance.client;

    runApp(
      Visit1MyApp(
        repository: VerificationRepository(client: client),
        accountRepository: SupabaseUserAccountRepository(client: client),
      ),
    );
  } catch (error) {
    runApp(StartupErrorApp(message: 'Application startup failed:\n$error'));
  }
}

class Visit1MyApp extends StatelessWidget {
  const Visit1MyApp({
    required this.repository,
    required this.accountRepository,
    super.key,
  });

  final VerificationRepository repository;
  final UserAccountRepository accountRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Visit 1MY',
      theme: buildAppTheme(),
      routes: {
        '/admin': (context) => AdminGate(
          repository: AdminRepository(client: accountRepository.client),
        ),
        '/profile': (context) =>
            UserProfileScreen(repository: accountRepository),
        '/verify': (context) => VerificationHomeScreen(repository: repository),
        '/map': (context) => ScamMapScreen(
          repository: ScamMapRepository(client: accountRepository.client),
        ),
        '/emergency': (context) => EmergencyDashboardScreen(
          repository: SupabaseEmergencyRepository(
            client: accountRepository.client,
          ),
          incidentReportRepository: SupabaseIncidentReportRepository(
            client: accountRepository.client,
          ),
          helpNearbyRepository: SupabaseHelpNearbyRepository(
            client: accountRepository.client,
          ),
          sosRepository: SupabaseSosRepository(
            client: accountRepository.client,
          ),
        ),
      },
      home: MobileAuthGate(accountRepository: accountRepository),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.red, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Visit 1MY could not start',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

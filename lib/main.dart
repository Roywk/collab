import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'data/verification_repository.dart';
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

    if (client.auth.currentSession == null) {
      await client.auth.signInAnonymously();
    }

    runApp(Visit1MyApp(repository: VerificationRepository(client: client)));
  } catch (error) {
    runApp(StartupErrorApp(message: 'Application startup failed:\n$error'));
  }
}

class Visit1MyApp extends StatelessWidget {
  const Visit1MyApp({required this.repository, super.key});

  final VerificationRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Visit 1MY',
      theme: buildAppTheme(),
      home: VerificationHomeScreen(repository: repository),
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

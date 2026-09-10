import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../data/admin_repository.dart';
import 'threat_database_screen.dart';

class AdminGate extends StatefulWidget {
  const AdminGate({required this.repository, super.key});

  final AdminRepository repository;

  @override
  State<AdminGate> createState() {
    return _AdminGateState();
  }
}

class _AdminGateState extends State<AdminGate> {
  late Future<bool> adminCheck;

  @override
  void initState() {
    super.initState();
    adminCheck = widget.repository.hasAdminSession();
  }

  void adminSignedIn() {
    setState(() {
      adminCheck = Future<bool>.value(true);
    });
  }

  Future<void> adminSignedOut() async {
    await widget.repository.signOutAdmin();

    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: adminCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (snapshot.data == true) {
          return ThreatDatabaseScreen(
            repository: widget.repository,
            onSignOut: adminSignedOut,
          );
        }

        return AdminLoginScreen(
          repository: widget.repository,
          onSignedIn: adminSignedIn,
        );
      },
    );
  }
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({
    required this.repository,
    required this.onSignedIn,
    super.key,
  });

  final AdminRepository repository;
  final VoidCallback onSignedIn;

  @override
  State<AdminLoginScreen> createState() {
    return _AdminLoginScreenState();
  }
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Enter your admin email and password.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await widget.repository.signInAdmin(email: email, password: password);

      widget.onSignedIn();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (error is AuthException) {
          errorMessage = error.message;
        } else {
          errorMessage = error.toString();
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;
          if (!wide) {
            return SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.chevron_left),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                        child: _buildLoginCard(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              const Expanded(flex: 4, child: _AdminLoginBrandPanel()),
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    Positioned(
                      left: 18,
                      top: 18,
                      child: IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.chevron_left),
                      ),
                    ),
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: _buildLoginCard(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: 430,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.admin_panel_settings_outlined,
                color: Colors.white,
                size: 27,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Admin Sign In',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Use an account registered in the administrator directory to '
            'manage Visit 1MY safety records.',
            style: TextStyle(
              color: AppColors.slate,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 23),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Admin email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            controller: passwordController,
            obscureText: hidePassword,
            onSubmitted: (_) => signIn(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => hidePassword = !hidePassword),
                icon: Icon(
                  hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.redSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: AppColors.red, fontSize: 11),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: isLoading ? null : signIn,
              icon: isLoading
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.login, size: 18),
              label: const Text('Sign In to Admin Dashboard'),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, color: AppColors.slate, size: 14),
              SizedBox(width: 5),
              Text(
                'Administrator access is verified after authentication',
                style: TextStyle(color: AppColors.slate, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminLoginBrandPanel extends StatelessWidget {
  const _AdminLoginBrandPanel();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.adminNavy,
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visit 1MY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'ADMINISTRATION',
                      style: TextStyle(color: AppColors.muted, fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.shield_outlined,
              color: AppColors.blueSoft,
              size: 48,
            ),
            const SizedBox(height: 18),
            const Text(
              'Safety operations,\nmanaged securely.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 13),
            const Text(
              'Maintain verified bank hotlines, emergency facilities and '
              'tourist protection records from one control centre.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const Spacer(),
            const Text(
              'AUTHORIZED PERSONNEL ONLY',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

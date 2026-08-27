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

    Navigator.of(context).pop();
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
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).maybePop();
          },
          icon: const Icon(Icons.chevron_left),
        ),
        title: const Text(
          'Visit 1MY Administration',
          style: TextStyle(
            color: AppColors.blue,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Admin Sign In',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Only accounts with the admin role can '
                  'manage threat records.',
                  style: TextStyle(color: AppColors.slate, fontSize: 12),
                ),

                const SizedBox(height: 22),

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
                  onSubmitted: (value) {
                    signIn();
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
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
                      style: const TextStyle(
                        color: AppColors.red,
                        fontSize: 11,
                      ),
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
                    label: const Text('Sign In to Threat Database'),
                  ),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).maybePop();
                        },
                  child: const Text('Back to verification'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

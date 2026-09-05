import 'package:flutter/material.dart';

import '../../data/user_account_repository.dart';
import 'home_screen.dart';
import 'mobile_login_screen.dart';

class MobileAuthGate extends StatelessWidget {
  const MobileAuthGate({required this.accountRepository, super.key});

  final UserAccountRepository accountRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: accountRepository.authStateChanges,
      builder: (context, snapshot) {
        final user = accountRepository.currentUser;
        if (user == null || user.isAnonymous) {
          return MobileLoginScreen(repository: accountRepository);
        }
        return FutureBuilder<bool>(
          future: accountRepository.hasTouristAccess(),
          builder: (context, accessSnapshot) {
            if (accessSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (accessSnapshot.data != true) {
              return MobileLoginScreen(repository: accountRepository);
            }
            return HomeScreen(repository: accountRepository);
          },
        );
      },
    );
  }
}

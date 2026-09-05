import 'package:collab/core/app_widgets.dart';
import 'package:collab/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user profile maps account, bank, and emergency contact data', () {
    final profile = UserProfile.fromJson({
      'id': 'user-1',
      'email': 'sarah@example.com',
      'full_name': 'Sarah Johnson',
      'phone_number': '+60111111111',
      'nationality': 'United Kingdom',
      'preferred_language': 'English',
      'role': 'tourist',
      'primary_bank_id': 'bank-1',
      'primary_bank_name': 'Maybank',
      'emergency_contact_name': 'Alex Johnson',
      'emergency_contact_phone': '+447700900123',
      'emergency_contact_relationship': 'Family',
      'created_at': '2026-09-05T00:00:00Z',
    });

    expect(profile.initials, 'SJ');
    expect(profile.primaryBankName, 'Maybank');
    expect(profile.emergencyContactPhone, '+447700900123');
    expect(profile.createdAt, isNotNull);
  });

  testWidgets('profile tab appears after Learn and opens profile route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/profile': (context) => const Scaffold(body: Text('Profile page')),
        },
        home: const Scaffold(
          bottomNavigationBar: VisitBottomNavigation(currentIndex: 0),
        ),
      ),
    );

    final learn = tester.getCenter(find.text('Learn'));
    final profile = tester.getCenter(find.text('Profile'));
    expect(profile.dx, greaterThan(learn.dx));

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile page'), findsOneWidget);
  });

  testWidgets('emergency tab uses the shared emergency route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/emergency': (context) =>
              const Scaffold(body: Text('Emergency dashboard')),
        },
        home: const Scaffold(
          bottomNavigationBar: VisitBottomNavigation(currentIndex: 0),
        ),
      ),
    );

    await tester.tap(find.text('Emergency'));
    await tester.pumpAndSettle();

    expect(find.text('Emergency dashboard'), findsOneWidget);
  });

  testWidgets('emergency footer keeps separate Home and Map tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/map': (context) => const Scaffold(body: Text('Scam map page')),
        },
        home: const Scaffold(
          bottomNavigationBar: VisitBottomNavigation(
            currentIndex: 4,
            emergencyMode: true,
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();

    expect(find.text('Scam map page'), findsOneWidget);
  });
}

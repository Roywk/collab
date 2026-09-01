import 'package:collab/core/app_theme.dart';
import 'package:collab/data/emergency_repository.dart';
import 'package:collab/data/help_nearby_repository.dart';
import 'package:collab/data/incident_report_repository.dart';
import 'package:collab/data/sos_repository.dart';
import 'package:collab/models/emergency_models.dart';
import 'package:collab/models/help_nearby_models.dart';
import 'package:collab/models/incident_report_models.dart';
import 'package:collab/models/sos_models.dart';
import 'package:collab/screens/mobile/emergency_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEmergencyRepository implements EmergencyRepository {
  final banks = const [
    BankHotline(
      id: 'maybank-id',
      name: 'Maybank',
      countryCode: 'MY',
      countryName: 'Malaysian Operations',
      hotlineNumber: '+603-5891-4744',
      serviceType: '24/7 Card Freeze & Emergency Helpline',
      targetDepartment: 'Card Emergency Services Department',
      supportsKillSwitch: true,
      availabilityLabel: 'Card Freeze Available',
      isPrimary: true,
    ),
  ];

  @override
  Future<List<BankHotline>> getUserBanks() async => banks;

  @override
  Future<void> recordKillSwitchCall(BankHotline bank) async {}
}

class _FakeIncidentReportRepository implements IncidentReportRepository {
  @override
  Future<TranslatedIncidentReport> translateAndSave(IncidentReportDraft draft) {
    throw UnimplementedError();
  }
}

class _FakeHelpNearbyRepository implements HelpNearbyRepository {
  @override
  Future<List<EmergencyFacility>> getActiveFacilities() async => const [];
}

class _FakeSosRepository implements SosRepository {
  @override
  Future<EmergencyContact?> getPrimaryEmergencyContact() async => null;

  @override
  Future<void> recordShareOpened({
    required EmergencyContact contact,
    required SosShareChannel channel,
  }) async {}
}

void main() {
  test('bank relation data is parsed without a hard-coded fallback', () {
    final bank = BankHotline.fromUserBankJson({
      'is_primary': true,
      'banks': {
        'id': 'bank-id',
        'name': 'Test Bank',
        'country_code': 'MY',
        'country_name': 'Malaysia',
        'hotline_number': '+603-0000-0000',
        'service_type': 'Emergency service',
        'target_department': 'Fraud department',
        'supports_kill_switch': true,
        'availability_label': '24/7 Hotline',
      },
    });

    expect(bank.name, 'Test Bank');
    expect(bank.hotlineNumber, '+603-0000-0000');
    expect(bank.isPrimary, isTrue);
    expect(bank.isMalaysian, isTrue);
  });

  testWidgets('dashboard opens the user bank and freeze confirmation flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: EmergencyDashboardScreen(
          repository: _FakeEmergencyRepository(),
          incidentReportRepository: _FakeIncidentReportRepository(),
          helpNearbyRepository: _FakeHelpNearbyRepository(),
          sosRepository: _FakeSosRepository(),
        ),
      ),
    );

    expect(find.text('Emergency Assistance'), findsOneWidget);
    await tester.tap(find.text('Bank Hotline & Kill Switch'));
    await tester.pumpAndSettle();

    expect(find.text('Maybank'), findsOneWidget);
    expect(find.text('+603-5891-4744'), findsOneWidget);

    await tester.tap(find.text('Kill Switch'));
    await tester.pumpAndSettle();
    expect(find.text('Maybank Details'), findsOneWidget);

    await tester.tap(find.text('Freeze Account / Kill Switch'));
    await tester.pumpAndSettle();
    expect(find.text('Freeze Your Account?'), findsOneWidget);
    expect(find.text('Confirm Freeze'), findsOneWidget);
  });

  testWidgets('dashboard opens the complete scrollable incident report form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: EmergencyDashboardScreen(
          repository: _FakeEmergencyRepository(),
          incidentReportRepository: _FakeIncidentReportRepository(),
          helpNearbyRepository: _FakeHelpNearbyRepository(),
          sosRepository: _FakeSosRepository(),
        ),
      ),
    );

    await tester.tap(find.text('Incident Report Generator'));
    await tester.pumpAndSettle();
    expect(find.text('New Incident Report'), findsOneWidget);

    final formList = find.byKey(const Key('incident-report-form-scroll'));
    await tester.drag(formList, const Offset(0, -650));
    await tester.pumpAndSettle();
    await tester.drag(formList, const Offset(0, -650));
    await tester.pumpAndSettle();

    expect(find.text('Additional Information'), findsOneWidget);
    expect(find.text('Report Language (Bahasa Laporan)'), findsOneWidget);
    expect(find.text('Translate & Generate Report'), findsOneWidget);
  });
}

import 'package:collab/core/app_theme.dart';
import 'package:collab/data/admin_bank_repository.dart';
import 'package:collab/models/admin_bank_models.dart';
import 'package:collab/screens/admin/admin_bank_hotline_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const maybank = AdminBankRecord(
  id: 'maybank-id',
  slug: 'maybank',
  name: 'Maybank',
  countryCode: 'MY',
  countryName: 'Malaysia',
  hotlineNumber: '+603-5891-4744',
  serviceType: 'Both',
  targetDepartment: 'Card Emergency Services Department',
  supportsKillSwitch: true,
  availabilityLabel: 'Card Freeze Available',
  isActive: true,
);

class _FakeAdminBankRepository implements AdminBankRepository {
  final List<AdminBankRecord> banks = [maybank];

  @override
  Future<List<AdminBankRecord>> getBanks() async => banks;

  @override
  Future<void> saveBank(AdminBankRecord bank) async {}

  @override
  Future<AdminBankDeleteResult> deleteBank(AdminBankRecord bank) async {
    return AdminBankDeleteResult.deactivatedBecauseLinked;
  }
}

void main() {
  test('admin bank record parses the shared banks directory row', () {
    final parsed = AdminBankRecord.fromJson({
      'id': maybank.id,
      'slug': maybank.slug,
      'name': maybank.name,
      'country_code': maybank.countryCode,
      'country_name': maybank.countryName,
      'hotline_number': maybank.hotlineNumber,
      'service_type': maybank.serviceType,
      'target_department': maybank.targetDepartment,
      'supports_kill_switch': true,
      'availability_label': maybank.availabilityLabel,
      'is_active': true,
    });

    expect(parsed.name, 'Maybank');
    expect(parsed.isMalaysian, isTrue);
    expect(parsed.isActive, isTrue);
    expect(parsed.supportsKillSwitch, isTrue);
  });

  testWidgets('desktop bank directory opens add, edit and delete dialogs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: AdminBankHotlineScreen(
          repository: _FakeAdminBankRepository(),
          onSignOut: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bank Hotline Management'), findsOneWidget);
    expect(find.text('Maybank'), findsOneWidget);
    expect(find.text('+603-5891-4744'), findsOneWidget);

    await tester.tap(find.text('Add Bank'));
    await tester.pumpAndSettle();
    expect(find.text('Add New Bank Hotline'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit Bank Hotline'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();
    expect(find.text('Delete Bank Record?'), findsOneWidget);
    expect(find.text('Delete Bank'), findsOneWidget);
  });
}

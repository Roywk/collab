import 'package:collab/screens/mobile/incident_location_picker_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('map selection keeps full address and precise coordinates', () {
    const selection = IncidentMapLocation(
      latitude: 3.1478,
      longitude: 101.7108,
      address: '45 Jalan Bukit Bintang, Kuala Lumpur, Malaysia',
    );

    expect(selection.reportLabel, contains('45 Jalan Bukit Bintang'));
    expect(selection.reportLabel, contains('3.147800, 101.710800'));
  });

  test('map selection falls back to coordinates without an address', () {
    const selection = IncidentMapLocation(
      latitude: 3.1478,
      longitude: 101.7108,
    );

    expect(selection.reportLabel, startsWith('Selected map location'));
    expect(selection.reportLabel, contains('3.147800, 101.710800'));
  });
}

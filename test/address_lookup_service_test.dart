import 'package:collab/services/address_lookup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('returns the full address from reverse geocoding', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'nominatim.openstreetmap.org');
      expect(request.url.path, '/reverse');
      expect(request.url.queryParameters['lat'], '3.1478');
      expect(request.url.queryParameters['lon'], '101.7108');
      return http.Response(
        '{"display_name":"45 Jalan Bukit Bintang, Kuala Lumpur, Malaysia"}',
        200,
      );
    });
    final service = AddressLookupService(
      client: client,
      minimumRequestInterval: Duration.zero,
    );

    final address = await service.addressFromCoordinates(
      latitude: 3.1478,
      longitude: 101.7108,
    );

    expect(address, '45 Jalan Bukit Bintang, Kuala Lumpur, Malaysia');
    service.dispose();
  });

  test('returns null when an address cannot be resolved', () async {
    final service = AddressLookupService(
      client: MockClient((_) async => http.Response('{}', 200)),
      minimumRequestInterval: Duration.zero,
    );

    final address = await service.addressFromCoordinates(
      latitude: 0,
      longitude: 0,
    );

    expect(address, isNull);
    service.dispose();
  });
}

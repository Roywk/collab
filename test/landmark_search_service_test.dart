import 'dart:convert';

import 'package:collab/services/landmark_search_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('landmark search is bounded to Kuala Lumpur', () async {
    late Uri requestedUri;
    final service = LandmarkSearchService(
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode([
            {
              'display_name': 'KLCC, Kuala Lumpur, Malaysia',
              'lat': '3.1579',
              'lon': '101.7117',
            },
            {
              'display_name': 'George Town, Penang, Malaysia',
              'lat': '5.4141',
              'lon': '100.3292',
            },
          ]),
          200,
        );
      }),
    );

    final results = await service.searchKualaLumpur('KLCC');

    expect(requestedUri.queryParameters['bounded'], '1');
    expect(requestedUri.queryParameters['countrycodes'], 'my');
    expect(requestedUri.queryParameters['q'], contains('Kuala Lumpur'));
    expect(results, hasLength(1));
    expect(results.single.name, contains('KLCC'));
    service.close();
  });
}

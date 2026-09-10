import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/haversine.dart';

class LandmarkSearchResult {
  const LandmarkSearchResult({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;
}

class LandmarkSearchService {
  LandmarkSearchService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<LandmarkSearchResult>> searchKualaLumpur(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': '$trimmedQuery, Kuala Lumpur, Malaysia',
      'format': 'jsonv2',
      'limit': '5',
      'countrycodes': 'my',
      'viewbox':
          '$kualaLumpurMinimumLongitude,$kualaLumpurMaximumLatitude,'
          '$kualaLumpurMaximumLongitude,$kualaLumpurMinimumLatitude',
      'bounded': '1',
    });

    final headers = <String, String>{
      'Accept': 'application/json',
      'Accept-Language': 'en',
      if (!kIsWeb) 'User-Agent': 'Visit1MY/1.0 academic travel safety app',
    };
    final response = await _client.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Location search is temporarily unavailable.');
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw const FormatException();

      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .map((item) {
            final latitude = double.tryParse(item['lat']?.toString() ?? '');
            final longitude = double.tryParse(item['lon']?.toString() ?? '');
            if (latitude == null ||
                longitude == null ||
                !isCoordinateInKualaLumpur(latitude, longitude)) {
              return null;
            }
            return LandmarkSearchResult(
              name: item['display_name']?.toString() ?? trimmedQuery,
              latitude: latitude,
              longitude: longitude,
            );
          })
          .whereType<LandmarkSearchResult>()
          .toList();
    } on Object {
      throw Exception('Location search returned an invalid response.');
    }
  }

  void close() => _client.close();
}

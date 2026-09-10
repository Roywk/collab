import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AddressLookupService {
  AddressLookupService({
    http.Client? client,
    this.minimumRequestInterval = const Duration(seconds: 1),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final Duration minimumRequestInterval;

  static final Map<String, String> _addressCache = {};
  static Future<void> _requestQueue = Future<void>.value();
  static DateTime? _lastRequestStartedAt;

  Future<String?> addressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final cacheKey =
        '${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';
    final cachedAddress = _addressCache[cacheKey];
    if (cachedAddress != null) {
      return cachedAddress;
    }

    final result = Completer<String?>();
    _requestQueue = _requestQueue.then((_) async {
      try {
        result.complete(
          await _performLookup(
            latitude: latitude,
            longitude: longitude,
            cacheKey: cacheKey,
          ),
        );
      } catch (_) {
        result.complete(null);
      }
    });
    return result.future;
  }

  Future<String?> _performLookup({
    required double latitude,
    required double longitude,
    required String cacheKey,
  }) async {
    final cachedAddress = _addressCache[cacheKey];
    if (cachedAddress != null) return cachedAddress;

    final lastRequest = _lastRequestStartedAt;
    if (lastRequest != null) {
      final remaining =
          minimumRequestInterval - DateTime.now().difference(lastRequest);
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
    }
    _lastRequestStartedAt = DateTime.now();

    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'zoom': '18',
      'addressdetails': '1',
      'accept-language': 'en',
    });

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              if (!kIsWeb) 'User-Agent': 'Visit1MY/1.0',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return null;
      }

      final payload = jsonDecode(utf8.decode(response.bodyBytes));
      if (payload is! Map<String, dynamic>) {
        return null;
      }

      final address = payload['display_name']?.toString().trim();
      if (address == null || address.isEmpty) {
        return null;
      }

      _addressCache[cacheKey] = address;
      return address;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

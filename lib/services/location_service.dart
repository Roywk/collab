import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationAccessStatus { granted, serviceDisabled, denied, deniedForever }

class LocationUnavailableException implements Exception {
  const LocationUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationService {
  Future<LocationAccessStatus> accessStatus() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccessStatus.serviceDisabled;
    }

    final permission = await Geolocator.checkPermission();
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationAccessStatus.granted,
      LocationPermission.deniedForever => LocationAccessStatus.deniedForever,
      _ => LocationAccessStatus.denied,
    };
  }

  Future<bool> hasLocationPermission() async {
    return await accessStatus() == LocationAccessStatus.granted;
  }

  Future<LocationPermission> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailableException(
        'Location tracking paused. Please enable GPS.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationUnavailableException(
        'Location permission is required to find nearby safety services.',
      );
    }

    return permission;
  }

  Future<Position> currentPosition() async {
    await ensurePermission();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Stream<Position> watchPosition() async* {
    await ensurePermission();
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  Future<bool> openLocationSettings() async {
    if (kIsWeb) return false;
    return Geolocator.openLocationSettings();
  }

  Future<bool> openAppSettings() async {
    if (kIsWeb) return false;
    return Geolocator.openAppSettings();
  }
}

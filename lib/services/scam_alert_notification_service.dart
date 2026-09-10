import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

import '../models/scam_map_models.dart';

class ScamAlertNotificationService {
  ScamAlertNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> showNearbyHotspots({
    required int count,
    required ScamMapReport nearestReport,
    required double nearestDistanceMeters,
  }) async {
    if (kIsWeb) {
      return;
    }

    try {
      await Vibration.vibrate(duration: 1000, amplitude: 255);
    } catch (_) {
      // Some devices do not expose a vibration motor; the alert still appears.
    }

    await initialize();
    await _plugin.show(
      id: 1001,
      title: count == 1
          ? 'Verified scam hotspot nearby'
          : '$count verified scam hotspots nearby',
      body: count == 1
          ? '${nearestReport.title} is ${nearestDistanceMeters.round()}m away. Stay alert.'
          : 'The nearest is ${nearestDistanceMeters.round()}m away. Tap to view the list.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'verified_scam_hotspots_v2',
          'Verified scam hotspot alerts',
          channelDescription:
              'High-priority warnings when approaching verified scam hotspots.',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: nearestReport.id,
    );
  }
}

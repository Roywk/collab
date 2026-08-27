import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  Future<void> showNearbyHotspot(
    ScamMapReport report,
    double distanceMeters,
  ) async {
    if (kIsWeb) {
      return;
    }

    await initialize();
    await _plugin.show(
      id: report.id.hashCode & 0x7fffffff,
      title: 'Scam alert nearby',
      body: '${report.title} is ${distanceMeters.round()}m away. Stay alert.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'verified_scam_hotspots',
          'Verified scam hotspot alerts',
          channelDescription:
              'High-priority warnings when approaching verified scam hotspots.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      payload: report.id,
    );
  }
}

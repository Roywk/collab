import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/traveller_notification.dart';

class TravellerNotificationRepository {
  TravellerNotificationRepository({this.client});

  final SupabaseClient? client;

  Future<List<TravellerNotification>> getActiveNotifications({
    int limit = 20,
  }) async {
    try {
      final supabase = client ?? Supabase.instance.client;
      final response = await supabase
          .from('traveller_notifications')
          .select('id, title, message, severity, published_at')
          .eq('is_active', true)
          .order('published_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map(
            (row) => TravellerNotification.fromMap(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

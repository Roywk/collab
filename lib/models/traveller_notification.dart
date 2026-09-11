class TravellerNotification {
  const TravellerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String message;
  final String severity;
  final DateTime publishedAt;

  factory TravellerNotification.fromMap(Map<String, dynamic> map) {
    return TravellerNotification(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Safety update',
      message: map['message']?.toString() ?? '',
      severity: map['severity']?.toString() ?? 'Information',
      publishedAt:
          DateTime.tryParse(map['published_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

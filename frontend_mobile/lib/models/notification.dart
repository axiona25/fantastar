/// Notifica in-app (locale).
class AppNotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // auction, trade, match, reminder
  final DateTime timestamp;
  final bool isRead;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });
}

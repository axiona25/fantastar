import '../providers/notification_provider.dart';

/// Riferimento statico al [NotificationProvider] per aggiungere notifiche da FCM (service layer).
class NotificationProviderRef {
  NotificationProviderRef._();

  static NotificationProvider? instance;

  /// Aggiunge una notifica in-app (es. da push) al provider corrente.
  static void addInApp(String title, String body) {
    instance?.addNotification(title, body, 'push');
  }
}

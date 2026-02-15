import 'providers/notification_provider.dart';

/// Riferimento statico al NotificationProvider per i callback FCM (onMessage).
/// Impostato in main dopo la creazione del provider.
abstract class NotificationProviderRef {
  static NotificationProvider? _instance;
  static set instance(NotificationProvider? p) => _instance = p;
  static NotificationProvider? get instance => _instance;

  static void addInApp(String title, String body) {
    _instance?.addNotification(title, body, 'push');
  }
}

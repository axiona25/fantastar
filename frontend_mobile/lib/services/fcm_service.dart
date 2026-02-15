import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_provider_ref.dart';

/// Configura FCM: permessi, token, handler messaggi.
/// Chiamare dopo Firebase.initializeApp().
/// Tutto il contenuto è in try-catch: non crasha su simulatore iOS (APNS non disponibile) né su device.
Future<String?> setupFcm({
  void Function(RemoteMessage)? onForegroundMessage,
}) async {
  if (!Platform.isAndroid && !Platform.isIOS) return null;
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final token = await messaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? message.data['title'] ?? 'Notifica';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      NotificationProviderRef.addInApp(title, body);
      onForegroundMessage?.call(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final title = message.notification?.title ?? message.data['title'] ?? 'Notifica';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      NotificationProviderRef.addInApp(title, body);
    });
    return token;
  } catch (e) {
    debugPrint('FCM not available: $e');
    return null;
  }
}

import 'package:flutter/foundation.dart';

import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  final List<AppNotificationModel> _notifications = [];
  static int _idCounter = 0;

  List<AppNotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification(String title, String message, String type) {
    _notifications.insert(
      0,
      AppNotificationModel(
        id: 'n${_idCounter++}',
        title: title,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );
    notifyListeners();
  }

  void markAsRead(String id) {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i >= 0) {
      _notifications[i] = AppNotificationModel(
        id: _notifications[i].id,
        title: _notifications[i].title,
        message: _notifications[i].message,
        type: _notifications[i].type,
        timestamp: _notifications[i].timestamp,
        isRead: true,
      );
      notifyListeners();
    }
  }

  void markAllRead() {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        final n = _notifications[i];
        _notifications[i] = AppNotificationModel(
          id: n.id,
          title: n.title,
          message: n.message,
          type: n.type,
          timestamp: n.timestamp,
          isRead: true,
        );
      }
    }
    notifyListeners();
  }
}

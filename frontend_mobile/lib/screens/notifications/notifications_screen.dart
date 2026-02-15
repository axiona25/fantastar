import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Notifiche'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings/notifications'),
          ),
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllRead(),
              child: const Text('Segna tutte lette'),
            ),
        ],
      ),
      body: provider.notifications.isEmpty
          ? const Center(child: Text('Nessuna notifica'))
          : ListView.builder(
              itemCount: provider.notifications.length,
              itemBuilder: (context, i) {
                final n = provider.notifications[i];
                return ListTile(
                  title: Text(n.title),
                  subtitle: Text(n.message),
                  trailing: n.isRead ? null : const Icon(Icons.circle, size: 8, color: Colors.blue),
                  onTap: () => provider.markAsRead(n.id),
                );
              },
            ),
    );
  }
}

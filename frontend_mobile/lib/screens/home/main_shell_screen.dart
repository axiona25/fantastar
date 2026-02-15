import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

/// Shell per StatefulShellRoute: AppBar + body (tab content) + bottom NavigationBar.
/// Mantiene la bottom nav sempre visibile sulle 5 tab principali.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Indice della tab Live nella bottom nav (per reset giornata al ritorno).
  static const int liveTabIndex = 1;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  static const _tabs = [
    _TabItem(icon: Icons.home, label: '🏠 Home'),
    _TabItem(icon: Icons.sports_soccer, label: '⚡ Live'),
    _TabItem(icon: Icons.people, label: '👕 Squadra'),
    _TabItem(icon: Icons.emoji_events, label: '🏆 Classifica'),
    _TabItem(icon: Icons.article, label: '📰 News'),
  ];

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _registerFcmToken());
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await _registerFcmToken(token: token);
          } catch (e) {
            debugPrint('FCM onTokenRefresh: $e');
          }
        });
      });
    }
  }

  Future<void> _registerFcmToken({String? token}) async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    try {
      final t = token ?? await FirebaseMessaging.instance.getToken();
      if (t != null && t.isNotEmpty && mounted) {
        await auth.authService.registerFcmToken(t);
      }
    } catch (e) {
      debugPrint('FCM token non disponibile (simulatore?): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell.currentIndex;
    return ShellIndexScope(
      currentIndex: index,
      child: Scaffold(
      appBar: AppBar(
        title: Text(_tabs[index].label),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => context.push('/notifications'),
              ),
              if (context.watch<NotificationProvider>().unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${context.watch<NotificationProvider>().unreadCount}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => widget.navigationShell.goBranch(i),
        destinations: _tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    ),
    );
  }
}

/// Fornisce l'indice della tab selezionata allo shell (per reset giornata in LiveTab).
class ShellIndexScope extends InheritedWidget {
  const ShellIndexScope({super.key, required this.currentIndex, required super.child});

  final int currentIndex;

  static int of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ShellIndexScope>();
    return scope?.currentIndex ?? 0;
  }

  @override
  bool updateShouldNotify(ShellIndexScope oldWidget) =>
      oldWidget.currentIndex != currentIndex;
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

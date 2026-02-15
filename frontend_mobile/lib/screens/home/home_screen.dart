import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import 'tabs/home_tab.dart';
import 'tabs/live_tab.dart';
import 'tabs/team_tab.dart';
import 'tabs/standings_tab.dart';
import 'tabs/news_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _registerFcmToken();
      });
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

  static const _tabs = [
    _TabItem(icon: Icons.home, label: 'Home'),
    _TabItem(icon: Icons.sports_soccer, label: 'Live'),
    _TabItem(icon: Icons.people, label: 'Squadra'),
    _TabItem(icon: Icons.emoji_events, label: 'Classifica'),
    _TabItem(icon: Icons.article, label: 'News'),
  ];

  @override
  Widget build(BuildContext context) {
    final body = [
      const HomeTab(),
      const LiveTab(),
      const TeamTab(),
      const StandingsTab(),
      const NewsTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[_currentIndex].label),
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
      body: body[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: _tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

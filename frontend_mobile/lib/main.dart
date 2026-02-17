import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/routes.dart';
import 'app/theme.dart';
import 'firebase_options.dart';
import 'services/notification_provider_ref.dart';
import 'services/fcm_service.dart';
import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';
import 'providers/notification_provider.dart';
import 'services/league_service.dart';
import 'services/stats_service.dart';
import 'services/team_service.dart';
import 'services/player_service.dart';
import 'services/auction_service.dart';
import 'services/auction_random_service.dart';
import 'services/market_service.dart';
import 'services/match_service.dart';
import 'services/calendar_service.dart';
import 'services/news_service.dart';
import 'app/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar: sfondo trasparente, icone scure (sfondo chiaro viola/rosa)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  await initializeDateFormatting('it_IT', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final notificationProvider = NotificationProvider();
  NotificationProviderRef.instance = notificationProvider;
  try {
    await setupFcm();
  } catch (e) {
    debugPrint('FCM setup failed (simulator?): $e');
  }
  final authProvider = AuthProvider();
  final router = createRouter(authProvider);
  debugPrint('API Base URL: $kApiBaseUrl');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        Provider<LeagueService>(create: (c) => LeagueService(c.read<AuthProvider>().authService)),
        Provider<StatsService>(create: (c) => StatsService(c.read<AuthProvider>().authService)),
        Provider<TeamService>(create: (c) => TeamService(c.read<AuthProvider>().authService)),
        Provider<PlayerService>(create: (c) => PlayerService(c.read<AuthProvider>().authService)),
        Provider<AuctionService>(create: (c) => AuctionService(c.read<AuthProvider>().authService)),
        Provider<AuctionRandomService>(create: (c) => AuctionRandomService(c.read<AuthProvider>().authService)),
        Provider<MarketService>(create: (c) => MarketService(c.read<AuthProvider>().authService)),
        Provider<MatchService>(create: (c) => MatchService(c.read<AuthProvider>().authService)),
        Provider<CalendarService>(create: (c) => CalendarService(c.read<AuthProvider>().authService)),
        Provider<NewsService>(create: (c) => NewsService(c.read<AuthProvider>().authService)),
        ChangeNotifierProvider<HomeProvider>(create: (c) => HomeProvider(c.read<LeagueService>())),
        ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider),
      ],
      child: MaterialApp.router(
        title: 'FANTASTAR',
        theme: appTheme,
        routerConfig: router,
      ),
    ),
  );
}

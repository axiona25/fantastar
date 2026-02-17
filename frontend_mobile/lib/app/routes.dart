import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/fantasy_league.dart';
import '../models/standing.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/main_shell.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/placeholder_tab.dart';
import '../screens/standings/standings_screen.dart';
import '../screens/standings/fantasy_standings_screen.dart';
import '../screens/standings/top_scorers_screen.dart';
import '../screens/player/player_detail_screen.dart';
import '../screens/team/set_lineup_screen.dart';
import '../screens/auction/auction_screen.dart';
import '../screens/auction/auction_config_screen.dart';
import '../screens/auction/auction_turn_screen.dart';
import '../screens/auction/auction_results_screen.dart';
import '../screens/auction/auction_overview_screen.dart';
import '../screens/auction/auction_tab_screen.dart';
import '../screens/auction/auction_live_screen.dart';
import '../screens/players/player_list_screen.dart';
import '../screens/market/market_screen.dart';
import '../screens/live/match_detail_screen.dart';
import '../screens/risultati/risultati_screen.dart';
import '../screens/risultati/pagelle_screen.dart';
import '../screens/leagues/leagues_screen.dart';
import '../screens/leagues/new_league_choice_screen.dart';
import '../screens/leagues/create_league_screen.dart';
import '../screens/leagues/join_league_screen.dart';
import '../screens/leagues/league_detail_screen.dart';
import '../screens/leagues/league_management_screen.dart';
import '../screens/leagues/create_team_screen.dart';
import '../screens/leagues/league_standings_screen.dart';
import '../screens/leagues/league_calendar_screen.dart';
import '../screens/teams/my_team_screen.dart';
import '../screens/players/players_list_standalone_screen.dart';
import '../screens/players/listone_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/notifications/notification_settings_screen.dart';
import '../screens/news/news_detail_screen.dart';

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final isLoggedIn = auth.isLoggedIn;
      final isAuthRoute = state.matchedLocation == '/splash' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/reset-password';
      if (!isLoggedIn && !isAuthRoute) return '/splash';
      if (isLoggedIn && isAuthRoute && state.matchedLocation != '/splash') return '/home';
      // Redirect vecchie tab verso home (nuova shell ha Home, Scores, Asta, Leghe, Altro)
      final loc = state.matchedLocation;
      if (loc == '/live' || loc == '/team' || loc == '/standings' || loc == '/news') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.extra as String?;
          return ResetPasswordScreen(resetToken: token);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (c, s) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/scores', builder: (c, s) => const PlaceholderTab(title: 'Scores'))]),
          StatefulShellBranch(routes: [GoRoute(path: '/asta', builder: (c, s) => const AuctionTabScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/leghe', builder: (c, s) => const PlaceholderTab(title: 'Leghe'))]),
          StatefulShellBranch(routes: [GoRoute(path: '/altro', builder: (c, s) => const PlaceholderTab(title: 'Altro'))]),
        ],
      ),
      GoRoute(
        path: '/leagues',
        builder: (context, state) => const LeaguesScreen(),
      ),
      GoRoute(
        path: '/leagues/new',
        builder: (context, state) => const NewLeagueChoiceScreen(),
      ),
      GoRoute(
        path: '/leagues/create',
        builder: (context, state) => const CreateLeagueScreen(),
      ),
      GoRoute(
        path: '/leagues/join',
        builder: (context, state) => const JoinLeagueScreen(),
      ),
      GoRoute(
        path: '/league/:leagueId',
        builder: (context, state) {
          final leagueId = state.pathParameters['leagueId'] ?? '';
          return LeagueDetailScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/league/:leagueId/management',
        builder: (context, state) {
          final leagueId = state.pathParameters['leagueId'] ?? '';
          return LeagueManagementScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/league/:leagueId/create-team',
        builder: (context, state) {
          final leagueId = state.pathParameters['leagueId'] ?? '';
          return CreateTeamScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/league/:leagueId/standings',
        builder: (context, state) {
          final leagueId = state.pathParameters['leagueId'] ?? '';
          return LeagueStandingsScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/league/:leagueId/calendar',
        builder: (context, state) {
          final leagueId = state.pathParameters['leagueId'] ?? '';
          return LeagueCalendarScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/league/:leagueId/my-team',
        builder: (context, state) {
          final leagueId = state.pathParameters['leagueId'] ?? '';
          final extra = state.extra as List?;
          if (extra == null || extra.length < 2) {
            return const SizedBox.shrink(); // fallback; in practice push is done with extra
          }
          final league = extra[0] as FantasyLeagueModel;
          final myStanding = extra[1] as StandingModel;
          final standings = extra.length > 2
              ? (extra[2] as List?)?.cast<StandingModel>() ?? <StandingModel>[]
              : <StandingModel>[];
          return MyTeamScreen(
            leagueId: leagueId,
            league: league,
            myStanding: myStanding,
            standings: standings,
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/players',
        builder: (context, state) => const PlayersListStandaloneScreen(),
      ),
      GoRoute(
        path: '/standings/serie-a',
        builder: (context, state) => const StandingsScreen(),
      ),
      GoRoute(
        path: '/standings/fantasy',
        builder: (context, state) => const FantasyStandingsScreen(),
      ),
      GoRoute(
        path: '/standings/scorers',
        builder: (context, state) => const TopScorersScreen(),
      ),
      GoRoute(
        path: '/player/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return PlayerDetailScreen(playerId: id);
        },
      ),
      GoRoute(
        path: '/team/:teamId/lineup',
        builder: (context, state) {
          final teamId = state.pathParameters['teamId'] ?? '';
          return SetLineupScreen(teamId: teamId);
        },
      ),
      GoRoute(
        path: '/league/:leagueId/auction',
        builder: (context, state) {
          final leagueId = state.pathParameters['leagueId'] ?? '';
          return AuctionScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/league/:leagueId/auction/live',
        builder: (context, state) {
          final leagueId = state.pathParameters['leagueId'] ?? '';
          final league = state.extra as FantasyLeagueModel?;
          final auctionType = league?.auctionType ?? 'classic';
          return AuctionLiveScreen(leagueId: leagueId, auctionType: auctionType);
        },
      ),
      GoRoute(
        path: '/league/:leagueId/auction/config',
        builder: (context, state) {
          final leagueId = state.pathParameters['leagueId'] ?? '';
          final league = state.extra as FantasyLeagueModel?;
          return AuctionConfigScreen(leagueId: leagueId, league: league);
        },
      ),
      GoRoute(
        path: '/league/:leagueId/auction/turn',
        builder: (context, state) {
          final leagueId = state.pathParameters['leagueId'] ?? '';
          return AuctionTurnScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/league/:leagueId/auction/results/:turnNumber',
        builder: (context, state) {
          final leagueId = state.pathParameters['leagueId'] ?? '';
          final turnNumber = int.tryParse(state.pathParameters['turnNumber'] ?? '') ?? 1;
          return AuctionResultsScreen(leagueId: leagueId, turnNumber: turnNumber);
        },
      ),
      GoRoute(
        path: '/league/:leagueId/auction/overview',
        builder: (context, state) {
          final leagueId = state.pathParameters['leagueId'] ?? '';
          return AuctionOverviewScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/league/:leagueId/players',
        builder: (context, state) {
          final leagueId = state.pathParameters['leagueId'] ?? '';
          final forAuction = state.uri.queryParameters['mode'] == 'auction';
          final auctionCategory = state.uri.queryParameters['category']?.toUpperCase();
          return PlayerListScreen(leagueId: leagueId, forAuction: forAuction, auctionCategory: auctionCategory);
        },
      ),
      GoRoute(
        path: '/league/:leagueId/market',
        builder: (context, state) {
          final leagueId = state.pathParameters['leagueId'] ?? '';
          return MarketScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/live/match/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return MatchDetailScreen(matchId: id);
        },
      ),
      GoRoute(
        path: '/league/:leagueId/risultati',
        builder: (context, state) {
          final leagueId = state.pathParameters['leagueId'] ?? '';
          return RisultatiScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/match/:matchId/pagelle',
        builder: (context, state) {
          final matchId = int.tryParse(state.pathParameters['matchId'] ?? '') ?? 0;
          return PagelleScreen(matchId: matchId);
        },
      ),
      GoRoute(
        path: '/news/:id',
        builder: (context, state) {
          final articleUrl = state.extra as String? ?? '';
          return NewsDetailScreen(articleUrl: articleUrl);
        },
      ),
      GoRoute(
        path: '/listone',
        builder: (context, state) => const ListoneScreen(),
      ),
    ],
  );
}

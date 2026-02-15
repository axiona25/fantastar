import 'package:flutter/foundation.dart';

import '../models/fantasy_league.dart';
import '../models/standing.dart';
import '../services/league_service.dart';
import '../utils/error_utils.dart';

/// Provider per Home: leghe, classifica prima lega, top 3.
class HomeProvider with ChangeNotifier {
  HomeProvider(this._leagueService);

  final LeagueService _leagueService;

  List<FantasyLeagueModel> _leagues = [];
  List<StandingModel> _standings = [];
  bool _loading = false;
  String? _error;

  List<FantasyLeagueModel> get leagues => _leagues;
  List<StandingModel> get standings => _standings;
  bool get loading => _loading;
  String? get error => _error;

  /// Top 3 della classifica (prima lega).
  List<StandingModel> get topThree =>
      _standings.length >= 3 ? _standings.take(3).toList() : _standings;

  /// Riga classifica della mia squadra (passa user id dall'auth).
  StandingModel? myStandingFor(String? userId) {
    if (userId == null) return null;
    try {
      return _standings.firstWhere((s) => s.userId == userId);
    } catch (_) {
      return null;
    }
  }

  FantasyLeagueModel? get firstLeague => _leagues.isEmpty ? null : _leagues.first;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _leagues = await _leagueService.getLeagues();
      if (_leagues.isNotEmpty) {
        final id = _leagues.first.id;
        _standings = await _leagueService.getStandings(id);
      } else {
        _standings = [];
      }
    } catch (e) {
      _error = userFriendlyErrorMessage(e);
      _standings = [];
    }
    _loading = false;
    notifyListeners();
  }
}

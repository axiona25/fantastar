import 'auth_service.dart';

/// API asta random (busta chiusa): configure, start, current-turn, bid, results, status.
class AuctionRandomService {
  AuctionRandomService(this.auth);

  final AuthService auth;

  String _path(String leagueId, [String? sub]) {
    final p = '/leagues/$leagueId/auction';
    return sub != null ? '$p/$sub' : p;
  }

  /// GET config — tipo asta, asta_started, config (null se non esiste)
  Future<Map<String, dynamic>> getConfig(String leagueId) async {
    final res = await auth.dio.get(_path(leagueId, 'config'));
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// POST configure — rosa + opzionali classica/busta chiusa
  Future<Map<String, dynamic>> configure(
    String leagueId, {
    int budgetPerTeam = 500,
    int maxRosterSize = 25,
    int minGoalkeepers = 3,
    int minDefenders = 8,
    int minMidfielders = 8,
    int minAttackers = 6,
    int basePrice = 1,
    int playersPerTurnP = 3,
    int playersPerTurnD = 5,
    int playersPerTurnC = 5,
    int playersPerTurnA = 3,
    int turnDurationHours = 24,
    int? roundsCount,
    bool? revealBids,
    bool? allowSamePlayerBids,
    int? maxBidsPerRound,
    String? tieBreaker,
    int? bidTimerSeconds,
    int? minRaise,
    String? callOrder,
    bool? allowNomination,
    int? pauseBetweenPlayers,
  }) async {
    final data = <String, dynamic>{
      'budget_per_team': budgetPerTeam,
      'max_roster_size': maxRosterSize,
      'min_goalkeepers': minGoalkeepers,
      'min_defenders': minDefenders,
      'min_midfielders': minMidfielders,
      'min_attackers': minAttackers,
      'base_price': basePrice,
      'players_per_turn_p': playersPerTurnP,
      'players_per_turn_d': playersPerTurnD,
      'players_per_turn_c': playersPerTurnC,
      'players_per_turn_a': playersPerTurnA,
      'turn_duration_hours': turnDurationHours,
    };
    if (roundsCount != null) data['rounds_count'] = roundsCount;
    if (revealBids != null) data['reveal_bids'] = revealBids;
    if (allowSamePlayerBids != null) data['allow_same_player_bids'] = allowSamePlayerBids;
    if (maxBidsPerRound != null) data['max_bids_per_round'] = maxBidsPerRound;
    if (tieBreaker != null) data['tie_breaker'] = tieBreaker;
    if (bidTimerSeconds != null) data['bid_timer_seconds'] = bidTimerSeconds;
    if (minRaise != null) data['min_raise'] = minRaise;
    if (callOrder != null) data['call_order'] = callOrder;
    if (allowNomination != null) data['allow_nomination'] = allowNomination;
    if (pauseBetweenPlayers != null) data['pause_between_players'] = pauseBetweenPlayers;
    final res = await auth.dio.post(_path(leagueId, 'configure'), data: data);
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// POST start (avvia asta random se config pending)
  Future<Map<String, dynamic>> start(String leagueId) async {
    final res = await auth.dio.post(_path(leagueId, 'start'));
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// GET current-turn
  Future<Map<String, dynamic>?> getCurrentTurn(String leagueId) async {
    try {
      final res = await auth.dio.get(_path(leagueId, 'current-turn'));
      return Map<String, dynamic>.from(res.data as Map);
    } catch (_) {
      return null;
    }
  }

  /// POST random/bid
  Future<void> placeBid(String leagueId, int playerId, int amount) async {
    await auth.dio.post(
      _path(leagueId, 'random/bid'),
      data: {'player_id': playerId, 'amount': amount},
    );
  }

  /// GET results/{turn_number}
  Future<Map<String, dynamic>?> getTurnResults(String leagueId, int turnNumber) async {
    try {
      final res = await auth.dio.get(_path(leagueId, 'results/$turnNumber'));
      return Map<String, dynamic>.from(res.data as Map);
    } catch (_) {
      return null;
    }
  }

  /// GET random/status
  Future<Map<String, dynamic>?> getStatus(String leagueId) async {
    try {
      final res = await auth.dio.get(_path(leagueId, 'random/status'));
      return Map<String, dynamic>.from(res.data as Map);
    } catch (_) {
      return null;
    }
  }
}

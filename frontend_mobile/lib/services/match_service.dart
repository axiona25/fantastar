import '../app/constants.dart';
import '../models/match.dart';
import '../models/player_rating.dart';
import 'auth_service.dart';

/// Servizio API partite: lista live, dettaglio, pagelle, URL WebSocket live e match.
class MatchService {
  MatchService(this.auth);

  final AuthService auth;

  /// GET /matches?status=IN_PLAY
  Future<List<MatchModel>> getLiveMatches() async {
    final r = await auth.dio.get<List<dynamic>>('/matches', queryParameters: {'status': 'IN_PLAY'});
    final list = r.data ?? [];
    return list.map((e) => MatchModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /matches/current-matchday — giornata corrente (con partite giocate/in corso o prossima).
  Future<int> getCurrentMatchday() async {
    final r = await auth.dio.get<Map<String, dynamic>>('/matches/current-matchday');
    final md = r.data?['matchday'];
    if (md is int) return md;
    if (md is num) return md.toInt();
    return 1;
  }

  /// GET /matches?matchday=X — partite della giornata (Serie A).
  Future<List<MatchModel>> getMatchesByMatchday(int matchday) async {
    final r = await auth.dio.get<List<dynamic>>('/matches', queryParameters: {'matchday': matchday});
    final list = r.data ?? [];
    return list.map((e) => MatchModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /matches/{id}
  Future<MatchDetailModel> getMatchDetail(int matchId) async {
    final r = await auth.dio.get<Map<String, dynamic>>('/matches/$matchId');
    return MatchDetailModel.fromJson(r.data!);
  }

  /// GET /matches/{id}/detail — dettaglio completo (eventi, formazioni, statistiche).
  Future<MatchDetailFullModel> getMatchDetailFull(int matchId) async {
    final r = await auth.dio.get<Map<String, dynamic>>('/matches/$matchId/detail');
    return MatchDetailFullModel.fromJson(r.data!);
  }

  /// GET /matches/{id}/ratings — voti live o ufficiali (casa/trasferta, live_rating, fantasy_score)
  Future<MatchRatingsResponseModel> getMatchRatings(int matchId) async {
    final r = await auth.dio.get<Map<String, dynamic>>('/matches/$matchId/ratings');
    return MatchRatingsResponseModel.fromJson(r.data!);
  }

  /// GET /matches/{id}/ratings/ai — pagelle AI (sentiment/mentions)
  Future<List<PlayerRatingModel>> getMatchRatingsAi(int matchId) async {
    final r = await auth.dio.get<List<dynamic>>('/matches/$matchId/ratings/ai');
    final list = r.data ?? [];
    return list.map((e) => PlayerRatingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /matches/{id}/highlights — video highlights (ScoreBat)
  Future<List<MatchHighlightModel>> getMatchHighlights(int matchId) async {
    final r = await auth.dio.get<List<dynamic>>('/matches/$matchId/highlights');
    final list = r.data ?? [];
    return list.map((e) => MatchHighlightModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  String liveWsUrl(String leagueId) => '$kWsBaseUrl/ws/live/$leagueId';
  String matchWsUrl(int matchId) => '$kWsBaseUrl/ws/match/$matchId';
}

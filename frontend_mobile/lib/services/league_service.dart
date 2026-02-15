import 'auth_service.dart';
import '../models/fantasy_league.dart';
import '../models/standing.dart';
import '../models/matchday_result.dart';
import '../models/league_member.dart';

/// Servizio API leghe e classifiche fantasy.
class LeagueService {
  LeagueService(this.auth);

  final AuthService auth;

  Future<List<FantasyLeagueModel>> getLeagues() async {
    final response = await auth.dio.get('/leagues');
    final list = response.data is List ? response.data as List : [];
    return list.map((e) => FantasyLeagueModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FantasyLeagueModel> getLeague(String leagueId) async {
    final response = await auth.dio.get('/leagues/$leagueId');
    return FantasyLeagueModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Cerca lega per codice invito (per unisciti).
  Future<FantasyLeagueModel> lookupByInviteCode(String inviteCode) async {
    final response = await auth.dio.get(
      '/leagues/lookup',
      queryParameters: {'invite_code': inviteCode.trim().toUpperCase()},
    );
    return FantasyLeagueModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FantasyLeagueModel> createLeague({
    required String name,
    String logo = 'trophy',
    required String leagueType,
    int? maxMembers,
    double budget = 500,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'logo': logo,
      'league_type': leagueType,
      'budget': budget,
    };
    if (leagueType == 'private' && maxMembers != null) {
      data['max_members'] = maxMembers;
    }
    final response = await auth.dio.post('/leagues', data: data);
    return FantasyLeagueModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FantasyLeagueModel> joinLeague(String leagueId, String inviteCode) async {
    final response = await auth.dio.post(
      '/leagues/$leagueId/join',
      data: {'invite_code': inviteCode.trim().toUpperCase()},
    );
    return FantasyLeagueModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> generateCalendar(String leagueId) async {
    await auth.dio.post('/leagues/$leagueId/generate-calendar');
  }

  Future<List<StandingModel>> getLeagueTeamsAsStandings(String leagueId) async {
    return getStandings(leagueId);
  }

  Future<List<StandingModel>> getStandings(String leagueId) async {
    final response = await auth.dio.get('/leagues/$leagueId/standings');
    final list = response.data is List ? response.data as List : [];
    return list.map((e) => StandingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Risultati della giornata fantasy (partite tra squadre della lega).
  Future<List<MatchdayResultModel>> getMatchdayResults(String leagueId, int matchday) async {
    final response = await auth.dio.get('/leagues/$leagueId/matchday/$matchday/results');
    final list = response.data is List ? response.data as List : [];
    return list.map((e) => MatchdayResultModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Lista membri della lega (solo per partecipanti).
  Future<List<LeagueMemberModel>> getLeagueMembers(String leagueId) async {
    final response = await auth.dio.get('/leagues/$leagueId/members');
    final list = response.data is List ? response.data as List : [];
    return list.map((e) => LeagueMemberModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Rimuovi membro dalla lega (solo admin).
  Future<void> removeLeagueMember(String leagueId, String userId) async {
    await auth.dio.delete('/leagues/$leagueId/members/$userId');
  }

  /// Blocca membro (solo admin).
  Future<void> blockLeagueMember(String leagueId, String userId, {String? reason}) async {
    await auth.dio.post(
      '/leagues/$leagueId/members/$userId/block',
      data: reason != null && reason.isNotEmpty ? {'reason': reason} : null,
    );
  }

  /// Sblocca membro (solo admin).
  Future<void> unblockLeagueMember(String leagueId, String userId) async {
    await auth.dio.post('/leagues/$leagueId/members/$userId/unblock');
  }

  /// Elimina lega - soft delete (solo admin).
  Future<void> deleteLeague(String leagueId) async {
    await auth.dio.delete('/leagues/$leagueId');
  }
}

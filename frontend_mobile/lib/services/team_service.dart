import 'auth_service.dart';
import '../models/team_detail.dart';
import '../models/fantasy_team.dart';
import '../models/lineup.dart';

/// Servizio API squadra fantasy: dettaglio rosa, formazione GET/POST.
class TeamService {
  TeamService(this.auth);

  final AuthService auth;

  Future<FantasyTeamModel> createTeam(
    String leagueId,
    String name, {
    String? logoUrl,
    String? coachName,
    String? coachAvatarUrl,
  }) async {
    final data = <String, dynamic>{
      'league_id': leagueId,
      'name': name,
    };
    if (logoUrl != null) data['logo_url'] = logoUrl;
    if (coachName != null) data['coach_name'] = coachName;
    if (coachAvatarUrl != null) data['coach_avatar_url'] = coachAvatarUrl;
    final response = await auth.dio.post('/teams', data: data);
    return FantasyTeamModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TeamDetailModel> getTeam(String teamId) async {
    final response = await auth.dio.get('/teams/$teamId');
    return TeamDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LineupResponseModel> getLineup(String teamId, int matchday) async {
    final response = await auth.dio.get('/teams/$teamId/lineup/$matchday');
    return LineupResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> setLineup(
    String teamId,
    int matchday,
    String formation,
    List<Map<String, dynamic>> slots,
  ) async {
    final response = await auth.dio.post(
      '/teams/$teamId/lineup/$matchday',
      data: {'formation': formation, 'slots': slots},
    );
    return response.data as Map<String, dynamic>;
  }
}

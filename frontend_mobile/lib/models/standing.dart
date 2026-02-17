import '../utils/json_utils.dart';

/// Riga classifica fantasy (backend StandingRow).
class StandingModel {
  final int rank;
  final String fantasyTeamId;
  final String teamName;
  final String userId;
  final int totalPoints;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final String? logoUrl;
  final String? coachAvatarUrl;
  final num? budgetRemaining;
  final bool isConfigured;

  const StandingModel({
    required this.rank,
    required this.fantasyTeamId,
    required this.teamName,
    required this.userId,
    required this.totalPoints,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    this.logoUrl,
    this.coachAvatarUrl,
    this.budgetRemaining,
    this.isConfigured = false,
  });

  factory StandingModel.fromJson(Map<String, dynamic> json) {
    return StandingModel(
      rank: toIntSafeOrDefault(json['rank'], 0),
      fantasyTeamId: _stringFromJson(json['fantasy_team_id']),
      teamName: _stringFromJson(json['team_name']) ?? '',
      userId: _stringFromJson(json['user_id']),
      totalPoints: toIntSafeOrDefault(json['total_points'], 0),
      wins: toIntSafeOrDefault(json['wins'], 0),
      draws: toIntSafeOrDefault(json['draws'], 0),
      losses: toIntSafeOrDefault(json['losses'], 0),
      goalsFor: toIntSafeOrDefault(json['goals_for'], 0),
      goalsAgainst: toIntSafeOrDefault(json['goals_against'], 0),
      logoUrl: _stringFromJson(json['logo_url']),
      coachAvatarUrl: _stringFromJson(json['coach_avatar_url']),
      budgetRemaining: toDoubleSafe(json['budget_remaining']),
      isConfigured: json['is_configured'] == true,
    );
  }

  static String _stringFromJson(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  int get goalDifference => goalsFor - goalsAgainst;
}

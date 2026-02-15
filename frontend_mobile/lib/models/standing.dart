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
  });

  factory StandingModel.fromJson(Map<String, dynamic> json) {
    return StandingModel(
      rank: toIntSafeOrDefault(json['rank'], 0),
      fantasyTeamId: json['fantasy_team_id'] as String,
      teamName: json['team_name'] as String,
      userId: json['user_id'] as String,
      totalPoints: toIntSafeOrDefault(json['total_points'], 0),
      wins: toIntSafeOrDefault(json['wins'], 0),
      draws: toIntSafeOrDefault(json['draws'], 0),
      losses: toIntSafeOrDefault(json['losses'], 0),
      goalsFor: toIntSafeOrDefault(json['goals_for'], 0),
      goalsAgainst: toIntSafeOrDefault(json['goals_against'], 0),
    );
  }

  int get goalDifference => goalsFor - goalsAgainst;
}

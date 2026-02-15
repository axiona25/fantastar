/// Risultato partita fantasy nella giornata (GET leagues/{id}/matchday/{md}/results).
class MatchdayResultModel {
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final double homeScore;
  final double awayScore;
  final int homeGoals;
  final int awayGoals;
  final String homeResult;
  final String awayResult;

  const MatchdayResultModel({
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    required this.homeGoals,
    required this.awayGoals,
    required this.homeResult,
    required this.awayResult,
  });

  factory MatchdayResultModel.fromJson(Map<String, dynamic> json) {
    return MatchdayResultModel(
      homeTeamId: json['home_team_id'] as String? ?? '',
      awayTeamId: json['away_team_id'] as String? ?? '',
      homeTeamName: json['home_team_name'] as String? ?? '',
      awayTeamName: json['away_team_name'] as String? ?? '',
      homeScore: (json['home_score'] as num?)?.toDouble() ?? 0,
      awayScore: (json['away_score'] as num?)?.toDouble() ?? 0,
      homeGoals: json['home_goals'] as int? ?? 0,
      awayGoals: json['away_goals'] as int? ?? 0,
      homeResult: json['home_result'] as String? ?? '',
      awayResult: json['away_result'] as String? ?? '',
    );
  }
}

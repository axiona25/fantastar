/// Partita del calendario fantasy (GET /leagues/{id}/calendar).
class CalendarMatchModel {
  final int matchday;
  final String homeTeamName;
  final String awayTeamName;

  const CalendarMatchModel({
    required this.matchday,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  factory CalendarMatchModel.fromJson(Map<String, dynamic> json) {
    return CalendarMatchModel(
      matchday: json['matchday'] as int,
      homeTeamName: json['home_team_name'] as String? ?? '',
      awayTeamName: json['away_team_name'] as String? ?? '',
    );
  }
}

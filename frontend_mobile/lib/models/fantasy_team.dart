/// Modello squadra fantasy (placeholder).
class FantasyTeamModel {
  final String id;
  final String name;
  final String leagueId;

  const FantasyTeamModel({
    required this.id,
    required this.name,
    required this.leagueId,
  });

  factory FantasyTeamModel.fromJson(Map<String, dynamic> json) {
    return FantasyTeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      leagueId: json['league_id'] as String,
    );
  }
}

/// Voce top marcatori (backend /stats/top-scorers).
class TopScorerModel {
  final int playerId;
  final String name;
  final String? position;
  final String? teamName;
  final int goals;

  const TopScorerModel({
    required this.playerId,
    required this.name,
    this.position,
    this.teamName,
    required this.goals,
  });

  factory TopScorerModel.fromJson(Map<String, dynamic> json) {
    return TopScorerModel(
      playerId: json['player_id'] as int,
      name: json['name'] as String,
      position: json['position'] as String?,
      teamName: json['team_name'] as String?,
      goals: (json['goals'] as num?)?.toInt() ?? 0,
    );
  }
}

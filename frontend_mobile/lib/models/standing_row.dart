/// Riga classifica Serie A (GET /stats/standings).
class StandingRow {
  final int position;
  final String? crest;
  final String teamName;
  final int points;
  final int won;
  final int draw;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;

  int get goalDifference => goalsFor - goalsAgainst;

  const StandingRow({
    required this.position,
    this.crest,
    required this.teamName,
    required this.points,
    required this.won,
    required this.draw,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
  });

  factory StandingRow.fromJson(Map<String, dynamic> json) {
    return StandingRow(
      position: (json['position'] as num?)?.toInt() ?? 0,
      crest: json['crest'] as String?,
      teamName: json['team_name'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      won: (json['won'] as num?)?.toInt() ?? 0,
      draw: (json['draw'] as num?)?.toInt() ?? 0,
      lost: (json['lost'] as num?)?.toInt() ?? 0,
      goalsFor: (json['goals_for'] as num?)?.toInt() ?? 0,
      goalsAgainst: (json['goals_against'] as num?)?.toInt() ?? 0,
    );
  }
}

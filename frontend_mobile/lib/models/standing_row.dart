/// Riga classifica Serie A (GET /standings/serie-a o GET /stats/standings).
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
  final int played;

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
    this.played = 0,
  });

  /// Logo squadra: team_logo (nuovo endpoint) o crest (stats/standings).
  String? get teamLogo => crest;

  factory StandingRow.fromJson(Map<String, dynamic> json) {
    final position = (json['rank'] as num?)?.toInt() ?? (json['position'] as num?)?.toInt() ?? 0;
    final crest = json['team_logo'] as String? ?? json['crest'] as String?;
    final teamName = json['team_name'] as String? ?? '';
    final points = (json['points'] as num?)?.toInt() ?? 0;
    final won = (json['wins'] as num?)?.toInt() ?? (json['won'] as num?)?.toInt() ?? 0;
    final draw = (json['draws'] as num?)?.toInt() ?? (json['draw'] as num?)?.toInt() ?? 0;
    final lost = (json['losses'] as num?)?.toInt() ?? (json['lost'] as num?)?.toInt() ?? 0;
    final goalsFor = (json['goals_for'] as num?)?.toInt() ?? 0;
    final goalsAgainst = (json['goals_against'] as num?)?.toInt() ?? 0;
    final played = (json['played'] as num?)?.toInt() ?? won + draw + lost;
    return StandingRow(
      position: position,
      crest: crest,
      teamName: teamName,
      points: points,
      won: won,
      draw: draw,
      lost: lost,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      played: played,
    );
  }
}

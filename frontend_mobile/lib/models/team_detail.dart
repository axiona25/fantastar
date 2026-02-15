import '../utils/json_utils.dart';

/// Dettaglio squadra fantasy con rosa (backend TeamDetailResponse).
class TeamDetailModel {
  final String id;
  final String name;
  final String leagueId;
  final double budgetRemaining;
  final int totalPoints;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final List<RosterPlayerModel> roster;

  const TeamDetailModel({
    required this.id,
    required this.name,
    required this.leagueId,
    required this.budgetRemaining,
    required this.totalPoints,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.roster,
  });

  factory TeamDetailModel.fromJson(Map<String, dynamic> json) {
    final rosterList = json['roster'] as List<dynamic>? ?? [];
    return TeamDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      leagueId: json['league_id'] as String,
      budgetRemaining: toDoubleSafeOrDefault(json['budget_remaining'], 0),
      totalPoints: toIntSafeOrDefault(json['total_points'], 0),
      wins: toIntSafeOrDefault(json['wins'], 0),
      draws: toIntSafeOrDefault(json['draws'], 0),
      losses: toIntSafeOrDefault(json['losses'], 0),
      goalsFor: toIntSafeOrDefault(json['goals_for'], 0),
      goalsAgainst: toIntSafeOrDefault(json['goals_against'], 0),
      roster: rosterList.map((e) => RosterPlayerModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Giocatore in rosa (backend RosterPlayerResponse).
class RosterPlayerModel {
  final int playerId;
  final String playerName;
  final String position;
  final double? purchasePrice;
  final String? realTeamName;
  final String? photoUrl;
  final String? cutoutUrl;

  const RosterPlayerModel({
    required this.playerId,
    required this.playerName,
    required this.position,
    this.purchasePrice,
    this.realTeamName,
    this.photoUrl,
    this.cutoutUrl,
  });

  factory RosterPlayerModel.fromJson(Map<String, dynamic> json) {
    return RosterPlayerModel(
      playerId: toIntSafeOrDefault(json['player_id'], 0),
      playerName: json['player_name'] as String,
      position: json['position'] as String,
      purchasePrice: toDoubleSafe(json['purchase_price']),
      realTeamName: json['real_team_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      cutoutUrl: json['cutout_url'] as String?,
    );
  }
}

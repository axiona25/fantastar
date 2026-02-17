/// Modello squadra fantasy.
class FantasyTeamModel {
  final String id;
  final String name;
  final String leagueId;
  final String? logoUrl;
  final String? coachName;
  final String? coachAvatarUrl;
  final bool isConfigured;
  final num? budgetRemaining;

  const FantasyTeamModel({
    required this.id,
    required this.name,
    required this.leagueId,
    this.logoUrl,
    this.coachName,
    this.coachAvatarUrl,
    this.isConfigured = false,
    this.budgetRemaining,
  });

  factory FantasyTeamModel.fromJson(Map<String, dynamic> json) {
    return FantasyTeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      leagueId: json['league_id'] as String,
      logoUrl: json['logo_url'] as String?,
      coachName: json['coach_name'] as String?,
      coachAvatarUrl: json['coach_avatar_url'] as String?,
      isConfigured: json['is_configured'] as bool? ?? false,
      budgetRemaining: json['budget_remaining'] != null ? (json['budget_remaining'] as num) : null,
    );
  }
}

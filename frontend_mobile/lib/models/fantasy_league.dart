import '../utils/json_utils.dart';

/// Modello lega fantasy (backend LeagueResponse).
class FantasyLeagueModel {
  final String id;
  final String name;
  /// Nome icona/logo (es. 'trophy', 'star'). Default 'trophy'.
  final String logo;
  final String? adminUserId;
  final String? inviteCode;
  final int maxTeams;
  final String leagueType; // 'public' | 'private'
  final int? maxMembers; // null per pubbliche, 4-20 per private
  final double budget;
  final int? teamCount;
  /// Per leghe figlie (auto-split): nome da mostrare (es. "Fantastar Public" invece di "Fantastar Public #2").
  final String? displayName;

  const FantasyLeagueModel({
    required this.id,
    required this.name,
    this.logo = 'trophy',
    this.adminUserId,
    this.inviteCode,
    this.maxTeams = 10,
    this.leagueType = 'private',
    this.maxMembers,
    this.budget = 500,
    this.teamCount,
    this.displayName,
  });

  factory FantasyLeagueModel.fromJson(Map<String, dynamic> json) {
    return FantasyLeagueModel(
      id: json['id'] as String,
      name: json['name'] as String,
      logo: json['logo'] as String? ?? 'trophy',
      adminUserId: json['admin_user_id'] as String?,
      inviteCode: json['invite_code'] as String?,
      maxTeams: toIntSafeOrDefault(json['max_teams'], 10),
      leagueType: json['league_type'] as String? ?? 'private',
      maxMembers: toIntSafe(json['max_members']),
      budget: toDoubleSafeOrDefault(json['budget'], 500),
      teamCount: toIntSafe(json['team_count']),
      displayName: json['display_name'] as String?,
    );
  }

  /// Nome da mostrare in UI: displayName se presente (leghe figlie), altrimenti name.
  String get displayTitle => displayName ?? name;

  bool get isPrivate => leagueType == 'private';
  bool get isPublic => leagueType == 'public';

  bool isAdminFor(String? userId) => userId != null && adminUserId == userId;
}

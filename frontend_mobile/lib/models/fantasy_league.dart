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
  /// Calendario round-robin già generato (una sola volta per lega).
  final bool calendarGenerated;
  /// Lega avviata: asta configurata e notifiche inviate; abilita il pulsante Asta in La mia Squadra.
  final bool astaStarted;
  /// Tipo asta scelto in creazione: 'classic' = rilanci competitivi, 'random' = busta chiusa.
  final String auctionType;

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
    this.calendarGenerated = false,
    this.astaStarted = false,
    this.auctionType = 'classic',
  });

  factory FantasyLeagueModel.fromJson(Map<String, dynamic> json) {
    return FantasyLeagueModel(
      id: _stringFromJson(json['id']) ?? '',
      name: _stringFromJson(json['name']) ?? '',
      logo: _stringFromJson(json['logo']) ?? 'trophy',
      adminUserId: _stringFromJson(json['admin_user_id']),
      inviteCode: _stringFromJson(json['invite_code']),
      maxTeams: toIntSafeOrDefault(json['max_teams'], 10),
      leagueType: _stringFromJson(json['league_type']) ?? 'private',
      maxMembers: toIntSafe(json['max_members']),
      budget: toDoubleSafeOrDefault(json['budget'], 500),
      teamCount: toIntSafe(json['team_count']),
      displayName: _stringFromJson(json['display_name']),
      calendarGenerated: json['calendar_generated'] == true,
      astaStarted: json['asta_started'] == true,
      auctionType: _stringFromJson(json['auction_type']) ?? 'classic',
    );
  }

  static String? _stringFromJson(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  /// Nome da mostrare in UI: displayName se presente (leghe figlie), altrimenti name.
  String get displayTitle => displayName ?? name;

  bool get isPrivate => leagueType == 'private';
  bool get isPublic => leagueType == 'public';

  bool isAdminFor(String? userId) => userId != null && adminUserId == userId;
}

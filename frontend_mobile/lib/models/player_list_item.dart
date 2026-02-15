import '../utils/json_utils.dart';

/// Riga listone / free agents (backend PlayerListResponse).
class PlayerListItemModel {
  final int id;
  final String name;
  final String position;
  final int realTeamId;
  final String realTeamName;
  final double initialPrice;
  final bool isAvailable;
  final String? ownedBy;
  final String? photoUrl;
  final String? cutoutUrl;

  const PlayerListItemModel({
    required this.id,
    required this.name,
    required this.position,
    this.realTeamId = 0,
    required this.realTeamName,
    required this.initialPrice,
    this.isAvailable = true,
    this.ownedBy,
    this.photoUrl,
    this.cutoutUrl,
  });

  factory PlayerListItemModel.fromJson(Map<String, dynamic> json) {
    return PlayerListItemModel(
      id: toIntSafeOrDefault(json['id'], 0),
      name: json['name'] as String,
      position: json['position'] as String? ?? 'CEN',
      realTeamId: toIntSafeOrDefault(json['real_team_id'], 0),
      realTeamName: json['real_team_name'] as String? ?? '—',
      initialPrice: toDoubleSafeOrDefault(json['initial_price'], 0),
      isAvailable: json['is_available'] as bool? ?? true,
      ownedBy: json['owned_by'] as String?,
      photoUrl: json['photo_url'] as String?,
      cutoutUrl: json['cutout_url'] as String?,
    );
  }
}

class PlayerListPaginatedResult {
  final List<PlayerListItemModel> players;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const PlayerListPaginatedResult({
    required this.players,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });
}

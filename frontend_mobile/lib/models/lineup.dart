/// Slot formazione (backend LineupSlot).
class LineupSlotModel {
  final int playerId;
  final String positionSlot;
  final bool isStarter;
  final int? benchOrder;

  const LineupSlotModel({
    required this.playerId,
    required this.positionSlot,
    this.isStarter = true,
    this.benchOrder,
  });

  factory LineupSlotModel.fromJson(Map<String, dynamic> json) {
    return LineupSlotModel(
      playerId: json['player_id'] as int,
      positionSlot: json['position_slot'] as String,
      isStarter: json['is_starter'] as bool? ?? true,
      benchOrder: (json['bench_order'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'position_slot': positionSlot,
        'is_starter': isStarter,
        'bench_order': benchOrder,
      };
}

/// Risposta GET lineup (backend LineupResponse).
class LineupResponseModel {
  final String fantasyTeamId;
  final int matchday;
  final String? formation;
  final List<LineupSlotModel> starters;
  final List<LineupSlotModel> bench;

  const LineupResponseModel({
    required this.fantasyTeamId,
    required this.matchday,
    this.formation,
    this.starters = const [],
    this.bench = const [],
  });

  factory LineupResponseModel.fromJson(Map<String, dynamic> json) {
    final startersList = json['starters'] as List<dynamic>? ?? [];
    final benchList = json['bench'] as List<dynamic>? ?? [];
    return LineupResponseModel(
      fantasyTeamId: json['fantasy_team_id'] as String,
      matchday: (json['matchday'] as num).toInt(),
      formation: json['formation'] as String?,
      starters: startersList.map((e) => LineupSlotModel.fromJson(e as Map<String, dynamic>)).toList(),
      bench: benchList.map((e) => LineupSlotModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Moduli validi (backend VALID_FORMATIONS).
const List<String> kValidFormations = ['3-4-3', '3-5-2', '4-3-3', '4-4-2', '4-5-1', '5-3-2', '5-4-1'];

/// Punteggio singolo giocatore in una giornata (dettaglio risultati, con flag 6 politico).
class PlayerScoreDetailModel {
  final int playerId;
  final double totalScore;
  final double baseScore;
  final double advancedScore;
  final bool wasSubbedIn;
  final bool isPostponed;

  const PlayerScoreDetailModel({
    required this.playerId,
    required this.totalScore,
    required this.baseScore,
    required this.advancedScore,
    this.wasSubbedIn = false,
    this.isPostponed = false,
  });

  factory PlayerScoreDetailModel.fromJson(Map<String, dynamic> json) {
    return PlayerScoreDetailModel(
      playerId: json['player_id'] as int? ?? 0,
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 0,
      baseScore: (json['base_score'] as num?)?.toDouble() ?? 0,
      advancedScore: (json['advanced_score'] as num?)?.toDouble() ?? 0,
      wasSubbedIn: json['was_subbed_in'] as bool? ?? false,
      isPostponed: json['is_postponed'] as bool? ?? false,
    );
  }
}

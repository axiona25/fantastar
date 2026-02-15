/// Pagella: voto giocatore per partita (GET matches/{id}/ratings).
class PlayerRatingModel {
  final int playerId;
  final String playerName;
  final double rating;
  final String trend;
  final int mentions;
  final int minute;

  const PlayerRatingModel({
    required this.playerId,
    required this.playerName,
    required this.rating,
    required this.trend,
    required this.mentions,
    required this.minute,
  });

  factory PlayerRatingModel.fromJson(Map<String, dynamic> json) {
    return PlayerRatingModel(
      playerId: json['player_id'] as int? ?? 0,
      playerName: json['player_name'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      trend: json['trend'] as String? ?? 'stable',
      mentions: json['mentions'] as int? ?? 0,
      minute: json['minute'] as int? ?? 0,
    );
  }
}

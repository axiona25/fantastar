/// Modello giocatore (placeholder — dettagli da task listone/mercato).
class PlayerModel {
  final int id;
  final String name;
  final String? position;

  const PlayerModel({required this.id, required this.name, this.position});

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] as int,
      name: json['name'] as String,
      position: json['position'] as String?,
    );
  }
}

/// Modello squadra reale (placeholder).
class RealTeamModel {
  final int id;
  final String name;

  const RealTeamModel({required this.id, required this.name});

  factory RealTeamModel.fromJson(Map<String, dynamic> json) {
    return RealTeamModel(id: json['id'] as int, name: json['name'] as String);
  }
}

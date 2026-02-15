import '../utils/json_utils.dart';

/// Scheda giocatore (backend PlayerDetailResponse).
class PlayerDetailModel {
  final int id;
  final String name;
  final String position;
  final String? positionDetail;
  final String? realTeamName;
  final String? realTeamBadge;
  final int? shirtNumber;
  final String? nationality;
  final String? dateOfBirth;
  final int? age;
  final String? height;
  final String? weight;
  final String? birthPlace;
  final String? description;
  final String? photoUrl;
  final String? cutoutUrl;
  final double? initialPrice;
  final double? currentValue;
  final PlayerSeasonStatsModel? seasonStats;
  final List<PlayerFantasyScoreModel> fantasyScores;

  const PlayerDetailModel({
    required this.id,
    required this.name,
    required this.position,
    this.positionDetail,
    this.realTeamName,
    this.realTeamBadge,
    this.shirtNumber,
    this.nationality,
    this.dateOfBirth,
    this.age,
    this.height,
    this.weight,
    this.birthPlace,
    this.description,
    this.photoUrl,
    this.cutoutUrl,
    this.initialPrice,
    this.currentValue,
    this.seasonStats,
    this.fantasyScores = const [],
  });

  factory PlayerDetailModel.fromJson(Map<String, dynamic> json) {
    final stats = json['season_stats'];
    final scores = json['fantasy_scores'] as List<dynamic>? ?? [];
    return PlayerDetailModel(
      id: toIntSafeOrDefault(json['id'], 0),
      name: json['name'] as String,
      position: json['position'] as String? ?? 'CEN',
      positionDetail: json['position_detail'] as String?,
      realTeamName: json['real_team_name'] as String?,
      realTeamBadge: json['real_team_badge'] as String?,
      shirtNumber: toIntSafe(json['shirt_number']),
      nationality: json['nationality'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      age: toIntSafe(json['age']),
      height: json['height'] as String?,
      weight: json['weight'] as String?,
      birthPlace: json['birth_place'] as String?,
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      cutoutUrl: json['cutout_url'] as String?,
      initialPrice: toDoubleSafe(json['initial_price']),
      currentValue: toDoubleSafe(json['current_value']),
      seasonStats: stats != null ? PlayerSeasonStatsModel.fromJson(stats as Map<String, dynamic>) : null,
      fantasyScores: scores.map((e) => PlayerFantasyScoreModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class PlayerSeasonStatsModel {
  final int appearances;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int minutesPlayed;
  final double? avgRating;

  const PlayerSeasonStatsModel({
    this.appearances = 0,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.minutesPlayed = 0,
    this.avgRating,
  });

  factory PlayerSeasonStatsModel.fromJson(Map<String, dynamic> json) {
    return PlayerSeasonStatsModel(
      appearances: toIntSafeOrDefault(json['appearances'], 0),
      goals: toIntSafeOrDefault(json['goals'], 0),
      assists: toIntSafeOrDefault(json['assists'], 0),
      yellowCards: toIntSafeOrDefault(json['yellow_cards'], 0),
      redCards: toIntSafeOrDefault(json['red_cards'], 0),
      minutesPlayed: toIntSafeOrDefault(json['minutes_played'], 0),
      avgRating: toDoubleSafe(json['avg_rating']),
    );
  }
}

class PlayerFantasyScoreModel {
  final int matchday;
  final double score;
  final List<String> events;

  const PlayerFantasyScoreModel({required this.matchday, required this.score, this.events = const []});

  factory PlayerFantasyScoreModel.fromJson(Map<String, dynamic> json) {
    final eventsList = json['events'] as List<dynamic>? ?? [];
    return PlayerFantasyScoreModel(
      matchday: toIntSafeOrDefault(json['matchday'], 0),
      score: toDoubleSafeOrDefault(json['score'], 0),
      events: eventsList.map((e) => e.toString()).toList(),
    );
  }
}

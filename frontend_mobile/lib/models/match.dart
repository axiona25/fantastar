/// Modello partita (placeholder / list item).
class MatchModel {
  final int id;
  final int matchday;
  final String homeTeamName;
  final String awayTeamName;
  final int? homeScore;
  final int? awayScore;
  final String? status;
  final int? minute;
  final DateTime? kickOff;
  final String? homeCrest;
  final String? awayCrest;
  final String? homeTla;
  final String? awayTla;

  const MatchModel({
    required this.id,
    required this.matchday,
    this.homeTeamName = '',
    this.awayTeamName = '',
    this.homeScore,
    this.awayScore,
    this.status,
    this.minute,
    this.kickOff,
    this.homeCrest,
    this.awayCrest,
    this.homeTla,
    this.awayTla,
  });

  /// Sigla 3 lettere per la squadra di casa (TLA o prime 3 lettere nome).
  String get homeSigla {
    if (homeTla != null && homeTla!.length >= 3) return homeTla!.toUpperCase().substring(0, 3);
    final n = homeTeamName.toUpperCase().replaceAll(' ', '');
    return n.isEmpty ? '---' : (n.length >= 3 ? n.substring(0, 3) : n);
  }

  /// Sigla 3 lettere per la squadra in trasferta.
  String get awaySigla {
    if (awayTla != null && awayTla!.length >= 3) return awayTla!.toUpperCase().substring(0, 3);
    final n = awayTeamName.toUpperCase().replaceAll(' ', '');
    return n.isEmpty ? '---' : (n.length >= 3 ? n.substring(0, 3) : n);
  }

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as int,
      matchday: json['matchday'] as int? ?? 0,
      homeTeamName: json['home_team_name'] as String? ?? '',
      awayTeamName: json['away_team_name'] as String? ?? '',
      homeScore: json['home_score'] as int?,
      awayScore: json['away_score'] as int?,
      status: json['status'] as String?,
      minute: json['minute'] as int?,
      kickOff: json['kick_off'] != null ? DateTime.tryParse(json['kick_off'] as String) : null,
      homeCrest: json['home_crest'] as String?,
      awayCrest: json['away_crest'] as String?,
      homeTla: json['home_tla'] as String?,
      awayTla: json['away_tla'] as String?,
    );
  }

  bool get isPlayed =>
      status == 'FINISHED' || (homeScore != null && awayScore != null);
}


/// Evento partita (gol, cartellino, sostituzione).
class MatchEventModel {
  final String type;
  final int? minute;

  const MatchEventModel({required this.type, this.minute});

  factory MatchEventModel.fromJson(Map<String, dynamic> json) {
    return MatchEventModel(
      type: json['type'] as String? ?? '',
      minute: json['minute'] as int?,
    );
  }
}

/// Team summary nel dettaglio partita (nome, sigla, stemma).
class TeamSummaryModel {
  final String name;
  final String? short;
  final String? crest;

  const TeamSummaryModel({required this.name, this.short, this.crest});

  factory TeamSummaryModel.fromJson(Map<String, dynamic> json) {
    return TeamSummaryModel(
      name: json['name'] as String? ?? '',
      short: json['short'] as String?,
      crest: json['crest'] as String?,
    );
  }
}

/// Evento cronaca (gol, cartellino, sostituzione) con dettagli.
class MatchEventDetailModel {
  /// Minuto come stringa (es. "15'", "90'+4") o numero.
  final String minuteDisplay;
  final String type;
  final String? team; // "home" | "away"
  final String? player;
  final String? detail;
  final String? playerIn;
  final String? playerOut;

  const MatchEventDetailModel({
    required this.minuteDisplay,
    required this.type,
    this.team,
    this.player,
    this.detail,
    this.playerIn,
    this.playerOut,
  });

  factory MatchEventDetailModel.fromJson(Map<String, dynamic> json) {
    final m = json['minute'];
    final minuteStr = m == null ? "—" : (m is num ? "$m'" : m.toString());
    return MatchEventDetailModel(
      minuteDisplay: minuteStr,
      type: json['type'] as String? ?? '',
      team: json['team'] as String?,
      player: json['player'] as String?,
      detail: json['detail'] as String?,
      playerIn: json['player_in'] as String?,
      playerOut: json['player_out'] as String?,
    );
  }
}

/// Giocatore in formazione (nome, numero, ruolo).
class LineupPlayerModel {
  final String name;
  final String? number; // numero maglia (stringa o int da API)
  final String? position;

  const LineupPlayerModel({required this.name, this.number, this.position});

  factory LineupPlayerModel.fromJson(Map<String, dynamic> json) {
    final n = json['number'];
    final numberStr = n == null ? null : (n is num ? n.toString() : n.toString());
    return LineupPlayerModel(
      name: json['name'] as String? ?? '',
      number: numberStr,
      position: json['position'] as String?,
    );
  }
}

/// Formazione (modulo, titolari, panchina).
class TeamLineupModel {
  final String? formation;
  final List<LineupPlayerModel> starting;
  final List<LineupPlayerModel> substitutes;

  const TeamLineupModel({
    this.formation,
    this.starting = const [],
    this.substitutes = const [],
  });

  factory TeamLineupModel.fromJson(Map<String, dynamic> json) {
    final startList = json['starting'] as List<dynamic>? ?? json['starters'] as List<dynamic>? ?? [];
    final subsList = json['substitutes'] as List<dynamic>? ?? [];
    return TeamLineupModel(
      formation: json['formation'] as String?,
      starting: startList.map((e) => LineupPlayerModel.fromJson(e as Map<String, dynamic>)).toList(),
      substitutes: subsList.map((e) => LineupPlayerModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Una riga statistiche (nome IT, valore casa, valore trasferta).
class StatisticsEntryModel {
  final String name;
  final String home;
  final String away;

  const StatisticsEntryModel({required this.name, required this.home, required this.away});

  factory StatisticsEntryModel.fromJson(Map<String, dynamic> json) {
    return StatisticsEntryModel(
      name: json['name'] as String? ?? '',
      home: (json['home'] ?? '').toString(),
      away: (json['away'] ?? '').toString(),
    );
  }
}

/// Voce cronaca testuale (minuto, testo).
class CommentaryEntryModel {
  final String minute;
  final String text;

  const CommentaryEntryModel({required this.minute, required this.text});

  factory CommentaryEntryModel.fromJson(Map<String, dynamic> json) {
    return CommentaryEntryModel(
      minute: (json['minute'] ?? '').toString(),
      text: json['text'] as String? ?? '',
    );
  }
}

/// Statistiche comparative casa/trasferta.
class MatchStatisticsModel {
  final List<int> possession;
  final List<int> shots;
  final List<int> shotsOnTarget;
  final List<int> corners;
  final List<int> fouls;
  final List<int> offsides;
  final List<int> yellowCards;
  final List<int> redCards;

  const MatchStatisticsModel({
    this.possession = const [],
    this.shots = const [],
    this.shotsOnTarget = const [],
    this.corners = const [],
    this.fouls = const [],
    this.offsides = const [],
    this.yellowCards = const [],
    this.redCards = const [],
  });

  factory MatchStatisticsModel.fromJson(Map<String, dynamic> json) {
    return MatchStatisticsModel(
      possession: (json['possession'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
      shots: (json['shots'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
      shotsOnTarget: (json['shots_on_target'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
      corners: (json['corners'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
      fouls: (json['fouls'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
      offsides: (json['offsides'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
      yellowCards: (json['yellow_cards'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
      redCards: (json['red_cards'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
    );
  }
}

/// Arbitro (da API).
class RefereeSummaryModel {
  final String name;
  final String? nationality;

  const RefereeSummaryModel({required this.name, this.nationality});

  factory RefereeSummaryModel.fromJson(Map<String, dynamic> json) {
    return RefereeSummaryModel(
      name: json['name'] as String? ?? '',
      nationality: json['nationality'] as String?,
    );
  }
}

/// Dettaglio partita (GET /matches/{id}/detail): risultato, data, stadio, arbitro, cronaca, formazioni, statistiche (IT), commentary.
class MatchDetailFullModel {
  final int id;
  final int matchday;
  final String status;
  final int? minute;
  final DateTime? kickOff;
  final TeamSummaryModel homeTeam;
  final TeamSummaryModel awayTeam;
  final int? homeScore;
  final int? awayScore;
  final RefereeSummaryModel? referee;
  final String? venue;
  final List<MatchEventDetailModel> events;
  final Map<String, TeamLineupModel> lineups;
  /// Statistiche in italiano (Possesso palla, Tiri totali, ...) con valori home/away.
  final List<StatisticsEntryModel> statistics;
  final MatchStatisticsModel? statisticsLegacy;
  final List<CommentaryEntryModel> commentary;
  /// false = traduzione in corso in background (alla prossima apertura sarà in italiano).
  final bool translated;

  const MatchDetailFullModel({
    required this.id,
    required this.matchday,
    required this.status,
    this.minute,
    this.kickOff,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.referee,
    this.venue,
    this.events = const [],
    this.lineups = const {},
    this.statistics = const [],
    this.statisticsLegacy,
    this.commentary = const [],
    this.translated = true,
  });

  factory MatchDetailFullModel.fromJson(Map<String, dynamic> json) {
    final home = json['home_team'] as Map<String, dynamic>?;
    final away = json['away_team'] as Map<String, dynamic>?;
    final eventsList = json['events'] as List<dynamic>? ?? [];
    final lineupsMap = json['lineups'] as Map<String, dynamic>? ?? {};
    final ref = json['referee'] as Map<String, dynamic>?;
    final statsRaw = json['statistics'];
    List<StatisticsEntryModel> statsList = const [];
    MatchStatisticsModel? statsLegacy;
    if (statsRaw is List) {
      statsList = statsRaw.map((e) => StatisticsEntryModel.fromJson(e as Map<String, dynamic>)).toList();
    } else if (statsRaw is Map<String, dynamic>) {
      statsLegacy = MatchStatisticsModel.fromJson(statsRaw);
    }
    final commList = json['commentary'] as List<dynamic>? ?? [];
    return MatchDetailFullModel(
      id: json['id'] as int,
      matchday: (json['matchday'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'SCHEDULED',
      minute: (json['minute'] as num?)?.toInt(),
      kickOff: json['kick_off'] != null ? DateTime.tryParse(json['kick_off'] as String) : null,
      homeTeam: home != null ? TeamSummaryModel.fromJson(home) : const TeamSummaryModel(name: ''),
      awayTeam: away != null ? TeamSummaryModel.fromJson(away) : const TeamSummaryModel(name: ''),
      homeScore: (json['home_score'] as num?)?.toInt(),
      awayScore: (json['away_score'] as num?)?.toInt(),
      referee: ref != null ? RefereeSummaryModel.fromJson(ref) : null,
      venue: json['venue'] as String?,
      events: eventsList.map((e) => MatchEventDetailModel.fromJson(e as Map<String, dynamic>)).toList(),
      lineups: lineupsMap.map((k, v) => MapEntry(k, TeamLineupModel.fromJson(v as Map<String, dynamic>))),
      statistics: statsList,
      statisticsLegacy: statsLegacy,
      commentary: commList.map((e) => CommentaryEntryModel.fromJson(e as Map<String, dynamic>)).toList(),
      translated: json['translated'] as bool? ?? true,
    );
  }

  String get homeSigla {
    final s = homeTeam.short;
    if (s != null && s.isNotEmpty) return s.length >= 3 ? s.toUpperCase().substring(0, 3) : s.toUpperCase();
    final n = homeTeam.name.toUpperCase().replaceAll(' ', '');
    return n.isEmpty ? '---' : (n.length >= 3 ? n.substring(0, 3) : n);
  }
  String get awaySigla {
    final s = awayTeam.short;
    if (s != null && s.isNotEmpty) return s.length >= 3 ? s.toUpperCase().substring(0, 3) : s.toUpperCase();
    final n = awayTeam.name.toUpperCase().replaceAll(' ', '');
    return n.isEmpty ? '---' : (n.length >= 3 ? n.substring(0, 3) : n);
  }

  bool get isLive => status == 'IN_PLAY' || status == 'PAUSED';
}

/// Dettaglio partita con eventi (REST o da WS match_update).
class MatchDetailModel {
  final int id;
  final int matchday;
  final String homeTeamName;
  final String awayTeamName;
  final int? homeScore;
  final int? awayScore;
  final int? minute;
  final String status;
  final List<MatchEventModel> events;

  const MatchDetailModel({
    required this.id,
    required this.matchday,
    this.homeTeamName = '',
    this.awayTeamName = '',
    this.homeScore,
    this.awayScore,
    this.minute,
    this.status = 'SCHEDULED',
    this.events = const [],
  });

  factory MatchDetailModel.fromJson(Map<String, dynamic> json) {
    final eventsList = json['events'] as List<dynamic>? ?? [];
    return MatchDetailModel(
      id: json['id'] as int,
      matchday: json['matchday'] as int? ?? 0,
      homeTeamName: json['home_team_name'] as String? ?? '',
      awayTeamName: json['away_team_name'] as String? ?? '',
      homeScore: json['home_score'] as int?,
      awayScore: json['away_score'] as int?,
      minute: json['minute'] as int?,
      status: json['status'] as String? ?? 'SCHEDULED',
      events: eventsList.map((e) => MatchEventModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Risultato fantasy giornata (da WS live_scores).
class LiveScoreMatchResult {
  final String homeTeamId;
  final String awayTeamId;
  final double homeScore;
  final double awayScore;
  final int homeGoals;
  final int awayGoals;
  final String homeResult;
  final String awayResult;

  const LiveScoreMatchResult({
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeScore,
    required this.awayScore,
    required this.homeGoals,
    required this.awayGoals,
    required this.homeResult,
    required this.awayResult,
  });

  factory LiveScoreMatchResult.fromJson(Map<String, dynamic> json) {
    return LiveScoreMatchResult(
      homeTeamId: json['home_team_id'] as String? ?? '',
      awayTeamId: json['away_team_id'] as String? ?? '',
      homeScore: (json['home_score'] as num?)?.toDouble() ?? 0,
      awayScore: (json['away_score'] as num?)?.toDouble() ?? 0,
      homeGoals: json['home_goals'] as int? ?? 0,
      awayGoals: json['away_goals'] as int? ?? 0,
      homeResult: json['home_result'] as String? ?? '',
      awayResult: json['away_result'] as String? ?? '',
    );
  }
}

/// Video highlight (ScoreBat o YouTube): watchUrl apre in app/browser esterno.
class MatchHighlightModel {
  final String title;
  final String thumbnail;
  final String? videoId;
  final String? matchviewUrl;
  /// URL da aprire con url_launcher (ScoreBat page o YouTube watch).
  final String watchUrl;
  /// Canale/fonte per sottotitolo (es. "ScoreBat", nome canale YouTube).
  final String source;

  const MatchHighlightModel({
    this.title = '',
    this.thumbnail = '',
    this.videoId,
    this.matchviewUrl,
    this.watchUrl = '',
    this.source = '',
  });

  factory MatchHighlightModel.fromJson(Map<String, dynamic> json) {
    final videoId = json['video_id'] as String?;
    final watch = json['watch_url'] as String? ?? '';
    return MatchHighlightModel(
      title: json['title'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      videoId: videoId,
      matchviewUrl: json['matchview_url'] as String? ?? json['matchviewUrl'] as String?,
      watchUrl: watch.isNotEmpty
          ? watch
          : (videoId != null && videoId.isNotEmpty
              ? 'https://www.youtube.com/watch?v=$videoId'
              : (json['matchviewUrl'] as String? ?? json['matchview_url'] as String? ?? '')),
      source: json['source'] as String? ?? '',
    );
  }
}

/// Eventi fantacalcio per un giocatore nella tab Voti (gol, assist, cartellini, sostituzione, infortunio, ecc.).
class MatchRatingPlayerEventsModel {
  final int goals;
  final int assists;
  final int ownGoals;
  final int yellowCards;
  final int redCards;
  final int penaltySaved;
  final int penaltyMissed;
  final int goalsConceded;
  final int saves;
  final int shotsOnTarget;
  final int minutesPlayed;
  final int subbedIn;
  final int subbedOut;
  final int injury;

  const MatchRatingPlayerEventsModel({
    this.goals = 0,
    this.assists = 0,
    this.ownGoals = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.penaltySaved = 0,
    this.penaltyMissed = 0,
    this.goalsConceded = 0,
    this.saves = 0,
    this.shotsOnTarget = 0,
    this.minutesPlayed = 0,
    this.subbedIn = 0,
    this.subbedOut = 0,
    this.injury = 0,
  });

  factory MatchRatingPlayerEventsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MatchRatingPlayerEventsModel();
    return MatchRatingPlayerEventsModel(
      goals: json['goals'] as int? ?? 0,
      assists: json['assists'] as int? ?? 0,
      ownGoals: json['own_goals'] as int? ?? 0,
      yellowCards: json['yellow_cards'] as int? ?? 0,
      redCards: json['red_cards'] as int? ?? 0,
      penaltySaved: json['penalty_saved'] as int? ?? 0,
      penaltyMissed: json['penalty_missed'] as int? ?? 0,
      goalsConceded: json['goals_conceded'] as int? ?? 0,
      saves: json['saves'] as int? ?? 0,
      shotsOnTarget: json['shots_on_target'] as int? ?? 0,
      minutesPlayed: json['minutes_played'] as int? ?? 0,
      subbedIn: json['subbed_in'] as int? ?? 0,
      subbedOut: json['subbed_out'] as int? ?? 0,
      injury: json['injury'] as int? ?? 0,
    );
  }
}

/// Singolo evento in lista (gol, cartellino, ecc.).
class MatchRatingPlayerEventItemModel {
  final String type;
  final int? minute;

  const MatchRatingPlayerEventItemModel({this.type = '', this.minute});

  factory MatchRatingPlayerEventItemModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MatchRatingPlayerEventItemModel();
    final m = json['minute'];
    return MatchRatingPlayerEventItemModel(
      type: json['type'] as String? ?? '',
      minute: m is int ? m : (m is num ? m.toInt() : null),
    );
  }
}

/// Un giocatore nella tab Voti (voto base + fantasy_score + eventi).
class MatchRatingPlayerModel {
  final String name;
  final String role;
  final String? number;
  final double? liveRating;
  final double? fantasyScore;
  final bool isStarter;
  /// True se ha messo piede in campo (titolare o subentrato).
  final bool played;
  final bool subbedIn;
  final bool subbedOut;
  final int? minuteIn;
  final int? minuteOut;
  final MatchRatingPlayerEventsModel events;
  /// Lista eventi (gol, cartellini, ecc.) per icone.
  final List<MatchRatingPlayerEventItemModel> eventList;
  final String? photoUrl;
  final String? cutoutUrl;

  const MatchRatingPlayerModel({
    required this.name,
    this.role = 'CEN',
    this.number,
    this.liveRating,
    this.fantasyScore,
    this.isStarter = true,
    this.played = true,
    this.subbedIn = false,
    this.subbedOut = false,
    this.minuteIn,
    this.minuteOut,
    this.events = const MatchRatingPlayerEventsModel(),
    this.eventList = const [],
    this.photoUrl,
    this.cutoutUrl,
  });

  factory MatchRatingPlayerModel.fromJson(Map<String, dynamic> json) {
    final numOrStr = json['number'];
    String? numberStr;
    if (numOrStr != null) numberStr = numOrStr is int ? numOrStr.toString() : numOrStr as String?;
    final minIn = json['minute_in'];
    final minOut = json['minute_out'];
    final eventListRaw = json['event_list'] as List<dynamic>? ?? [];
    return MatchRatingPlayerModel(
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'CEN',
      number: numberStr,
      liveRating: (json['live_rating'] as num?)?.toDouble(),
      fantasyScore: (json['fantasy_score'] as num?)?.toDouble(),
      isStarter: json['is_starter'] as bool? ?? true,
      played: json['played'] as bool? ?? true,
      subbedIn: json['subbed_in'] as bool? ?? false,
      subbedOut: json['subbed_out'] as bool? ?? false,
      minuteIn: minIn is int ? minIn : (minIn is num ? minIn.toInt() : null),
      minuteOut: minOut is int ? minOut : (minOut is num ? minOut.toInt() : null),
      events: MatchRatingPlayerEventsModel.fromJson(json['events'] as Map<String, dynamic>?),
      eventList: eventListRaw.map((e) => MatchRatingPlayerEventItemModel.fromJson(e as Map<String, dynamic>?)).toList(),
      photoUrl: json['photo_url'] as String?,
      cutoutUrl: json['cutout_url'] as String?,
    );
  }
}

/// Squadra nella tab Voti (casa o trasferta): titolari e panchina separati.
class MatchRatingTeamModel {
  final String name;
  final List<MatchRatingPlayerModel> starters;
  final List<MatchRatingPlayerModel> bench;

  const MatchRatingTeamModel({this.name = '', this.starters = const [], this.bench = const []});

  /// Lista concatenata starters + bench (per compatibilità).
  List<MatchRatingPlayerModel> get players => [...starters, ...bench];

  factory MatchRatingTeamModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MatchRatingTeamModel();
    final startersList = json['starters'] as List<dynamic>? ?? [];
    final benchList = json['bench'] as List<dynamic>? ?? [];
    return MatchRatingTeamModel(
      name: json['name'] as String? ?? '',
      starters: startersList.map((e) => MatchRatingPlayerModel.fromJson(e as Map<String, dynamic>)).toList(),
      bench: benchList.map((e) => MatchRatingPlayerModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Risposta GET /matches/{id}/ratings: voti live o ufficiali per partita.
class MatchRatingsResponseModel {
  final int matchId;
  final String source;
  final bool isFinal;
  final MatchRatingTeamModel homeTeam;
  final MatchRatingTeamModel awayTeam;

  const MatchRatingsResponseModel({
    required this.matchId,
    this.source = 'algorithm',
    this.isFinal = false,
    this.homeTeam = const MatchRatingTeamModel(),
    this.awayTeam = const MatchRatingTeamModel(),
  });

  factory MatchRatingsResponseModel.fromJson(Map<String, dynamic> json) {
    return MatchRatingsResponseModel(
      matchId: json['match_id'] as int? ?? 0,
      source: json['source'] as String? ?? 'algorithm',
      isFinal: json['is_final'] as bool? ?? false,
      homeTeam: MatchRatingTeamModel.fromJson(json['home_team'] as Map<String, dynamic>?),
      awayTeam: MatchRatingTeamModel.fromJson(json['away_team'] as Map<String, dynamic>?),
    );
  }
}

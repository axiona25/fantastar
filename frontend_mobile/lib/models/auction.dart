/// Progresso categoria corrente per utente (completed/required).
class AuctionStatusCategoryProgress {
  final int completed;
  final int required;

  const AuctionStatusCategoryProgress({required this.completed, required this.required});

  factory AuctionStatusCategoryProgress.fromJson(Map<String, dynamic> json) =>
      AuctionStatusCategoryProgress(
        completed: num.tryParse(json['completed']?.toString() ?? '')?.toInt() ?? 0,
        required: num.tryParse(json['required']?.toString() ?? '')?.toInt() ?? 0,
      );
}

/// Stato asta (GET /auction/status).
class AuctionStatusModel {
  final String status; // idle | active | paused | completed
  final AuctionStatusPlayer? currentPlayer;
  final AuctionStatusBid? currentBid;
  final int? timerRemaining;
  final List<String> eligibleBidders;
  final List<AuctionStatusParticipant> participants;
  final String? currentCategory; // POR | DIF | CEN | ATT
  final String? currentTurnUserId;
  final String? currentTurnUserName;
  final Map<String, AuctionStatusCategoryProgress>? categoryProgress;
  final bool? isMyTurn;
  final bool? isOnlyOneLeftInCategory;

  const AuctionStatusModel({
    required this.status,
    this.currentPlayer,
    this.currentBid,
    this.timerRemaining,
    this.eligibleBidders = const [],
    this.participants = const [],
    this.currentCategory,
    this.currentTurnUserId,
    this.currentTurnUserName,
    this.categoryProgress,
    this.isMyTurn,
    this.isOnlyOneLeftInCategory,
  });

  factory AuctionStatusModel.fromJson(Map<String, dynamic> json) {
    AuctionStatusPlayer? cp;
    if (json['current_player'] != null) {
      cp = AuctionStatusPlayer.fromJson(json['current_player'] as Map<String, dynamic>);
    }
    AuctionStatusBid? cb;
    if (json['current_bid'] != null) {
      cb = AuctionStatusBid.fromJson(json['current_bid'] as Map<String, dynamic>);
    }
    final parts = (json['participants'] as List<dynamic>?) ?? [];
    Map<String, AuctionStatusCategoryProgress>? catProg;
    if (json['category_progress'] != null && json['category_progress'] is Map) {
      final raw = json['category_progress'] as Map<String, dynamic>;
      catProg = raw.map((k, v) => MapEntry(k, AuctionStatusCategoryProgress.fromJson(v as Map<String, dynamic>)));
    }
    return AuctionStatusModel(
      status: json['status'] as String? ?? 'idle',
      currentPlayer: cp,
      currentBid: cb,
      timerRemaining: num.tryParse(json['timer_remaining']?.toString() ?? '')?.toInt(),
      eligibleBidders: (json['eligible_bidders'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      participants: parts.map((e) => AuctionStatusParticipant.fromJson(e as Map<String, dynamic>)).toList(),
      currentCategory: json['current_category'] as String?,
      currentTurnUserId: json['current_turn_user_id']?.toString(),
      currentTurnUserName: json['current_turn_user_name'] as String?,
      categoryProgress: catProg,
      isMyTurn: json['is_my_turn'] as bool?,
      isOnlyOneLeftInCategory: json['is_only_one_left_in_category'] as bool?,
    );
  }

  /// Etichetta categoria per UI (es. POR -> PORTIERI).
  static String categoryLabel(String? cat) {
    if (cat == null || cat.isEmpty) return '—';
    switch (cat.toUpperCase()) {
      case 'POR': return 'PORTIERI';
      case 'DIF': return 'DIFENSORI';
      case 'CEN': return 'CENTROCAMPISTI';
      case 'ATT': return 'ATTACCANTI';
      default: return cat;
    }
  }

  /// Progresso testo categoria corrente (es. "2/3 portieri completati").
  String get categoryProgressText {
    if (currentCategory == null || categoryProgress == null || categoryProgress!.isEmpty) return '';
    final required = ROLE_LIMITS[currentCategory!] ?? 8;
    int completed = 0;
    for (final p in categoryProgress!.values) {
      if (p.completed >= required) completed++;
    }
    final total = categoryProgress!.length;
    final label = AuctionStatusModel.categoryLabel(currentCategory);
    return '$completed/$total $label completati';
  }

  /// Progresso breve: "2/3".
  String get categoryProgressShort {
    if (currentCategory == null || categoryProgress == null || categoryProgress!.isEmpty) return '';
    final required = ROLE_LIMITS[currentCategory!] ?? 8;
    int completed = 0;
    for (final p in categoryProgress!.values) {
      if (p.completed >= required) completed++;
    }
    return '$completed/${categoryProgress!.length}';
  }
}

const ROLE_LIMITS = {'POR': 3, 'DIF': 8, 'CEN': 8, 'ATT': 6};

class AuctionStatusPlayer {
  final int id;
  final String name;
  final String role;
  final String? team;
  final String? photoUrl;
  final String? cutoutUrl;
  final double basePrice;

  const AuctionStatusPlayer({
    required this.id,
    required this.name,
    required this.role,
    this.team,
    this.photoUrl,
    this.cutoutUrl,
    required this.basePrice,
  });

  factory AuctionStatusPlayer.fromJson(Map<String, dynamic> json) => AuctionStatusPlayer(
        id: num.tryParse(json['id']?.toString() ?? '')?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? 'CEN',
        team: json['team'] as String?,
        photoUrl: json['photo_url'] as String?,
        cutoutUrl: json['cutout_url'] as String?,
        basePrice: num.tryParse(json['base_price']?.toString() ?? '')?.toDouble() ?? 1,
      );
}

class AuctionStatusBid {
  final double amount;
  final String bidder;
  final String bidderId;

  const AuctionStatusBid({required this.amount, required this.bidder, required this.bidderId});

  factory AuctionStatusBid.fromJson(Map<String, dynamic> json) => AuctionStatusBid(
        amount: num.tryParse(json['amount']?.toString() ?? '')?.toDouble() ?? 0,
        bidder: json['bidder'] as String? ?? '',
        bidderId: json['bidder_id']?.toString() ?? '',
      );
}

class AuctionStatusParticipant {
  final String id;
  final String name;
  final double budget;
  final int rosterCount;
  final bool canBid;
  final int currentRoleCompleted;
  final int currentRoleRequired;

  const AuctionStatusParticipant({
    required this.id,
    required this.name,
    required this.budget,
    required this.rosterCount,
    required this.canBid,
    this.currentRoleCompleted = 0,
    this.currentRoleRequired = 0,
  });

  factory AuctionStatusParticipant.fromJson(Map<String, dynamic> json) => AuctionStatusParticipant(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        budget: num.tryParse(json['budget']?.toString() ?? '')?.toDouble() ?? 0,
        rosterCount: num.tryParse(json['roster_count']?.toString() ?? '')?.toInt() ?? 0,
        canBid: json['can_bid'] as bool? ?? false,
        currentRoleCompleted: num.tryParse(json['current_role_completed']?.toString() ?? '')?.toInt() ?? 0,
        currentRoleRequired: num.tryParse(json['current_role_required']?.toString() ?? '')?.toInt() ?? 0,
      );

  /// Testo progresso categoria corrente: "POR: 2/3" o "✅ POR: 3/3".
  String roleProgressText(String categoryCode) {
    if (currentRoleRequired == 0) return '';
    final done = currentRoleCompleted >= currentRoleRequired;
    final prefix = done ? '✅ ' : '';
    return '$prefix$categoryCode: $currentRoleCompleted/$currentRoleRequired';
  }
}

/// Stato asta corrente (backend GET /current - compat).
class AuctionCurrentModel {
  final int playerId;
  final String playerName;
  final String position;
  final String? realTeamName;
  final double highestBid;
  final String? highestBidderTeamName;
  final DateTime? endsAt;
  final int secondsRemaining;
  final int? roundNumber;

  const AuctionCurrentModel({
    required this.playerId,
    required this.playerName,
    required this.position,
    this.realTeamName,
    required this.highestBid,
    this.highestBidderTeamName,
    this.endsAt,
    required this.secondsRemaining,
    this.roundNumber,
  });

  factory AuctionCurrentModel.fromJson(Map<String, dynamic> json) {
    DateTime? endsAt;
    if (json['ends_at'] != null) {
      endsAt = DateTime.tryParse(json['ends_at'].toString());
    }
    return AuctionCurrentModel(
      playerId: num.tryParse(json['player_id']?.toString() ?? '')?.toInt() ?? 0,
      playerName: json['player_name'] as String? ?? '',
      position: json['position'] as String? ?? 'CEN',
      realTeamName: json['real_team_name'] as String?,
      highestBid: num.tryParse(json['highest_bid']?.toString() ?? '')?.toDouble() ?? 0,
      highestBidderTeamName: json['highest_bidder_team_name'] as String?,
      endsAt: endsAt,
      secondsRemaining: num.tryParse(json['seconds_remaining']?.toString() ?? '')?.toInt() ?? 0,
      roundNumber: num.tryParse(json['round_number']?.toString() ?? '')?.toInt(),
    );
  }
}

/// Voce storico asta (backend AuctionHistoryItem).
class AuctionHistoryItemModel {
  final int playerId;
  final String playerName;
  final String position;
  final String teamName;
  final double amount;
  final DateTime? purchasedAt;

  const AuctionHistoryItemModel({
    required this.playerId,
    required this.playerName,
    required this.position,
    required this.teamName,
    required this.amount,
    this.purchasedAt,
  });

  factory AuctionHistoryItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? at;
    if (json['purchased_at'] != null) at = DateTime.tryParse(json['purchased_at'].toString());
    return AuctionHistoryItemModel(
      playerId: num.tryParse(json['player_id']?.toString() ?? '')?.toInt() ?? 0,
      playerName: json['player_name'] as String? ?? '',
      position: json['position'] as String? ?? 'CEN',
      teamName: json['team_name'] as String? ?? '',
      amount: num.tryParse(json['amount']?.toString() ?? '')?.toDouble() ?? 0,
      purchasedAt: at,
    );
  }
}

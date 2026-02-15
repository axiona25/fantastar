import 'auth_service.dart';
import '../models/player_list_item.dart';

/// Servizio API mercato: svincolati, acquisto, rilascio, scambi. svincolati, acquisto, rilascio, scambi.
class MarketService {
  MarketService(this.auth);

  final AuthService auth;

  String _base(String leagueId) => '/leagues/$leagueId/market';

  /// Filtri: role (POR, DIF, CEN, ATT), teamId (real_team_id), search (nome).
  Future<PlayerListPaginatedResult> getFreeAgents(
    String leagueId, {
    String? role,
    int? teamId,
    String? search,
    int page = 1,
    int pageSize = 30,
  }) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (role != null && role.isNotEmpty) query['role'] = role;
    if (teamId != null && teamId > 0) query['team_id'] = teamId;
    if (search != null && search.isNotEmpty) query['search'] = search;
    final response = await auth.dio.get('${_base(leagueId)}/free-agents', queryParameters: query);
    final data = response.data as Map<String, dynamic>;
    final list = (data['players'] as List<dynamic>?) ?? [];
    return PlayerListPaginatedResult(
      players: list.map((e) => PlayerListItemModel.fromJson(e as Map<String, dynamic>)).toList(),
      total: (data['total'] as num?)?.toInt() ?? 0,
      page: (data['page'] as num?)?.toInt() ?? 1,
      pageSize: (data['page_size'] as num?)?.toInt() ?? 30,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<Map<String, dynamic>>> getMarketTeams(String leagueId) async {
    final response = await auth.dio.get('${_base(leagueId)}/teams');
    final list = response.data as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Acquista svincolato. [price] in crediti (default quotazione dal backend).
  Future<void> buy(String leagueId, int playerId, {double? price}) async {
    final data = <String, dynamic>{'player_id': playerId};
    if (price != null) data['price'] = price;
    await auth.dio.post('${_base(leagueId)}/buy', data: data);
  }

  Future<void> release(String leagueId, int playerId) async {
    await auth.dio.post('${_base(leagueId)}/release', data: {'player_id': playerId});
  }

  Future<void> tradePropose(String leagueId, String toTeamId, List<int> offerPlayerIds, List<int> requestPlayerIds) async {
    await auth.dio.post('${_base(leagueId)}/trade-propose', data: {
      'to_team_id': toTeamId,
      'offer_player_ids': offerPlayerIds,
      'request_player_ids': requestPlayerIds,
    });
  }

  Future<Map<String, dynamic>> getTrades(String leagueId) async {
    final response = await auth.dio.get('${_base(leagueId)}/trades');
    return response.data as Map<String, dynamic>;
  }

  Future<void> tradeRespond(String leagueId, int tradeId, bool accept) async {
    await auth.dio.post('${_base(leagueId)}/trade-respond', data: {'trade_id': tradeId, 'accept': accept});
  }
}

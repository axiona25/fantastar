import 'auth_service.dart';
import '../models/player_detail.dart';
import '../models/player_list_item.dart';

/// Servizio API giocatori: listone e scheda dettaglio.
class PlayerService {
  PlayerService(this.auth);

  final AuthService auth;

  Future<PlayerListPaginatedResult> getPlayers({
    String? leagueId,
    String? position,
    String? search,
    String sortBy = 'name',
    String sortOrder = 'asc',
    int page = 1,
    int pageSize = 30,
  }) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize, 'sort_by': sortBy, 'sort_order': sortOrder};
    if (position != null && position.isNotEmpty) query['position'] = position;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (leagueId != null && leagueId.isNotEmpty) query['league_id'] = leagueId;
    final response = await auth.dio.get('/players', queryParameters: query);
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

  Future<PlayerDetailModel?> getPlayerDetail(int playerId) async {
    try {
      final response = await auth.dio.get('/players/$playerId');
      return PlayerDetailModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

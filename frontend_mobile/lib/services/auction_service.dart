import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import '../models/auction.dart';
import '../app/constants.dart';

/// Servizio API asta: status, current (compat), bid, nominate, start session, expire, pause, stop, history.
///
/// **Autenticazione**: TUTTE le chiamate usano [auth.dio] (stesso client con interceptor JWT
/// che invia `Authorization: Bearer {token}`). Non viene mai creata un'istanza Dio separata.
/// Pattern identico a [MarketService] e [LeagueService].
class AuctionService {
  AuctionService(this.auth);

  final AuthService auth;

  String _leagueBase(String leagueId) => '/leagues/$leagueId/auction';

  /// GET status: stato completo (timer, current_player, current_bid, participants).
  Future<AuctionStatusModel> getStatus(String leagueId) async {
    final url = '${_leagueBase(leagueId)}/status';
    debugPrint('AUCTION SERVICE: GET $url');
    final response = await auth.dio.get(url);
    debugPrint('AUCTION SERVICE response: ${response.statusCode}');
    debugPrint('AUCTION SERVICE data: ${response.data}');
    return AuctionStatusModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET current (compat): ritorna null se nessuna asta.
  Future<AuctionCurrentModel?> getCurrent(String leagueId) async {
    try {
      final response = await auth.dio.get('${_leagueBase(leagueId)}/current');
      final data = response.data as Map<String, dynamic>;
      if (data['active'] == false || data['player_id'] == null) return null;
      return AuctionCurrentModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> placeBid(String leagueId, double amount) async {
    await auth.dio.post(
      '${_leagueBase(leagueId)}/bid',
      data: {'amount': amount},
    );
  }

  Future<List<AuctionHistoryItemModel>> getHistory(String leagueId) async {
    final response = await auth.dio.get('${_leagueBase(leagueId)}/history');
    final items = (response.data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
    return items.map((e) => AuctionHistoryItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Avvia sessione asta (solo admin). POST /start senza body.
  Future<void> startSession(String leagueId) async {
    await auth.dio.post(_leagueBase(leagueId) + '/start');
  }

  /// Admin nomina il giocatore all'asta. POST /nominate.
  Future<void> nominate(String leagueId, int playerId) async {
    await auth.dio.post(
      '${_leagueBase(leagueId)}/nominate',
      data: {'player_id': playerId},
    );
  }

  /// Forza scadenza e assegna (solo admin). POST /expire.
  Future<void> assignCurrent(String leagueId) async {
    await auth.dio.post('${_leagueBase(leagueId)}/expire');
  }

  Future<void> pauseSession(String leagueId) async {
    await auth.dio.post('${_leagueBase(leagueId)}/pause');
  }

  Future<void> stopSession(String leagueId) async {
    await auth.dio.post('${_leagueBase(leagueId)}/stop');
  }

  String auctionWsUrl(String leagueId) => '$kWsBaseUrl/ws/auction/$leagueId';
}

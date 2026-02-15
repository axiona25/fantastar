import 'auth_service.dart';
import '../models/top_scorer.dart';
import '../models/standing_row.dart';

/// Servizio API statistiche: classifica Serie A, top marcatori, top assist, ecc.
class StatsService {
  StatsService(this.auth);

  final AuthService auth;

  /// GET /stats/standings — classifica Serie A reale.
  Future<List<StandingRow>> getStandings() async {
    final response = await auth.dio.get('/stats/standings');
    final list = response.data is List ? response.data as List : [];
    return list.map((e) => StandingRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TopScorerModel>> getTopScorers({int limit = 20, String? position}) async {
    final query = <String, dynamic>{'limit': limit};
    if (position != null && position.isNotEmpty) query['position'] = position;
    final response = await auth.dio.get('/stats/top-scorers', queryParameters: query);
    final list = response.data is List ? response.data as List : [];
    return list.map((e) => TopScorerModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> getTopAssists({int limit = 20, String? position}) async {
    final query = <String, dynamic>{'limit': limit};
    if (position != null && position.isNotEmpty) query['position'] = position;
    final response = await auth.dio.get('/stats/top-assists', queryParameters: query);
    final list = response.data is List ? response.data as List : [];
    return list.cast<Map<String, dynamic>>();
  }
}

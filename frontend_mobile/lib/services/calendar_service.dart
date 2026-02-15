import 'auth_service.dart';
import '../models/calendar_match.dart';

class CalendarService {
  CalendarService(this.auth);

  final AuthService auth;

  Future<List<CalendarMatchModel>> getCalendar(String leagueId) async {
    final response = await auth.dio.get('/leagues/$leagueId/calendar');
    final list = response.data is List ? response.data as List : [];
    return list.map((e) => CalendarMatchModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

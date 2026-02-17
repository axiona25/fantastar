/// URL base API backend. Tutti gli endpoint sono sotto /api/v1/ tranne league-badges.
/// - News: GET ${baseUrl}/news  → http://localhost:8000/api/v1/news
/// - Classifica: GET ${baseUrl}/standings/serie-a  → http://localhost:8000/api/v1/standings/serie-a
/// - League badges: GET $kBackendOrigin/api/league-badges  (senza /v1/)
/// - iOS Simulator: http://localhost:8000/api/v1
/// - Android Emulator: http://10.0.2.2:8000/api/v1 (10.0.2.2 = host machine)
const String kApiBaseUrl = 'http://localhost:8000/api/v1';

/// Origine backend (host:port) per URL statici e per /api/league-badges (senza /v1/).
String get kBackendOrigin => Uri.parse(kApiBaseUrl).origin;

/// URL avatar 3D Disney per giocatore. Sempre: static/media/avatars/{player_id}.png
/// Usare ovunque nell'app si mostri un giocatore (listone, asta, rosa, dettaglio, etc.).
String getPlayerAvatarUrl(int playerId) {
  return '$kBackendOrigin/static/media/avatars/$playerId.png';
}

/// Restituisce l'URL assoluto per la foto del giocatore.
/// - null/vuoto → null (usare fallback iniziali).
/// - inizia con 'http' → URL remoto TheSportsDB, usa così com'è.
/// - inizia con '/static/' → foto locale → [HOST:8000] + photo_url.
String? resolvePlayerPhotoUrl(String? photoUrl) {
  if (photoUrl == null || photoUrl.isEmpty) return null;
  if (photoUrl.startsWith('http')) return photoUrl;
  return '$kBackendOrigin$photoUrl';
}

/// Base URL WebSocket (stesso host, path /ws/...).
String get kWsBaseUrl {
  final u = Uri.parse(kApiBaseUrl);
  return '${u.scheme == 'https' ? 'wss' : 'ws'}://${u.host}${u.port != 80 && u.port != 443 ? ':${u.port}' : ''}';
}

/// Chiavi SharedPreferences per token e user.
const String kKeyAccessToken = 'access_token';
const String kKeyRefreshToken = 'refresh_token';
const String kKeyUserId = 'user_id';

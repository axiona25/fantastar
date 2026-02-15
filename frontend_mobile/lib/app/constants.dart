/// URL base API backend (cambia per emulatore: 10.0.2.2:8000 su Android, localhost su iOS sim).
const String kApiBaseUrl = 'http://localhost:8000/api/v1';

/// Origine backend per URL statici (foto giocatori: /static/photos/...).
String get kBackendOrigin => Uri.parse(kApiBaseUrl).origin;

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

# TASK 10 — Report Flutter: Setup & Navigation

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Creare la struttura dell'app Flutter con navigazione, tema placeholder, modelli e servizi API. Tutto **funzionante** (routing, API client, WebSocket, modelli, logica) con **UI minima e placeholder**; tema Material default, nessun design definitivo né colori custom (da applicare in un secondo momento).

---

## 2. Dipendenze

- Task 05 (Auth API: register, login, /me, refresh)

---

## 3. Cosa è stato fatto

### 3.1 Progetto e dipendenze

- **Progetto:** `frontend_mobile` (flutter create --org com.fantastar).
- **pubspec.yaml:** provider, dio, shared_preferences, web_socket_channel, go_router, intl. Nessuna dipendenza UI avanzata (cached_network_image, shimmer, fl_chart, freezed) per mantenere setup minimo; aggiungibili nei task successivi.

### 3.2 Struttura cartelle

```
frontend_mobile/lib/
├── main.dart
├── app/
│   ├── routes.dart          # GoRouter config (redirect login/home)
│   ├── theme.dart           # Tema Material placeholder
│   └── constants.dart       # Base URL API, chiavi storage
├── models/
│   ├── user.dart            # UserModel (allineato UserResponse)
│   ├── token.dart            # TokenModel (access/refresh)
│   ├── player.dart
│   ├── real_team.dart
│   ├── match.dart
│   ├── fantasy_league.dart
│   ├── fantasy_team.dart
│   ├── lineup.dart
│   └── news.dart
├── services/
│   ├── api_client.dart       # Dio + JWT interceptor, 401 → onUnauthorized
│   ├── auth_service.dart    # login, register, getMe, refresh, logout
│   ├── websocket_service.dart # Connessione WS generica, send/receive JSON
│   ├── league_service.dart  # Placeholder
│   ├── player_service.dart  # Placeholder
│   └── match_service.dart   # Placeholder
├── providers/
│   └── auth_provider.dart   # Stato user, login/register/logout, errori
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   └── home/
│       ├── home_screen.dart       # Bottom nav 5 tab
│       └── tabs/
│           ├── home_tab.dart      # Benvenuto + nome utente
│           ├── live_tab.dart      # Placeholder
│           ├── team_tab.dart      # Placeholder
│           ├── standings_tab.dart # Placeholder
│           └── news_tab.dart      # Placeholder
```

### 3.3 Tema

- **app/theme.dart:** `ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue))` — Material default, nessun colore FANTASTAR custom.

### 3.4 Costanti

- **kApiBaseUrl:** `http://localhost:8000/api/v1` (per emulatore Android usare `http://10.0.2.2:8000/api/v1`).
- **kKeyAccessToken, kKeyRefreshToken, kKeyUserId** per SharedPreferences.

### 3.5 API Client (Dio + JWT)

- **createApiClient(AuthService):** BaseOptions con baseUrl, timeout, header JSON.
- **Interceptor onRequest:** aggiunge `Authorization: Bearer <access_token>` se presente.
- **Interceptor onError (401):** tenta refresh token; se fallisce chiama `authService.onUnauthorized?.call()` per logout e redirect a login.

### 3.6 Auth service

- Login POST `/auth/login`, Register POST `/auth/register`, Get `/auth/me`, Refresh POST `/auth/refresh`.
- Persistenza token in SharedPreferences; `clearTokens` su logout.
- Callback `onUnauthorized` usato da AuthProvider per notificare e far reindirizzare GoRouter.

### 3.7 WebSocket service

- **WebSocketService:** `connect(url)`, `send(Map)`, `disconnect()`, callback `onMessage`, `onDone`, `onError`.
- Decodifica JSON in entrata; base per ws/auction, ws/live, ws/match (task successivi).

### 3.8 Auth provider

- **ChangeNotifier:** user, isLoggedIn, loading, error.
- **login(email, password)** / **register(email, username, password):** chiamano AuthService, aggiornano user, ritornano true/false; errore backend (DioException.detail) esposto in `error`.
- **logout:** clear tokens e user, notifyListeners.
- **refreshListenable** per GoRouter: al cambio stato auth il router riesegue redirect.

### 3.9 GoRouter

- **Redirect:** non loggato e route non auth → `/login`; loggato su `/login` o `/register` → `/home`.
- **Route:** `/login`, `/register`, `/home`.
- Router creato in main con `createRouter(authProvider)`; stesso `authProvider` passato a `MultiProvider` e a `GoRouter(refreshListenable: auth)`.

### 3.10 Schermate

- **Login:** campi email/password, pulsante Accedi, link Registrati; messaggio errore da backend; loading durante richiesta.
- **Register:** email, username, password, pulsante Registrati, link Torna al login; stesso trattamento errori/loading.
- **Home:** AppBar con titolo (nome tab) e pulsante Logout; **NavigationBar** a 5 tab: Home, Live, Squadra, Classifica, News. Contenuto tab: Home mostra “Benvenuto, {displayName}”; gli altri testo placeholder.

---

## 4. File creati/modificati

| File | Azione |
|------|--------|
| `frontend_mobile/pubspec.yaml` | Modificato (dipendenze) |
| `frontend_mobile/lib/main.dart` | Sostituito (Provider + GoRouter + MaterialApp.router) |
| `frontend_mobile/lib/app/constants.dart` | Creato |
| `frontend_mobile/lib/app/theme.dart` | Creato |
| `frontend_mobile/lib/app/routes.dart` | Creato |
| `frontend_mobile/lib/models/*.dart` | Creati (user, token, player, real_team, match, fantasy_league, fantasy_team, lineup, news) |
| `frontend_mobile/lib/services/api_client.dart` | Creato |
| `frontend_mobile/lib/services/auth_service.dart` | Creato |
| `frontend_mobile/lib/services/websocket_service.dart` | Creato |
| `frontend_mobile/lib/services/league_service.dart` | Creato (placeholder) |
| `frontend_mobile/lib/services/player_service.dart` | Creato (placeholder) |
| `frontend_mobile/lib/services/match_service.dart` | Creato (placeholder) |
| `frontend_mobile/lib/providers/auth_provider.dart` | Creato |
| `frontend_mobile/lib/screens/auth/login_screen.dart` | Creato |
| `frontend_mobile/lib/screens/auth/register_screen.dart` | Creato |
| `frontend_mobile/lib/screens/home/home_screen.dart` | Creato |
| `frontend_mobile/lib/screens/home/tabs/*.dart` | Creati (5 tab) |
| `reports/TASK_10_REPORT.md` | Creato |

---

## 5. Verifica

- **L'app si avvia** senza errori (`flutter run`).
- **Login/Register** funzionano con il backend: inserire email/password (e username per register), invio; in caso di successo redirect a Home; in caso di errore viene mostrato il messaggio `detail` della risposta (es. "Incorrect email or password").
- **Navigazione:** dai 5 tab si passa tra Home, Live, Squadra, Classifica, News; Logout riporta al Login e il redirect di GoRouter impedisce di tornare a `/home` senza login.

**Nota:** Con backend in locale, su emulatore Android usare `kApiBaseUrl = 'http://10.0.2.2:8000/api/v1'` (o variabile d’ambiente / config per ambiente).

---

## 6. Note

- UI volutamente **minima**: TextField standard, FilledButton, NavigationBar, testo placeholder; nessun design grafico, nessuna immagine.
- Modelli con `fromJson` manuale (no freezed/json_serializable in questo task).
- Widget riutilizzabili (player_card, match_card, ecc.) e schermate league/team/auction/lineup/live/standings/player/news saranno introdotti nei task 11–14.

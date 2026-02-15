# TASK FLUTTER-COMPLETE — Report Completamento Schermate Flutter

**Data completamento:** 14 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo

Completare le schermate Flutter mancanti e collegare le API backend in modo che l’app sia utilizzabile end-to-end (login → leghe → squadra → asta/mercato → formazione → live/classifiche/news). UI minima e placeholder, nessun design definitivo.

---

## 2. Dipendenze

- Backend API (Task 05–09, 16, 17)
- Flutter (SDK ^3.10.7), go_router, provider, dio, shared_preferences, web_socket_channel

---

## 3. Cosa è stato implementato

### PARTE 1: Gestione leghe

- **Le mie leghe** (`/leagues`): lista leghe (GET /leagues), card con nome, team count, invite_code; FAB con “Crea lega” e “Unisciti con codice”; tap → `/league/{id}`.
- **Crea lega** (`/leagues/create`): form nome, max squadre (4–20), budget; POST /leagues; dopo creazione → dettaglio lega.
- **Unisciti a lega** (`/leagues/join`): campo codice 8 caratteri; lookup GET /leagues/lookup?invite_code=; POST /leagues/{id}/join; dopo join → dettaglio lega.
- **Dettaglio lega** (`/league/{id}`): nome, invite_code con pulsante copia, squadre/max, budget; lista squadre (da standings); pulsante “Crea la mia squadra” se assente; menu: Classifica, Asta, Mercato, Risultati, Calendario, Invita amici (share_plus); se admin: “Genera calendario” (POST generate-calendar).
- **Crea squadra** (`/league/{id}/create-team`): form nome; POST /teams; dopo creazione → dettaglio lega.
- **Condividi invito**: Share.share con testo e invite_code (share_plus).
- **Backend**: aggiunto GET /leagues/lookup?invite_code= per risolvere la lega dal codice; GET /leagues/{id}/calendar (CalendarMatchRow); schema CalendarMatchRow.

### PARTE 2: Asta

- Nessuna modifica strutturale: schermata asta esistente lasciata com’è (budget, countdown, storico come miglioramenti futuri).

### PARTE 3: Mercato

- Nessuna modifica: tab Svincolati/Rilascia/Scambi già presenti; proposta scambio completa e lista scambi come miglioramenti futuri.

### PARTE 4: Listone e scheda giocatore

- **Listone** (`/players`): schermata standalone con GET /players (paginazione), filtri ruolo e ricerca, tap → `/player/{id}`. Route `/players` aggiunta.
- Scheda giocatore esistente: nessun arricchimento (disponibilità, preferiti, voto AI come miglioramenti futuri).

### PARTE 5: Notifiche in-app

- **NotificationProvider**: lista notifiche, unreadCount, addNotification, markAsRead, markAllRead.
- **Modello** `AppNotificationModel`: id, title, message, type, timestamp, isRead.
- **Notifiche** (`/notifications`): lista notifiche, “Segna tutte lette”, icona impostazioni → `/settings/notifications`.
- **Impostazioni notifiche** (`/settings/notifications`): toggle per tipo (asta, scambio, partita, promemoria) salvati in SharedPreferences.
- **Badge**: in AppBar della Home, icona campanella con badge conteggio non lette → `/notifications`.

### PARTE 6: Calendario lega

- **Calendario** (`/league/{id}/calendar`): GET /leagues/{id}/calendar; lista per giornata con “Casa – Trasferta”; UI minima.
- **CalendarService**: getCalendar(leagueId).
- **Modello** `CalendarMatchModel`: matchday, homeTeamName, awayTeamName.

### PARTE 7: Navigazione e tab

- **Home tab**: card “Le mie leghe” → `/leagues`; card “La mia squadra” → dettaglio lega o `/leagues`; “Listone” → `/players`; “Ultime news” con prime 3 da GET /news; link Asta/Mercato se c’è una lega.
- **News tab**: GET /news e GET /news/sources; filtri per fonte (chip); tap articolo → url_launcher.
- **Team tab**: invariato (rosa, link Formazione/Mercato/Asta).
- **Live / Classifica**: invariati (collegamenti già presenti dove previsti).

### PARTE 8: Servizi

- **NewsService**: getNews({ source, limit }), getSources().
- **CalendarService**: getCalendar(leagueId).
- **LeagueService**: getLeague, lookupByInviteCode, createLeague, joinLeague, generateCalendar, getLeagueTeamsAsStandings (alias getStandings).
- **TeamService**: createTeam(leagueId, name).

---

## 4. Route aggiunte/modificate

| Route | Schermata |
|-------|-----------|
| `/leagues` | LeaguesScreen |
| `/leagues/create` | CreateLeagueScreen |
| `/leagues/join` | JoinLeagueScreen |
| `/league/:leagueId` | LeagueDetailScreen |
| `/league/:leagueId/create-team` | CreateTeamScreen |
| `/league/:leagueId/standings` | LeagueStandingsScreen |
| `/league/:leagueId/calendar` | LeagueCalendarScreen |
| `/players` | PlayersListStandaloneScreen |
| `/notifications` | NotificationsScreen |
| `/settings/notifications` | NotificationSettingsScreen |

---

## 5. File creati/modificati (principali)

### Nuovi file

- `lib/screens/leagues/leagues_screen.dart`
- `lib/screens/leagues/create_league_screen.dart`
- `lib/screens/leagues/join_league_screen.dart`
- `lib/screens/leagues/league_detail_screen.dart`
- `lib/screens/leagues/create_team_screen.dart`
- `lib/screens/leagues/league_standings_screen.dart`
- `lib/screens/leagues/league_calendar_screen.dart`
- `lib/screens/players/players_list_standalone_screen.dart`
- `lib/screens/notifications/notifications_screen.dart`
- `lib/screens/notifications/notification_settings_screen.dart`
- `lib/providers/notification_provider.dart`
- `lib/models/notification.dart`
- `lib/models/calendar_match.dart`
- `lib/services/news_service.dart`
- `lib/services/calendar_service.dart`

### Modificati

- `lib/app/routes.dart` — tutte le nuove route
- `lib/main.dart` — CalendarService, NewsService, NotificationProvider
- `lib/models/fantasy_league.dart` — inviteCode, teamCount
- `lib/models/news.dart` — source, imageUrl
- `lib/services/league_service.dart` — getLeague, lookupByInviteCode, createLeague, joinLeague, generateCalendar
- `lib/services/team_service.dart` — createTeam
- `lib/screens/home/home_screen.dart` — icona notifiche con badge
- `lib/screens/home/tabs/home_tab.dart` — card Le mie leghe, La mia squadra, Listone, Ultime news (API)
- `lib/screens/home/tabs/news_tab.dart` — GET /news, filtri fonte, url_launcher
- `pubspec.yaml` — share_plus, url_launcher

### Backend

- `backend/app/api/v1/leagues.py` — GET /leagues/lookup, GET /leagues/{id}/calendar; FantasyCalendar, CalendarMatchRow
- `backend/app/schemas/league.py` — CalendarMatchRow

---

## 6. Flusso end-to-end verificabile

1. Login/Register → Home.
2. “Le mie leghe” → nessuna lega → “Crea lega” → compilazione → dettaglio con invite_code.
3. “Invita amici” → share codice.
4. “Crea la mia squadra” → nome → dettaglio lega con squadra in lista.
5. Asta → schermata asta (admin può avviare).
6. Listone → `/players` → filtri → tap giocatore → scheda.
7. Tab Squadra → rosa → “Imposta formazione” → lineup.
8. Tab Live / Classifica / News → dati da API dove previsto.
9. Notifiche → lista in-app; impostazioni → toggle salvati.
10. Mercato → svincolati/rilascia/scambi (UI esistente).

---

## 7. Note

- **UI minima**: layout essenziale, nessun design definitivo; countdown asta, storico, proposta scambio completa, disponibilità/preferiti giocatore sono lasciati come estensioni future.
- **Join lega**: il backend richiede league_id; è stato aggiunto GET /leagues/lookup?invite_code= per ottenere la lega dal codice e poi chiamare POST join.
- **Notifiche**: solo in-app (locale); push e integrazione WebSocket per eventi asta/partita non implementate in questo task.
- **Calendario**: backend GET /leagues/{id}/calendar restituisce le partite fantasy (fantasy_calendar); nessun dato “giornata corrente” da API (evidenziazione possibile in seguito).

---

**Fine report TASK FLUTTER-COMPLETE**

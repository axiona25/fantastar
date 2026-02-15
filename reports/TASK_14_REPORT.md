# TASK 14 — Report Flutter: Live Match

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Schermata **partita live** con punteggi e aggiornamenti in tempo reale: **Live Overview** (lista partite in corso con score, minuto, indicatore LIVE), **Dettaglio partita** (score, timeline eventi, WebSocket), **Fantasy Matchday Live** (punteggi giornata in tempo reale via WS live_scores). UI minima e placeholder, nessun design definitivo.

---

## 2. Dipendenze

- Task 09 (WebSocket live/match), Task 10 (Setup Flutter, auth, servizi)
- Backend: WebSocket `ws/live/{league_id}` (live_scores), `ws/match/{match_id}` (match_update); REST partite aggiunto in questo task.

---

## 3. Cosa è stato fatto

### 3.1 Backend (API partite)

- **GET /api/v1/matches** (`backend/app/api/v1/matches.py`): lista partite con nomi squadre; query `status` (es. IN_PLAY), `matchday` opzionali. Join con RealTeam (alias HomeTeam, AwayTeam) per home_team_name e away_team_name.
- **GET /api/v1/matches/{match_id}**: dettaglio partita con eventi (event_type, minute da MatchEvent). Schema in `backend/app/schemas/match_schema.py`: MatchListItem, MatchEventItem, MatchDetailResponse.
- Router registrato in `main.py`.

### 3.2 Modelli Flutter

- **MatchModel** (`lib/models/match.dart`): esteso con matchday, homeTeamName, awayTeamName; usato per lista live.
- **MatchEventModel**: type, minute; fromJson per eventi da REST/WS.
- **MatchDetailModel**: id, matchday, squadre, score, minute, status, events; fromJson per dettaglio e per messaggio WS match_update.
- **LiveScoreMatchResult**: homeTeamId, awayTeamId, homeScore, awayScore, homeGoals, awayGoals, homeResult, awayResult; fromJson per payload live_scores.

### 3.3 Servizi Flutter

- **MatchService** (`lib/services/match_service.dart`):  
  `getLiveMatches()` → GET `/matches?status=IN_PLAY`;  
  `getMatchDetail(matchId)` → GET `/matches/{id}`;  
  **liveWsUrl(leagueId)** e **matchWsUrl(matchId)** (URL WebSocket da kWsBaseUrl).  
- Registrato in `main.dart`.

### 3.4 Live Overview

- **LiveOverviewScreen** (`lib/screens/live/live_overview_screen.dart`): carica partite con `MatchService.getLiveMatches()`, pull-to-refresh; lista card con home–away, score, minuto; **indicatore LIVE** (badge “LIVE” che pulsa in rosso); tap → `context.push('/live/match/${m.id}')`.

### 3.5 Dettaglio partita live

- **MatchDetailScreen** (`lib/screens/live/match_detail_screen.dart`), route **/live/match/:id**:  
  Carica dettaglio con `getMatchDetail(matchId)`; si connette a **WebSocket** `ws/match/{match_id}` e su messaggio `match_update` aggiorna score, minute, events.  
  UI: score grande (squadre e risultato), minuto; **timeline eventi** (icona ⚽ gol, 🟨🟥 cartellini, 🔄 sostituzione + tipo e minuto); placeholder “Formazioni”.

### 3.6 Fantasy Matchday Live

- **FantasyMatchdayLiveScreen** (`lib/screens/live/fantasy_matchday_live_screen.dart`): si connette a **WebSocket** `ws/live/{league_id}`; su messaggio **live_scores** mostra gli `updates` (matchday + results con punteggi e gol fantasy). Placeholder per “La mia formazione con punteggio in tempo reale”.

### 3.7 Tab Live e route

- **LiveTab** (`lib/screens/home/tabs/live_tab.dart`): **TabBar** a 2 tab: (1) **Partite** → `LiveOverviewScreen`; (2) **La mia giornata** → `FantasyMatchdayLiveScreen(leagueId)` se c’è una lega, altrimenti messaggio “Partecipa a una lega”.
- **Route** `/live/match/:id` → `MatchDetailScreen(matchId)`.

---

## 4. File creati/modificati

| File | Azione |
|------|--------|
| `backend/app/schemas/match_schema.py` | Creato |
| `backend/app/api/v1/matches.py` | Creato |
| `backend/app/main.py` | Modificato (router matches) |
| `frontend_mobile/lib/models/match.dart` | Modificato (MatchModel, MatchEventModel, MatchDetailModel, LiveScoreMatchResult) |
| `frontend_mobile/lib/services/match_service.dart` | Implementato (getLiveMatches, getMatchDetail, liveWsUrl, matchWsUrl) |
| `frontend_mobile/lib/main.dart` | Modificato (MatchService) |
| `frontend_mobile/lib/screens/live/live_overview_screen.dart` | Creato |
| `frontend_mobile/lib/screens/live/match_detail_screen.dart` | Creato |
| `frontend_mobile/lib/screens/live/fantasy_matchday_live_screen.dart` | Creato |
| `frontend_mobile/lib/screens/home/tabs/live_tab.dart` | Sostituito (Tab Partite / La mia giornata) |
| `frontend_mobile/lib/app/routes.dart` | Modificato (/live/match/:id) |
| `reports/TASK_14_REPORT.md` | Creato |

---

## 5. Verifica

- **Tab Live → Partite:** lista partite in corso (o “Nessuna partita in corso” se GET /matches?status=IN_PLAY restituisce vuoto); badge LIVE pulsante sulle partite IN_PLAY; tap apre dettaglio.
- **Dettaglio partita:** score e eventi da REST; aggiornamenti in tempo reale via WS quando il backend invia match_update (es. durante sync_live_matches).
- **Tab Live → La mia giornata:** con lega selezionata, connessione a ws/live/{league_id}; alla ricezione di live_scores compaiono i risultati giornata (punteggi e gol fantasy).
- Eseguire `flutter analyze` (nessun errore); eventualmente `flutter build apk --debug`.

---

## 6. Note

- **Stemmi squadre** in Live Overview: non implementati (solo testo nomi); placeholder per design successivo.
- **Formazioni** in Dettaglio partita: testo placeholder; integrazione con dati formazione richiederebbe endpoint o logica dedicata.
- **Punteggio fantasy per singolo giocatore** in “La mia giornata”: non implementato; live_scores fornisce solo risultati incontri (coppie di squadre e punteggi). Una “formazione con punteggio in tempo reale” per giocatore richiederebbe un’API o un calcolo lato client con dati da WS.
- **Riconnessione WebSocket** in caso di disconnessione: non implementata automaticamente; l’utente può riaprire la schermata.
- **Notifica push** (suono/vibrazione) quando un mio giocatore segna/prende cartellino: non implementata.
- **VS avversario fantasy** in La mia giornata: i risultati mostrati sono gli incontri della giornata (home_score, away_score, home_goals, away_goals); il “mio” avversario andrebbe individuato tramite calendario lega e messo in evidenza in un passo successivo.

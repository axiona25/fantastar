# TASK 14B — Report: Risultati e Pagelle

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo

Implementare **Risultati** (risultati giornata fantasy per lega) e **Pagelle** (voti giocatori per partita). Prima backend (endpoint), poi schermate Flutter. UI minima e placeholder.

*Nota: il file TASK_14B_RISULTATI_PAGELLE.md non era presente nel workspace; l’implementazione segue un’interpretazione coerente (risultati giornata + pagelle partita).*

---

## 2. Backend

### 2.1 Risultati giornata

- **GET /api/v1/leagues/{league_id}/matchday/{matchday}/results**
  - **Auth:** richiesta (get_current_user).
  - **Risposta:** lista di oggetti (MatchdayResultRow) con: home_team_id, away_team_id, home_team_name, away_team_name, home_score, away_score, home_goals, away_goals, home_result, away_result.
  - **Logica:** uso di `ScoringEngine.calculate_matchday_results(league_id, matchday)`; per ogni risultato risoluzione dei nomi squadra con `FantasyTeam.name` (query su home_team_id e away_team_id).
  - **Schema:** `MatchdayResultRow` in `app/schemas/league.py`.

### 2.2 Pagelle partita

- **GET /api/v1/matches/{match_id}/ratings**
  - **Auth:** non richiesta (endpoint pubblico).
  - **Risposta:** lista di oggetti (PlayerRatingRow) con: player_id, player_name, rating, trend, mentions, minute.
  - **Logica:** lettura da `PlayerAIRating` con join su `Player` per il nome; per ogni giocatore viene restituita solo l’ultima riga (ordinamento per player_id, minute desc). Lista ordinata per rating decrescente.
  - **Schema:** `PlayerRatingRow` in `app/schemas/match_schema.py`.

---

## 3. Flutter

### 3.1 Modelli

- **MatchdayResultModel** (`lib/models/matchday_result.dart`): campi come da API (homeTeamId, awayTeamId, nomi, score, goals, homeResult, awayResult); `fromJson`.
- **PlayerRatingModel** (`lib/models/player_rating.dart`): playerId, playerName, rating, trend, mentions, minute; `fromJson`.

### 3.2 Servizi

- **LeagueService:** `getMatchdayResults(leagueId, matchday)` → GET `/leagues/{id}/matchday/{md}/results` → `List<MatchdayResultModel>`.
- **MatchService:** `getMatchRatings(matchId)` → GET `/matches/{id}/ratings` → `List<PlayerRatingModel>`.

### 3.3 Schermata Risultati

- **RisultatiScreen** (`lib/screens/risultati/risultati_screen.dart`), route **/league/:leagueId/risultati**:
  - Parametro: leagueId.
  - Dropdown **Giornata** (1–38); al cambio si chiama `getMatchdayResults(leagueId, matchday)`.
  - Lista card: per ogni risultato mostra “Squadra Casa – Squadra Trasferta”, punteggio (homeScore - awayScore), gol (homeGoals-awayGoals), esito (homeResult-awayResult). UI minima, nessun design definitivo.

### 3.4 Schermata Pagelle

- **PagelleScreen** (`lib/screens/risultati/pagelle_screen.dart`), route **/match/:matchId/pagelle**:
  - Parametro: matchId.
  - Caricamento con `getMatchRatings(matchId)`.
  - Lista: per ogni rating, icona trend (↑/↓/→), nome giocatore, menzioni e minuto, voto; tap → push a `/player/{playerId}`.

### 3.5 Route e ingressi

- **Route:**  
  `/league/:leagueId/risultati` → RisultatiScreen(leagueId).  
  `/match/:matchId/pagelle` → PagelleScreen(matchId).
- **Ingressi:**  
  - **Tab Classifica:** voce “Risultati giornata” → push a `/league/{firstLeague.id}/risultati` (se c’è una lega, altrimenti SnackBar “Partecipa a una lega”).  
  - **Dettaglio partita (MatchDetailScreen):** pulsante “Pagelle” in AppBar → push a `/match/{matchId}/pagelle`.

---

## 4. File creati/modificati

| File | Azione |
|------|--------|
| `backend/app/schemas/league.py` | Modificato (MatchdayResultRow) |
| `backend/app/schemas/match_schema.py` | Modificato (PlayerRatingRow) |
| `backend/app/api/v1/leagues.py` | Modificato (GET matchday results) |
| `backend/app/api/v1/matches.py` | Modificato (GET match ratings) |
| `frontend_mobile/lib/models/matchday_result.dart` | Creato |
| `frontend_mobile/lib/models/player_rating.dart` | Creato |
| `frontend_mobile/lib/services/league_service.dart` | Modificato (getMatchdayResults) |
| `frontend_mobile/lib/services/match_service.dart` | Modificato (getMatchRatings, import player_rating) |
| `frontend_mobile/lib/screens/risultati/risultati_screen.dart` | Creato |
| `frontend_mobile/lib/screens/risultati/pagelle_screen.dart` | Creato |
| `frontend_mobile/lib/screens/home/tabs/standings_tab.dart` | Modificato (voce Risultati) |
| `frontend_mobile/lib/screens/live/match_detail_screen.dart` | Modificato (pulsante Pagelle) |
| `frontend_mobile/lib/app/routes.dart` | Modificato (risultati, pagelle) |
| `reports/TASK_14B_REPORT.md` | Creato |

---

## 5. Verifica

- **Risultati:** dalla Classifica, “Risultati giornata” (con lega) apre Risultati; scelta giornata 1–38 mostra l’elenco risultati (o “Nessun risultato” se calendario vuoto per quella giornata).
- **Pagelle:** da una partita (Live → Partite → dettaglio partita), pulsante “Pagelle” apre Pagelle; lista voti da `player_ai_ratings` (vuota se non c’è nessun rating per quella partita). Tap su giocatore apre scheda giocatore.
- **Backend:** GET `/leagues/{uuid}/matchday/1/results` (con token) e GET `/matches/1/ratings` ritornano rispettivamente lista risultati e lista pagelle.

---

## 6. Note

- Le pagelle dipendono dai dati in **player_ai_ratings** (Task AI-Ratings: sync cronache e keyword). Senza partite live o senza sync non ci sono voti.
- Risultati giornata sono calcolati al volo con **ScoringEngine.calculate_matchday_results** (nessuna persistenza in fantasy_scores richiesta per questo endpoint).
- UI volutamente minima (liste, card, dropdown, pulsanti); design definitivo non previsto in questo task.

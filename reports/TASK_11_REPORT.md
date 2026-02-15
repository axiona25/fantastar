# TASK 11 — Report Flutter: Home & Classifiche

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Dashboard home con card (prossima giornata, la mia squadra, classifica fantasy top 3, ultime news, partite live) e schermate classifiche: Classifica Serie A (placeholder), Classifica Fantasy (API), Classifica Marcatori (API con filtro ruolo). UI minima e placeholder, nessun design definitivo.

---

## 2. Dipendenze

- Task 10 (Setup Flutter, auth, navigazione, servizi base)

---

## 3. Cosa è stato fatto

### 3.1 Modelli

- **StandingModel** (`lib/models/standing.dart`): rank, fantasy_team_id, team_name, user_id, total_points, wins, draws, losses, goals_for, goals_against; `fromJson` allineato a backend StandingRow.
- **TopScorerModel** (`lib/models/top_scorer.dart`): player_id, name, position, team_name, goals; per `/stats/top-scorers`.
- **FantasyLeagueModel**: esteso con max_teams e budget (da LeagueResponse).

### 3.2 Servizi

- **LeagueService** (`lib/services/league_service.dart`):
  - `getLeagues()` → GET `/leagues`
  - `getStandings(leagueId)` → GET `/leagues/{id}/standings`
- **StatsService** (`lib/services/stats_service.dart`):
  - `getTopScorers(limit, position)` → GET `/stats/top-scorers`
  - `getTopAssists(limit, position)` → GET `/stats/top-assists` (disponibile per uso futuro)

### 3.3 Provider

- **HomeProvider** (`lib/providers/home_provider.dart`): carica leghe e classifica della prima lega; espone `leagues`, `standings`, `topThree`, `myStandingFor(userId)`, `firstLeague`; `load()` richiamabile da Home tab e pull-to-refresh.

### 3.4 Home Screen (tab Home)

- **Header:** “Benvenuto, {displayName}”.
- **Card “Prossima giornata”:** placeholder (testo “Giornata 15 — Inizio tra X giorni”).
- **Card “La mia squadra”:** punteggio dalla classifica fantasy (prima lega, riga con user_id = utente corrente); messaggio se nessuna lega/squadra.
- **Card “Classifica fantasy (top 3)”:** prime 3 righe della classifica della prima lega (rank, nome, punti, W/D/L).
- **Card “Ultime news”:** placeholder (testo; API news non esposta dal backend).
- **Card “Partite live”:** placeholder (nessuna partita in corso).
- Pull-to-refresh su tutta la colonna; caricamento iniziale in `initState` tramite `HomeProvider.load()`.

### 3.5 Tab Classifica

- Tre voci di lista:
  1. **Classifica Serie A** → `context.push('/standings/serie-a')`
  2. **Classifica Fantasy** → `context.push('/standings/fantasy')`
  3. **Classifica Marcatori** → `context.push('/standings/scorers')`

### 3.6 Classifica Serie A

- **SerieAStandingsScreen** (`lib/screens/standings/serie_a_standings_screen.dart`): schermata placeholder; testo che spiega che i dati (lista 20 squadre con posizione, stemma, punti, W/D/L) andranno integrati con API esterna/Redis (backend al momento non espone endpoint).

### 3.7 Classifica Fantasy

- **FantasyStandingsScreen** (`lib/screens/standings/fantasy_standings_screen.dart`):
  - Dropdown per scelta lega (da `HomeProvider.leagues`).
  - Lista classifiche da `LeagueService.getStandings(selectedLeagueId)`; pull-to-refresh.
  - Per ogni riga: posizione, nome squadra, punti, W/D/L, gol fatti/subiti.
  - **Evidenziazione “la mia squadra”:** riga con `userId == currentUser.id` con `Card` colorata (`surfaceContainerHighest`).
  - Caricamento iniziale leghe con `HomeProvider.load()`; caricamento classifica per lega selezionata.

### 3.8 Classifica Marcatori

- **TopScorersScreen** (`lib/screens/standings/top_scorers_screen.dart`):
  - GET `/stats/top-scorers` con `limit: 20` e `position` opzionale.
  - **Filtro per ruolo:** dropdown (Tutti, POR, DIF, CEN, ATT); al cambio si rilancia la richiesta.
  - Lista: posizione, nome, squadra, ruolo, gol; pull-to-refresh.

### 3.9 Route

- In `app/routes.dart` aggiunte:
  - `/standings/serie-a` → `SerieAStandingsScreen`
  - `/standings/fantasy` → `FantasyStandingsScreen`
  - `/standings/scorers` → `TopScorersScreen`

### 3.10 Main / Provider

- In `main.dart` registrati `LeagueService`, `StatsService` e `ChangeNotifierProvider<HomeProvider>` (costruiti a partire da `AuthProvider` e `LeagueService`).

---

## 4. File creati/modificati

| File | Azione |
|------|--------|
| `lib/models/standing.dart` | Creato |
| `lib/models/top_scorer.dart` | Creato |
| `lib/models/fantasy_league.dart` | Modificato (max_teams, budget) |
| `lib/services/league_service.dart` | Implementato (getLeagues, getStandings) |
| `lib/services/stats_service.dart` | Creato |
| `lib/providers/home_provider.dart` | Creato |
| `lib/main.dart` | Modificato (provider League, Stats, Home) |
| `lib/screens/home/tabs/home_tab.dart` | Sostituito (card + refresh) |
| `lib/screens/home/tabs/standings_tab.dart` | Sostituito (3 link alle classifiche) |
| `lib/screens/standings/serie_a_standings_screen.dart` | Creato |
| `lib/screens/standings/fantasy_standings_screen.dart` | Creato |
| `lib/screens/standings/top_scorers_screen.dart` | Creato |
| `lib/app/routes.dart` | Modificato (3 route standings) |
| `reports/TASK_11_REPORT.md` | Creato |

---

## 5. Verifica

- **Home:** avvio app, login, tab Home: si vedono card con dati da API (leghe/classifica) dove disponibili; pull-to-refresh aggiorna.
- **Classifica Fantasy:** dal tab Classifica → “Classifica Fantasy” → dropdown leghe, lista con punti e differenza gol; la propria squadra evidenziata; refresh funzionante.
- **Classifica Marcatori:** tab Classifica → “Classifica Marcatori” → lista top scorers; cambio ruolo nel dropdown filtra; refresh aggiorna.
- **Classifica Serie A:** tab Classifica → “Classifica Serie A” → schermata placeholder con testo esplicativo.

---

## 6. Note

- **Serie A:** il backend non espone un endpoint per la classifica reale (dati in Redis da sync); la UI è pronta per un eventuale GET `/standings/serie-a` o simile.
- **News e partite live:** card in Home lasciate in placeholder in attesa di endpoint o integrazione con dati esistenti.
- **Prossima giornata:** countdown e numero giornata sono placeholder; si potranno collegare a un endpoint “next matchday” o a dati calendario.

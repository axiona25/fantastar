# TASK 12 — Report Flutter: Gestione Squadra

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Schermate per gestire la rosa e impostare la formazione: **La mia rosa** (lista giocatori per ruolo, tap → scheda giocatore), **Scheda giocatore** (info, statistiche stagione, punteggi fantasy), **Imposta formazione** (modulo, titolari, panchina, conferma). UI minima e placeholder, nessun design definitivo.

---

## 2. Dipendenze

- Task 10 (Setup Flutter, auth, servizi)
- Backend: GET/POST `/teams/{id}`, GET/POST `/teams/{id}/lineup/{matchday}`, GET `/players/{id}`

---

## 3. Cosa è stato fatto

### 3.1 Modelli

- **TeamDetailModel** e **RosterPlayerModel** (`lib/models/team_detail.dart`): id, name, leagueId, budgetRemaining, totalPoints, wins/draws/losses, goalsFor/Against, roster (lista RosterPlayerModel con playerId, playerName, position, purchasePrice); `fromJson` allineato a TeamDetailResponse e RosterPlayerResponse.
- **LineupSlotModel**, **LineupResponseModel** (`lib/models/lineup.dart`): slot (player_id, position_slot, is_starter, bench_order), risposta GET lineup (fantasy_team_id, matchday, formation, starters, bench); **kValidFormations**: 3-4-3, 3-5-2, 4-3-3, 4-4-2, 4-5-1, 5-3-2, 5-4-1.
- **PlayerDetailModel**, **PlayerSeasonStatsModel**, **PlayerFantasyScoreModel** (`lib/models/player_detail.dart`): scheda giocatore (id, name, position, real_team_name, initial_price, season_stats, fantasy_scores); `fromJson` da PlayerDetailResponse.

### 3.2 Servizi

- **TeamService** (`lib/services/team_service.dart`):
  - `getTeam(teamId)` → GET `/teams/{id}`
  - `getLineup(teamId, matchday)` → GET `/teams/{id}/lineup/{matchday}`
  - `setLineup(teamId, matchday, formation, slots)` → POST `/teams/{id}/lineup/{matchday}` (body: formation, slots)
- **PlayerService** (`lib/services/player_service.dart`): `getPlayerDetail(playerId)` → GET `/players/{id}`.

### 3.3 Tab Squadra (La mia rosa)

- **Team tab** (`lib/screens/home/tabs/team_tab.dart`):
  - Ottiene l’id della “mia” squadra dalla prima lega: `HomeProvider.myStandingFor(userId)?.fantasyTeamId`.
  - Carica il dettaglio squadra con `TeamService.getTeam(teamId)`; pull-to-refresh.
  - Mostra nome squadra, budget, punti e **rosa raggruppata per ruolo** (POR, DIF, CEN, ATT); per ogni giocatore: nome, prezzo acquisto; tap → `context.push('/player/${playerId}')`.
  - Voce **“Imposta formazione”** → `context.push('/team/${teamId}/lineup')`.
  - Messaggi placeholder se nessuna lega, nessuna squadra o errore di caricamento.

### 3.4 Scheda giocatore

- **PlayerDetailScreen** (`lib/screens/player/player_detail_screen.dart`):
  - Route `/player/:id`; carica dati con `PlayerService.getPlayerDetail(playerId)` (FutureBuilder).
  - UI minima: nome, ruolo, squadra reale, quotazione; **Statistiche stagione** (presenze, gol, assist, minuti da season_stats); **Punteggi fantasy** (elenco giornata + punteggio + eventi, max 10).
  - Nessuna foto/stemma (placeholder per design successivo).

### 3.5 Imposta formazione

- **SetLineupScreen** (`lib/screens/team/set_lineup_screen.dart`), route `/team/:teamId/lineup`:
  - **Giornata:** dropdown 1–38; al cambio si ricarica team e lineup.
  - **Modulo:** dropdown (3-4-3, 3-5-2, 4-3-3, 4-4-2, 4-5-1, 5-3-2, 5-4-1).
  - **Titolari:** per ogni slot (POR, DIF1..n, CEN1..n, ATT1..n in base al modulo) un dropdown con i giocatori della rosa di quel ruolo; selezione titolari aggiorna la lista panchina (giocatori non titolari).
  - **Panchina:** elenco lettura (ordine = ordine subentri); non implementato drag & drop (solo testo “ordine subentri”).
  - **Conferma formazione:** costruisce `slots` (11 titolari con position_slot e is_starter=true, panchina con B1, B2, … e bench_order) e chiama `TeamService.setLineup`; messaggio di successo e pop.
  - All’apertura: GET team e GET lineup per la giornata selezionata; se esiste una formazione salvata, si precompilano modulo, titolari e panchina.

### 3.6 Route

- **`/player/:id`** → `PlayerDetailScreen(playerId: int)`.
- **`/team/:teamId/lineup`** → `SetLineupScreen(teamId: string)`.

### 3.7 Provider / main

- In `main.dart` registrati **TeamService** e **PlayerService** (creati da `AuthProvider.authService`).

---

## 4. File creati/modificati

| File | Azione |
|------|--------|
| `lib/models/team_detail.dart` | Creato |
| `lib/models/lineup.dart` | Creato |
| `lib/models/player_detail.dart` | Creato |
| `lib/services/team_service.dart` | Creato |
| `lib/services/player_service.dart` | Implementato (getPlayerDetail) |
| `lib/main.dart` | Modificato (TeamService, PlayerService) |
| `lib/screens/home/tabs/team_tab.dart` | Sostituito (rosa per ruolo, link giocatore e formazione) |
| `lib/screens/player/player_detail_screen.dart` | Creato |
| `lib/screens/team/set_lineup_screen.dart` | Creato |
| `lib/app/routes.dart` | Modificato (/player/:id, /team/:teamId/lineup) |
| `reports/TASK_12_REPORT.md` | Creato |

---

## 5. Verifica

- **Tab Squadra:** con utente in lega e squadra, si vede la rosa per ruolo; tap su un giocatore apre la scheda; “Imposta formazione” apre la schermata formazione.
- **Scheda giocatore:** mostra dati da GET `/players/{id}` (nome, ruolo, squadra, stats, punteggi fantasy).
- **Imposta formazione:** scelta giornata e modulo, assegnazione titolari per slot, conferma salva con POST lineup e torna indietro; validazione backend (11 titolari, 1 POR, DIF/CEN/ATT coerenti con modulo).

---

## 6. Note

- **Deadline formazione:** non implementata (1 ora prima della prima partita); da integrare con dati calendario/partite.
- **Campo da calcio visuale e drag & drop:** non implementati; UI minima con dropdown per titolari e lista panchina.
- **Ordine panchina:** attualmente derivato automaticamente (rosa meno titolari); riordino manuale (es. drag) da aggiungere in seguito.
- **Warnings disponibilità:** il backend può restituire warnings (squalifiche, infortuni) in risposta al POST lineup; la UI può essere estesa per mostrarli (es. SnackBar o dialog).

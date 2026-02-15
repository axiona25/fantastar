# TASK 07 — Report Scoring Engine

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Creare il motore di calcolo punteggi fantasy event-based: punteggio giocatore (eventi + statistiche avanzate), punteggio squadra con sostituzioni panchina, conversione in gol fantasy, risultati giornata e classifica.

---

## 2. Cosa è stato fatto

### 2.1 File principale: `backend/app/services/scoring_engine.py`

- **BASE_SCORING**: punteggi per tipo evento (match_events)
  - GOAL per ruolo (POR 5, DIF 5, CEN 4, ATT 3), OWN_GOAL -2, PENALTY_SCORED 3, PENALTY_MISSED -3
  - YELLOW_CARD -0.5, RED_CARD -1, SECOND_YELLOW -1, ASSIST 1, PENALTY_SAVED 3 (solo POR)
  - CLEAN_SHEET (POR/DIF 1), GOAL_CONCEDED (POR -1 per gol subito), APPEARANCE 1
- **ADVANCED_SCORING**: bonus da player_stats (BZZoiro)
  - xg_wasted -0.5, xa_wasted -0.25, key_passes_3plus 0.5, tackles_5plus 0.5 (DIF/CEN)
  - pass_accuracy_90plus 0.5 (min 30 pass), high_rating 1.0 (rating ≥ 8.0)

### 2.2 Funzione pura gol fantasy

- **calculate_fantasy_goals(total_score, threshold=66, step=8) -> int**
  - `total_score < threshold` → 0 gol
  - altrimenti `1 + int((total_score - threshold) / step)`

### 2.3 Classe ScoringEngine(db: AsyncSession)

- **calculate_player_score(player_id, match_id) -> PlayerScoreResult | None**
  - Carica Player (ruolo), Match, MatchEvent (player_id o assist_player_id), PlayerStats
  - Base: somma punteggi eventi (GOAL/ASSIST/cartellini/PENALTY_SAVED ecc.), CLEAN_SHEET/GOAL_CONCEDED da risultato partita (solo se FINISHED), APPEARANCE se ha minuti o eventi
  - Avanzato: da PlayerStats (xG/xA wasted, key_passes ≥3, tackles ≥5, pass accuracy ≥90%, rating ≥8)
  - Ritorna dataclass con base_score, advanced_score, total_score, events_json, minutes_played, played

- **calculate_team_score(fantasy_team_id, matchday, league_id=None, threshold=66, step=8) -> TeamScoreResult | None**
  - Legge formazione (FantasyLineup) per team + matchday: titolari + panchina ordinata per bench_order
  - Per ogni titolare: match della giornata per la sua squadra reale → calculate_player_score
  - **Sostituzione panchina**: se il titolare non ha giocato (played=False), sostituisce con il primo panchinaro dello stesso ruolo (bench_order) non ancora usato
  - Somma i 11 punteggi, applica calculate_fantasy_goals
  - Se league_id fornito: da FantasyCalendar ricava avversario, ricalcola punteggio avversario e imposta opponent_score, opponent_goals, result (W/D/L), points_earned (3/1/0)

- **calculate_matchday_results(league_id, matchday) -> list[MatchResult]**
  - Legge FantasyCalendar per (league_id, matchday); per ogni coppia (home, away) calcola team_score di entrambe
  - Usa goal_threshold e goal_step della lega (FantasyLeague)
  - Ritorna lista di MatchResult (home_team_id, away_team_id, home_score, away_score, home_goals, away_goals, home_result, away_result)

- **recalculate_standings(league_id) -> list[StandingRow]**
  - Aggrega da FantasyScore (per ogni squadra: somma points_earned, conteggio W/D/L, goals_for, goals_against)
  - Ordina per punti, differenza reti, gol fatti
  - Ritorna lista StandingRow (fantasy_team_id, team_name, rank, points, wins, draws, losses, goals_for, goals_against)

### 2.4 Dataclass di ritorno

- **PlayerScoreResult**: player_id, match_id, matchday, base_score, advanced_score, total_score, is_starter, was_subbed_in, events_json, minutes_played, played
- **TeamScoreResult**: fantasy_team_id, matchday, total_score, fantasy_goals, player_scores, opponent_id, opponent_score, opponent_goals, result, points_earned, detail_json
- **MatchResult**: home_team_id, away_team_id, home_score, away_score, home_goals, away_goals, home_result, away_result
- **StandingRow**: fantasy_team_id, team_name, rank, points, wins, draws, losses, goals_for, goals_against

### 2.5 Logica Clean sheet / Goal conceded

- CLEAN_SHEET e GOAL_CONCEDED non sono eventi in DB: derivati da Match (status=FINISHED, home_score, away_score) e da Player.real_team_id. Gol subiti = away_score se la squadra del giocatore è in casa, altrimenti home_score. Clean sheet = 0 gol subiti; bonus solo per POR/DIF che hanno giocato (minuti o eventi).

---

## 3. Dipendenze da task precedenti

- **Task 02**: modelli Match, MatchEvent, Player, PlayerStats, FantasyTeam, FantasyLineup, FantasyRoster, FantasyScore, FantasyPlayerScore, FantasyCalendar, FantasyLeague
- **Task 04**: dati partite/eventi/stats sincronizzati (per punteggi reali)

---

## 4. File creati/modificati

| File | Azione |
|------|--------|
| `backend/app/services/scoring_engine.py` | Creato |
| `backend/tests/test_scoring_engine.py` | Creato |
| `reports/TASK_07_REPORT.md` | Creato |

---

## 5. Verifica

I test coprono:

- **calculate_fantasy_goals**: sotto soglia (0 gol), soglia e step (66→1, 74→2, …), parametri custom, input Decimal
- **BASE_SCORING / ADVANCED_SCORING**: presenza chiavi e valori attesi (GOAL per ruolo, high_rating)
- **ScoringEngine**: calculate_player_score con id inesistenti → None; calculate_team_score con team inesistente → None; calculate_matchday_results (lista, eventualmente vuota); recalculate_standings lega inesistente → [], lega esistente → list[StandingRow]

Eseguire i test (da backend con venv/Docker dove sono installate le dipendenze, es. asyncpg):

```bash
cd backend
pytest tests/test_scoring_engine.py -v
```

In Docker:

```bash
docker-compose exec backend pytest tests/test_scoring_engine.py -v
```

---

## 6. Utilizzo tipico

1. **Dopo una giornata**: per ogni (league_id, matchday) chiamare `calculate_matchday_results(league_id, matchday)`; per ogni MatchResult persistire in FantasyScore (fantasy_team_id, matchday, total_score, fantasy_goals, opponent_id, opponent_score, opponent_goals, result, points_earned).
2. **Classifica**: `recalculate_standings(league_id)` legge da FantasyScore e ritorna la classifica; opzionalmente aggiornare FantasyTeam (total_points, wins, draws, losses, goals_for, goals_against).
3. **Punteggio singola squadra**: `calculate_team_score(fantasy_team_id, matchday, league_id)` per avere anche avversario e risultato; utile per visualizzazione o per popolare FantasyScore.

---

## 7. Note

- La **sostituzione panchina** usa il primo panchinaro dello **stesso ruolo** (POR/DIF/CEN/ATT) in ordine di `bench_order`; se non c’è nessuno disponibile dello stesso ruolo, lo slot mantiene punteggio 0 (titolare non giocato e nessun sub).
- **recalculate_standings** si basa sui dati già presenti in FantasyScore; un job di chiusura giornata deve aver precedentemente calcolato e salvato i punteggi (es. tramite calculate_matchday_results + scrittura FantasyScore).
- Soglia e step per i gol fantasy sono configurabili per lega (FantasyLeague.goal_threshold, goal_step) e usati in calculate_team_score e calculate_matchday_results quando si usa la lega.

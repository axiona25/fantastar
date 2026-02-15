# TASK 09 — Report Live WebSocket

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

WebSocket per aggiornamenti in tempo reale: partite live, punteggi fantasy, asta. I client si connettono ai canali **live** (punteggi lega) e **match** (eventi partita) e ricevono broadcast quando lo scheduler aggiorna le partite in corso (polling Football-Data.org ogni 60s).

---

## 2. Dipendenze

- **Task 07** (Scoring Engine): ricalcolo punteggi fantasy per giornata.
- **Task 04** (Sync + Scheduler): `sync_live_matches()`, partite IN_PLAY, eventi in `match_events`.

---

## 3. Cosa è stato fatto

### 3.1 Canali WebSocket (`app/api/websocket.py`)

| Canale | URL | Descrizione |
|--------|-----|-------------|
| **Asta** | `ws://localhost:8000/ws/auction/{league_id}` | Offerte e assegnazioni asta (già presente). |
| **Live** | `ws://localhost:8000/ws/live/{league_id}` | Aggiornamenti punteggi fantasy in tempo reale per la lega. |
| **Match** | `ws://localhost:8000/ws/match/{match_id}` | Eventi partita (gol, cartellini) e score in tempo reale. |

- **ConnectionManager**: tre istanze (`auction_connection_manager`, `live_connection_manager`, `match_connection_manager`) con canali `auction:{league_id}`, `live:{league_id}`, `match:{match_id}`.
- **broadcast_live_update(league_id, payload)** e **broadcast_match_update(match_id, payload)** usate dal task di sync live.

### 3.2 Flusso Live Match (spec TASK 04 / 09)

1. **Scheduler** (ogni 5 min) verifica se ci sono partite IN_PLAY; se sì, attiva job ogni 60s.
2. **sync_live_matches()** (ogni 60s durante partite live):
   - Chiama Football-Data.org per partite IN_PLAY.
   - Aggiorna `matches` (score, minute, status) e scarica eventi con `_save_match_events`.
   - Salva in Redis `live:matches` (TTL 30s).
   - **Dopo commit**: chiama `_broadcast_live_updates(session, updated_ext_ids)`.
3. **_broadcast_live_updates** (in `app/tasks/sync_matches.py`):
   - Per ogni partita aggiornata: invia a **ws/match/{match_id}** un messaggio `match_update` (match_id, matchday, home_score, away_score, minute, status, events).
   - Trova le leghe che hanno quella giornata in calendario (`fantasy_calendar`).
   - Per ogni lega: ricalcola i risultati della giornata con **ScoringEngine.calculate_matchday_results(league_id, matchday)** e invia a **ws/live/{league_id}** un messaggio `live_scores` con `updates` (lista di matchday + results).

### 3.3 Formato messaggi WebSocket

**match_update** (canale `match:{match_id}`):

```json
{
  "type": "match_update",
  "match_id": 123,
  "matchday": 15,
  "home_score": 1,
  "away_score": 0,
  "minute": 67,
  "status": "IN_PLAY",
  "events": [
    { "type": "GOAL", "minute": 23 },
    { "type": "YELLOW_CARD", "minute": 45 }
  ]
}
```

**live_scores** (canale `live:{league_id}`):

```json
{
  "type": "live_scores",
  "updates": [
    {
      "matchday": 15,
      "results": [
        {
          "home_team_id": "uuid-1",
          "away_team_id": "uuid-2",
          "home_score": 72.5,
          "away_score": 68.0,
          "home_goals": 1,
          "away_goals": 1,
          "home_result": "D",
          "away_result": "D"
        }
      ]
    }
  ]
}
```

- I client connessi a **ws/live/{league_id}** possono aggiornare la UI (risultati giornata, eventuale classifica) senza ricaricare.
- I client connessi a **ws/match/{match_id}** vedono score e eventi (gol, cartellini) in tempo reale.

### 3.4 Endpoint WebSocket

- **ws/live/{league_id}**: accetta connessione solo se la lega esiste; risponde a `{"type": "ping"}` con `{"type": "pong"}`.
- **ws/match/{match_id}**: accetta connessione solo se la partita esiste; stesso comportamento ping/pong.

---

## 4. File creati/modificati

| File | Azione |
|------|--------|
| `backend/app/api/websocket.py` | Modificato: live_channel, match_channel, live_connection_manager, match_connection_manager, broadcast_live_update, broadcast_match_update, ws/live/{league_id}, ws/match/{match_id} |
| `backend/app/tasks/sync_matches.py` | Modificato: raccolta updated_ext_ids in sync_live_matches; nuova _broadcast_live_updates (broadcast match + live_scores dopo commit); import FantasyCalendar |
| `reports/TASK_09_REPORT.md` | Creato |

---

## 5. Come testare

1. Avviare backend e scheduler (partite live abilitate quando Football-Data.org restituisce IN_PLAY).

2. **Canale partita**
   - Connettersi a `ws://localhost:8000/ws/match/{match_id}` (es. match_id = 1).
   - Durante una partita live, ogni 60s (se ci sono aggiornamenti) arriva un messaggio `match_update` con score, minute, events.

3. **Canale live lega**
   - Connettersi a `ws://localhost:8000/ws/live/{league_id}`.
   - Quando una partita della giornata viene aggiornata, arriva `live_scores` con i risultati ricalcolati della giornata per quella lega.

4. **Ping**
   - Inviare `{"type": "ping"}` su qualsiasi canale per ricevere `{"type": "pong"}`.

---

## 6. Note

- Il ricalcolo punteggi usa **ScoringEngine.calculate_matchday_results** (solo in memoria per il broadcast); non viene aggiornata la tabella `fantasy_scores` in questa fase (eventuale persistenza può essere fatta a fine giornata da job separato).
- Le leghe che ricevono `live_scores` sono quelle con almeno una riga in `fantasy_calendar` per la giornata delle partite aggiornate.
- In produzione si può aggiungere autenticazione (query `?token=JWT`) per ws/live e ws/match.

# TASK AI-RATINGS — Report: Voti Dinamici da Cronaca Live (keyword locale)

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo

Sistema che analizza cronache testuali live (minuto per minuto) e genera un voto dinamico per ogni giocatore menzionato. Implementate **solo Parti 1–6**, con **keyword locale** (nessuna API LLM/AI). UI minima e placeholder.

---

## 2. Parti implementate

| Parte | Descrizione |
|-------|-------------|
| 1 | Provider cronache testuali |
| 2 | LocalRatingService con keyword matching |
| 3 | Tabella player_ai_ratings + migrazione |
| 4 | Integrazione con scoring engine (bonus/malus da rating) |
| 5 | Task sync cronache ogni 2 min durante partite live |
| 6 | WebSocket player_ratings_update + UI Flutter |

---

## 3. Cosa è stato fatto

### 3.1 Parte 1: Provider cronache testuali

- **`backend/app/data_providers/live_commentary.py`**
  - **LiveCommentaryProvider**: `fetch_commentary(match_external_id, source)` → lista di `{minute, text, source, fetched_at}`; `fetch_all_sources(match_external_id)` → unione da più fonti con deduplica (minuto + testo).
  - **SOURCES**: football_italia, tuttomercatoweb (url_template e language).
  - In caso di errore HTTP o parsing vuoto viene usata **mock** `_mock_entries()` (nessuno scraping reale per rispetto ToS e UI minima). Parsing HTML reale lasciato vuoto in `_parse_commentary_html`.

### 3.2 Parte 2: LocalRatingService

- **`backend/app/services/local_rating_service.py`**
  - Dizionari **POSITIVE_KEYWORDS**, **NEGATIVE_KEYWORDS**, **GOAL_ACTIONS** (EN/IT) con impatto sul voto.
  - **LocalRatingService**: `analyze_entry(entry, known_players)` aggiorna punteggio cumulativo per giocatore menzionato; `_player_mentioned(text, player_name)` (match su parti nome >3 caratteri); `_calculate_impact(text)` somma impatti keyword; `get_all_ratings()` → lista `{player_name, rating, mentions, trend, last_action}` ordinata per rating.
  - Voto base 6.0, clamp 3.0–10.0.

### 3.3 Parte 3: Tabella player_ai_ratings + migrazione

- **`backend/app/models/player_ai_rating.py`**
  - **PlayerAIRating**: id, player_id, match_id, minute, rating, trend, mentions, key_actions (JSON), source (default "local"), is_final, created_at, updated_at; FK a players e matches (ondelete CASCADE); indici su match_id e (player_id, match_id).
- **Migrazione Alembic** `f6a2b3c4d5e5_add_player_ai_ratings.py` (revises e5f1a2b3d4c4): create table player_ai_ratings e indici.

### 3.4 Parte 4: Integrazione scoring engine

- **`backend/app/services/scoring_engine.py`**
  - **AI_RATING_BONUS**: fasce (9–10: +1.5, 8–9: +1.0, 7–8: +0.5, 6–7: 0, 5.5–6: -0.25, 5–5.5: -0.5, 3–5: -1.0).
  - In **calculate_player_score**: dopo base_score e advanced_score si legge l’ultimo **PlayerAIRating** (is_final desc, minute desc) per (player_id, match_id); si applica `_ai_rating_bonus(rating)` e si somma a **total_score**.
  - **PlayerScoreResult**: aggiunto campo **ai_rating_bonus** (Decimal).

### 3.5 Parte 5: Task sync cronache ogni 2 min

- **`backend/app/tasks/sync_commentary.py`**
  - **sync_live_commentary()**: seleziona partite con status IN_PLAY; per ogni partita: `fetch_all_sources(external_id)`, ottiene giocatori match (home/away), esegue **LocalRatingService** su tutte le entry, mappa rating player_name → player_id (`_match_player_name`), inserisce **PlayerAIRating** (session.add), commit; invia **broadcast_match_update(match_id, payload)** con `type: "player_ratings_update"`, minute e ratings.
- **Scheduler** (`backend/app/tasks/scheduler.py`): quando ci sono partite live viene aggiunto job **sync_commentary** con **IntervalTrigger(minutes=2)**; quando non ci sono più partite live il job viene rimosso.

### 3.6 Parte 6: WebSocket + UI Flutter

- **WebSocket**: il messaggio **player_ratings_update** è inviato sullo stesso canale **ws/match/{match_id}** già usato per match_update (stesso `broadcast_match_update`). Payload: type, match_id, minute, ratings (player_name, rating, trend, last_action).
- **Flutter** `lib/screens/live/match_detail_screen.dart`:
  - Stato `_liveRatings` (lista mappe), `_liveRatingsMinute`.
  - In **onMessage** se `type == 'player_ratings_update'` si aggiornano stato e minuto.
  - Sezione **"Voti Live (XX')"**: per ogni rating riga con icona trend (↑/↓/→), nome, last_action (sottotitolo), voto; sotto "Aggiornato ogni 2 min". UI minima/placeholder.

---

## 4. File creati/modificati

| File | Azione |
|------|--------|
| `backend/app/data_providers/live_commentary.py` | Creato |
| `backend/app/services/local_rating_service.py` | Creato |
| `backend/app/models/player_ai_rating.py` | Creato |
| `backend/app/models/__init__.py` | Modificato (import PlayerAIRating) |
| `backend/alembic/versions/f6a2b3c4d5e5_add_player_ai_ratings.py` | Creato |
| `backend/app/services/scoring_engine.py` | Modificato (AI_RATING_BONUS, query PlayerAIRating, ai_rating_bonus in PlayerScoreResult) |
| `backend/app/tasks/sync_commentary.py` | Creato |
| `backend/app/tasks/scheduler.py` | Modificato (sync_commentary ogni 2 min quando live) |
| `frontend_mobile/lib/screens/live/match_detail_screen.dart` | Modificato (player_ratings_update, sezione Voti Live) |
| `reports/TASK_AI_RATINGS_REPORT.md` | Creato |

---

## 5. Verifica

- **Migrazione:** `cd backend && alembic upgrade head` crea la tabella `player_ai_ratings`.
- **Backend:** con partite IN_PLAY, ogni 2 minuti il job scarica cronache (mock se fetch fallisce), calcola voti con LocalRatingService, salva in player_ai_ratings e invia `player_ratings_update` su ws/match/{id}.
- **Scoring:** in `calculate_player_score` viene letto l’ultimo rating da player_ai_ratings e applicato il bonus/malus a total_score.
- **Flutter:** nella schermata Dettaglio partita, connessi a ws/match/{id}, alla ricezione di `player_ratings_update` compare la sezione "Voti Live" con elenco e trend.

---

## 6. Note

- **Cronache reali:** il provider è predisposto per URL e parsing; attualmente in errore o senza contenuto si usano entry mock. Lo scraping va fatto rispettando i ToS delle fonti e preferendo RSS dove disponibili.
- **Match nome → player_id:** `_match_player_name` fa match approssimativo (cognome / parti nome); possibili ambiguità con omonimi.
- **Nessuna API LLM:** non è implementata alcuna chiamata a Claude/OpenAI; solo keyword locale (Parti 1–6).
- **Voti Live in Flutter:** sezione mostrata solo dopo almeno un messaggio `player_ratings_update`; nessun suono/vibrazione su aggiornamento.

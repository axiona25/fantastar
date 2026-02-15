# TASK 08B — Report Mercato, Listone e Miglioramenti Asta

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Completare listone giocatori con quotazioni e statistiche, mercato di riparazione (svincolati, acquisto, rilascio, scambi), endpoint statistiche aggregate e miglioramento asta con countdown che si resetta a ogni rilancio.

---

## 2. Cosa è stato fatto

### 2.1 Listone e scheda giocatore

- **GET /api/v1/players** (listone):
  - Query: `position`, `team_id`, `search`, `sort_by` (name, initial_price), `sort_order`, `min_price`, `max_price`, `available_only`, `league_id`, `page`, `page_size`.
  - Risposta: **PlayerListPaginated** (players, total, page, page_size, total_pages).
  - Ogni riga: **PlayerListResponse** (id, name, position, real_team_*, photo/cutout, initial_price, current_value, season_stats, is_available, owned_by se league_id fornito).
  - **PlayerSeasonStats**: appearances, goals, assists, minutes_played, avg_rating, total_xg, total_xa, clean_sheets (aggregate da PlayerStats + Match.season).

- **GET /api/v1/players/{id}** (scheda):
  - Risposta: **PlayerDetailResponse** (eredita listone + match_stats, fantasy_scores, next_matches).
  - **PlayerMatchStat**: ultime 10 partite (matchday, opponent, date, minutes, goals, assists, rating, xg, xa, key_passes).
  - **PlayerFantasyScore**: matchday, score, events (da FantasyPlayerScore).
  - **NextMatch**: prossime partite della squadra reale (matchday, opponent_name, date, home_away).

- **Calcolo valore attuale** (`player_list_service.calculate_current_value`):
  - Formula: prezzo_base * (1 + bonus). Bonus: gol +2%, assist +1%; media rating ≥9 +25%, ≥7 +10%, <4 -15%; presenze <50% partite -10%.

- **Servizio**: `app/services/player_list_service.py` (get_players_paginated, get_player_detail, get_season_stats_for_players).

### 2.2 Mercato di riparazione

- **GET /api/v1/leagues/{id}/market/free-agents**: svincolati (available_only + league_id), paginato, filtri position/search.
- **POST /api/v1/leagues/{id}/market/buy**: body `{"player_id": int}`. Acquisto a prezzo = initial_price; controlli budget e limiti rosa (max 3 POR, 8 DIF, 8 CEN, 6 ATT, 25 totali).
- **POST /api/v1/leagues/{id}/market/release**: body `{"player_id": int}`. Rilascio con rimborso 50% di purchase_price.

- **Servizio**: `app/services/market_service.py` (get_free_agents, buy_free_agent, release_player). Limiti in **ROSTER_LIMITS** e **MAX_ROSTER_SIZE = 25**.

### 2.3 Scambi (trade)

- **TradeProposal** (`app/models/trade_proposal.py`): league_id, from_team_id, to_team_id, offer_player_ids (JSONB), request_player_ids (JSONB), status (PENDING/ACCEPTED/REJECTED).
- **POST /api/v1/leagues/{id}/market/trade-propose**: body `to_team_id`, `offer_player_ids`, `request_player_ids`. Verifica che i giocatori siano nelle rispettive rose.
- **GET /api/v1/leagues/{id}/market/trades**: lista proposte inviate e ricevute dalla mia squadra.
- **POST /api/v1/leagues/{id}/market/trade-respond**: body `trade_id`, `accept`. Solo la squadra destinataria; se accept=true si aggiornano i fantasy_team_id sulle roster (scambio effettivo).

- **Migrazione**: `e5f1a2b3d4c4_add_trade_proposals.py`.

### 2.4 Statistiche aggregate

- **GET /api/v1/stats/top-scorers**: top marcatori (parametri: limit, position, season). Aggregate da PlayerStats + Match.season.
- **GET /api/v1/stats/top-fantasy**: top per punteggio fantasy medio (limit, position, min_appearances). Da FantasyPlayerScore.
- **GET /api/v1/stats/top-assists**: top assistman (limit, position, season).
- **GET /api/v1/stats/best-value**: miglior rapporto (avg_fantasy_score / initial_price) * 100 (limit, position, min_appearances).

- **Router**: `app/api/v1/stats.py`.

### 2.5 Miglioramento asta

- **Config**: `AUCTION_RESET_SECONDS = 15`.
- **place_bid**: se il tempo rimanente è < AUCTION_RESET_SECONDS, il countdown viene portato a 15 secondi da ora; altrimenti si usa AUCTION_BID_EXTEND_SECONDS (30 s). Così ogni rilancio evita che il timer scada in pochi secondi (comportamento stile eBay).

---

## 3. Endpoint riepilogo

| Metodo | Endpoint | Descrizione |
|--------|----------|-------------|
| GET | `/api/v1/players` | Listone con filtri, paginazione, quotazioni e statistiche |
| GET | `/api/v1/players/{id}` | Scheda giocatore completa |
| GET | `/api/v1/leagues/{id}/market/free-agents` | Svincolati |
| POST | `/api/v1/leagues/{id}/market/buy` | Acquista svincolato |
| POST | `/api/v1/leagues/{id}/market/release` | Rilascia (rimborso 50%) |
| POST | `/api/v1/leagues/{id}/market/trade-propose` | Proponi scambio |
| GET | `/api/v1/leagues/{id}/market/trades` | Lista scambi inviati/ricevuti |
| POST | `/api/v1/leagues/{id}/market/trade-respond` | Accetta/rifiuta scambio |
| GET | `/api/v1/stats/top-scorers` | Top marcatori |
| GET | `/api/v1/stats/top-fantasy` | Top punteggio fantasy |
| GET | `/api/v1/stats/top-assists` | Top assistman |
| GET | `/api/v1/stats/best-value` | Miglior rapporto qualità/prezzo |

---

## 4. File creati/modificati

| File | Azione |
|------|--------|
| `backend/app/config.py` | Modificato (AUCTION_RESET_SECONDS) |
| `backend/app/schemas/player_list.py` | Creato |
| `backend/app/services/player_list_service.py` | Creato |
| `backend/app/services/market_service.py` | Creato |
| `backend/app/services/auction_service.py` | Modificato (reset countdown su bid) |
| `backend/app/models/trade_proposal.py` | Creato |
| `backend/app/models/__init__.py` | Modificato (TradeProposal) |
| `backend/alembic/versions/e5f1a2b3d4c4_add_trade_proposals.py` | Creato |
| `backend/app/api/v1/players.py` | Modificato (GET list, GET detail) |
| `backend/app/api/v1/market.py` | Creato |
| `backend/app/api/v1/stats.py` | Creato |
| `backend/app/main.py` | Modificato (include market, stats) |
| `reports/TASK_08B_REPORT.md` | Creato |

---

## 5. Come testare

```bash
# Listone
curl "http://localhost:8000/api/v1/players?position=ATT&sort_by=initial_price&sort_order=desc&page_size=10"

# Scheda giocatore
curl "http://localhost:8000/api/v1/players/1"

# Svincolati (con token)
curl "http://localhost:8000/api/v1/leagues/{LEAGUE_ID}/market/free-agents?position=ATT" \
  -H "Authorization: Bearer $TOKEN"

# Acquista svincolato
curl -X POST "http://localhost:8000/api/v1/leagues/{LEAGUE_ID}/market/buy" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"player_id": 123}'

# Statistiche
curl "http://localhost:8000/api/v1/stats/top-scorers?limit=10"
curl "http://localhost:8000/api/v1/stats/best-value?min_appearances=3"
```

---

## 6. Note

- **Stato asta in Redis**: il task suggerisce di persistere lo stato in Redis (chiave `auction:{league_id}:state`); l’implementazione attuale usa solo la tabella `auction_current`. L’aggiunta di Redis può essere fatta in un secondo momento per resistenza ai restart.
- **WebSocket messaggi tipizzati**: i payload broadcast (auction_started, bid, assigned) sono già inviati; i tipi formali (auction_start, new_bid, countdown_tick, auction_end, auction_no_sale) possono essere allineati dal client.
- **Trade**: in caso di accettazione si aggiorna solo `fantasy_team_id` sulle righe di FantasyRoster coinvolte; non viene gestita differenza di valore con aggiustamento budget (si può estendere in seguito).

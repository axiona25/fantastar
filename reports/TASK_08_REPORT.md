# TASK 08 — Report Auction System

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Sistema asta per l’acquisto dei giocatori con budget: admin mette un giocatore all’asta, i partecipanti fanno offerte (incremento minimo 1 credito), timer esteso a ogni offerta, assegnazione al miglior offerente con scalaggio budget e limiti di ruolo. Aggiornamenti in tempo reale via WebSocket.

---

## 2. Cosa è stato fatto

### 2.1 Modello e migrazione

- **`app/models/auction_current.py`** (nuovo): tabella `auction_current`
  - `league_id` (PK, FK fantasy_leagues)
  - `player_id` (FK players), `highest_bid`, `highest_bidder_team_id` (FK fantasy_teams, nullable)
  - `ends_at`, `round_number`, `created_at`
  - Una riga per lega: lo stato corrente dell’asta (giocatore, miglior offerta, scadenza).
- **Migrazione** `alembic/versions/c3d9f0e2b1e1_add_auction_current.py`: crea `auction_current`.

### 2.2 Config

- **`app/config.py`**: `AUCTION_BID_EXTEND_SECONDS = 30` (secondi di countdown e di estensione per ogni offerta).

### 2.3 Schemi Pydantic (`app/schemas/auction.py`)

- **ROLE_LIMITS**: max 3 POR, 8 DIF, 8 CEN, 6 ATT per squadra.
- **AuctionStartRequest**: player_id, round_number (opzionale).
- **AuctionStartResponse**: message, player_id, player_name, position, ends_at, seconds_remaining.
- **AuctionCurrentResponse**: player_id, player_name, position, real_team_name, highest_bid, highest_bidder_team_id/name, ends_at, seconds_remaining, round_number.
- **AuctionCurrentEmptyResponse**: active=False, message (nessuna asta in corso).
- **AuctionBidRequest**: amount (≥ 1).
- **AuctionBidResponse**: message, amount, is_leading, ends_at, seconds_remaining, highest_bidder_team_name (opzionale).
- **AuctionAssignResponse**: message, player_id, player_name, fantasy_team_id, team_name, amount.
- **AuctionHistoryItem** / **AuctionHistoryResponse**: storico acquisti (player, team, amount, purchased_at).

### 2.4 Servizio asta (`app/services/auction_service.py`)

- **start_auction(db, league_id, player_id, round_number)**: verifica che il giocatore non sia già in rosa in nessuna squadra della lega; crea/aggiorna `auction_current` (highest_bid=0, ends_at = now + 30s).
- **get_current(db, league_id)**: ritorna stato asta corrente (giocatore, offerta massima, nome squadra offerente, ends_at, seconds_remaining) o None.
- **place_bid(db, league_id, fantasy_team_id, amount)**: verifica squadra in lega, budget ≥ amount, amount ≥ highest_bid + 1, limite ruolo (can_team_sign_player); aggiorna `auction_current` e inserisce `AuctionBid` (PENDING); imposta ends_at = now + 30s.
- **assign_current(db, league_id)**: assegna il giocatore al miglior offerente: crea `FantasyRoster` (purchase_price = highest_bid), scala `budget_remaining`, elimina riga `auction_current`. Se non c’è nessuna offerta valida, chiude l’asta senza assegnare. Validazione limite ruolo prima dell’assegnazione.
- **get_history(db, league_id)**: da FantasyRoster (league_id tramite FantasyTeam) con purchase_price non nullo, ordinato per purchased_at desc.

### 2.5 API REST (`app/api/v1/auction.py`)

Tutti sotto **`/api/v1/leagues/{league_id}/auction`**:

| Metodo | Endpoint | Descrizione |
|--------|----------|-------------|
| POST | `/start` | Avvia asta (solo admin lega). Body: player_id, round_number opzionale. |
| GET | `/current` | Giocatore corrente all’asta (o risposta “nessuna asta”). |
| POST | `/bid` | Fai un’offerta (squadra dell’utente nella lega). Body: amount. |
| POST | `/assign` | Assegna giocatore al miglior offerente (solo admin). Chiude l’asta. |
| GET | `/history` | Storico acquisti asta (tutte le squadre della lega). |

- Accesso: utente autenticato; per start/assign è richiesto essere admin della lega (`league.admin_user_id == current_user.id`).
- Per `/bid` si usa la squadra fantasy dell’utente nella stessa lega (un team per utente per lega).

### 2.6 WebSocket (`app/api/websocket.py`)

- **ConnectionManager**: canali per `channel` (es. `auction:{league_id}`), connect/disconnect/broadcast.
- **ws/auction/{league_id}**: canale asta. I client connessi ricevono messaggi broadcast con **`type`** e payload strutturato:
  - **auction_start**: `type: "auction_start"`, `player` (id, name, position, team), `countdown` (secondi), `base_price`.
  - **new_bid**: `type: "new_bid"`, `team_name`, `amount`, `countdown`.
  - **auction_end**: `type: "auction_end"`, `winner` (nome squadra), `amount`, `player` (id, name).
  - **auction_no_sale**: `type: "auction_no_sale"`, `player` (id, name) — quando l’admin chiude l’asta senza offerte valide.
- Ogni messaggio include anche `event` (auction_started, bid, assigned, auction_no_sale) per retrocompatibilità.
- Client può inviare `{"type": "ping"}` e ricevere `{"type": "pong"}`.

### 2.7 Persistenza stato asta in Redis

- **Chiave**: `auction:{league_id}:state`, TTL 3600 secondi.
- **Scrittura**: in `start_auction` e dopo ogni `place_bid` (player_id, highest_bid, highest_bidder_team_id/name, countdown_end, is_active, round_number).
- **Cancellazione**: in `assign_current` (sia in caso di assegnazione sia in caso di chiusura senza offerte).
- Consente di recuperare lo stato dell’asta dopo un restart del backend (opzionale: GET current può essere esteso per leggere da Redis se il DB non ha riga).

### 2.8 Integrazione

- Router auction e websocket registrati in `main.py` (auction con prefix `/api/v1`, websocket con prefix `/ws`).

---

## 3. Logica e validazioni

- **Incremento minimo**: ogni offerta deve essere ≥ `highest_bid + 1` (1 credito).
- **Budget**: non si può offrire più del `budget_remaining` della propria squadra.
- **Limiti ruolo**: max 3 POR, 8 DIF, 8 CEN, 6 ATT per squadra; controllati in place_bid (per il nuovo miglior offerente) e in assign_current prima di creare la rosa.
- **Timer**: a ogni offerta `ends_at` viene impostato a `now + AUCTION_BID_EXTEND_SECONDS` (30 s). L’assegnazione avviene tramite chiamata esplicita POST `/assign` (admin); un job schedulato potrebbe in futuro chiamare la stessa logica allo scadere di `ends_at`.
- **Giocatore già in rosa**: non si può avviare l’asta su un giocatore già acquistato da una squadra della lega.

---

## 4. File creati/modificati

| File | Azione |
|------|--------|
| `backend/app/config.py` | Modificato (AUCTION_BID_EXTEND_SECONDS) |
| `backend/app/models/auction_current.py` | Creato |
| `backend/app/models/__init__.py` | Modificato (export AuctionCurrent) |
| `backend/alembic/versions/c3d9f0e2b1e1_add_auction_current.py` | Creato |
| `backend/app/schemas/auction.py` | Creato |
| `backend/app/services/auction_service.py` | Creato |
| `backend/app/api/v1/auction.py` | Creato |
| `backend/app/api/websocket.py` | Creato |
| `backend/app/main.py` | Modificato (include auction + websocket) |
| `reports/TASK_08_REPORT.md` | Creato |

---

## 5. Come testare

Eseguire la migrazione (da backend o container):

```bash
alembic upgrade head
```

**REST**

```bash
# Token (login)
TOKEN="..."

# Avvia asta (admin)
curl -s -X POST "http://localhost:8000/api/v1/leagues/LEAGUE_ID/auction/start" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"player_id": 1, "round_number": 1}'

# Stato corrente
curl -s "http://localhost:8000/api/v1/leagues/LEAGUE_ID/auction/current" \
  -H "Authorization: Bearer $TOKEN"

# Offerta
curl -s -X POST "http://localhost:8000/api/v1/leagues/LEAGUE_ID/auction/bid" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"amount": 5}'

# Assegna (admin)
curl -s -X POST "http://localhost:8000/api/v1/leagues/LEAGUE_ID/auction/assign" \
  -H "Authorization: Bearer $TOKEN"

# Storico
curl -s "http://localhost:8000/api/v1/leagues/LEAGUE_ID/auction/history" \
  -H "Authorization: Bearer $TOKEN"
```

**WebSocket**

- Connessione: `ws://localhost:8000/ws/auction/{league_id}`.
- Messaggi in arrivo: JSON con `event`, `type` (auction_start, new_bid, auction_end, auction_no_sale) e payload strutturato (player, countdown, amount, winner, ecc.).
- Opzionale: invio `{"type": "ping"}` per ricevere `{"type": "pong"}`.

---

## 6. Note

- Lo **storico acquisti** è derivato da FantasyRoster (purchase_price e purchased_at); le righe AuctionBid restano per tracciare le offerte (stato PENDING/WON/LOST può essere esteso in seguito).
- Il **timer** non chiude automaticamente l’asta: l’admin deve chiamare POST `/assign` (o un job può farlo quando `ends_at` è superato).
- **WebSocket** non richiede autenticazione in questa versione; in produzione si può validare un token (es. query `?token=...`) prima di accettare la connessione.

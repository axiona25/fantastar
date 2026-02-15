# TASK 04 — Sync Engine & Background Tasks

## Obiettivo
Creare il sistema di sincronizzazione automatica dei dati dalle API esterne verso il database locale, con scheduler per polling partite live.

## Dipendenze
- Task 02 (Database) + Task 03 (Data Providers)

## Istruzioni

### Componenti da creare

**1. `backend/app/tasks/sync_matches.py`**
- `sync_all_matches()` — Scarica tutte le partite della stagione e le salva nel DB
- `sync_live_matches()` — Polling ogni 60 secondi sulle partite IN_PLAY
- `sync_match_events(match_id)` — Scarica eventi (gol, cartellini) di una partita

**2. `backend/app/tasks/sync_standings.py`**
- `sync_standings()` — Aggiorna classifica Serie A

**3. `backend/app/tasks/sync_players.py`**
- `sync_all_players()` — Scarica tutte le rose delle 20 squadre (656 giocatori)
- Mappa le posizioni con POSITION_MAP

**4. `backend/app/tasks/sync_media.py`**
- `download_all_badges()` — Scarica stemmi da Football-Data.org + TheSportsDB
- `download_all_player_photos()` — Scarica foto cutout da TheSportsDB
- `generate_missing_avatars()` — Genera avatar con iniziali per foto mancanti
- Salva tutto in `/media/` con path locale nel DB

**5. `backend/app/tasks/sync_stats.py`**
- `sync_player_stats(match_id)` — Dopo una partita, scarica stat avanzate da BZZoiro

**6. `backend/app/tasks/sync_news.py`**
- `sync_news()` — Fetch RSS feeds e salva in news_articles

**7. `backend/app/tasks/scheduler.py`**
Usa APScheduler:
```python
# Ogni 5 minuti: controlla se ci sono partite live
# Ogni 60 secondi (solo durante partite): polling live
# Ogni 6 ore: sync classifica
# Ogni 24 ore: sync news
# Ogni settimana: sync rose (per eventuali cambi)
```

**8. `backend/scripts/init_season.py`**
Script one-shot per inizio stagione:
```bash
python scripts/init_season.py
# 1. Sync squadre Serie A
# 2. Sync tutte le rose (giocatori)
# 3. Sync tutte le partite della stagione
# 4. Download stemmi e foto
# 5. Sync classifica iniziale
# 6. Sync news
```

### Logica Polling Live

```
Ogni 5 minuti:
  → Chiedi a Football-Data.org le partite di oggi
  → Se qualcuna ha status IN_PLAY:
      → Attiva polling ogni 60 secondi
      → Per ogni partita IN_PLAY:
          - Aggiorna score
          - Scarica nuovi eventi
          - Ricalcola punteggi fantasy
          - Notifica via WebSocket
  → Se nessuna è IN_PLAY:
      → Torna a polling ogni 5 minuti
```

### Cache Redis

Usa Redis per:
- Classifica (TTL 5 min)
- Partite live (TTL 30 sec)
- Rose squadre (TTL 1 ora)
- News (TTL 15 min)

## Verifica
```bash
python scripts/init_season.py
# Deve popolare il DB con squadre, giocatori, partite
# Deve scaricare stemmi e foto in /media/
```

## Report
Genera `/reports/TASK_04_REPORT.md`

---

# TASK 05 — Auth & Users API

## Obiettivo
Creare sistema di autenticazione JWT e API utenti.

## Dipendenze
- Task 01, Task 02

## Endpoint da creare

| Metodo | Endpoint | Descrizione |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Registrazione utente |
| POST | `/api/v1/auth/login` | Login → ritorna JWT token |
| GET | `/api/v1/auth/me` | Profilo utente corrente |
| PUT | `/api/v1/auth/me` | Modifica profilo |
| POST | `/api/v1/auth/refresh` | Refresh token |

### Implementazione

- Password hashing con `passlib[bcrypt]`
- JWT token con `python-jose`
- Dependency `get_current_user` per proteggere le route
- Schema Pydantic per request/response

### Verifica
```bash
# Registra utente
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test@test.com", "username": "testuser", "password": "test1234"}'

# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@test.com", "password": "test1234"}'
```

## Report
Genera `/reports/TASK_05_REPORT.md`

---

# TASK 06 — Leagues & Fantasy Teams API

## Obiettivo
API per creare leghe fantasy, squadre, e gestire inviti.

## Dipendenze
- Task 05 (Auth)

## Endpoint da creare

| Metodo | Endpoint | Descrizione |
|--------|----------|-------------|
| POST | `/api/v1/leagues` | Crea lega fantasy |
| GET | `/api/v1/leagues` | Lista leghe dell'utente |
| GET | `/api/v1/leagues/{id}` | Dettaglio lega |
| POST | `/api/v1/leagues/{id}/join` | Unisciti con invite_code |
| POST | `/api/v1/leagues/{id}/generate-calendar` | Genera calendario |
| GET | `/api/v1/leagues/{id}/standings` | Classifica fantasy |
| POST | `/api/v1/teams` | Crea squadra fantasy |
| GET | `/api/v1/teams/{id}` | Dettaglio squadra con rosa |
| GET | `/api/v1/teams/{id}/lineup/{matchday}` | Formazione per giornata |
| POST | `/api/v1/teams/{id}/lineup/{matchday}` | Imposta formazione |

### Logica generazione calendario
- Round-robin: ogni squadra gioca contro tutte le altre (andata e ritorno)
- Per N squadre: (N-1)*2 giornate
- Ogni giornata corrisponde a una giornata reale di Serie A

### Logica formazione
- Moduli ammessi: 3-4-3, 3-5-2, 4-3-3, 4-4-2, 4-5-1, 5-3-2, 5-4-1
- Validazione: deve avere 1 POR, giusto numero per ruolo
- Panchina: ordine di subentro (per ruolo)

## Report
Genera `/reports/TASK_06_REPORT.md`

---

# TASK 07 — ⭐ Scoring Engine

## Obiettivo
Creare il cuore dell'app: il motore di calcolo punteggi event-based.

## Dipendenze
- Task 02, Task 04

## File principale: `backend/app/services/scoring_engine.py`

### Regole Punteggio

```python
# Punteggio base (da match_events)
BASE_SCORING = {
    "GOAL": {"POR": 5.0, "DIF": 5.0, "CEN": 4.0, "ATT": 3.0},
    "OWN_GOAL": -2.0,
    "PENALTY_SCORED": 3.0,
    "PENALTY_MISSED": -3.0,
    "YELLOW_CARD": -0.5,
    "RED_CARD": -1.0,
    "SECOND_YELLOW": -1.0,
    "ASSIST": 1.0,
    "PENALTY_SAVED": 3.0,        # Solo POR
    "CLEAN_SHEET": {"POR": 1.0, "DIF": 1.0},
    "GOAL_CONCEDED": {"POR": -1.0},
    "APPEARANCE": 1.0,           # Presente in campo
}

# Punteggio avanzato (da player_stats BZZoiro)
ADVANCED_SCORING = {
    "xg_wasted": -0.5,          # xG > 0.5 senza gol
    "xa_wasted": -0.25,         # xA > 0.3 senza assist
    "key_passes_3plus": 0.5,    # 3+ passaggi chiave
    "tackles_5plus": 0.5,       # 5+ tackle (solo DIF/CEN)
    "pass_accuracy_90plus": 0.5, # 90%+ precisione (min 30 pass)
    "high_rating": 1.0,          # Rating >= 8.0
}
```

### Metodi principali

```python
class ScoringEngine:
    def calculate_player_score(player_id, match_id) -> PlayerScore
    def calculate_team_score(fantasy_team_id, matchday) -> TeamScore
    def calculate_fantasy_goals(team_score) -> int
    def calculate_matchday_results(league_id, matchday) -> list[MatchResult]
    def recalculate_standings(league_id) -> list[StandingRow]
```

### Logica subentro panchina
Se un titolare non ha giocato (nessun evento), viene sostituito dal primo panchinaro dello stesso ruolo nell'ordine di panchina.

### Conversione in gol fantasy
```python
def calculate_fantasy_goals(total_score: float, threshold: float = 66, step: float = 8) -> int:
    if total_score < threshold:
        return 0
    return 1 + int((total_score - threshold) / step)
```

## Verifica
```python
# Test con dati reali
pytest tests/test_scoring_engine.py -v
```

## Report
Genera `/reports/TASK_07_REPORT.md`

---

# TASK 08 — Auction System

## Obiettivo
Sistema asta per l'acquisto dei giocatori con budget.

## Dipendenze
- Task 06

## Endpoint

| Metodo | Endpoint | Descrizione |
|--------|----------|-------------|
| POST | `/api/v1/leagues/{id}/auction/start` | Avvia asta (solo admin) |
| GET | `/api/v1/leagues/{id}/auction/current` | Giocatore corrente all'asta |
| POST | `/api/v1/leagues/{id}/auction/bid` | Fai un'offerta |
| POST | `/api/v1/leagues/{id}/auction/assign` | Assegna giocatore (admin) |
| GET | `/api/v1/leagues/{id}/auction/history` | Storico acquisti |

### Logica asta
1. Admin mette un giocatore all'asta
2. Tutti possono fare offerte (incremento minimo: 1 credito)
3. Timer countdown (es. 30 secondi). Ogni offerta resetta il timer
4. Allo scadere, il giocatore va al miglior offerente
5. Il budget viene scalato
6. Validazione: non puoi offrire più del tuo budget rimasto
7. Validazione: max 3 POR, 8 DIF, 8 CEN, 6 ATT per squadra

### WebSocket per asta live
L'asta deve funzionare in real-time via WebSocket, con tutti i partecipanti che vedono le offerte istantaneamente.

## Report
Genera `/reports/TASK_08_REPORT.md`

---

# TASK 09 — Live WebSocket

## Obiettivo
WebSocket per aggiornamenti in tempo reale: partite live, punteggi fantasy, asta.

## Dipendenze
- Task 07

## Implementazione `backend/app/api/websocket.py`

### Canali WebSocket

```python
# ws://localhost:8000/ws/live/{league_id}
# → Ricevi: aggiornamenti punteggi fantasy in tempo reale

# ws://localhost:8000/ws/match/{match_id}  
# → Ricevi: eventi partita (gol, cartellini) in tempo reale

# ws://localhost:8000/ws/auction/{league_id}
# → Ricevi/Invia: offerte asta in tempo reale
```

### ConnectionManager
```python
class ConnectionManager:
    def __init__(self):
        self.active_connections: dict[str, list[WebSocket]] = {}
    
    async def connect(self, channel: str, websocket: WebSocket)
    async def disconnect(self, channel: str, websocket: WebSocket)
    async def broadcast(self, channel: str, data: dict)
```

### Flusso Live Match
```
Scheduler rileva partita IN_PLAY
  → Polling Football-Data.org ogni 60s
  → Nuovo evento (es. gol)?
    → Salva in match_events
    → Ricalcola punteggi fantasy (ScoringEngine)
    → Broadcast via WebSocket a tutti i connessi
    → Client aggiorna UI in tempo reale
```

## Report
Genera `/reports/TASK_09_REPORT.md`

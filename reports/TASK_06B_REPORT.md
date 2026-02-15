# TASK 06B — Report Gestione Infortuni, Squalificati e Disponibilità Giocatori

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Aggiungere lo stato di disponibilità dei giocatori (infortunato, squalificato, in dubbio, disponibile) con avvisi in formazione, sync da API esterne e squalifiche automatiche da cartellini.

---

## 2. Cosa è stato fatto

### 2.1 Database

- **Player** (`app/models/player.py`): campi
  - `availability_status` (String 20, default `AVAILABLE`)
  - `availability_detail` (String 200, nullable)
  - `availability_return_date` (Date, nullable)
  - `availability_updated_at` (DateTime, nullable)
- **PlayerSuspension** (`app/models/suspension.py`): tabella `player_suspensions`
  - `player_id`, `reason` (YELLOW_ACCUMULATION, RED_CARD, SECOND_YELLOW, DISCIPLINARY), `matchday_from`, `matchday_to`, `matches_count`, `season`, `is_active`, `created_at`
- **Migrazione** `d4e0f1a3c2b2_add_player_availability_and_suspensions.py`

### 2.2 Servizio disponibilità (`app/services/availability_service.py`)

- **AvailabilityService(db)**:
  - **update_suspensions_after_matchday(matchday, season)**: dopo la giornata calcola rosso diretto (1 gg), doppio giallo (1 gg), accumulo gialli (5°=1, 10°=2, 15°=3); crea `PlayerSuspension` e imposta `availability_status = SUSPENDED`.
  - **check_suspension_expiry(matchday, season)**: squalifiche con `matchday_to < matchday` → `is_active=False` e giocatore `AVAILABLE`.
  - **sync_injuries_from_api()**: da TheSportsDB `get_team_players` legge `strInjured`; mapping keyword → status (INJURED, DOUBTFUL, SUSPENDED); aggiorna `Player.availability_*`.
  - **get_player_availability(player_id, matchday)**: stato completo (status, detail, return_date, is_available_for_matchday, warning_level); considera anche `PlayerSuspension` attiva per quella giornata.
  - **get_squad_availability** / **get_squad_availability_with_icons**: disponibilità di una lista di giocatori con icona (🟢🟠🔴🔵).
  - **manually_set_availability(player_id, status, detail, return_date)**: aggiorna a mano (admin).

Soglie: `DEFAULT_YELLOW_THRESHOLDS = {5: 1, 10: 2, 15: 3}`, `RED_CARD_SUSPENSION = 1`, `SECOND_YELLOW_SUSPENSION = 1`.

### 2.3 Endpoint formazione e disponibilità

- **POST /api/v1/teams/{id}/lineup/{matchday}`** (modificato):
  - Validazione modulo invariata; prima del salvataggio viene calcolata la disponibilità di ogni titolare.
  - **Non blocca** il salvataggio: la formazione viene sempre salvata.
  - Risposta **LineupSetResponse**: `message`, `fantasy_team_id`, `matchday`, `formation`, `starters`, `bench` (conteggi), **warnings** (lista con `player_id`, `player_name`, `level` red/orange, `message`, `suggestion`), **unavailable_count** (numero di avvisi rossi).
  - Messaggi tipo: SQUALIFICATO, INFORTUNATO (con rientro stimato), IN DUBBIO, NON CONVOCATO.

- **GET /api/v1/teams/{id}/lineup/{matchday}/availability`** (nuovo):
  - Stato disponibilità di tutta la rosa per quella giornata.
  - Risposta: lista di `PlayerAvailabilityItem` (`player_id`, `name`, `position`, `status`, `icon`, `detail`) per uso in UI (icone colorate).

- **PUT /api/v1/players/{id}/availability`** (nuovo):
  - Body: `PlayerAvailabilitySet` (`status`, `detail`, `return_date`).
  - Solo **admin app** o **admin di almeno una lega**.
  - Imposta manualmente `availability_status`, `availability_detail`, `availability_return_date` e `availability_updated_at`.

### 2.4 Sync e scheduler

- **sync_availability.py**:
  - `sync_availability_injuries()`: chiama `AvailabilityService.sync_injuries_from_api()`.
  - `update_suspensions_after_matchday(matchday, season)`: squalifiche da cartellini.
  - `check_suspension_expiry(matchday, season)`: sblocco squalifiche scadute.
  - `run_availability_after_matchday(matchday, season)`: esegue le due funzioni sopra (dopo una giornata).

- **Scheduler** (`app/tasks/scheduler.py`):
  - Ogni **12 ore**: `sync_availability_injuries` (infortuni TheSportsDB).
  - Ogni **6 ore**: `_job_availability_after_matchday` (ultima giornata con partite FINISHED → squalifiche + scadenza).

### 2.5 Schemi

- **team.py**: `LineupWarning`, `LineupSetResponse`, `PlayerAvailabilityItem`.
- **player_availability.py**: `PlayerAvailabilitySet` con validazione `status` in `VALID_AVAILABILITY_STATUSES`.

---

## 3. Endpoint riepilogo

| Metodo | Endpoint | Descrizione |
|--------|----------|-------------|
| POST | `/api/v1/teams/{id}/lineup/{matchday}` | **Modificato**: formazione + warnings disponibilità |
| GET | `/api/v1/teams/{id}/lineup/{matchday}/availability` | **Nuovo**: stato rosa per giornata |
| PUT | `/api/v1/players/{id}/availability` | **Nuovo**: admin imposta stato manuale |

---

## 4. File creati/modificati

| File | Azione |
|------|--------|
| `backend/app/models/player.py` | Modificato (campi availability_*) |
| `backend/app/models/suspension.py` | Creato |
| `backend/app/models/__init__.py` | Modificato (PlayerSuspension) |
| `backend/alembic/versions/d4e0f1a3c2b2_add_player_availability_and_suspensions.py` | Creato |
| `backend/app/services/availability_service.py` | Creato |
| `backend/app/schemas/team.py` | Modificato (LineupWarning, LineupSetResponse, PlayerAvailabilityItem) |
| `backend/app/schemas/player_availability.py` | Creato |
| `backend/app/api/v1/teams.py` | Modificato (set_lineup + warnings, GET availability) |
| `backend/app/api/v1/players.py` | Creato |
| `backend/app/main.py` | Modificato (include players router) |
| `backend/app/tasks/sync_availability.py` | Creato |
| `backend/app/tasks/scheduler.py` | Modificato (job infortuni 12h, job squalifiche 6h) |
| `reports/TASK_06B_REPORT.md` | Creato |

---

## 5. Come testare

```bash
# Migrazione
docker-compose exec backend alembic upgrade head

# Disponibilità rosa (con token)
curl -s "http://localhost:8000/api/v1/teams/{TEAM_ID}/lineup/25/availability" \
  -H "Authorization: Bearer $TOKEN"

# Imposta formazione (risposta con eventuali warnings)
curl -s -X POST "http://localhost:8000/api/v1/teams/{TEAM_ID}/lineup/25" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"formation": "4-3-3", "slots": [...]}'
# → "warnings" e "unavailable_count" in risposta

# Imposta disponibilità manuale (admin lega o app)
curl -s -X PUT "http://localhost:8000/api/v1/players/1/availability" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "INJURED", "detail": "Lesione muscolare", "return_date": "2026-03-01"}'
```

---

## 6. Icone stato (riferimento frontend)

| Status | Icona | Livello |
|--------|-------|--------|
| AVAILABLE | 🟢 | green |
| DOUBTFUL | 🟠 | orange |
| INJURED | 🔴 | red |
| SUSPENDED | 🔴 | red |
| NOT_CALLED | 🔴 | red |
| NATIONAL_TEAM | 🔵 | - |

---

## 7. Note

- La formazione viene **sempre salvata** anche in presenza di avvisi; i warnings servono solo a informare l’utente.
- Le squalifiche automatiche usano i **match_events** (RED_CARD, SECOND_YELLOW, YELLOW_CARD) e la **matchday** delle partite; la stagione è letta da `Match.season`.
- Sync infortuni dipende da **TheSportsDB** (`get_team_players`) e dal campo `strInjured`; il mapping delle keyword è in `INJURY_STATUS_MAP` in `availability_service.py`.

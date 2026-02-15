# TASK 06 — Report Leagues & Fantasy Teams API

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

API per creare leghe fantasy, squadre, gestire inviti, generare calendario round-robin, classifiche e formazioni (con validazione moduli).

---

## 2. Cosa è stato fatto

### 2.1 Schemi Pydantic
- **app/schemas/league.py**: LeagueCreate, LeagueJoin, LeagueResponse, LeagueDetailResponse (con team_count), StandingRow.
- **app/schemas/team.py**: TeamCreate, TeamResponse, TeamDetailResponse, RosterPlayerResponse, LineupSlot, LineupSet (formation + slots), LineupResponse; VALID_FORMATIONS e validazione formation (3-4-3, 3-5-2, 4-3-3, 4-4-2, 4-5-1, 5-3-2, 5-4-1).

### 2.2 Servizio leghe (app/services/league_service.py)
- **generate_invite_code()**: codice alfanumerico univoco (8 caratteri).
- **round_robin_pairings(team_ids)**: genera abbinamenti andata (N-1 giornate, N/2 partite per giornata).
- **generate_calendar_for_league(db, league_id)**: inserisce in fantasy_calendar andata + ritorno; con meno di 2 squadre ritorna 0. Fix: uso di `r.scalars().all()` per lista ID (compatibilità asyncpg/Row).

### 2.3 Router Leghe (app/api/v1/leagues.py)
- **POST /api/v1/leagues**: crea lega (admin = utente corrente), genera invite_code se non fornito.
- **GET /api/v1/leagues**: lista leghe dell’utente (admin o membro di una squadra).
- **GET /api/v1/leagues/{id}**: dettaglio lega con team_count.
- **POST /api/v1/leagues/{id}/join**: body invite_code; crea FantasyTeam per l’utente (nome default username + " FC"), verifica max_teams.
- **POST /api/v1/leagues/{id}/generate-calendar**: round-robin andata e ritorno; solo admin o membro; rollback su errore.
- **GET /api/v1/leagues/{id}/standings**: classifica (total_points desc, goals_for desc) con StandingRow.

### 2.4 Router Squadre (app/api/v1/teams.py)
- **POST /api/v1/teams**: crea squadra nella lega (un team per utente per lega), budget_remaining = budget lega.
- **GET /api/v1/teams/{id}**: dettaglio squadra con roster (giocatori in fantasy_rosters attivi + nome, ruolo, purchase_price).
- **GET /api/v1/teams/{id}/lineup/{matchday}**: formazione (starters, bench, formation).
- **POST /api/v1/teams/{id}/lineup/{matchday}**: imposta formazione; validazione: 11 titolari, 1 POR, DIF/CEN/ATT coerenti con modulo; tutti i player_id in rosa della squadra.

### 2.5 Validazione formazione
- Moduli ammessi: 3-4-3, 3-5-2, 4-3-3, 4-4-2, 4-5-1, 5-3-2, 5-4-1.
- _validate_lineup_slots(formation, slots, player_positions): 11 titolari, esattamente 1 POR, numero DIF/CEN/ATT come da formazione.

### 2.6 Integrazione
- Router leagues e teams registrati in main.py con prefisso /api/v1.

---

## 3. Endpoint creati

| Metodo | Endpoint | Descrizione |
|--------|----------|-------------|
| POST | `/api/v1/leagues` | Crea lega fantasy |
| GET | `/api/v1/leagues` | Lista leghe dell'utente |
| GET | `/api/v1/leagues/{id}` | Dettaglio lega (+ team_count) |
| POST | `/api/v1/leagues/{id}/join` | Unisciti con invite_code |
| POST | `/api/v1/leagues/{id}/generate-calendar` | Genera calendario round-robin |
| GET | `/api/v1/leagues/{id}/standings` | Classifica fantasy |
| POST | `/api/v1/teams` | Crea squadra fantasy |
| GET | `/api/v1/teams/{id}` | Dettaglio squadra con rosa |
| GET | `/api/v1/teams/{id}/lineup/{matchday}` | Formazione per giornata |
| POST | `/api/v1/teams/{id}/lineup/{matchday}` | Imposta formazione |

---

## 4. File creati/modificati (percorsi completi)

| File | Azione |
|------|--------|
| `backend/app/schemas/league.py` | Creato |
| `backend/app/schemas/team.py` | Creato |
| `backend/app/services/__init__.py` | Creato |
| `backend/app/services/league_service.py` | Creato |
| `backend/app/api/v1/leagues.py` | Creato |
| `backend/app/api/v1/teams.py` | Creato |
| `backend/app/main.py` | Modificato (include leagues e teams router) |
| `reports/TASK_06_REPORT.md` | Creato |

---

## 5. Logica calendario

- Round-robin: una squadra fissa, rotazione delle altre; (N-1) giornate andata, stessa struttura per ritorno con campi invertiti.
- Giornate totali: (N-1)*2.
- Con meno di 2 squadre la generazione non inserisce partite (ritorna 0).

---

## 6. Come testare

```bash
# Login e variabile TOKEN
TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@test.com", "password": "test1234"}' | \
  python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

# Crea lega
curl -s -X POST http://localhost:8000/api/v1/leagues -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -d '{"name": "Lega Test", "max_teams": 10}'

# Crea squadra (usare league_id dalla risposta sopra)
curl -s -X POST http://localhost:8000/api/v1/teams -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -d '{"league_id": "<LEAGUE_ID>", "name": "Test FC"}'

# Lista leghe, dettaglio lega, standings, generate-calendar, get team, get/set lineup
curl -s http://localhost:8000/api/v1/leagues -H "Authorization: Bearer $TOKEN"
curl -s http://localhost:8000/api/v1/leagues/<LEAGUE_ID> -H "Authorization: Bearer $TOKEN"
curl -s -X POST http://localhost:8000/api/v1/leagues/<LEAGUE_ID>/generate-calendar -H "Authorization: Bearer $TOKEN"
curl -s http://localhost:8000/api/v1/leagues/<LEAGUE_ID>/standings -H "Authorization: Bearer $TOKEN"
curl -s http://localhost:8000/api/v1/teams/<TEAM_ID> -H "Authorization: Bearer $TOKEN"
curl -s http://localhost:8000/api/v1/teams/<TEAM_ID>/lineup/1 -H "Authorization: Bearer $TOKEN"
```

---

## 7. Verifica eseguita

- POST leagues: 200, lega creata con invite_code.
- POST teams: 200, squadra creata con budget_remaining = budget lega.
- GET leagues: 200, lista con la lega creata.
- GET leagues/{id}: 200, dettaglio con team_count.
- POST generate-calendar: 200, generated 0 (1 sola squadra); con 2+ squadre genera partite.
- GET standings: 200, classifica con una riga (Test FC).
- GET teams/{id}: 200, roster vuoto (nessun giocatore acquistato).
- GET lineup: 200, starters/bench vuoti.

---

## 8. Problemi noti / TODO

- Con una sola squadra il calendario non genera partite (comportamento atteso).
- Per POST lineup è necessario avere giocatori in rosa (fantasy_rosters); l’asta/acquisti saranno nel Task 08.
- Panchina: ordine di subentro (bench_order) è salvato; logica di subentro automatico (titolare non sceso → primo panchinaro stesso ruolo) sarà nel motore punteggi (Task 07).

---

## 9. Prossimo task

**TASK 07 — Scoring Engine**: motore calcolo punteggi event-based, calculate_player_score, calculate_team_score, calculate_fantasy_goals, regole base e avanzate.

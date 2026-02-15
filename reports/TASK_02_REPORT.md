# TASK 02 — Report Database Schema & Models

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Creare lo schema completo del database PostgreSQL con SQLAlchemy models, migrazioni Alembic e script di seed per le 20 squadre di Serie A.

---

## 2. Cosa è stato fatto

- **Step 1:** Creati tutti i modelli SQLAlchemy in `backend/app/models/` (un file per tabella più `__init__.py`): User, RealTeam, Player, Match, MatchEvent, PlayerStats, FantasyLeague, FantasyTeam, FantasyRoster, FantasyLineup, FantasyScore, FantasyPlayerScore, AuctionBid, Transfer, FantasyCalendar, NewsArticle. Aggiunti indici e unique constraint come da specifica.
- **Step 2:** Creato `backend/app/database.py` con engine async (asyncpg), AsyncSessionLocal, Base e `get_db()`.
- **Step 3:** Configurato Alembic: `alembic.ini`, `alembic/env.py` (caricamento .env da root, uso di Base e modelli, migrazioni async con asyncpg), `alembic/script.py.mako`.
- **Step 4:** Generata e applicata la prima migrazione `e54babdf6aab_initial_schema.py` con `alembic revision --autogenerate` e `alembic upgrade head`.
- **Step 5:** Creato `backend/scripts/seed_database.py` che inserisce le 20 squadre di Serie A con nome, short_name, tla, primary_color, secondary_color, city.
- **Verifica:** Confermato che le 16 tabelle + alembic_version sono presenti e che `real_teams` contiene 20 righe.
- **Docker:** Aggiunto override in `docker-compose.yml` per `DATABASE_URL` e `REDIS_URL` (host `db` e `redis`) quando i servizi girano in container.

---

## 3. Schema DB (tabelle create)

| Tabella | Descrizione |
|---------|-------------|
| users | Utenti (email, username, hashed_password, profilo) |
| real_teams | Squadre Serie A reali (nome, short_name, tla, colori, stemma, città) |
| players | Giocatori reali (squadra, ruolo, prezzo base, foto) |
| matches | Partite (giornata, squadre, punteggio, status, kick_off) |
| match_events | Eventi partita (gol, cartellini, assist, tipo, minuto) |
| player_stats | Statistiche avanzate per partita (xG, xA, rating, passaggi, tackle, ecc.) |
| fantasy_leagues | Leghe fantacalcio (admin, budget, soglia gol, status) |
| fantasy_teams | Squadre fantasy (legacy, utente, budget rimanente, punti) |
| fantasy_rosters | Rosa giocatori per fantasquadra |
| fantasy_lineups | Formazioni schierate per giornata |
| fantasy_scores | Punteggi fantasy per giornata (totale, gol fantasy, avversario) |
| fantasy_player_scores | Punteggio singolo giocatore per giornata |
| auction_bids | Offerte asta |
| transfers | Scambi e mercato riparazione |
| fantasy_calendar | Calendario partite fantasy (abbinamenti giornata) |
| news_articles | Cache news RSS |

---

## 4. File creati/modificati (percorsi completi)

| File | Azione |
|------|--------|
| `backend/app/database.py` | Creato |
| `backend/app/models/__init__.py` | Creato |
| `backend/app/models/user.py` | Creato |
| `backend/app/models/real_team.py` | Creato |
| `backend/app/models/player.py` | Creato |
| `backend/app/models/match.py` | Creato |
| `backend/app/models/match_event.py` | Creato |
| `backend/app/models/player_stats.py` | Creato |
| `backend/app/models/league.py` | Creato |
| `backend/app/models/fantasy_team.py` | Creato |
| `backend/app/models/fantasy_roster.py` | Creato |
| `backend/app/models/fantasy_lineup.py` | Creato |
| `backend/app/models/fantasy_score.py` | Creato |
| `backend/app/models/fantasy_player_score.py` | Creato |
| `backend/app/models/auction_bid.py` | Creato |
| `backend/app/models/transfer.py` | Creato |
| `backend/app/models/fantasy_calendar.py` | Creato |
| `backend/app/models/news_article.py` | Creato |
| `backend/alembic.ini` | Creato |
| `backend/alembic/env.py` | Creato |
| `backend/alembic/script.py.mako` | Creato |
| `backend/alembic/versions/e54babdf6aab_initial_schema.py` | Creato (autogenerate) |
| `backend/scripts/seed_database.py` | Creato |
| `docker-compose.yml` | Modificato (environment DATABASE_URL, REDIS_URL per container) |

---

## 5. Come testare

```bash
cd /Users/r.amoroso/Documents/Cursor/Fantastar
docker-compose up -d
docker-compose exec db psql -U fantastar -d fantastar -c "\dt"
docker-compose exec db psql -U fantastar -d fantastar -c "SELECT COUNT(*) FROM real_teams;"
docker-compose exec backend python scripts/seed_database.py
```

Risultato atteso: 17 tabelle (16 app + alembic_version), 20 righe in `real_teams` dopo lo seed.

---

## 6. Output verifica

```
List of relations: users, real_teams, players, matches, match_events, player_stats,
fantasy_leagues, fantasy_teams, fantasy_rosters, fantasy_lineups, fantasy_scores,
fantasy_player_scores, auction_bids, transfers, fantasy_calendar, news_articles, alembic_version.

SELECT COUNT(*) FROM real_teams; → 20
```

---

## 7. Problemi noti / TODO

- Per eseguire Alembic in locale (senza Docker) serve un venv con le dipendenze e `DATABASE_URL` con `localhost`; in Docker usare sempre `docker-compose exec backend alembic ...`.
- Lo script `seed_database.py` usa engine sincrono (create_engine); se `DATABASE_URL` nel container fosse async, lo script converte in URL sync (nel container è già sync).

---

## 8. Prossimo task

**TASK 03 — Data Providers** (`TASK_03_DATA_PROVIDERS.md`): connettori API esterne (Football-Data.org, TheSportsDB, BZZoiro, RSS).

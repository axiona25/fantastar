# TASK 04 — Report Sync Engine & Background Tasks

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Creare il sistema di sincronizzazione automatica dei dati dalle API esterne verso il database locale, con scheduler per polling partite live e script one-shot per inizio stagione.

---

## 2. Cosa è stato fatto

### 2.1 Redis cache (`app/utils/cache.py`)
- `get_redis()`, `cache_get(key)`, `cache_set(key, value, ttl_seconds)`, `cache_delete(key)`, `close_redis()`.
- TTL: standings 5 min, live matches 30 sec, roster 1 ora, news 15 min.
- Chiavi: `standings:sa`, `live:matches`, `news:list`.

### 2.2 Task sync
- **sync_matches.py**: `sync_real_teams()` — aggiorna real_teams con external_id e crest da API; `sync_all_matches()` — scarica tutte le partite e le salva/aggiorna nel DB; `sync_live_matches()` — polling partite IN_PLAY, aggiorna score e eventi, salva in Redis; `sync_match_events(match_id)` — scarica eventi (gol, cartellini) per una partita.
- **sync_standings.py**: `sync_standings()` — scarica classifica da Football-Data.org e la salva in Redis (TTL 5 min).
- **sync_players.py**: `sync_all_players()` — scarica rose delle 20 squadre, mappa posizioni con POSITION_MAP, upsert in `players`.
- **sync_media.py**: `download_all_badges()` — scarica stemmi da Football-Data.org in `media/team_badges/` e aggiorna `crest_local`; `download_all_player_photos()` — scarica cutout da TheSportsDB dove `cutout_url` è valorizzato; `generate_missing_avatars()` — genera avatar con iniziali (PIL) per giocatori senza foto in `media/avatars/`.
- **sync_stats.py**: `sync_player_stats(match_id=None, event_id=None)` — scarica statistiche avanzate da BZZoiro e upsert in `player_stats`.
- **sync_news.py**: `sync_news()` — fetch tutti i feed RSS, upsert in `news_articles` per url, e cache in Redis (TTL 15 min).

### 2.3 Scheduler (`app/tasks/scheduler.py`)
- APScheduler `AsyncIOScheduler`.
- **Ogni 5 min**: `_job_check_live` — verifica partite IN_PLAY; se ce ne sono, attiva job 60s.
- **Ogni 60s** (solo se ci sono partite live): `_job_sync_live` — sync partite live.
- **Ogni 6 ore**: sync classifica.
- **Ogni 24 ore**: sync news.
- **Ogni settimana** (domenica 03:00): sync rose.
- Avvio/arresto tramite lifespan FastAPI (`main.py`).

### 2.4 Script init_season (`scripts/init_season.py`)
Ordine esecuzione:
1. Sync squadre Serie A (real_teams con external_id).
2. Sync rose (giocatori).
3. Sync partite stagione.
4. Download stemmi, foto giocatori, avatar mancanti.
5. Sync classifica (cache Redis).
6. Sync news.

### 2.5 Config e Docker
- Aggiunto `MEDIA_ROOT` in `config.py`; in Docker impostato `MEDIA_ROOT=/app/media` in `docker-compose.yml`.

---

## 3. File creati/modificati (percorsi completi)

| File | Azione |
|------|--------|
| `backend/app/utils/__init__.py` | Creato |
| `backend/app/utils/cache.py` | Creato |
| `backend/app/tasks/__init__.py` | Creato |
| `backend/app/tasks/sync_standings.py` | Creato |
| `backend/app/tasks/sync_matches.py` | Creato |
| `backend/app/tasks/sync_players.py` | Creato |
| `backend/app/tasks/sync_media.py` | Creato |
| `backend/app/tasks/sync_stats.py` | Creato |
| `backend/app/tasks/sync_news.py` | Creato |
| `backend/app/tasks/scheduler.py` | Creato |
| `backend/scripts/init_season.py` | Creato |
| `backend/app/main.py` | Modificato (lifespan, start/stop scheduler) |
| `backend/app/config.py` | Modificato (MEDIA_ROOT) |
| `docker-compose.yml` | Modificato (MEDIA_ROOT per backend) |
| `reports/TASK_04_REPORT.md` | Creato |

---

## 4. Logica polling live

- Ogni 5 minuti viene chiamata l’API partite (status IN_PLAY).
- Se esiste almeno una partita IN_PLAY viene aggiunto un job che ogni 60 secondi esegue `sync_live_matches()` (aggiornamento score, eventi, cache Redis).
- Quando non ci sono più partite live, il job a 60s viene rimosso.

---

## 5. Cache Redis (chiavi e TTL)

| Chiave | Contenuto | TTL |
|--------|-----------|-----|
| `standings:sa` | Classifica Serie A (JSON) | 5 min |
| `live:matches` | Partite in corso (JSON) | 30 sec |
| `news:list` | Ultimi articoli (lista) | 15 min |
| Rose squadre | (previsto per uso futuro) | 1 ora |

---

## 6. Come testare

```bash
cd /Users/r.amoroso/Documents/Cursor/Fantastar
docker-compose up -d
docker-compose exec backend python scripts/init_season.py
```

Verifica DB e media:
```bash
docker-compose exec db psql -U fantastar -d fantastar -c "SELECT COUNT(*) FROM real_teams; SELECT COUNT(*) FROM players; SELECT COUNT(*) FROM matches; SELECT COUNT(*) FROM news_articles;"
ls -la media/team_badges media/avatars
```

---

## 7. Verifica eseguita

- `init_season.py` eseguito nel container con esito positivo.
- Sync squadre: aggiornamento/inserimento real_teams con external_id e crest.
- Sync rose: inserimento/aggiornamento giocatori con POSITION_MAP.
- Sync partite: inserimento/aggiornamento matches.
- Download stemmi e avatar; news inserite in `news_articles` (es. 42 inserted).
- Output finale: `Init season completed.`

---

## 8. Problemi noti / TODO

- **sync_match_events**: gli eventi vengono salvati con `player_id` null (mapping external player id → nostro player.id non implementato); i tipi evento (GOAL, OWN_GOAL, YELLOW_CARD, ecc.) sono mappati dal JSON API.
- **Football-Data.org**: goals/bookings in match detail potrebbero richiedere header `X-Unfold-Goals` e `X-Unfold-Bookings`; in caso di risposta vuota va esteso il provider.
- **generate_missing_avatars**: usa font DejaVu se disponibile, altrimenti default; in container senza font l’immagine viene comunque generata.
- **sync_player_stats**: la struttura della risposta BZZoiro può variare; i campi sono mappati in modo flessibile (es. goal_assist/assists, total_pass/total_passes).

---

## 9. Prossimo task

**TASK 05 — Auth & Users API**: registrazione, login JWT, profilo utente, dependency `get_current_user`.

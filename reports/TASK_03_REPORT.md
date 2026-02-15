# TASK 03 — Report Data Providers (Connettori API Esterne)

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Creare i connettori per le fonti dati esterne: Football-Data.org, TheSportsDB, BZZoiro, RSS Feeds, e un orchestratore (Sync Manager).

---

## 2. Cosa è stato fatto

- **BaseProvider** (`base_provider.py`): classe base astratta con `_request()` (rate limiting, error handling), `_get_headers()` astratto, client httpx async, metodo `close()`.
- **FootballDataOrgProvider** (`football_data_org.py`): get_standings(), get_teams(), get_matches(matchday, status), get_match_detail(match_id), get_scorers(), get_live_matches(); POSITION_MAP e STATUS_MAP; base URL v4, header X-Auth-Token, rate limit 6s.
- **TheSportsDBProvider** (`thesportsdb.py`): search_team(name), get_team_players(team_id), get_team_badge(team_id), get_standings(league_id, season), download_image(url, save_path); PLAYER_FIELDS; base URL con API key nel path, league ID 4332, rate limit 1s.
- **BZZoiroProvider** (`bzzoiro.py`): get_leagues(), get_events(status), get_player_stats(event_id), get_predictions(upcoming); STAT_FIELDS; header Authorization: Token, rate limit 0.5s; endpoint con trailing slash per evitare 301.
- **RSS News** (`rss_news.py`): fetch_feed(url, source), fetch_all_feeds(); RSS_FEEDS con Football Italia, Get Football News Italy, Cult of Calcio, FIGC; feedparser e normalizzazione articoli (title, summary, url, source, image_url, published_at).
- **SyncManager** (`sync_manager.py`): full_sync(), sync_standings(), sync_matches(matchday), sync_live(), sync_media(), sync_news(), sync_player_stats(match_id); coordina i tre provider + RSS.
- **Test** (`tests/test_data_providers.py`): 9 test async che chiamano API reali, verificano formato e stampano sample; conftest per .env e asyncio; pytest.ini con asyncio_mode=auto.

---

## 3. File creati/modificati (percorsi completi)

| File | Azione |
|------|--------|
| `backend/app/data_providers/base_provider.py` | Creato |
| `backend/app/data_providers/football_data_org.py` | Creato |
| `backend/app/data_providers/thesportsdb.py` | Creato |
| `backend/app/data_providers/bzzoiro.py` | Creato |
| `backend/app/data_providers/rss_news.py` | Creato |
| `backend/app/data_providers/sync_manager.py` | Creato |
| `backend/app/data_providers/__init__.py` | Creato |
| `backend/tests/conftest.py` | Creato |
| `backend/tests/test_data_providers.py` | Creato |
| `backend/pytest.ini` | Creato |
| `reports/TASK_03_REPORT.md` | Creato |

---

## 4. Provider creati e metodi

| Provider | Metodi principali |
|----------|-------------------|
| **FootballDataOrgProvider** | get_standings, get_teams, get_matches, get_match_detail, get_scorers, get_live_matches |
| **TheSportsDBProvider** | search_team, get_team_players, get_team_badge, get_standings, download_image |
| **BZZoiroProvider** | get_leagues, get_events, get_player_stats, get_predictions |
| **RSS** (modulo) | fetch_feed, fetch_all_feeds |
| **SyncManager** | full_sync, sync_standings, sync_matches, sync_live, sync_media, sync_news, sync_player_stats |

---

## 5. Test superati

Eseguiti con: `docker-compose exec backend pytest tests/test_data_providers.py -v`

- test_football_data_org_standings — PASSED  
- test_football_data_org_teams — PASSED  
- test_football_data_org_matches — PASSED  
- test_thesportsdb_search_team — PASSED  
- test_thesportsdb_standings — PASSED  
- test_bzzoiro_leagues_or_events — PASSED  
- test_rss_fetch_all_feeds — PASSED  
- test_sync_manager_standings — PASSED  
- test_sync_manager_news — PASSED  

**Risultato:** 9 passed.

---

## 6. Sample dati (verifica visiva)

- **Football-Data**: standings con competition/standings; teams con id, name, shortName, tla; matches con id, matchday, status, utcDate.
- **TheSportsDB**: search_team("Inter") ritorna team con strTeam, strTeamBadge, idTeam; standings con struttura tabella/standings.
- **BZZoiro**: get_leagues() o get_events() ritorna dict (chiavi dipendono da API).
- **RSS**: fetch_all_feeds() ritorna lista di dict con title, summary, url, source, image_url, published_at; articoli da 4 feed.

---

## 7. Come testare

```bash
cd /Users/r.amoroso/Documents/Cursor/Fantastar
docker-compose up -d
docker-compose exec backend pytest tests/test_data_providers.py -v
```

Per vedere output sample: `docker-compose exec backend pytest tests/test_data_providers.py -v -s`

---

## 8. Problemi noti / TODO

- **BZZoiro**: l’API richiede trailing slash negli endpoint (es. `leagues/`, `events/`); senza si riceve 301. Implementato con slash finale.
- I test che usano FOOTBALL_DATA_ORG_KEY o BZZOIRO_KEY fanno skip se le key non sono configurate; in Docker le variabili sono passate da .env.
- sync_media() attualmente incrementa solo i badge per squadra; eventuale download massivo cutout giocatori da integrare in seguito.

---

## 9. Prossimo task

**TASK 04** (in `TASK_04_TO_09_BACKEND.md`): Sync Engine & Background Tasks — scheduler sync dati, download media, polling partite.

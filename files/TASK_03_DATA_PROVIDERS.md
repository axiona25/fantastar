# TASK 03 — Data Providers (Connettori API Esterne)

## Obiettivo
Creare i connettori per tutte le fonti dati esterne: Football-Data.org, TheSportsDB, BZZoiro, RSS Feeds.

## Dipendenze
- Task 01 completato

## Istruzioni per Cursor

### Architettura

Tutti i provider ereditano da una classe base astratta:

```python
# backend/app/data_providers/base_provider.py

from abc import ABC, abstractmethod
import httpx
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

class BaseProvider(ABC):
    """Classe base per tutti i data provider esterni"""
    
    def __init__(self, base_url: str, api_key: str = None, rate_limit: float = 0):
        self.base_url = base_url
        self.api_key = api_key
        self.rate_limit = rate_limit  # Secondi tra richieste
        self._last_request = None
        self.client = httpx.AsyncClient(timeout=15.0)
    
    async def _request(self, endpoint: str, params: dict = None) -> dict:
        """Esegue richiesta con rate limiting e error handling"""
        # Rate limiting
        if self.rate_limit > 0 and self._last_request:
            elapsed = (datetime.now() - self._last_request).total_seconds()
            if elapsed < self.rate_limit:
                await asyncio.sleep(self.rate_limit - elapsed)
        
        url = f"{self.base_url}/{endpoint}"
        headers = self._get_headers()
        
        try:
            response = await self.client.get(url, headers=headers, params=params)
            self._last_request = datetime.now()
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            logger.error(f"{self.__class__.__name__} HTTP error: {e.response.status_code} - {url}")
            raise
        except Exception as e:
            logger.error(f"{self.__class__.__name__} error: {e} - {url}")
            raise
    
    @abstractmethod
    def _get_headers(self) -> dict:
        pass
```

### Provider 1: Football-Data.org (FONTE PRIMARIA)

```python
# backend/app/data_providers/football_data_org.py
```

Implementa:
- `get_standings()` → Classifica Serie A
- `get_teams()` → Tutte le squadre con rose complete
- `get_matches(matchday=None, status=None)` → Partite (filtrabili)
- `get_match_detail(match_id)` → Dettaglio singola partita con eventi
- `get_scorers()` → Classifica marcatori
- `get_live_matches()` → Partite in corso

**Configurazione:**
```
Base URL: https://api.football-data.org/v4
Header: X-Auth-Token: {api_key}
Competition: SA (Serie A)
Rate limit: 6 secondi tra richieste (10 req/min)
```

**Mapping importante:**
```python
POSITION_MAP = {
    "Goalkeeper": "POR",
    "Defence": "DIF",
    "Left-Back": "DIF",
    "Right-Back": "DIF",
    "Centre-Back": "DIF",
    "Midfield": "CEN",
    "Defensive Midfield": "CEN",
    "Central Midfield": "CEN",
    "Attacking Midfield": "CEN",
    "Left Winger": "ATT",
    "Right Winger": "ATT",
    "Centre-Forward": "ATT",
    "Offence": "ATT",
}

STATUS_MAP = {
    "SCHEDULED": "SCHEDULED",
    "TIMED": "TIMED",
    "IN_PLAY": "IN_PLAY",
    "PAUSED": "PAUSED",
    "FINISHED": "FINISHED",
    "POSTPONED": "POSTPONED",
    "CANCELLED": "CANCELLED",
    "SUSPENDED": "SUSPENDED",
}
```

### Provider 2: TheSportsDB (MEDIA)

```python
# backend/app/data_providers/thesportsdb.py
```

Implementa:
- `search_team(name)` → Cerca squadra, ritorna stemma + divise
- `get_team_players(team_id)` → Giocatori con foto cutout
- `get_team_badge(team_id)` → URL stemma
- `get_standings(league_id, season)` → Classifica (backup)
- `download_image(url, save_path)` → Scarica e salva immagine

**Configurazione:**
```
Base URL: https://www.thesportsdb.com/api/v1/json/{api_key}
API Key: 3 (test gratuita)
Serie A League ID: 4332
Rate limit: 1 secondo
```

**Campi utili dal JSON risposta giocatori:**
```python
PLAYER_FIELDS = {
    "strPlayer": "name",
    "strPosition": "position",
    "strNationality": "nationality",
    "strNumber": "shirt_number",
    "dateBorn": "date_of_birth",
    "strThumb": "photo_url",        # Foto thumbnail
    "strCutout": "cutout_url",       # PNG trasparente (il migliore!)
    "strRender": "render_url",       # Render full body
    "idPlayer": "thesportsdb_id",
}
```

### Provider 3: BZZoiro Sports (STATISTICHE AVANZATE)

```python
# backend/app/data_providers/bzzoiro.py
```

Implementa:
- `get_leagues()` → Lista leghe (per trovare ID Serie A)
- `get_events(status=None)` → Partite
- `get_player_stats(event_id=None)` → Statistiche giocatori per partita
- `get_predictions(upcoming=True)` → Predizioni ML

**Configurazione:**
```
Base URL: https://sports.bzzoiro.com/api
Header: Authorization: Token {api_key}
Rate limit: nessuno dichiarato, usa 0.5s per sicurezza
```

**Campi statistiche disponibili (dal test):**
```python
STAT_FIELDS = [
    "minutes_played", "rating", "goals", "goal_assist",
    "expected_goals", "expected_assists", "total_shots",
    "shots_on_target", "total_pass", "accurate_pass",
    "key_pass", "total_cross", "accurate_cross",
    "total_long_balls", "accurate_long_balls",
    "total_tackles", "tackles_won", "interceptions",
    "clearances", "saves"
]
```

### Provider 4: RSS News

```python
# backend/app/data_providers/rss_news.py
```

Implementa:
- `fetch_all_feeds()` → Scarica tutti i feed e ritorna articoli normalizzati
- `fetch_feed(url)` → Singolo feed

**Feed configurati (testati e funzionanti):**
```python
RSS_FEEDS = {
    "Football Italia": "https://football-italia.net/feed",
    "Get Football News Italy": "https://getfootballnewsitaly.com/feed",
    "Cult of Calcio": "https://cultofcalcio.com/feed/",
    "FIGC": "https://figc.it/it/rss/tutto-il-sito/",
}
# NOTA: Calciomercato.com fallito nel test, escluso
```

Usa la libreria `feedparser` per il parsing.

### Provider 5: Sync Manager (Orchestratore)

```python
# backend/app/data_providers/sync_manager.py
```

Orchestratore che coordina tutti i provider:
- `full_sync()` → Sync completo (inizio stagione)
- `sync_standings()` → Aggiorna classifica
- `sync_matches(matchday)` → Aggiorna partite per giornata
- `sync_live()` → Polling partite live
- `sync_media()` → Download bulk foto e stemmi
- `sync_news()` → Aggiorna news RSS
- `sync_player_stats(match_id)` → Statistiche dopo partita

### Verifica

Crea `backend/tests/test_data_providers.py` con test per ogni provider:
```bash
pytest tests/test_data_providers.py -v
```

Ogni test deve:
1. Chiamare l'API reale (con le key configurate)
2. Verificare che i dati ritornati sono nel formato atteso
3. Stampare un sample dei dati per verifica visiva

## Report
Genera `/reports/TASK_03_REPORT.md` con tutti i provider creati, test superati, e sample dati.

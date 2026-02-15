"""
Orchestratore che coordina tutti i data provider per sync classifica, partite, media, news, statistiche.
"""
import logging
from typing import List, Dict, Any, Optional

from app.data_providers.football_data_org import FootballDataOrgProvider
from app.data_providers.thesportsdb import TheSportsDBProvider
from app.data_providers.bzzoiro import BZZoiroProvider
from app.data_providers.rss_news import fetch_all_feeds

logger = logging.getLogger(__name__)


class SyncManager:
    """Coordina full_sync, standings, matches, live, media, news, player_stats."""

    def __init__(self):
        self.football_data = FootballDataOrgProvider()
        self.thesportsdb = TheSportsDBProvider()
        self.bzzoiro = BZZoiroProvider()

    async def full_sync(self) -> Dict[str, Any]:
        """Sync completo (inizio stagione): classifica, squadre, partite, media, news."""
        result = {"standings": None, "teams": None, "matches": None, "news_count": 0}
        try:
            result["standings"] = await self.sync_standings()
        except Exception as e:
            logger.exception("full_sync standings: %s", e)
        try:
            result["teams"] = await self.football_data.get_teams()
        except Exception as e:
            logger.exception("full_sync teams: %s", e)
        try:
            result["matches"] = await self.sync_matches()
        except Exception as e:
            logger.exception("full_sync matches: %s", e)
        try:
            articles = await self.sync_news()
            result["news_count"] = len(articles)
        except Exception as e:
            logger.exception("full_sync news: %s", e)
        return result

    async def sync_standings(self) -> dict:
        """Aggiorna classifica Serie A."""
        return await self.football_data.get_standings()

    async def sync_matches(self, matchday: Optional[int] = None) -> dict:
        """Aggiorna partite (tutte o per giornata)."""
        return await self.football_data.get_matches(matchday=matchday)

    async def sync_live(self) -> dict:
        """Polling partite in corso."""
        return await self.football_data.get_live_matches()

    async def sync_media(self) -> Dict[str, Any]:
        """Download bulk foto e stemmi (coordina TheSportsDB). Ritorna elenco operazioni."""
        # Ottieni squadre da Football-Data per nomi, poi cerca su TheSportsDB e scarica
        teams_data = await self.football_data.get_teams()
        result = {"badges": 0, "players": 0, "errors": []}
        teams = teams_data.get("teams") or []
        for team in teams:
            name = team.get("name")
            if not name:
                continue
            try:
                search = await self.thesportsdb.search_team(name)
                tdb_teams = search.get("teams") or []
                if not tdb_teams:
                    continue
                team_id = tdb_teams[0].get("idTeam")
                if team_id:
                    result["badges"] += 1
                # Opzionale: get_team_players e download cutout
                # players = await self.thesportsdb.get_team_players(team_id)
                # ...
            except Exception as e:
                result["errors"].append(f"{name}: {e}")
        return result

    async def sync_news(self) -> List[Dict[str, Any]]:
        """Aggiorna news da tutti i feed RSS."""
        return await fetch_all_feeds()

    async def sync_player_stats(self, match_id: Optional[str] = None) -> dict:
        """Statistiche giocatori dopo partita (BZZoiro)."""
        return await self.bzzoiro.get_player_stats(event_id=match_id)

    async def close(self):
        """Chiude i client HTTP di tutti i provider."""
        await self.football_data.close()
        await self.thesportsdb.close()
        await self.bzzoiro.close()

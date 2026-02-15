"""
Provider Football-Data.org v4 - Fonte primaria: classifica, rose, partite, marcatori.
Competition: SA (Serie A). Rate limit: 10 req/min = 6 secondi tra richieste.
"""
from app.data_providers.base_provider import BaseProvider
from app.config import settings

BASE_URL = "https://api.football-data.org/v4"
COMPETITION_CODE = "SA"  # Serie A

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


class FootballDataOrgProvider(BaseProvider):
    def __init__(self, api_key: str = None, rate_limit: float = 6.0):
        super().__init__(BASE_URL, api_key=api_key or settings.FOOTBALL_DATA_ORG_KEY, rate_limit=rate_limit)

    def _get_headers(self) -> dict:
        headers = {}
        if self.api_key:
            headers["X-Auth-Token"] = self.api_key
        return headers

    async def get_standings(self) -> dict:
        """Classifica Serie A."""
        return await self._request(f"competitions/{COMPETITION_CODE}/standings")

    async def get_teams(self) -> dict:
        """Tutte le squadre con rose complete."""
        return await self._request(f"competitions/{COMPETITION_CODE}/teams")

    async def get_matches(self, matchday: int = None, status: str = None) -> dict:
        """Partite (filtrabili per matchday e status)."""
        params = {}
        if matchday is not None:
            params["matchday"] = matchday
        if status:
            params["status"] = status
        return await self._request(f"competitions/{COMPETITION_CODE}/matches", params=params or None)

    async def get_match_detail(self, match_id: int) -> dict:
        """Dettaglio singola partita con eventi."""
        return await self._request(f"matches/{match_id}")

    async def get_scorers(self) -> dict:
        """Classifica marcatori."""
        return await self._request(f"competitions/{COMPETITION_CODE}/scorers")

    async def get_live_matches(self) -> dict:
        """Partite in corso."""
        return await self.get_matches(status="IN_PLAY")

"""
Provider BZZoiro Sports - Statistiche avanzate: xG, xA, passaggi, tackle, predizioni ML.
Base URL: https://sports.bzzoiro.com/api
Header: Authorization: Token {api_key}
Rate limit: 0.5s per sicurezza.
"""
from app.data_providers.base_provider import BaseProvider
from app.config import settings

BASE_URL = "https://sports.bzzoiro.com/api"

STAT_FIELDS = [
    "minutes_played",
    "rating",
    "goals",
    "goal_assist",
    "expected_goals",
    "expected_assists",
    "total_shots",
    "shots_on_target",
    "total_pass",
    "accurate_pass",
    "key_pass",
    "total_cross",
    "accurate_cross",
    "total_long_balls",
    "accurate_long_balls",
    "total_tackles",
    "tackles_won",
    "interceptions",
    "clearances",
    "saves",
]


class BZZoiroProvider(BaseProvider):
    def __init__(self, api_key: str = None, rate_limit: float = 0.5):
        super().__init__(BASE_URL, api_key=api_key or settings.BZZOIRO_KEY, rate_limit=rate_limit)

    def _get_headers(self) -> dict:
        headers = {}
        if self.api_key:
            headers["Authorization"] = f"Token {self.api_key}"
        return headers

    async def get_leagues(self) -> dict:
        """Lista leghe (per trovare ID Serie A)."""
        return await self._request("leagues/")

    async def get_events(self, status: str = None) -> dict:
        """Partite/eventi, opzionalmente filtrate per status."""
        params = {}
        if status is not None:
            params["status"] = status
        return await self._request("events/", params=params or None)

    async def get_player_stats(self, event_id: str = None) -> dict:
        """Statistiche giocatori per partita (event_id)."""
        params = {}
        if event_id is not None:
            params["event_id"] = event_id
        return await self._request("player-stats/", params=params or None)

    async def get_predictions(self, upcoming: bool = True) -> dict:
        """Predizioni ML."""
        params = {}
        if upcoming is not None:
            params["upcoming"] = str(upcoming).lower()
        return await self._request("predictions/", params=params or None)

"""
Provider TheSportsDB - Media: stemmi, divise, foto cutout giocatori.
Serie A League ID: 4332. Rate limit: 1 secondo.
"""
import logging
from pathlib import Path

from app.data_providers.base_provider import BaseProvider
from app.config import settings

logger = logging.getLogger(__name__)

# Base URL: api key va nel path
def _base_url():
    key = settings.THESPORTSDB_KEY or "3"
    return f"https://www.thesportsdb.com/api/v1/json/{key}"

SERIE_A_LEAGUE_ID = "4332"

PLAYER_FIELDS = {
    "strPlayer": "name",
    "strPosition": "position",
    "strNationality": "nationality",
    "strNumber": "shirt_number",
    "dateBorn": "date_of_birth",
    "strThumb": "photo_url",
    "strCutout": "cutout_url",
    "strRender": "render_url",
    "idPlayer": "thesportsdb_id",
}


class TheSportsDBProvider(BaseProvider):
    def __init__(self, api_key: str = None, rate_limit: float = 1.0):
        super().__init__(_base_url(), api_key=api_key or settings.THESPORTSDB_KEY, rate_limit=rate_limit)

    def _get_headers(self) -> dict:
        return {}

    async def search_team(self, name: str) -> dict:
        """Cerca squadra, ritorna stemma + divise."""
        return await self._request("searchteams.php", params={"t": name})

    async def get_team_players(self, team_id: str) -> dict:
        """Giocatori con foto cutout."""
        return await self._request("lookup_all_players.php", params={"id": team_id})

    async def get_team_badge(self, team_id: str) -> dict:
        """URL stemma (lookup team ritorna anche badge)."""
        data = await self._request("lookupteam.php", params={"id": team_id})
        return data

    async def get_standings(self, league_id: str = SERIE_A_LEAGUE_ID, season: str = None) -> dict:
        """Classifica (backup)."""
        params = {"l": league_id}
        if season:
            params["s"] = season
        return await self._request("lookuptable.php", params=params)

    async def download_image(self, url: str, save_path: str) -> bool:
        """Scarica e salva immagine su disco."""
        if not url:
            return False
        try:
            path = Path(save_path)
            path.parent.mkdir(parents=True, exist_ok=True)
            async with self.client.stream("GET", url) as response:
                response.raise_for_status()
                with open(path, "wb") as f:
                    async for chunk in response.aiter_bytes():
                        f.write(chunk)
            return True
        except Exception as e:
            logger.warning(f"TheSportsDB download_image failed: {url} -> {save_path}: {e}")
            return False

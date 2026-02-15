from abc import ABC, abstractmethod
import asyncio
import httpx
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class BaseProvider(ABC):
    """Classe base per tutti i data provider esterni"""

    def __init__(self, base_url: str, api_key: str = None, rate_limit: float = 0):
        self.base_url = base_url.rstrip("/")
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

        url = f"{self.base_url}/{endpoint.lstrip('/')}"
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

    async def close(self):
        """Chiude il client HTTP."""
        await self.client.aclose()

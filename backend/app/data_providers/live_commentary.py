"""
Provider cronache testuali live (Parte 1).
Scarica cronache da più fonti; per UI minima/placeholder usa mock se fetch fallisce.
Keyword locale, NO LLM/AI API.
"""
import asyncio
import logging
from datetime import datetime

import httpx

logger = logging.getLogger(__name__)

SOURCES = {
    "football_italia": {
        "url_template": "https://www.football-italia.net/match/{match_slug}/live",
        "language": "en",
    },
    "tuttomercatoweb": {
        "url_template": "https://www.tuttomercatoweb.com/diretta/{match_slug}",
        "language": "it",
    },
}


def _mock_entries(match_external_id: str, source: str) -> list[dict]:
    """Entry cronaca mock per test/placeholder (nessuno scraping reale)."""
    return [
        {"minute": 15, "text": "Good build-up play, ball into the box.", "source": source},
        {"minute": 23, "text": "Brilliant run and clinical finish. Goal!", "source": source},
        {"minute": 45, "text": "Booked for a late tackle.", "source": source},
    ]


class LiveCommentaryProvider:
    """
    Scarica cronache testuali live da più fonti.
    Usa httpx; in caso di errore o per placeholder ritorna mock.
    """

    def __init__(self, timeout: float = 10.0):
        self.timeout = timeout

    async def fetch_commentary(self, match_external_id: str, source: str) -> list[dict]:
        """
        Scarica le entry della cronaca live per una fonte.
        Ritorna lista di {minute, text, source, fetched_at} ordinata per minuto.
        """
        if source not in SOURCES:
            return []
        url_template = SOURCES[source]["url_template"]
        # match_slug: alcuni siti usano external_id, altri slug tipo "inter-milan"
        match_slug = str(match_external_id)
        url = url_template.format(match_slug=match_slug)
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    url,
                    headers={"User-Agent": "FANTASTAR/1.0 (compat)"},
                )
                response.raise_for_status()
                # Parsing reale andrebbe con BeautifulSoup; per Parte 1-6 UI minima
                # non implementiamo scraping reale (ToS). Ritorniamo mock.
                entries = self._parse_commentary_html(response.text, source)
                if not entries:
                    entries = _mock_entries(match_external_id, source)
        except Exception as e:
            logger.debug("fetch_commentary %s %s: %s", match_external_id, source, e)
            entries = _mock_entries(match_external_id, source)
        now = datetime.utcnow()
        for e in entries:
            e.setdefault("source", source)
            e["fetched_at"] = now
        return sorted(entries, key=lambda x: (x.get("minute") or 0))

    def _parse_commentary_html(self, html: str, source: str) -> list[dict]:
        """Estrae entry da HTML; override per implementazione reale. Placeholder: vuoto."""
        return []

    async def fetch_all_sources(self, match_external_id: str) -> list[dict]:
        """
        Scarica da tutte le fonti disponibili e unifica.
        Deduplica per minuto/contenuto simile (stesso minuto: tiene una sola entry).
        """
        all_entries: list[dict] = []
        seen_minute_text: set[tuple[int, str]] = set()
        for source in SOURCES:
            entries = await self.fetch_commentary(match_external_id, source)
            for e in entries:
                minute = e.get("minute") or 0
                text = (e.get("text") or "")[:200]
                key = (minute, text)
                if key not in seen_minute_text:
                    seen_minute_text.add(key)
                    all_entries.append(e)
            await asyncio.sleep(0.3)
        return sorted(all_entries, key=lambda x: (x.get("minute") or 0))

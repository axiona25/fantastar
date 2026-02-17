"""Pulizia testo da tag HTML e entities (titoli/summary news, ecc.)."""
import re
from html import unescape


def clean_html(text: str | None) -> str:
    """
    Pulizia aggressiva: rimuove tutti i tag HTML, decodifica entities, normalizza spazi.
    Usare su title, summary, subtitle da feed RSS o scraping.
    """
    if not text or not isinstance(text, str):
        return ""
    # Rimuovi tutti i tag HTML (inclusi <p>, <meta>, <br>, <a>, etc.)
    s = re.sub(r"<[^>]+>", "", text)
    # Decodifica HTML entities
    s = unescape(s)
    # Rimuovi spazi multipli e newline
    s = re.sub(r"\s+", " ", s).strip()
    return s

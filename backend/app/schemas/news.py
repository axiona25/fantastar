"""Schema per API news (feed RSS e dettaglio articolo scrapato)."""
from datetime import datetime
from pydantic import BaseModel


class NewsItemResponse(BaseModel):
    id: int
    title: str
    summary: str | None
    url: str | None
    source: str | None
    image_url: str | None
    published_at: datetime | None

    class Config:
        from_attributes = True


class ArticleDetailResponse(BaseModel):
    """Risposta GET /news/article?url=... (contenuto scrapato)."""
    title: str
    subtitle: str
    author: str
    date: str
    image_url: str
    body_html: str

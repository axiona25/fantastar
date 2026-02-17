"""
API News: feed articoli da RSS (tabella news_articles, popolata da sync_news);
articolo singolo via scraping GET /news/article?url=...
Solo Serie A maschile: filtra per keyword include/esclude.
Titolo e summary in response vengono puliti da tag HTML (anche per dati già in DB).
"""
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.news_article import NewsArticle
from app.schemas.news import NewsItemResponse, ArticleDetailResponse
from app.services.article_scraper import fetch_article
from app.utils.html_utils import clean_html

router = APIRouter(prefix="/news", tags=["news"])

# Filtro Serie A maschile (stesso criterio di sync_news)
_NEWS_EXCLUDE = (
    "women", "femminile", "serie a women", "serie b", "serie c", "primavera",
)
_NEWS_INCLUDE = (
    "serie a", "campionato",
    "napoli", "inter", "milan", "juventus", "atalanta", "lazio", "roma",
    "fiorentina", "bologna", "torino", "genoa", "cagliari", "empoli", "como",
    "verona", "parma", "lecce", "venezia", "monza", "udinese",
)


def _is_serie_a_article(title: str | None, summary: str | None) -> bool:
    text = ((title or "") + " " + (summary or "")).lower()
    if any(ex in text for ex in _NEWS_EXCLUDE):
        return False
    return any(inc in text for inc in _NEWS_INCLUDE)


@router.get("", response_model=list[NewsItemResponse])
async def list_news(
    source: Annotated[str | None, Query(description="Filtro per fonte (es. Football Italia)")] = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
):
    """Lista articoli news Serie A maschile (più recenti prima). Opzionale filtro per source."""
    q = (
        select(NewsArticle)
        .order_by(NewsArticle.published_at.desc().nullslast(), NewsArticle.id.desc())
        .limit(limit * 2)
    )
    if source:
        q = q.where(NewsArticle.source == source)
    r = await db.execute(q)
    rows = r.scalars().all()
    filtered = [x for x in rows if _is_serie_a_article(x.title, x.summary)]
    # Pulisci title/summary da tag HTML (anche per articoli già in DB)
    return [
        NewsItemResponse(
            id=x.id,
            title=clean_html(x.title or ""),
            summary=clean_html(x.summary or "") if x.summary else None,
            url=x.url,
            source=x.source,
            image_url=x.image_url,
            published_at=x.published_at,
        )
        for x in filtered[:limit]
    ]


@router.get("/sources", response_model=list[str])
async def list_sources(db: Annotated[AsyncSession, Depends(get_db)] = None):
    """Elenco fonti distinte (per filtro)."""
    from sqlalchemy import distinct
    r = await db.execute(select(distinct(NewsArticle.source)).where(NewsArticle.source.isnot(None)).order_by(NewsArticle.source))
    return [row[0] for row in r.all() if row[0]]


@router.get("/article", response_model=ArticleDetailResponse)
async def get_article(
    url: Annotated[str, Query(description="URL dell'articolo da mostrare in-app")],
    db: Annotated[AsyncSession, Depends(get_db)] = None,
):
    """
    Scarica la pagina e estrae titolo, sottotitolo, autore, data, immagine, body HTML
    per visualizzazione in-app (scraping con BeautifulSoup).
    Se lo scraper trova un'immagine (og:image, twitter:image, prima img in article) e
    l'articolo nel DB ha image_url NULL, aggiorna il DB così la lista può mostrarla al prossimo caricamento.
    """
    if not url.strip().lower().startswith(("http://", "https://")):
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="URL must be http or https")
    url_stripped = url.strip()
    data = await fetch_article(url_stripped)
    # Fallback: se abbiamo trovato un'immagine dallo scraping, aggiorna l'articolo nel DB se non ne aveva
    if data.get("image_url"):
        r = await db.execute(select(NewsArticle).where(NewsArticle.url == url_stripped))
        article_row = r.scalar_one_or_none()
        if article_row and not article_row.image_url:
            article_row.image_url = data["image_url"][:1000]
            await db.commit()
    return ArticleDetailResponse(
        title=data["title"],
        subtitle=data["subtitle"],
        author=data["author"],
        date=data["date"],
        image_url=data["image_url"],
        body_html=data["body_html"],
    )

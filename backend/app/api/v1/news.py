"""
API News: feed articoli da RSS (tabella news_articles, popolata da sync_news);
articolo singolo via scraping GET /news/article?url=...
Se lo scraper trova un'immagine e l'articolo nel DB non ne ha, aggiorna image_url nel DB.
"""
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.news_article import NewsArticle
from app.schemas.news import NewsItemResponse, ArticleDetailResponse
from app.services.article_scraper import fetch_article

router = APIRouter(prefix="/news", tags=["news"])


@router.get("", response_model=list[NewsItemResponse])
async def list_news(
    source: Annotated[str | None, Query(description="Filtro per fonte (es. Football Italia)")] = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
):
    """Lista articoli news (più recenti prima). Opzionale filtro per source."""
    q = (
        select(NewsArticle)
        .order_by(NewsArticle.published_at.desc().nullslast(), NewsArticle.id.desc())
        .limit(limit)
    )
    if source:
        q = q.where(NewsArticle.source == source)
    r = await db.execute(q)
    rows = r.scalars().all()
    return [NewsItemResponse.model_validate(x) for x in rows]


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

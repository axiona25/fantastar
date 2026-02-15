from datetime import datetime
from sqlalchemy import String, Text, Integer, DateTime, Index, func
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class NewsArticle(Base):
    __tablename__ = "news_articles"
    __table_args__ = (
        Index("idx_news_published", "published_at"),
        Index("idx_news_source", "source"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    url: Mapped[str | None] = mapped_column(String(1000), unique=True, nullable=True)
    source: Mapped[str | None] = mapped_column(String(100), nullable=True)
    image_url: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    published_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    fetched_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

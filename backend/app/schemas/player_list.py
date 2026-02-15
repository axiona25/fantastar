"""Schema listone giocatori e scheda dettaglio (Task 08B)."""
from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from pydantic import BaseModel


class PlayerSeasonStats(BaseModel):
    """Statistiche stagione aggregate da player_stats."""
    appearances: int = 0
    goals: int = 0
    assists: int = 0
    yellow_cards: int = 0
    red_cards: int = 0
    clean_sheets: int = 0
    minutes_played: int = 0
    avg_rating: Optional[float] = None
    total_xg: Optional[float] = None
    total_xa: Optional[float] = None
    avg_fantasy_score: Optional[float] = None
    total_fantasy_score: Optional[float] = None


class PlayerListResponse(BaseModel):
    """Riga listone con quotazione e statistiche."""
    id: int
    name: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    position: str
    shirt_number: Optional[int] = None
    nationality: Optional[str] = None
    real_team_id: int
    real_team_name: str
    real_team_short: Optional[str] = None
    real_team_badge: Optional[str] = None
    photo_url: Optional[str] = None
    cutout_url: Optional[str] = None
    initial_price: float
    current_value: Optional[float] = None
    season_stats: Optional[PlayerSeasonStats] = None
    is_available: bool = True
    owned_by: Optional[str] = None

    class Config:
        from_attributes = True


class PlayerListPaginated(BaseModel):
    players: list[PlayerListResponse]
    total: int
    page: int
    page_size: int
    total_pages: int


class PlayerMatchStat(BaseModel):
    match_id: int
    matchday: int
    opponent: str
    date: Optional[datetime] = None
    minutes_played: int
    goals: int
    assists: int
    rating: Optional[float] = None
    xg: Optional[float] = None
    xa: Optional[float] = None
    key_passes: Optional[int] = None


class PlayerFantasyScore(BaseModel):
    matchday: int
    score: float
    events: list[str] = []


class NextMatch(BaseModel):
    matchday: int
    opponent_name: str
    opponent_badge: Optional[str] = None
    date: Optional[datetime] = None
    home_away: str


class PlayerDetailResponse(PlayerListResponse):
    """Scheda completa giocatore con dettagli fisici e biografia."""
    date_of_birth: Optional[str] = None  # ISO date "1999-03-15"
    age: Optional[int] = None
    height: Optional[str] = None  # es. "1.85 m"
    weight: Optional[str] = None  # es. "78 kg"
    birth_place: Optional[str] = None
    description: Optional[str] = None  # biografia
    position_detail: Optional[str] = None  # es. "Centre-Back"
    match_stats: list[PlayerMatchStat] = []
    fantasy_scores: list[PlayerFantasyScore] = []
    next_matches: list[NextMatch] = []

"""
Schema Pydantic per Leghe fantasy.
"""
from datetime import datetime
from decimal import Decimal
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, Field, model_validator


class LeagueCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    logo: Optional[str] = Field(default="trophy", max_length=50, description="Nome icona/logo lega (default: trophy)")
    league_type: Literal["public", "private"] = Field(default="private", description="public=mercato libero, private=asta")
    max_teams: int = Field(default=10, ge=2, le=20)
    max_members: Optional[int] = Field(None, ge=2, le=20, description="Obbligatorio se league_type=private (2-20)")
    budget: Decimal = Field(default=Decimal("500"), ge=Decimal("0"))
    invite_code: Optional[str] = Field(None, max_length=20)

    @model_validator(mode="after")
    def private_requires_max_members(self):
        if self.league_type == "private":
            if self.max_members is None:
                raise ValueError("Per leghe private max_members è obbligatorio")
            if self.max_members < 2 or self.max_members > 20:
                raise ValueError("Il numero di partecipanti deve essere tra 2 e 20")
        return self


class LeagueJoin(BaseModel):
    invite_code: str = Field(..., min_length=1, max_length=20)


class LeagueResponse(BaseModel):
    id: UUID
    name: str
    logo: str = "trophy"
    admin_user_id: Optional[UUID] = None
    invite_code: Optional[str] = None
    max_teams: int
    league_type: str = "private"
    max_members: Optional[int] = None
    budget: Decimal
    scoring_type: str
    status: str
    season: str
    goal_threshold: Decimal
    goal_step: Decimal
    created_at: datetime
    display_name: Optional[str] = None  # per leghe figlie: nome della lega root (es. "Fantastar Public")

    class Config:
        from_attributes = True


class LeagueDetailResponse(LeagueResponse):
    team_count: Optional[int] = None


class StandingRow(BaseModel):
    rank: int
    fantasy_team_id: UUID
    team_name: str
    user_id: UUID
    total_points: int
    wins: int
    draws: int
    losses: int
    goals_for: int
    goals_against: int


class CalendarMatchRow(BaseModel):
    """Partita del calendario fantasy (per GET calendar)."""
    matchday: int
    home_team_name: str
    away_team_name: str


class MatchdayResultRow(BaseModel):
    """Risultato di una partita fantasy nella giornata (risultati e pagelle)."""
    home_team_id: UUID
    away_team_id: UUID
    home_team_name: str
    away_team_name: str
    home_score: float
    away_score: float
    home_goals: int
    away_goals: int
    home_result: str  # W, D, L
    away_result: str


class LeagueMemberRow(BaseModel):
    """Membro della lega (GET /leagues/{id}/members)."""
    user_id: UUID
    name: str
    role: str  # admin | member
    status: str  # active | blocked | kicked
    budget: Decimal
    roster_count: int
    joined_at: datetime


class LeagueBlockRequest(BaseModel):
    """Body opzionale per POST .../members/{user_id}/block."""
    reason: Optional[str] = None

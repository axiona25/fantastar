"""
Schema Pydantic per Squadre fantasy e formazioni.
"""
from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


class TeamCreate(BaseModel):
    league_id: UUID
    name: str = Field(..., min_length=1, max_length=100)
    logo_url: Optional[str] = None
    coach_name: Optional[str] = None
    coach_avatar_url: Optional[str] = None


class TeamResponse(BaseModel):
    id: UUID
    league_id: UUID
    user_id: UUID
    name: str
    logo_url: Optional[str] = None
    coach_name: Optional[str] = None
    coach_avatar_url: Optional[str] = None
    is_configured: bool = False
    budget_remaining: Decimal
    total_points: int
    wins: int
    draws: int
    losses: int
    goals_for: int
    goals_against: int
    created_at: datetime

    class Config:
        from_attributes = True


class RosterPlayerResponse(BaseModel):
    player_id: int
    player_name: str
    position: str
    purchase_price: Optional[Decimal] = None
    real_team_name: Optional[str] = None
    photo_url: Optional[str] = None
    cutout_url: Optional[str] = None


class TeamDetailResponse(TeamResponse):
    roster: list[RosterPlayerResponse] = []


# Moduli ammessi: (dif, cen, att) -> 1 POR + dif + cen + att = 11 titolari
VALID_FORMATIONS = {
    "3-4-3": (3, 4, 3),
    "3-5-2": (3, 5, 2),
    "4-3-3": (4, 3, 3),
    "4-4-2": (4, 4, 2),
    "4-5-1": (4, 5, 1),
    "5-3-2": (5, 3, 2),
    "5-4-1": (5, 4, 1),
}


class LineupSlot(BaseModel):
    player_id: int
    position_slot: str  # POR, DIF1, DIF2, ... CEN1, ... ATT1, B1, B2, ...
    is_starter: bool = True
    bench_order: Optional[int] = None


class LineupSet(BaseModel):
    formation: str = Field(..., min_length=5, max_length=7)
    slots: list[LineupSlot] = Field(..., min_length=1)

    @field_validator("formation")
    @classmethod
    def formation_allowed(cls, v: str) -> str:
        if v not in VALID_FORMATIONS:
            raise ValueError("Formation must be one of: 3-4-3, 3-5-2, 4-3-3, 4-4-2, 4-5-1, 5-3-2, 5-4-1")
        return v


class LineupResponse(BaseModel):
    fantasy_team_id: UUID
    matchday: int
    formation: Optional[str] = None
    starters: list[LineupSlot] = []
    bench: list[LineupSlot] = []


class LineupWarning(BaseModel):
    """Avviso disponibilità in formazione (Task 06B)."""
    player_id: int
    player_name: str
    level: str  # red, orange
    message: str
    suggestion: str


class LineupSetResponse(BaseModel):
    """Risposta POST lineup con eventuali warnings (non blocca il salvataggio)."""
    message: str = "Formazione salvata"
    fantasy_team_id: Optional[UUID] = None
    matchday: Optional[int] = None
    formation: Optional[str] = None
    starters: int = 11
    bench: int = 0
    warnings: list[LineupWarning] = []
    unavailable_count: int = 0


class PlayerAvailabilityItem(BaseModel):
    """Stato disponibilità singolo giocatore per schermata formazione."""
    player_id: int
    name: str
    position: str
    status: str
    icon: str
    detail: Optional[str] = None

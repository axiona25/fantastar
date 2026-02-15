"""Schema Pydantic per asta lega (modulo session-based)."""
from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


# Limiti ruolo per squadra (max in rosa): 25 totali, POR 3, DIF 8, CEN 8, ATT 6
ROLE_LIMITS = {"POR": 3, "DIF": 8, "CEN": 8, "ATT": 6}
TOTAL_ROSTER_LIMIT = 25


# --- Session-based API ---


class AuctionStartRequest(BaseModel):
    """Body per avvio sessione asta (POST /auction/start). Nessun body richiesto."""
    pass


class AuctionStartResponse(BaseModel):
    """Risposta avvio sessione asta (POST /auction/start)."""
    message: str
    session_id: int
    status: str = "active"


class AuctionNominateRequest(BaseModel):
    """Admin nomina il giocatore all'asta (POST /auction/nominate)."""
    player_id: int = Field(..., gt=0)


class AuctionNominateResponse(BaseModel):
    """Risposta nomina giocatore."""
    message: str
    player_id: int
    player_name: str
    position: str
    real_team_name: Optional[str] = None
    base_price: Decimal
    timer_remaining: int


class AuctionBidRequest(BaseModel):
    """Offerta (crediti). Incremento minimo 1 (POST /auction/bid)."""
    amount: Decimal = Field(..., ge=Decimal("1"))


class AuctionBidResponse(BaseModel):
    """Risposta dopo offerta."""
    message: str
    amount: Decimal
    is_leading: bool
    timer_remaining: int


# GET /auction/status
class AuctionStatusCurrentPlayer(BaseModel):
    id: int
    name: str
    role: str
    team: Optional[str] = None
    photo_url: Optional[str] = None
    cutout_url: Optional[str] = None
    base_price: Decimal


class AuctionStatusCurrentBid(BaseModel):
    amount: Decimal
    bidder: str
    bidder_id: UUID


class AuctionStatusParticipant(BaseModel):
    id: UUID
    name: str
    budget: Decimal
    roster_count: int
    can_bid: bool
    current_role_completed: Optional[int] = None  # nella categoria corrente
    current_role_required: Optional[int] = None


class AuctionStatusCategoryProgress(BaseModel):
    """Progresso categoria corrente per un utente."""
    completed: int
    required: int


class AuctionStatusResponse(BaseModel):
    """Stato asta (GET /auction/status)."""
    status: str  # idle | active | paused | completed
    current_player: Optional[AuctionStatusCurrentPlayer] = None
    current_bid: Optional[AuctionStatusCurrentBid] = None
    timer_remaining: Optional[int] = None  # secondi rimanenti, null se nessun giocatore in corso
    eligible_bidders: list[UUID] = []  # user_id che possono ancora fare offerte
    participants: list[AuctionStatusParticipant] = []
    # Turni per categoria
    current_category: Optional[str] = None  # POR | DIF | CEN | ATT
    current_turn_user_id: Optional[UUID] = None
    current_turn_user_name: Optional[str] = None
    category_progress: Optional[dict[str, AuctionStatusCategoryProgress]] = None  # user_id -> {completed, required}
    is_my_turn: Optional[bool] = None
    is_only_one_left_in_category: Optional[bool] = None  # true = sei l'unico ancora da completare → acquisto diretto


class AuctionExpireResponse(BaseModel):
    """Risposta dopo scadenza timer / assegnazione."""
    message: str
    player_id: int
    player_name: str
    winner_id: UUID
    winner_name: str
    final_price: Decimal


class AuctionPauseResponse(BaseModel):
    message: str
    status: str = "paused"


class AuctionStopResponse(BaseModel):
    message: str
    status: str = "completed"


# Legacy / compat (GET current, history)
class AuctionCurrentResponse(BaseModel):
    """Giocatore corrente all'asta (GET current) - compat."""
    player_id: int
    player_name: str
    position: str
    real_team_name: Optional[str] = None
    highest_bid: Decimal
    highest_bidder_team_id: Optional[UUID] = None
    highest_bidder_team_name: Optional[str] = None
    ends_at: datetime
    seconds_remaining: int
    round_number: Optional[int] = None


class AuctionCurrentEmptyResponse(BaseModel):
    """Nessuna asta attiva."""
    active: bool = False
    message: str = "Nessuna asta in corso"


class AuctionAssignResponse(BaseModel):
    """Risposta assegnazione giocatore (admin)."""
    message: str
    player_id: int
    player_name: str
    fantasy_team_id: UUID
    team_name: str
    amount: Decimal


class AuctionHistoryItem(BaseModel):
    """Voce storico acquisti."""
    player_id: int
    player_name: str
    position: str
    fantasy_team_id: UUID
    team_name: str
    amount: Decimal
    purchased_at: datetime


class AuctionHistoryResponse(BaseModel):
    """Storico acquisti asta (tutti i round)."""
    items: list[AuctionHistoryItem]

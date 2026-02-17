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
    real_team_logo_url: Optional[str] = None
    real_team_short_name: Optional[str] = None


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


# --- Asta Random (busta chiusa) ---


class AuctionConfigureRequest(BaseModel):
    """Body per configurazione asta (POST /auction/configure). Rosa + opzionali classica/busta chiusa."""
    # Rosa (comuni)
    budget_per_team: int = Field(500, ge=1)
    max_roster_size: int = Field(25, ge=11)
    min_goalkeepers: int = Field(3, ge=1)
    min_defenders: int = Field(8, ge=1)
    min_midfielders: int = Field(8, ge=1)
    min_attackers: int = Field(6, ge=1)
    base_price: int = Field(1, ge=0)
    # Busta chiusa
    players_per_turn_p: int = Field(3, ge=1, description="Portieri per turno")
    players_per_turn_d: int = Field(5, ge=1, description="Difensori per turno")
    players_per_turn_c: int = Field(5, ge=1, description="Centrocampisti per turno")
    players_per_turn_a: int = Field(3, ge=1, description="Attaccanti per turno")
    turn_duration_hours: int = Field(24, ge=1, le=168)
    rounds_count: Optional[int] = Field(3, ge=1)
    reveal_bids: Optional[bool] = False
    allow_same_player_bids: Optional[bool] = True
    max_bids_per_round: Optional[int] = Field(5, ge=1)
    tie_breaker: Optional[str] = Field("budget", description="budget | random")
    # Classica (rilancio)
    bid_timer_seconds: Optional[int] = Field(60, ge=10, le=300)
    min_raise: Optional[int] = Field(1, ge=0)
    call_order: Optional[str] = Field("random", description="random | round_robin | snake")
    allow_nomination: Optional[bool] = True
    pause_between_players: Optional[int] = Field(10, ge=0)


class AuctionConfigureResponse(BaseModel):
    config_id: int
    status: str = "pending"
    message: str = "Configurazione salvata."


class AuctionConfigGetResponse(BaseModel):
    """Risposta GET /auction/config: lega + config (null se non esiste)."""
    league_id: UUID
    auction_type: str = "classic"
    asta_started: bool = False
    config: Optional[dict] = None


class AuctionRandomStartResponse(BaseModel):
    status: str = "active"
    config_id: int
    first_turn_id: Optional[int] = None
    expires_at: Optional[str] = None


class AuctionCurrentTurnPlayer(BaseModel):
    auction_turn_player_id: int
    player_id: int
    name: str
    position: str
    real_team: Optional[str] = None
    initial_price: float
    photo_url: Optional[str] = None
    cutout_url: Optional[str] = None
    my_bid: Optional[int] = None


class AuctionCurrentTurnResponse(BaseModel):
    turn_id: int
    turn_number: int
    role: str
    expires_at: str
    seconds_remaining: int
    players: list[AuctionCurrentTurnPlayer]
    my_budget_remaining: Optional[float] = None
    config_budget: int = 500


class AuctionRandomBidRequest(BaseModel):
    player_id: int = Field(..., gt=0)
    amount: int = Field(..., ge=1)


class AuctionRandomBidResponse(BaseModel):
    message: str
    player_id: int
    amount: int


class AuctionTurnResultBid(BaseModel):
    amount: int
    username: str


class AuctionTurnResultPlayer(BaseModel):
    player_id: int
    player_name: str
    position: str
    real_team: Optional[str] = None
    winner_team_name: Optional[str] = None
    winner_username: Optional[str] = None
    winning_bid: int
    status: str
    all_bids: list[AuctionTurnResultBid]


class AuctionTurnResultsResponse(BaseModel):
    turn_id: int
    turn_number: int
    role: str
    completed_at: Optional[str] = None
    results: list[AuctionTurnResultPlayer]


class AuctionRandomStatusTeam(BaseModel):
    team_id: str
    team_name: str
    username: Optional[str] = None
    budget_remaining: float
    roster_size: int


class AuctionRandomStatusResponse(BaseModel):
    config_id: int
    status: str
    current_role: str
    current_turn: int
    teams: list[AuctionRandomStatusTeam]
    active_turn: Optional[dict] = None

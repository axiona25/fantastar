"""
API Asta (modulo session-based).
POST start, nominate, bid, GET status, POST expire (admin), pause, stop.
Compat: GET current, GET history.
"""
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.league import FantasyLeague
from app.models.fantasy_team import FantasyTeam
from app.schemas.auction import (
    AuctionStartResponse,
    AuctionNominateRequest,
    AuctionNominateResponse,
    AuctionBidRequest,
    AuctionBidResponse,
    AuctionStatusResponse,
    AuctionStatusCurrentPlayer,
    AuctionStatusCurrentBid,
    AuctionStatusParticipant,
    AuctionExpireResponse,
    AuctionPauseResponse,
    AuctionStopResponse,
    AuctionCurrentResponse,
    AuctionCurrentEmptyResponse,
    AuctionHistoryItem,
    AuctionHistoryResponse,
)
from app.dependencies import get_current_user
from app.services.auction_service import (
    start_session,
    get_active_session,
    nominate,
    place_bid,
    get_status,
    _do_expire,
    _cancel_expire,
    pause_session,
    stop_session,
    get_current,
    get_history,
)
from app.services.push_service import send_push_to_users
from app.api.websocket import broadcast_auction_update

router = APIRouter(prefix="/leagues/{league_id}/auction", tags=["auction"])


async def _require_league_member(
    league_id: UUID, user: User, db: AsyncSession
) -> FantasyLeague:
    r = await db.execute(select(FantasyLeague).where(FantasyLeague.id == league_id, FantasyLeague.is_active == True))
    league = r.scalar_one_or_none()
    if not league:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Questa lega non esiste più")
    return league


async def _require_admin(league_id: UUID, user: User, db: AsyncSession) -> FantasyLeague:
    league = await _require_league_member(league_id, user, db)
    if league.admin_user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Solo l'admin della lega può eseguire questa azione")
    return league


def _require_private_league(league: FantasyLeague) -> None:
    """Raises 400 if league is public (asta solo per leghe private)."""
    if getattr(league, "league_type", "private") != "private":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="L'asta non è disponibile per leghe pubbliche",
        )


@router.post("/start", response_model=AuctionStartResponse)
async def auction_start(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Avvia sessione d'asta (solo admin, solo leghe private). Crea session con status=active."""
    league = await _require_admin(league_id, current_user, db)
    _require_private_league(league)
    try:
        out = await start_session(db, league_id, current_user.id)
        await broadcast_auction_update(league_id, "auction_started", {"session_id": out["session_id"], "status": out["status"]})
        return AuctionStartResponse(**out)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post("/nominate", response_model=AuctionNominateResponse)
async def auction_nominate(
    league_id: UUID,
    body: AuctionNominateRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Chi ha il turno nomina il giocatore (categoria corrente). Solo leghe private."""
    league = await _require_league_member(league_id, current_user, db)
    _require_private_league(league)
    try:
        out = await nominate(db, league_id, body.player_id, current_user.id)
        await broadcast_auction_update(
            league_id, "nominate",
            {
                "player_id": out["player_id"],
                "player_name": out["player_name"],
                "position": out["position"],
                "base_price": float(out["base_price"]),
                "timer_remaining": out["timer_remaining"],
            },
        )
        r = await db.execute(select(FantasyTeam.user_id).where(FantasyTeam.league_id == league_id).distinct())
        user_ids = [row[0] for row in r.all()]
        if user_ids:
            nominator_name = current_user.full_name or current_user.username or "Un giocatore"
            msg = f"⚽ {nominator_name} ha messo all'asta {out['player_name']} ({out['position']}) - Base: {out['base_price']:.0f} cr. Hai 60 secondi per rilanciare!"
            await send_push_to_users(db, user_ids, "Asta", msg)
        return AuctionNominateResponse(**out)
    except ValueError as e:
        msg = str(e)
        if msg.strip() == "Non è il tuo turno":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=msg)
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=msg)


@router.post("/bid", response_model=AuctionBidResponse)
async def auction_bid(
    league_id: UUID,
    body: AuctionBidRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Fai un'offerta. Solo leghe private. Verifica budget e limiti rosa. Resetta timer a 60s."""
    league = await _require_league_member(league_id, current_user, db)
    _require_private_league(league)
    try:
        out = await place_bid(db, league_id, current_user.id, body.amount)
        return AuctionBidResponse(
            message=out["message"],
            amount=out["amount"],
            is_leading=out["is_leading"],
            timer_remaining=out["timer_remaining"],
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.get("/status", response_model=AuctionStatusResponse)
async def auction_status(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Stato asta: status, current_player, current_bid, timer_remaining, participants, turni (categoria, turno, is_my_turn)."""
    await _require_league_member(league_id, current_user, db)
    data = await get_status(db, league_id, current_user.id)
    current_player = None
    if data.get("current_player"):
        cp = data["current_player"]
        current_player = AuctionStatusCurrentPlayer(
            id=cp["id"],
            name=cp["name"],
            role=cp["role"],
            team=cp.get("team"),
            photo_url=cp.get("photo_url"),
            cutout_url=cp.get("cutout_url"),
            base_price=cp["base_price"],
        )
    current_bid = None
    if data.get("current_bid"):
        cb = data["current_bid"]
        current_bid = AuctionStatusCurrentBid(amount=cb["amount"], bidder=cb["bidder"], bidder_id=cb["bidder_id"])
    participants = [AuctionStatusParticipant(**p) for p in data.get("participants", [])]
    return AuctionStatusResponse(
        status=data["status"],
        current_player=current_player,
        current_bid=current_bid,
        timer_remaining=data.get("timer_remaining"),
        eligible_bidders=data.get("eligible_bidders", []),
        participants=participants,
        current_category=data.get("current_category"),
        current_turn_user_id=data.get("current_turn_user_id"),
        current_turn_user_name=data.get("current_turn_user_name"),
        category_progress=data.get("category_progress"),
        is_my_turn=data.get("is_my_turn"),
        is_only_one_left_in_category=data.get("is_only_one_left_in_category"),
    )


@router.post("/expire", response_model=AuctionExpireResponse)
async def auction_expire(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Forza scadenza timer e assegna il giocatore (solo admin, solo leghe private). Chiamato anche dal timer server."""
    league = await _require_admin(league_id, current_user, db)
    _require_private_league(league)
    session = await get_active_session(db, league_id)
    if not session:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nessuna asta attiva")
    try:
        _cancel_expire(session.id)
        out = await _do_expire(db, session.id)
        if not out:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nessuna offerta valida; asta chiusa senza assegnazione")
        return AuctionExpireResponse(
            message="Giocatore aggiudicato",
            player_id=out["player_id"],
            player_name=out["player_name"],
            winner_id=out["winner_id"],
            winner_name=out["winner_name"],
            final_price=out["final_price"],
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post("/pause", response_model=AuctionPauseResponse)
async def auction_pause(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Mette in pausa l'asta (solo admin, solo leghe private)."""
    league = await _require_admin(league_id, current_user, db)
    _require_private_league(league)
    try:
        out = await pause_session(db, league_id, current_user.id)
        return AuctionPauseResponse(**out)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post("/stop", response_model=AuctionStopResponse)
async def auction_stop(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Termina la sessione d'asta (solo admin, solo leghe private)."""
    league = await _require_admin(league_id, current_user, db)
    _require_private_league(league)
    try:
        out = await stop_session(db, league_id, current_user.id)
        return AuctionStopResponse(**out)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


# --- Compat: GET current (legacy), GET history ---

@router.get("/current", response_model=AuctionCurrentResponse | AuctionCurrentEmptyResponse)
async def auction_current(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Giocatore corrente all'asta (formato legacy)."""
    await _require_league_member(league_id, current_user, db)
    out = await get_current(db, league_id)
    if not out:
        return AuctionCurrentEmptyResponse(message="Nessuna asta in corso")
    return AuctionCurrentResponse(**out)


@router.get("/history", response_model=AuctionHistoryResponse)
async def auction_history(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Storico acquisti asta (tutte le squadre della lega)."""
    await _require_league_member(league_id, current_user, db)
    items = await get_history(db, league_id)
    return AuctionHistoryResponse(items=[AuctionHistoryItem(**x) for x in items])

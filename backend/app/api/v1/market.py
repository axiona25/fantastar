"""API Mercato: svincolati, acquisto, rilascio, scambi."""
from decimal import Decimal
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.league import FantasyLeague
from app.models.fantasy_team import FantasyTeam
from app.models.real_team import RealTeam
from app.schemas.player_list import PlayerListResponse, PlayerListPaginated
from app.dependencies import get_current_user
from app.services.market_service import (
    get_free_agents,
    buy_free_agent,
    release_player,
    propose_trade,
    respond_to_trade,
)
from app.services.player_list_service import get_players_paginated
from app.services.push_service import send_push_to_users

router = APIRouter(prefix="/leagues/{league_id}/market", tags=["market"])


async def _require_league_member(league_id: UUID, user: User, db: AsyncSession) -> FantasyLeague:
    r = await db.execute(select(FantasyLeague).where(FantasyLeague.id == league_id, FantasyLeague.is_active == True))
    league = r.scalar_one_or_none()
    if not league:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Questa lega non esiste più")
    return league


@router.get("/free-agents", response_model=PlayerListPaginated)
async def market_free_agents(
    league_id: UUID,
    role: str | None = Query(None, description="Ruolo: POR, DIF, CEN, ATT"),
    team_id: int | None = Query(None, description="ID squadra Serie A (real_team_id)"),
    search: str | None = Query(None, description="Ricerca per nome giocatore"),
    page: int = Query(1, ge=1),
    page_size: int = Query(30, ge=1, le=100),
    current_user: Annotated[User, Depends(get_current_user)] = None,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
):
    """Giocatori svincolati nella lega. Filtri: role, team_id, search."""
    await _require_league_member(league_id, current_user, db)
    position = role.upper()[:3] if role else None
    players_list, total = await get_players_paginated(
        db,
        position=position,
        team_id=team_id,
        search=search,
        available_only=True,
        league_id=league_id,
        page=page,
        page_size=page_size,
    )
    total_pages = (total + page_size - 1) // page_size if page_size else 0
    return PlayerListPaginated(players=players_list, total=total, page=page, page_size=page_size, total_pages=total_pages)


@router.get("/teams")
async def market_teams(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)] = None,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
):
    """Lista squadre Serie A (id, name, short_name) per filtro mercato."""
    await _require_league_member(league_id, current_user, db)
    r = await db.execute(select(RealTeam.id, RealTeam.name, RealTeam.short_name).order_by(RealTeam.name))
    return [{"id": row[0], "name": row[1], "short_name": row[2]} for row in r.all()]


@router.post("/buy")
async def market_buy(
    league_id: UUID,
    body: dict,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Acquista giocatore svincolato. Body: {"player_id": int, "price": float (opzionale, default quotazione)}."""
    await _require_league_member(league_id, current_user, db)
    player_id = body.get("player_id")
    if player_id is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="player_id required")
    price = body.get("price")
    if price is not None:
        try:
            price = float(price)
        except (TypeError, ValueError):
            price = None
    r = await db.execute(
        select(FantasyTeam.id).where(FantasyTeam.league_id == league_id, FantasyTeam.user_id == current_user.id)
    )
    row = r.one_or_none()
    if not row:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nessuna squadra in questa lega")
    team_id = row[0]
    try:
        out = await buy_free_agent(
            db, league_id, team_id, int(player_id),
            price=Decimal(str(price)) if price is not None else None,
        )
        return out
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post("/release")
async def market_release(
    league_id: UUID,
    body: dict,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Rilascia un giocatore (rimborso 50%). Body: {"player_id": int}."""
    await _require_league_member(league_id, current_user, db)
    player_id = body.get("player_id")
    if player_id is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="player_id required")
    r = await db.execute(
        select(FantasyTeam.id).where(FantasyTeam.league_id == league_id, FantasyTeam.user_id == current_user.id)
    )
    row = r.one_or_none()
    if not row:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nessuna squadra in questa lega")
    team_id = row[0]
    try:
        out = await release_player(db, league_id, team_id, int(player_id))
        return out
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post("/trade-propose")
async def market_trade_propose(
    league_id: UUID,
    body: dict,
  current_user: Annotated[User, Depends(get_current_user)],
  db: Annotated[AsyncSession, Depends(get_db)],
):
    """Proponi scambio. Body: {"to_team_id": "uuid", "offer_player_ids": [1,2], "request_player_ids": [3]}."""
    await _require_league_member(league_id, current_user, db)
    to_team_id = body.get("to_team_id")
    offer_player_ids = body.get("offer_player_ids") or []
    request_player_ids = body.get("request_player_ids") or []
    if not to_team_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="to_team_id required")
    r = await db.execute(
        select(FantasyTeam.id).where(FantasyTeam.league_id == league_id, FantasyTeam.user_id == current_user.id)
    )
    row = r.one_or_none()
    if not row:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nessuna squadra in questa lega")
    from_team_id = row[0]
    try:
        out = await propose_trade(
            db, league_id, from_team_id, UUID(str(to_team_id)), offer_player_ids, request_player_ids
        )
        # Push: notifica il destinatario dello scambio
        try:
            r_to = await db.execute(
                select(FantasyTeam.user_id).where(FantasyTeam.id == UUID(str(to_team_id)))
            )
            to_user_id = r_to.scalar_one_or_none()
            if to_user_id and to_user_id[0]:
                await send_push_to_users(
                    db, [to_user_id[0]],
                    "Nuova proposta di scambio",
                    "Hai ricevuto una proposta di scambio. Apri l'app per rispondere.",
                )
        except Exception:
            pass
        return out
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.get("/trades")
async def market_trades(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Lista proposte di scambio (inviate e ricevute)."""
    await _require_league_member(league_id, current_user, db)
    from app.models.trade_proposal import TradeProposal
    r = await db.execute(
        select(FantasyTeam.id).where(FantasyTeam.league_id == league_id, FantasyTeam.user_id == current_user.id)
    )
    row = r.one_or_none()
    if not row:
        return {"sent": [], "received": []}
    my_team_id = row[0]
    r2 = await db.execute(
        select(TradeProposal).where(
            TradeProposal.league_id == league_id,
            (TradeProposal.from_team_id == my_team_id) | (TradeProposal.to_team_id == my_team_id),
        ).order_by(TradeProposal.created_at.desc())
    )
    rows = r2.scalars().all()
    sent = [{"id": t.id, "to_team_id": str(t.to_team_id), "offer_player_ids": t.offer_player_ids, "request_player_ids": t.request_player_ids, "status": t.status} for t in rows if t.from_team_id == my_team_id]
    received = [{"id": t.id, "from_team_id": str(t.from_team_id), "offer_player_ids": t.offer_player_ids, "request_player_ids": t.request_player_ids, "status": t.status} for t in rows if t.to_team_id == my_team_id]
    return {"sent": sent, "received": received}


@router.post("/trade-respond")
async def market_trade_respond(
    league_id: UUID,
    body: dict,
  current_user: Annotated[User, Depends(get_current_user)],
  db: Annotated[AsyncSession, Depends(get_db)],
):
    """Accetta o rifiuta proposta. Body: {"trade_id": int, "accept": bool}."""
    await _require_league_member(league_id, current_user, db)
    trade_id = body.get("trade_id")
    accept = body.get("accept", False)
    if trade_id is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="trade_id required")
    r = await db.execute(
        select(FantasyTeam.id).where(FantasyTeam.league_id == league_id, FantasyTeam.user_id == current_user.id)
    )
    row = r.one_or_none()
    if not row:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nessuna squadra in questa lega")
    to_team_id = row[0]
    try:
        out = await respond_to_trade(db, int(trade_id), to_team_id, accept)
        # Push (se accettato): notifica chi ha proposto lo scambio
        if accept:
            try:
                from app.models.trade_proposal import TradeProposal
                r_t = await db.execute(select(TradeProposal.from_team_id).where(TradeProposal.id == int(trade_id)))
                from_team_id_row = r_t.one_or_none()
                if from_team_id_row:
                    r_u = await db.execute(select(FantasyTeam.user_id).where(FantasyTeam.id == from_team_id_row[0]))
                    from_user_id = r_u.scalar_one_or_none()
                    if from_user_id and from_user_id[0]:
                        await send_push_to_users(
                            db, [from_user_id[0]],
                            "Scambio accettato",
                            "La tua proposta di scambio è stata accettata!",
                        )
            except Exception:
                pass
        return out
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

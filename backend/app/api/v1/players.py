"""API Giocatori: listone, scheda dettaglio, impostazione disponibilità (admin)."""
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.league import FantasyLeague
from app.models.player import Player
from app.schemas.player_availability import PlayerAvailabilitySet
from app.schemas.player_list import PlayerListResponse, PlayerListPaginated, PlayerDetailResponse
from app.dependencies import get_current_user
from app.services.availability_service import AvailabilityService
from app.services.player_list_service import get_players_paginated, get_player_detail

router = APIRouter(prefix="/players", tags=["players"])


async def _require_availability_admin(user: User, db: AsyncSession) -> None:
    """L'utente deve essere admin di almeno una lega o admin app."""
    if getattr(user, "is_admin", False):
        return
    r = await db.execute(select(FantasyLeague.id).where(FantasyLeague.admin_user_id == user.id))
    if r.scalar_one_or_none():
        return
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Solo l'admin della lega o l'admin app può impostare la disponibilità manualmente",
    )


@router.get("", response_model=PlayerListPaginated)
async def list_players(
    db: Annotated[AsyncSession, Depends(get_db)],
    position: str | None = Query(None, description="Filtro ruolo: POR, DIF, CEN, ATT"),
    team_id: int | None = Query(None, description="Filtro squadra reale"),
    search: str | None = Query(None, description="Cerca per nome"),
    sort_by: str = Query("name", description="name, initial_price"),
    sort_order: str = Query("asc", description="asc, desc"),
    min_price: float | None = None,
    max_price: float | None = None,
    available_only: bool = Query(False, description="Solo non acquistati nella lega"),
    league_id: UUID | None = Query(None, description="Per disponibilità/owned_by"),
    page: int = Query(1, ge=1),
    page_size: int = Query(30, ge=1, le=100),
):
    """Listone giocatori Serie A con quotazioni e statistiche stagione."""
    players_list, total = await get_players_paginated(
        db,
        position=position,
        team_id=team_id,
        search=search,
        sort_by=sort_by,
        sort_order=sort_order,
        min_price=min_price,
        max_price=max_price,
        available_only=available_only,
        league_id=league_id,
        page=page,
        page_size=page_size,
    )
    total_pages = (total + page_size - 1) // page_size if page_size else 0
    return PlayerListPaginated(
        players=players_list,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


@router.get("/{player_id}", response_model=PlayerDetailResponse)
async def get_player(
    player_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    league_id: UUID | None = Query(None),
):
    """Scheda completa giocatore: info, statistiche stagione, ultime partite, punteggi fantasy, prossime partite."""
    detail = await get_player_detail(db, player_id, league_id=league_id)
    if not detail:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Player not found")
    return detail


@router.put("/{player_id}/availability")
async def set_player_availability(
    player_id: int,
    body: PlayerAvailabilitySet,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Imposta manualmente stato disponibilità di un giocatore (solo admin lega o app admin)."""
    await _require_availability_admin(current_user, db)
    r = await db.execute(select(Player.id).where(Player.id == player_id))
    if not r.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Player not found")
    service = AvailabilityService(db)
    await service.manually_set_availability(
        player_id=player_id,
        status=body.status,
        detail=body.detail,
        return_date=body.return_date,
    )
    return {"message": "Disponibilità aggiornata", "player_id": player_id, "status": body.status}

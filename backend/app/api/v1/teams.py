"""
API Squadre fantasy: create, detail con rosa, GET/POST lineup per giornata.
"""
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.league import FantasyLeague
from app.models.fantasy_team import FantasyTeam
from app.models.fantasy_roster import FantasyRoster
from app.models.fantasy_lineup import FantasyLineup
from app.models.player import Player
from app.models.real_team import RealTeam
from app.schemas.team import (
    TeamCreate,
    TeamResponse,
    TeamDetailResponse,
    RosterPlayerResponse,
    LineupSet,
    LineupResponse,
    LineupSlot,
    LineupSetResponse,
    LineupWarning,
    PlayerAvailabilityItem,
    VALID_FORMATIONS,
)
from app.dependencies import get_current_user
from app.services.availability_service import AvailabilityService

router = APIRouter(prefix="/teams", tags=["teams"])


def _validate_lineup_slots(formation: str, slots: list[LineupSlot], player_positions: dict[int, str]) -> str | None:
    """Ritorna None se ok, altrimenti messaggio errore. Verifica 1 POR, numeri DIF/CEN/ATT per formazione."""
    dif, cen, att = VALID_FORMATIONS[formation]
    starters = [s for s in slots if s.is_starter]
    bench = [s for s in slots if not s.is_starter]
    if len(starters) != 11:
        return "Exactly 11 starters required"
    por = sum(1 for s in starters if player_positions.get(s.player_id) == "POR")
    if por != 1:
        return "Exactly 1 goalkeeper (POR) required in starters"
    dif_n = sum(1 for s in starters if player_positions.get(s.player_id) == "DIF")
    cen_n = sum(1 for s in starters if player_positions.get(s.player_id) == "CEN")
    att_n = sum(1 for s in starters if player_positions.get(s.player_id) == "ATT")
    if (dif_n, cen_n, att_n) != (dif, cen, att):
        return f"Formation {formation} requires {dif} DIF, {cen} CEN, {att} ATT (got {dif_n}, {cen_n}, {att_n})"
    return None


@router.post("", response_model=TeamResponse)
async def create_team(
    body: TeamCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Crea squadra fantasy in una lega (l'utente ne diventa proprietario)."""
    r = await db.execute(select(FantasyLeague).where(FantasyLeague.id == body.league_id, FantasyLeague.is_active == True))
    league = r.scalar_one_or_none()
    if not league:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Questa lega non esiste più")
    existing = await db.execute(
        select(FantasyTeam).where(FantasyTeam.league_id == body.league_id, FantasyTeam.user_id == current_user.id)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Already have a team in this league")
    count_r = await db.execute(select(func.count()).select_from(FantasyTeam).where(FantasyTeam.league_id == body.league_id))
    member_count = count_r.scalar() or 0
    if league.league_type == "private" and league.max_members is not None and member_count >= league.max_members:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Lega piena ({member_count}/{league.max_members} partecipanti)",
        )
    team = FantasyTeam(
        league_id=body.league_id,
        user_id=current_user.id,
        name=body.name,
        budget_remaining=league.budget,
    )
    db.add(team)
    await db.commit()
    await db.refresh(team)
    return team


@router.get("/{team_id}", response_model=TeamDetailResponse)
async def get_team(
    team_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Dettaglio squadra con rosa giocatori."""
    r = await db.execute(select(FantasyTeam).where(FantasyTeam.id == team_id))
    team = r.scalar_one_or_none()
    if not team:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Team not found")
    rl = await db.execute(select(FantasyLeague).where(FantasyLeague.id == team.league_id, FantasyLeague.is_active == True))
    if not rl.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Questa lega non esiste più")
    if team.user_id != current_user.id:
        league = (await db.execute(select(FantasyLeague).where(FantasyLeague.id == team.league_id))).scalar_one_or_none()
        if not league or league.admin_user_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your team")
    rosters = await db.execute(
        select(FantasyRoster, Player, RealTeam.name)
        .join(Player, FantasyRoster.player_id == Player.id)
        .outerjoin(RealTeam, Player.real_team_id == RealTeam.id)
        .where(FantasyRoster.fantasy_team_id == team_id, FantasyRoster.is_active == True)
    )
    roster_list = [
        RosterPlayerResponse(
            player_id=p.id,
            player_name=p.name,
            position=p.position,
            purchase_price=r.purchase_price,
            real_team_name=rt_name or None,
            photo_url=f"/static/{p.photo_local}" if p.photo_local else p.photo_url,
            cutout_url=f"/static/{p.cutout_local}" if p.cutout_local else p.cutout_url,
        )
        for r, p, rt_name in rosters.all()
    ]
    return TeamDetailResponse.model_validate(team).model_copy(update={"roster": roster_list})


@router.get("/{team_id}/lineup/{matchday}/availability", response_model=list[PlayerAvailabilityItem])
async def get_lineup_availability(
    team_id: UUID,
    matchday: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Stato disponibilità di tutta la rosa per la giornata (per icone in schermata formazione)."""
    r = await db.execute(select(FantasyTeam).where(FantasyTeam.id == team_id))
    team = r.scalar_one_or_none()
    if not team or team.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Team not found")
    rosters = await db.execute(
        select(FantasyRoster.player_id).where(
            FantasyRoster.fantasy_team_id == team_id,
            FantasyRoster.is_active == True,
        )
    )
    player_ids = [row[0] for row in rosters.all()]
    availability = AvailabilityService(db)
    items = await availability.get_squad_availability_with_icons(player_ids, matchday)
    return [PlayerAvailabilityItem(**x) for x in items]


@router.get("/{team_id}/lineup/{matchday}", response_model=LineupResponse)
async def get_lineup(
    team_id: UUID,
    matchday: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Formazione schierata per la giornata."""
    r = await db.execute(select(FantasyTeam).where(FantasyTeam.id == team_id))
    team = r.scalar_one_or_none()
    if not team or team.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Team not found")
    r = await db.execute(
        select(FantasyLineup).where(
            FantasyLineup.fantasy_team_id == team_id,
            FantasyLineup.matchday == matchday,
        )
    )
    rows = r.scalars().all()
    formation = rows[0].formation if rows else None
    starters = [LineupSlot(player_id=x.player_id, position_slot=x.position_slot, is_starter=True, bench_order=x.bench_order) for x in rows if x.is_starter]
    bench = [LineupSlot(player_id=x.player_id, position_slot=x.position_slot, is_starter=False, bench_order=x.bench_order) for x in rows if not x.is_starter]
    return LineupResponse(fantasy_team_id=team_id, matchday=matchday, formation=formation, starters=starters, bench=bench)


@router.post("/{team_id}/lineup/{matchday}", response_model=LineupSetResponse)
async def set_lineup(
    team_id: UUID,
    matchday: int,
    body: LineupSet,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Imposta formazione per la giornata (validazione modulo e ruoli). Ritorna warnings disponibilità senza bloccare il salvataggio."""
    r = await db.execute(select(FantasyTeam).where(FantasyTeam.id == team_id))
    team = r.scalar_one_or_none()
    if not team or team.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Team not found")
    player_ids = [s.player_id for s in body.slots]
    rosters = await db.execute(
        select(FantasyRoster.player_id).where(
            FantasyRoster.fantasy_team_id == team_id,
            FantasyRoster.is_active == True,
            FantasyRoster.player_id.in_(player_ids),
        )
    )
    roster_ids = {row[0] for row in rosters.all()}
    if set(player_ids) != roster_ids or len(player_ids) != len(set(player_ids)):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="All players must be in your roster and unique")
    players_r = await db.execute(select(Player.id, Player.position).where(Player.id.in_(player_ids)))
    player_positions = {row[0]: row[1] for row in players_r.all()}
    err = _validate_lineup_slots(body.formation, body.slots, player_positions)
    if err:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=err)
    # Check disponibilità (solo per i titolari) e costruisci warnings
    availability = AvailabilityService(db)
    warnings: list[LineupWarning] = []
    for slot in body.slots:
        if not slot.is_starter:
            continue
        avail = await availability.get_player_availability(slot.player_id, matchday)
        status = avail.get("status", "AVAILABLE")
        name = avail.get("player_name", "")
        if status == "SUSPENDED":
            warnings.append(LineupWarning(
                player_id=slot.player_id,
                player_name=name,
                level="red",
                message=f"SQUALIFICATO: {avail.get('detail', '')}. Non giocherà!",
                suggestion="Metti in panchina e usa un sostituto",
            ))
        elif status == "INJURED":
            rd = avail.get("return_date") or ""
            warnings.append(LineupWarning(
                player_id=slot.player_id,
                player_name=name,
                level="red",
                message=f"INFORTUNATO: {avail.get('detail', '')}. Rientro stimato: {rd}",
                suggestion="Metti in panchina e usa un sostituto",
            ))
        elif status == "DOUBTFUL":
            warnings.append(LineupWarning(
                player_id=slot.player_id,
                player_name=name,
                level="orange",
                message=f"IN DUBBIO: {avail.get('detail', '')}",
                suggestion="Prevedi un sostituto in panchina",
            ))
        elif status == "NOT_CALLED":
            warnings.append(LineupWarning(
                player_id=slot.player_id,
                player_name=name,
                level="red",
                message="NON CONVOCATO per la prossima partita",
                suggestion="Metti in panchina e usa un sostituto",
            ))
    # Salva formazione comunque
    await db.execute(FantasyLineup.__table__.delete().where(
        FantasyLineup.fantasy_team_id == team_id,
        FantasyLineup.matchday == matchday,
    ))
    for s in body.slots:
        db.add(FantasyLineup(
            fantasy_team_id=team_id,
            matchday=matchday,
            player_id=s.player_id,
            position_slot=s.position_slot,
            is_starter=s.is_starter,
            bench_order=s.bench_order,
            formation=body.formation,
        ))
    await db.commit()
    starters = [s for s in body.slots if s.is_starter]
    bench = [s for s in body.slots if not s.is_starter]
    red_count = len([w for w in warnings if w.level == "red"])
    return LineupSetResponse(
        message="Formazione salvata",
        fantasy_team_id=team_id,
        matchday=matchday,
        formation=body.formation,
        starters=len(starters),
        bench=len(bench),
        warnings=warnings,
        unavailable_count=red_count,
    )

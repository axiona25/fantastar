"""
Mercato di riparazione: svincolati, acquisto, rilascio, scambi.
Limiti rosa: max 3 POR, 8 DIF, 8 CEN, 6 ATT, 25 totali.
"""
from datetime import datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.player import Player
from app.models.real_team import RealTeam
from app.models.fantasy_league_member import FantasyLeagueMember
from app.models.fantasy_team import FantasyTeam
from app.models.fantasy_roster import FantasyRoster
from app.models.trade_proposal import TradeProposal
from app.services.player_list_service import get_players_paginated

ROSTER_LIMITS = {"POR": 3, "DIF": 8, "CEN": 8, "ATT": 6}
MAX_ROSTER_SIZE = 25
RELEASE_REFUND_PERCENT = 0.5


async def _roster_counts(db: AsyncSession, fantasy_team_id: UUID) -> tuple[dict[str, int], int]:
    """(counts per role, total size)."""
    r = await db.execute(
        select(Player.position, func.count(FantasyRoster.player_id))
        .join(FantasyRoster, FantasyRoster.player_id == Player.id)
        .where(FantasyRoster.fantasy_team_id == fantasy_team_id, FantasyRoster.is_active == True)
        .group_by(Player.position)
    )
    counts = {"POR": 0, "DIF": 0, "CEN": 0, "ATT": 0}
    total = 0
    for (pos, c) in r.all():
        pos = (pos or "CEN")[:3].upper()
        if pos in counts:
            counts[pos] = c
        total += c
    return counts, total


async def get_free_agents(
    db: AsyncSession,
    league_id: UUID,
    position: str | None = None,
    search: str | None = None,
    page: int = 1,
    page_size: int = 30,
) -> tuple[list, int]:
    """Giocatori non in nessuna rosa della lega (svincolati). Ritorna (lista PlayerListResponse, total)."""
    return await get_players_paginated(
        db,
        position=position,
        search=search,
        available_only=True,
        league_id=league_id,
        page=page,
        page_size=page_size,
    )


async def buy_free_agent(
    db: AsyncSession,
    league_id: UUID,
    fantasy_team_id: UUID,
    player_id: int,
    price: Decimal | None = None,
    allow_duplicate_players: bool = False,
) -> dict:
    """
    Acquista svincolato. Verifica che l'utente sia membro della lega, usa budget da fantasy_league_members.
    Crea roster entry con league_id.
    allow_duplicate_players: se True (leghe pubbliche) non verifica che il giocatore sia già in altre rose.
    """
    r = await db.execute(select(FantasyTeam).where(FantasyTeam.id == fantasy_team_id, FantasyTeam.league_id == league_id))
    team = r.scalar_one_or_none()
    if not team:
        raise ValueError("Squadra non trovata")
    r = await db.execute(
        select(FantasyLeagueMember).where(
            FantasyLeagueMember.league_id == league_id,
            FantasyLeagueMember.user_id == team.user_id,
        )
    )
    member = r.scalar_one_or_none()
    if not member:
        raise ValueError("Non sei membro di questa lega. Crea o unisciti a una lega dalla tab Squadra.")
    r = await db.execute(select(Player).where(Player.id == player_id))
    player = r.scalar_one_or_none()
    if not player:
        raise ValueError("Giocatore non trovato")
    price = price if price is not None else (player.initial_price or Decimal("1"))
    price = Decimal(str(price))
    if member.budget_remaining < price:
        raise ValueError(f"Budget insufficiente (serve {price}, disponibile {member.budget_remaining})")
    counts, total = await _roster_counts(db, fantasy_team_id)
    if total >= MAX_ROSTER_SIZE:
        raise ValueError(f"Rosa piena (max {MAX_ROSTER_SIZE})")
    pos = (player.position or "CEN")[:3].upper()
    limit = ROSTER_LIMITS.get(pos, 8)
    if counts.get(pos, 0) >= limit:
        raise ValueError(f"Limite ruolo {pos} raggiunto (max {limit})")
    if not allow_duplicate_players:
        r = await db.execute(
            select(FantasyRoster.id).join(FantasyTeam, FantasyTeam.id == FantasyRoster.fantasy_team_id).where(
                FantasyTeam.league_id == league_id, FantasyRoster.player_id == player_id, FantasyRoster.is_active == True
            )
        )
        if r.scalar_one_or_none():
            raise ValueError("Giocatore già in rosa di una squadra della lega")
    db.add(FantasyRoster(
        fantasy_team_id=fantasy_team_id,
        league_id=league_id,
        player_id=player_id,
        purchase_price=price,
        is_active=True,
    ))
    member.budget_remaining = member.budget_remaining - price
    team.budget_remaining = team.budget_remaining - price
    await db.commit()
    await db.refresh(team)
    return {"message": "Acquisto effettuato", "player_id": player_id, "amount": float(price), "team_name": team.name}


async def release_player(db: AsyncSession, league_id: UUID, fantasy_team_id: UUID, player_id: int) -> dict:
    """Rilascia giocatore; rimborso 50% del purchase_price. Aggiorna budget su member e team."""
    r = await db.execute(select(FantasyTeam).where(FantasyTeam.id == fantasy_team_id, FantasyTeam.league_id == league_id))
    team = r.scalar_one_or_none()
    if not team:
        raise ValueError("Squadra non trovata")
    r = await db.execute(
        select(FantasyLeagueMember).where(
            FantasyLeagueMember.league_id == league_id,
            FantasyLeagueMember.user_id == team.user_id,
        )
    )
    member = r.scalar_one_or_none()
    r = await db.execute(
        select(FantasyRoster).where(
            FantasyRoster.fantasy_team_id == fantasy_team_id,
            FantasyRoster.player_id == player_id,
            FantasyRoster.is_active == True,
        )
    )
    roster = r.scalar_one_or_none()
    if not roster:
        raise ValueError("Giocatore non in rosa")
    refund = (roster.purchase_price or Decimal(0)) * Decimal(str(RELEASE_REFUND_PERCENT))
    roster.is_active = False
    team.budget_remaining = team.budget_remaining + refund
    if member:
        member.budget_remaining = member.budget_remaining + refund
    await db.commit()
    await db.refresh(team)
    return {"message": "Giocatore rilasciato", "player_id": player_id, "refund": float(refund)}


async def propose_trade(
    db: AsyncSession,
    league_id: UUID,
    from_team_id: UUID,
    to_team_id: UUID,
    offer_player_ids: list[int],
    request_player_ids: list[int],
) -> dict:
    """Crea proposta di scambio. Verifica che i giocatori appartengano alle rispettive squadre."""
    if from_team_id == to_team_id:
        raise ValueError("Non puoi proporre uno scambio a te stesso")
    r = await db.execute(
        select(FantasyTeam.id).where(FantasyTeam.league_id == league_id, FantasyTeam.id.in_([from_team_id, to_team_id]))
    )
    if len(r.all()) != 2:
        raise ValueError("Una o entrambe le squadre non sono in questa lega")
    for pid in offer_player_ids:
        r2 = await db.execute(
            select(FantasyRoster.id).where(
                FantasyRoster.fantasy_team_id == from_team_id,
                FantasyRoster.player_id == pid,
                FantasyRoster.is_active == True,
            )
        )
        if not r2.scalar_one_or_none():
            raise ValueError(f"Giocatore {pid} non è nella tua rosa")
    for pid in request_player_ids:
        r2 = await db.execute(
            select(FantasyRoster.id).where(
                FantasyRoster.fantasy_team_id == to_team_id,
                FantasyRoster.player_id == pid,
                FantasyRoster.is_active == True,
            )
        )
        if not r2.scalar_one_or_none():
            raise ValueError(f"Giocatore {pid} non è nella rosa della squadra destinataria")
    db.add(TradeProposal(
        league_id=league_id,
        from_team_id=from_team_id,
        to_team_id=to_team_id,
        offer_player_ids=offer_player_ids,
        request_player_ids=request_player_ids,
        status="PENDING",
    ))
    await db.commit()
    return {"message": "Proposta inviata", "offer": offer_player_ids, "request": request_player_ids}


async def respond_to_trade(db: AsyncSession, trade_id: int, to_team_id: UUID, accept: bool) -> dict:
    """Accetta o rifiuta proposta (solo la squadra destinataria). Se accettato, scambia i giocatori."""
    r = await db.execute(select(TradeProposal).where(TradeProposal.id == trade_id))
    trade = r.scalar_one_or_none()
    if not trade:
        raise ValueError("Proposta non trovata")
    if trade.to_team_id != to_team_id:
        raise ValueError("Solo la squadra destinataria può rispondere")
    if trade.status != "PENDING":
        raise ValueError("Proposta già elaborata")
    if not accept:
        trade.status = "REJECTED"
        await db.commit()
        return {"message": "Proposta rifiutata"}
    for pid in trade.offer_player_ids:
        r2 = await db.execute(
            select(FantasyRoster).where(
                FantasyRoster.fantasy_team_id == trade.from_team_id,
                FantasyRoster.player_id == pid,
                FantasyRoster.is_active == True,
            )
        )
        roster = r2.scalar_one_or_none()
        if roster:
            roster.fantasy_team_id = trade.to_team_id
    for pid in trade.request_player_ids:
        r2 = await db.execute(
            select(FantasyRoster).where(
                FantasyRoster.fantasy_team_id == trade.to_team_id,
                FantasyRoster.player_id == pid,
                FantasyRoster.is_active == True,
            )
        )
        roster = r2.scalar_one_or_none()
        if roster:
            roster.fantasy_team_id = trade.from_team_id
    trade.status = "ACCEPTED"
    await db.commit()
    return {"message": "Scambio accettato"}

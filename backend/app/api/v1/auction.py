"""
API Asta (modulo session-based).
POST start, nominate, bid, GET status, POST expire (admin), pause, stop.
Sedie tavolo: POST join, POST leave, GET seats, POST heartbeat.
Compat: GET current, GET history.
"""
import logging
import random
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import delete, func, select, text, update
from sqlalchemy.exc import OperationalError, ProgrammingError
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.league import FantasyLeague
from app.models.fantasy_team import FantasyTeam
from app.models.auction_seat import AuctionSeat
from app.models.auction_purchase import AuctionPurchase
from app.models.auction_config import AuctionConfig
from app.models.player import Player
from app.models.real_team import RealTeam
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
    AuctionConfigureRequest,
    AuctionConfigureResponse,
    AuctionConfigGetResponse,
    AuctionRandomStartResponse,
    AuctionCurrentTurnResponse,
    AuctionCurrentTurnPlayer,
    AuctionRandomBidRequest,
    AuctionRandomBidResponse,
    AuctionTurnResultsResponse,
    AuctionTurnResultPlayer,
    AuctionTurnResultBid,
    AuctionRandomStatusResponse,
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
from app.services.auction_random_service import (
    get_config as get_auction_config,
    configure as configure_random_auction,
    _config_to_dict,
    start as start_random_auction,
    get_current_turn_info,
    place_bid as place_random_bid,
    get_turn_results,
    get_random_auction_status,
    resolve_expired_turns,
)
from app.services.push_service import send_push_to_users
from app.api.websocket import broadcast_auction_update

router = APIRouter(prefix="/leagues/{league_id}/auction", tags=["auction"])
logger = logging.getLogger(__name__)


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


@router.post("/start", response_model=AuctionStartResponse | AuctionRandomStartResponse)
async def auction_start(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Avvia asta: se esiste config asta random (pending) avvia quella, altrimenti asta classica (solo admin, leghe private)."""
    league = await _require_admin(league_id, current_user, db)
    _require_private_league(league)
    config = await get_auction_config(db, league_id)
    if config and getattr(config, "auction_type", None) == "random" and config.status == "pending":
        try:
            out = await start_random_auction(db, league_id)
            await broadcast_auction_update(league_id, "auction_started", {"config_id": out["config_id"], "status": out["status"]})
            return AuctionRandomStartResponse(**out)
        except ValueError as e:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
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
            real_team_logo_url=cp.get("real_team_logo_url"),
            real_team_short_name=cp.get("real_team_short_name"),
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


# --- Configurazione asta (classica + busta chiusa) ---

@router.get("/config", response_model=AuctionConfigGetResponse)
async def get_auction_config_endpoint(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Ritorna tipo asta della lega e configurazione esistente (se presente)."""
    league = await _require_league_member(league_id, current_user, db)
    config = await get_auction_config(db, league_id)
    auction_type = getattr(league, "auction_type", "classic") or "classic"
    asta_started = getattr(league, "asta_started", False) or False
    return AuctionConfigGetResponse(
        league_id=league_id,
        auction_type=auction_type,
        asta_started=asta_started,
        config=_config_to_dict(config) if config else None,
    )


@router.post("/configure", response_model=AuctionConfigureResponse)
async def auction_configure(
    league_id: UUID,
    body: AuctionConfigureRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Configura asta (solo admin). Rosa + opzionali classica/busta chiusa. Per busta chiusa genera ordine giocatori."""
    league = await _require_admin(league_id, current_user, db)
    _require_private_league(league)
    try:
        config = await configure_random_auction(
            db,
            league_id,
            players_per_turn_p=body.players_per_turn_p,
            players_per_turn_d=body.players_per_turn_d,
            players_per_turn_c=body.players_per_turn_c,
            players_per_turn_a=body.players_per_turn_a,
            turn_duration_hours=body.turn_duration_hours,
            budget_per_team=body.budget_per_team,
            max_roster_size=body.max_roster_size,
            min_goalkeepers=body.min_goalkeepers,
            min_defenders=body.min_defenders,
            min_midfielders=body.min_midfielders,
            min_attackers=body.min_attackers,
            base_price=body.base_price,
            bid_timer_seconds=body.bid_timer_seconds,
            min_raise=body.min_raise,
            call_order=body.call_order,
            allow_nomination=body.allow_nomination,
            pause_between_players=body.pause_between_players,
            rounds_count=body.rounds_count,
            reveal_bids=body.reveal_bids,
            allow_same_player_bids=body.allow_same_player_bids,
            max_bids_per_round=body.max_bids_per_round,
            tie_breaker=body.tie_breaker,
        )
        return AuctionConfigureResponse(config_id=config.id, status=config.status)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except (OperationalError, ProgrammingError) as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Il database non è aggiornato. Esegui le migrazioni sul server (alembic upgrade head) e riprova.",
        ) from e


@router.get("/current-turn", response_model=AuctionCurrentTurnResponse)
async def auction_current_turn(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Turno attivo asta random: giocatori proposti, tempo rimanente, le MIE offerte, il mio budget."""
    await _require_league_member(league_id, current_user, db)
    data = await get_current_turn_info(db, league_id, current_user.id)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nessun turno attivo")
    players = [AuctionCurrentTurnPlayer(**p) for p in data["players"]]
    return AuctionCurrentTurnResponse(
        turn_id=data["turn_id"],
        turn_number=data["turn_number"],
        role=data["role"],
        expires_at=data["expires_at"],
        seconds_remaining=data["seconds_remaining"],
        players=players,
        my_budget_remaining=data.get("my_budget_remaining"),
        config_budget=data.get("config_budget", 500),
    )


@router.post("/random/bid", response_model=AuctionRandomBidResponse)
async def auction_random_bid(
    league_id: UUID,
    body: AuctionRandomBidRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Offerta segreta per un giocatore del turno corrente (asta random)."""
    await _require_league_member(league_id, current_user, db)
    try:
        out = await place_random_bid(db, league_id, current_user.id, body.player_id, body.amount)
        return AuctionRandomBidResponse(**out)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.get("/results/{turn_number}", response_model=AuctionTurnResultsResponse)
async def auction_turn_results(
    league_id: UUID,
    turn_number: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Risultati di un turno completato: vincitori e tutte le offerte (ora visibili)."""
    await _require_league_member(league_id, current_user, db)
    data = await get_turn_results(db, league_id, turn_number)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Turno non trovato o non ancora completato")
    results = [
        AuctionTurnResultPlayer(
            player_id=r["player_id"],
            player_name=r["player_name"],
            position=r["position"],
            real_team=r.get("real_team"),
            winner_team_name=r.get("winner_team_name"),
            winner_username=r.get("winner_username"),
            winning_bid=r["winning_bid"],
            status=r["status"],
            all_bids=[AuctionTurnResultBid(amount=b["amount"], username=b["username"]) for b in r["all_bids"]],
        )
        for r in data["results"]
    ]
    return AuctionTurnResultsResponse(
        turn_id=data["turn_id"],
        turn_number=data["turn_number"],
        role=data["role"],
        completed_at=data.get("completed_at"),
        results=results,
    )


@router.get("/random/status", response_model=AuctionRandomStatusResponse)
async def auction_random_status(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Stato generale asta random: ruolo, turno, budget e rose di tutti."""
    await _require_league_member(league_id, current_user, db)
    data = await get_random_auction_status(db, league_id)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nessuna asta random per questa lega")
    from app.schemas.auction import AuctionRandomStatusTeam
    teams = [AuctionRandomStatusTeam(**t) for t in data["teams"]]
    return AuctionRandomStatusResponse(
        config_id=data["config_id"],
        status=data["status"],
        current_role=data["current_role"],
        current_turn=data["current_turn"],
        teams=teams,
        active_turn=data.get("active_turn"),
    )


@router.post("/resolve-turn")
async def auction_resolve_turn(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Risolve turni scaduti (solo admin). Usato anche dallo scheduler per risolvere automaticamente."""
    league = await _require_admin(league_id, current_user, db)
    _require_private_league(league)
    count = await resolve_expired_turns(db, league_id=league_id)
    return {"message": f"Risolti {count} turni", "resolved": count}


# --- Sedie tavolo asta live: join, leave, seats, heartbeat ---


async def _get_all_seats(league_id: UUID, db: AsyncSession) -> list[dict]:
    """Ritorna le sedie occupate con info squadra, username e budget (per info sotto il badge)."""
    budget_subq = (
        select(AuctionConfig.budget_per_team)
        .where(AuctionConfig.league_id == league_id)
        .limit(1)
        .scalar_subquery()
    )
    r = await db.execute(
        select(
            AuctionSeat.seat_number,
            AuctionSeat.team_id,
            FantasyTeam.name.label("team_name"),
            FantasyTeam.logo_url.label("badge_url"),
            FantasyTeam.budget_remaining,
            User.username,
            budget_subq.label("budget_per_team"),
        )
        .join(FantasyTeam, FantasyTeam.id == AuctionSeat.team_id)
        .join(User, User.id == FantasyTeam.user_id)
        .where(AuctionSeat.league_id == league_id)
        .order_by(AuctionSeat.seat_number)
    )
    rows = r.all()
    out = []
    for row in rows:
        budget_total = int(row.budget_per_team or 500)
        budget_remaining = float(row.budget_remaining) if row.budget_remaining is not None else float(budget_total)
        spent = int(round(budget_total - budget_remaining))
        out.append({
            "seat_number": int(row.seat_number),
            "team_id": str(row.team_id),
            "team_name": str(row.team_name) if row.team_name else "",
            "badge_url": str(row.badge_url) if row.badge_url else None,
            "username": str(row.username) if row.username else "",
            "budget_total": budget_total,
            "budget_remaining": int(round(budget_remaining)),
            "budget_spent": spent,
        })
    return out


@router.post("/join")
async def join_auction(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """L'utente si siede a una sedia random del tavolo. Schema: fantasy_teams.user_id, logo_url; fantasy_leagues."""
    try:
        logger.info("Join asta richiesto: league_id=%s, user_id=%s", league_id, current_user.id)
        league = await _require_league_member(league_id, current_user, db)

        r = await db.execute(
            select(FantasyTeam.id, FantasyTeam.name, FantasyTeam.logo_url).where(
                FantasyTeam.league_id == league_id,
                FantasyTeam.user_id == current_user.id,
                FantasyTeam.is_configured == True,
            )
        )
        team_row = r.one_or_none()
        if not team_row:
            r = await db.execute(
                select(FantasyTeam.id, FantasyTeam.name, FantasyTeam.logo_url).where(
                    FantasyTeam.league_id == league_id,
                    FantasyTeam.user_id == current_user.id,
                )
            )
            team_row = r.one_or_none()
            if team_row:
                logger.warning(
                    "Join asta: squadra trovata ma non configurata per user %s in league %s",
                    current_user.id,
                    league_id,
                )
        if not team_row:
            logger.error(
                "Join asta: nessuna squadra per user %s in league %s",
                current_user.id,
                league_id,
            )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Non hai una squadra in questa lega",
            )
        team_id = team_row[0]
        logger.info("Join asta: squadra trovata %s (id=%s)", team_row[1], team_id)

        r = await db.execute(
            select(AuctionSeat.seat_number).where(
                AuctionSeat.league_id == league_id,
                AuctionSeat.team_id == team_id,
            )
        )
        existing = r.scalar_one_or_none()
        if existing is not None:
            seat_num = existing
            await db.execute(
                update(AuctionSeat)
                .where(AuctionSeat.league_id == league_id, AuctionSeat.team_id == team_id)
                .values(last_heartbeat=func.now())
            )
            await db.commit()
            seats = await _get_all_seats(league_id, db)
            return {"seat_number": seat_num, "seats": seats, "my_team_id": str(team_id)}

        max_seats = int(league.max_teams or 8)
        r = await db.execute(select(AuctionSeat.seat_number).where(AuctionSeat.league_id == league_id))
        occupied_seats = {row[0] for row in r.scalars().all()}
        free_seats = [i for i in range(max_seats) if i not in occupied_seats]
        if not free_seats:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Tutte le sedie sono occupate")

        seat = random.choice(free_seats)
        db.add(AuctionSeat(league_id=league_id, seat_number=seat, team_id=team_id))
        await db.commit()
        seats = await _get_all_seats(league_id, db)
        return {"seat_number": seat, "seats": seats, "my_team_id": str(team_id)}
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Join asta errore 500: %s", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Errore join asta: {e!s}",
        ) from e


@router.post("/leave")
async def leave_auction(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """L'utente si alza dalla sedia."""
    await _require_league_member(league_id, current_user, db)
    r = await db.execute(select(FantasyTeam.id).where(FantasyTeam.league_id == league_id, FantasyTeam.user_id == current_user.id))
    team_id = r.scalar_one_or_none()
    if team_id is not None:
        await db.execute(delete(AuctionSeat).where(AuctionSeat.league_id == league_id, AuctionSeat.team_id == team_id))
        await db.commit()
    return {"message": "ok"}


@router.get("/seats")
async def get_auction_seats(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Lista tutte le sedie con chi è seduto. Pulisce sedie con heartbeat > 30s."""
    league = await _require_league_member(league_id, current_user, db)
    await db.execute(
        text("DELETE FROM auction_seats WHERE league_id = :lid AND last_heartbeat < NOW() - INTERVAL '30 seconds'"),
        {"lid": league_id},
    )
    await db.commit()
    max_seats = league.max_teams or 8
    seats = await _get_all_seats(league_id, db)
    return {"max_seats": max_seats, "seats": seats}


@router.post("/heartbeat")
async def auction_heartbeat(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Aggiorna l'heartbeat per indicare che l'utente è ancora connesso."""
    r = await db.execute(select(FantasyTeam.id).where(FantasyTeam.league_id == league_id, FantasyTeam.user_id == current_user.id))
    team_id = r.scalar_one_or_none()
    if team_id is not None:
        await db.execute(
            update(AuctionSeat)
            .where(AuctionSeat.league_id == league_id, AuctionSeat.team_id == team_id)
            .values(last_heartbeat=func.now())
        )
        await db.commit()
    return {"message": "ok"}


# --- Portfolio / budget in tempo reale ---


def _position_to_role(position: str | None) -> str:
    """POR->P, DIF->D, CEN->C, ATT->A."""
    if not position:
        return "C"
    u = position.upper()
    if u == "POR":
        return "P"
    if u == "DIF":
        return "D"
    if u == "CEN":
        return "C"
    if u == "ATT":
        return "A"
    return "C"


async def _get_initial_budget_and_limits(league_id: UUID, db: AsyncSession) -> tuple[int, int, dict]:
    """Ritorna (initial_budget, max_players, min_roles)."""
    r = await db.execute(select(AuctionConfig).where(AuctionConfig.league_id == league_id))
    config = r.scalar_one_or_none()
    if config:
        return (
            int(config.budget_per_team or 500),
            int(config.max_roster_size or 25),
            {"P": config.min_goalkeepers or 3, "D": config.min_defenders or 8, "C": config.min_midfielders or 8, "A": config.min_attackers or 6},
        )
    r = await db.execute(select(FantasyLeague.budget).where(FantasyLeague.id == league_id))
    row = r.scalar_one_or_none()
    budget = int(row[0]) if row and row[0] is not None else 500
    return budget, 25, {"P": 3, "D": 8, "C": 8, "A": 6}


@router.get("/portfolio")
async def get_my_portfolio(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Portfolio della squadra dell'utente: budget iniziale, speso, rimanente, acquisti, conteggi ruolo."""
    await _require_league_member(league_id, current_user, db)
    r = await db.execute(select(FantasyTeam.id).where(FantasyTeam.league_id == league_id, FantasyTeam.user_id == current_user.id, FantasyTeam.is_configured == True))
    team_row = r.scalar_one_or_none()
    if not team_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nessuna squadra configurata in questa lega")
    team_id = team_row.id
    initial_budget, max_players, min_roles = await _get_initial_budget_and_limits(league_id, db)
    r = await db.execute(
        select(
            AuctionPurchase.player_id,
            AuctionPurchase.price,
            AuctionPurchase.purchased_at,
            Player.name.label("player_name"),
            Player.position,
            RealTeam.short_name.label("real_team_short_name"),
        )
        .join(Player, Player.id == AuctionPurchase.player_id)
        .outerjoin(RealTeam, RealTeam.id == Player.real_team_id)
        .where(AuctionPurchase.league_id == league_id, AuctionPurchase.team_id == team_id)
        .order_by(AuctionPurchase.purchased_at.desc())
    )
    rows = r.all()
    total_spent = sum(int(row.price) for row in rows)
    remaining = initial_budget - total_spent
    role_counts: dict[str, int] = {"P": 0, "D": 0, "C": 0, "A": 0}
    for row in rows:
        role = _position_to_role(row.position)
        if role in role_counts:
            role_counts[role] += 1
    purchases = [
        {
            "player_id": row.player_id,
            "price": row.price,
            "purchased_at": row.purchased_at.isoformat() if row.purchased_at else None,
            "player_name": row.player_name,
            "role": row.position,
            "real_team_short_name": row.real_team_short_name,
        }
        for row in rows
    ]
    return {
        "initial_budget": initial_budget,
        "total_spent": total_spent,
        "remaining": remaining,
        "total_players": len(purchases),
        "max_players": max_players,
        "role_counts": role_counts,
        "min_roles": min_roles,
        "purchases": purchases,
    }


@router.get("/portfolios")
async def get_all_portfolios(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Budget rimanente di tutte le squadre (per il tavolo)."""
    await _require_league_member(league_id, current_user, db)
    initial_budget, _, _ = await _get_initial_budget_and_limits(league_id, db)
    r = await db.execute(
        select(
            FantasyTeam.id,
            FantasyTeam.name,
            FantasyTeam.logo_url,
            func.coalesce(func.sum(AuctionPurchase.price), 0).label("total_spent"),
            func.count(AuctionPurchase.id).label("total_players"),
        )
        .outerjoin(AuctionPurchase, (AuctionPurchase.team_id == FantasyTeam.id) & (AuctionPurchase.league_id == league_id))
        .where(FantasyTeam.league_id == league_id, FantasyTeam.is_configured == True)
        .group_by(FantasyTeam.id, FantasyTeam.name, FantasyTeam.logo_url)
    )
    rows = r.all()
    return [
        {
            "team_id": str(row.id),
            "team_name": row.name,
            "badge_url": row.logo_url,
            "initial_budget": initial_budget,
            "spent": int(row.total_spent),
            "remaining": initial_budget - int(row.total_spent),
            "players_count": int(row.total_players),
        }
        for row in rows
    ]


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

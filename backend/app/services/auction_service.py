"""
Modulo ASTA completo (session-based, a turni per categoria).
- Categorie: POR → DIF → CEN → ATT (ordine fisso)
- turn_order: ordine partecipanti; solo chi ha il turno può nominare
- nominate: solo current_turn può nominare; giocatore deve essere della categoria corrente
- expire: assegna poi avanza turno (salta chi ha completato categoria); se tutti completati → prossima categoria o completed
"""
import logging
from datetime import datetime, timedelta
from decimal import Decimal
from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.models.auction_session import AuctionSession, AUCTION_CATEGORY_ORDER
from app.models.auction_bid import AuctionBid
from app.models.auction_result import AuctionResult
from app.models.fantasy_team import FantasyTeam
from app.models.fantasy_roster import FantasyRoster
from app.models.player import Player
from app.models.real_team import RealTeam
from app.models.user import User
from app.schemas.auction import ROLE_LIMITS, TOTAL_ROSTER_LIMIT

logger = logging.getLogger(__name__)

AUCTION_TIMER_SECONDS = 60


def _now() -> datetime:
    return datetime.utcnow()


async def _count_roles_in_roster(db: AsyncSession, fantasy_team_id: UUID) -> dict[str, int]:
    """Conta giocatori per ruolo nella rosa (solo attivi)."""
    r = await db.execute(
        select(Player.position, func.count(FantasyRoster.player_id))
        .join(FantasyRoster, FantasyRoster.player_id == Player.id)
        .where(
            FantasyRoster.fantasy_team_id == fantasy_team_id,
            FantasyRoster.is_active == True,
        )
        .group_by(Player.position)
    )
    counts = {"POR": 0, "DIF": 0, "CEN": 0, "ATT": 0}
    for (pos, c) in r.all():
        pos = (pos or "CEN")[:3].upper()
        if pos in counts:
            counts[pos] = c
    return counts


async def _roster_total_count(db: AsyncSession, fantasy_team_id: UUID) -> int:
    r = await db.execute(
        select(func.count(FantasyRoster.id)).where(
            FantasyRoster.fantasy_team_id == fantasy_team_id,
            FantasyRoster.is_active == True,
        )
    )
    return r.scalar_one() or 0


async def can_team_sign_player(
    db: AsyncSession, fantasy_team_id: UUID, player_position: str
) -> tuple[bool, str]:
    """Verifica se la squadra può acquisire un altro giocatore di quel ruolo. Ritorna (ok, messaggio)."""
    counts = await _count_roles_in_roster(db, fantasy_team_id)
    total = sum(counts.values())
    if total >= TOTAL_ROSTER_LIMIT:
        return False, f"Rosa piena (max {TOTAL_ROSTER_LIMIT})"
    pos = (player_position or "CEN")[:3].upper()
    if pos not in ROLE_LIMITS:
        pos = "CEN"
    limit = ROLE_LIMITS.get(pos, 8)
    if counts.get(pos, 0) >= limit:
        return False, f"Limite ruolo {pos} raggiunto (max {limit})"
    return True, ""


def _turn_order_uids(session: AuctionSession) -> list[UUID]:
    """Restituisce turn_order come lista di UUID."""
    order = session.turn_order or []
    out = []
    for x in order:
        if isinstance(x, UUID):
            out.append(x)
        else:
            try:
                out.append(UUID(str(x)))
            except (ValueError, TypeError):
                pass
    return out


async def _count_role_in_roster_for_user(db: AsyncSession, league_id: UUID, user_id: UUID, role: str) -> int:
    """Conta quanti giocatori di quel ruolo ha l'utente nella lega (rosa attiva)."""
    r = await db.execute(
        select(FantasyTeam.id).where(
            FantasyTeam.league_id == league_id,
            FantasyTeam.user_id == user_id,
        )
    )
    team_id = r.scalar_one_or_none()
    if not team_id:
        return 0
    counts = await _count_roles_in_roster(db, team_id)
    return counts.get((role or "CEN")[:3].upper(), 0)


async def _get_active_user_ids_for_category(db: AsyncSession, session: AuctionSession) -> list[UUID]:
    """Utenti che devono ancora completare la categoria corrente (count < required)."""
    category = (session.current_category or "POR")[:3].upper()
    required = ROLE_LIMITS.get(category, 8)
    order = _turn_order_uids(session)
    active = []
    for uid in order:
        n = await _count_role_in_roster_for_user(db, session.league_id, uid, category)
        if n < required:
            active.append(uid)
    return active


async def _send_turn_push(db: AsyncSession, league_id: UUID, user_id: UUID, category_label: str) -> None:
    """Push a un utente: è il tuo turno, scegli un [categoria]."""
    try:
        from app.services.push_service import send_push_to_users
        await send_push_to_users(
            db, [user_id],
            "È il tuo turno!",
            f"Scegli un {category_label} da mettere all'asta",
        )
    except Exception as e:
        logger.exception("Push turno: %s", e)


async def _send_category_change_push(db: AsyncSession, league_id: UUID, old_label: str, new_label: str) -> None:
    """Push a tutti i membri: categoria completata, si passa alla successiva."""
    try:
        from app.services.push_service import send_push_to_users
        r = await db.execute(select(FantasyTeam.user_id).where(FantasyTeam.league_id == league_id).distinct())
        user_ids = [row[0] for row in r.all()]
        if user_ids:
            await send_push_to_users(
                db, user_ids,
                "Cambio categoria",
                f"📋 Categoria {old_label} completata! Si passa ai {new_label}",
            )
    except Exception as e:
        logger.exception("Push cambio categoria: %s", e)


async def _advance_turn(db: AsyncSession, session: AuctionSession) -> None:
    """Dopo assegnazione/no_sale: avanza turn_index (salta chi ha completato); se tutti completati → prossima categoria o completed."""
    order = _turn_order_uids(session)
    if not order:
        return
    active = await _get_active_user_ids_for_category(db, session)
    if not active:
        category = (session.current_category or "POR")[:3].upper()
        idx = AUCTION_CATEGORY_ORDER.index(category) if category in AUCTION_CATEGORY_ORDER else 0
        next_idx = idx + 1
        old_label = _category_label(category)
        if next_idx >= len(AUCTION_CATEGORY_ORDER):
            session.status = "completed"
            session.current_category = AUCTION_CATEGORY_ORDER[-1]
            session.current_turn_index = 0
            await db.commit()
            return
        new_category = AUCTION_CATEGORY_ORDER[next_idx]
        session.current_category = new_category
        session.current_turn_index = 0
        await db.commit()
        await _send_category_change_push(db, session.league_id, old_label, _category_label(new_category))
        try:
            from app.api.websocket import broadcast_auction_update
            await broadcast_auction_update(
                session.league_id, "category_change",
                {"old_category": category, "new_category": new_category, "old_label": old_label, "new_label": _category_label(new_category)},
            )
        except Exception:
            pass
        return
    current_idx = session.current_turn_index
    next_idx = (current_idx + 1) % len(order)
    attempts = 0
    while attempts < len(order):
        candidate_uid = order[next_idx]
        if candidate_uid in active:
            session.current_turn_index = next_idx
            await db.commit()
            category = (session.current_category or "POR")[:3].upper()
            await _send_turn_push(db, session.league_id, candidate_uid, _category_label(category))
            return
        next_idx = (next_idx + 1) % len(order)
        attempts += 1
    session.current_turn_index = 0
    await db.commit()
    category = (session.current_category or "POR")[:3].upper()
    next_uid = order[0] if order else None
    if next_uid and next_uid in (await _get_active_user_ids_for_category(db, session)):
        await _send_turn_push(db, session.league_id, next_uid, _category_label(category))


async def start_session(db: AsyncSession, league_id: UUID, started_by: UUID) -> dict:
    """Crea una nuova sessione d'asta attiva. Inizializza turn_order con tutti i membri lega, category=POR, turn_index=0."""
    r = await db.execute(
        select(AuctionSession).where(
            AuctionSession.league_id == league_id,
            AuctionSession.status.in_(["active", "paused"]),
        )
    )
    if r.scalar_one_or_none():
        raise ValueError("Esiste già una sessione d'asta attiva o in pausa")
    rteams = await db.execute(
        select(FantasyTeam.user_id).where(FantasyTeam.league_id == league_id).order_by(FantasyTeam.id)
    )
    user_ids = [row[0] for row in rteams.all()]
    if not user_ids:
        raise ValueError("Nessuna squadra nella lega: crea almeno una squadra prima di avviare l'asta")
    session = AuctionSession(
        league_id=league_id,
        status="active",
        started_by=started_by,
        current_category="POR",
        current_turn_index=0,
        turn_order=[str(u) for u in user_ids],
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return {"message": "Asta avviata", "session_id": session.id, "status": session.status}


async def get_active_session(db: AsyncSession, league_id: UUID) -> AuctionSession | None:
    """Ritorna la sessione attiva o in pausa per la lega."""
    r = await db.execute(
        select(AuctionSession).where(
            AuctionSession.league_id == league_id,
            AuctionSession.status.in_(["active", "paused"]),
        ).order_by(AuctionSession.id.desc()).limit(1)
    )
    return r.scalar_one_or_none()


async def nominate(
    db: AsyncSession, league_id: UUID, player_id: int, admin_user_id: UUID
) -> dict:
    """Solo chi ha il turno può nominare. Il giocatore deve essere della categoria corrente. Se solo uno attivo in categoria → auto-assegna a prezzo base."""
    session = await get_active_session(db, league_id)
    if not session or session.status != "active":
        raise ValueError("Nessuna asta attiva")
    order = _turn_order_uids(session)
    if not order:
        raise ValueError("Ordine turni non configurato")
    idx = session.current_turn_index
    if idx >= len(order):
        idx = 0
    current_turn_user_id = order[idx]
    if admin_user_id != current_turn_user_id:
        raise ValueError("Non è il tuo turno")
    category = (session.current_category or "POR")[:3].upper()
    r = await db.execute(select(Player).where(Player.id == player_id))
    player = r.scalar_one_or_none()
    if not player:
        raise ValueError("Giocatore non trovato")
    player_role = (player.position or "CEN")[:3].upper()
    if player_role != category:
        raise ValueError(f"Devi nominare un giocatore della categoria {_category_label(category)}")
    teams = await db.execute(select(FantasyTeam.id, FantasyTeam.user_id).where(FantasyTeam.league_id == league_id))
    team_rows = teams.all()
    team_ids = [row[0] for row in team_rows]
    if team_ids:
        r2 = await db.execute(
            select(FantasyRoster.id).where(
                FantasyRoster.player_id == player_id,
                FantasyRoster.fantasy_team_id.in_(team_ids),
                FantasyRoster.is_active == True,
            )
        )
        if r2.scalar_one_or_none():
            raise ValueError("Giocatore già in rosa di una squadra della lega")
    base = player.initial_price or Decimal("1")
    if base < Decimal("1"):
        base = Decimal("1")
    active = await _get_active_user_ids_for_category(db, session)
    if len(active) == 1 and admin_user_id in active:
        team = await db.execute(
            select(FantasyTeam).where(
                FantasyTeam.league_id == league_id,
                FantasyTeam.user_id == admin_user_id,
            )
        )
        team_row = team.scalar_one_or_none()
        if not team_row or team_row.budget_remaining < base:
            raise ValueError("Budget insufficiente per acquisto a prezzo base")
        ok, err = await can_team_sign_player(db, team_row.id, player_role)
        if not ok:
            raise ValueError(err)
        db.add(AuctionResult(session_id=session.id, player_id=player_id, winner_id=admin_user_id, final_price=base))
        db.add(FantasyRoster(
            fantasy_team_id=team_row.id,
            league_id=league_id,
            player_id=player_id,
            purchase_price=base,
            is_active=True,
        ))
        team_row.budget_remaining = team_row.budget_remaining - base
        session.current_player_id = None
        session.timer_ends_at = None
        await db.commit()
        await db.refresh(team_row)
        await _advance_turn(db, session)
        try:
            from app.api.websocket import broadcast_auction_update
            await broadcast_auction_update(
                league_id, "assigned",
                {"player_name": player.name, "winner_name": "Tu", "winner_id": str(admin_user_id), "amount": float(base)},
            )
        except Exception:
            pass
        real_team_name = None
        if player.real_team_id:
            rt = await db.execute(select(RealTeam.name).where(RealTeam.id == player.real_team_id))
            real_team_name = rt.scalar_one_or_none()
        return {
            "message": "Giocatore acquistato a prezzo base (solo tu in categoria)",
            "player_id": player.id,
            "player_name": player.name,
            "position": player_role,
            "real_team_name": real_team_name,
            "base_price": base,
            "timer_remaining": 0,
        }
    session.current_player_id = player_id
    session.current_min_bid = base
    session.timer_ends_at = _now() + timedelta(seconds=AUCTION_TIMER_SECONDS)
    await db.commit()
    await db.refresh(session)
    _schedule_expire(session.id, session.timer_ends_at)
    real_team_name = None
    if player.real_team_id:
        rt = await db.execute(select(RealTeam.name).where(RealTeam.id == player.real_team_id))
        real_team_name = rt.scalar_one_or_none()
    return {
        "message": "Giocatore nominato",
        "player_id": player.id,
        "player_name": player.name,
        "position": player_role,
        "real_team_name": real_team_name,
        "base_price": base,
        "timer_remaining": AUCTION_TIMER_SECONDS,
    }


def _category_label(cat: str) -> str:
    labels = {"POR": "PORTIERI", "DIF": "DIFENSORI", "CEN": "CENTROCAMPISTI", "ATT": "ATTACCANTI"}
    return labels.get(cat, cat)


def _schedule_expire(session_id: int, run_at: datetime) -> None:
    try:
        from app.tasks.scheduler import scheduler
        from app.services.auction_service import expire_auction_job
        job_id = f"expire_auction_{session_id}"
        scheduler.add_job(
            expire_auction_job,
            "date",
            run_date=run_at,
            id=job_id,
            args=[session_id],
            replace_existing=True,
        )
        logger.info("Scheduled expire_auction_%s at %s", session_id, run_at)
    except Exception as e:
        logger.exception("Schedule expire: %s", e)


def _cancel_expire(session_id: int) -> None:
    try:
        from app.tasks.scheduler import scheduler
        job_id = f"expire_auction_{session_id}"
        if scheduler.get_job(job_id):
            scheduler.remove_job(job_id)
            logger.info("Cancelled job %s", job_id)
    except Exception as e:
        logger.exception("Cancel expire: %s", e)


async def expire_auction_job(session_id: int) -> None:
    """Eseguito da APScheduler alla scadenza del timer. Assegna il giocatore all'ultimo offerente."""
    async with AsyncSessionLocal() as db:
        try:
            await _do_expire(db, session_id)
        except Exception as e:
            logger.exception("expire_auction_job session_id=%s: %s", session_id, e)
        finally:
            _cancel_expire(session_id)


async def _do_expire(db: AsyncSession, session_id: int) -> dict | None:
    """Logica di scadenza: assegna al miglior offerente, aggiorna roster e budget, notifiche."""
    r = await db.execute(select(AuctionSession).where(AuctionSession.id == session_id))
    session = r.scalar_one_or_none()
    if not session:
        return None
    player_id = session.current_player_id
    if not player_id:
        return None
    rp = await db.execute(select(Player).where(Player.id == player_id))
    player = rp.scalar_one_or_none()
    if not player:
        session.current_player_id = None
        session.timer_ends_at = None
        await db.commit()
        return None
    # Ultima offerta per questa sessione e questo giocatore (nessuna offerta = current_bid null, giocatore non assegnato)
    player_name = player.name
    rbid = await db.execute(
        select(AuctionBid).where(
            AuctionBid.session_id == session_id,
            AuctionBid.player_id == player_id,
        ).order_by(AuctionBid.amount.desc()).limit(1)
    )
    last_bid = rbid.scalar_one_or_none()
    min_bid = session.current_min_bid or Decimal("1")
    bid_amount = last_bid.amount if last_bid and last_bid.amount is not None else None
    if last_bid is None or bid_amount is None or bid_amount < min_bid:
        session.current_player_id = None
        session.timer_ends_at = None
        await db.commit()
        await _broadcast_expire_no_sale(db, session.league_id, player_name)
        await _advance_turn(db, session)
        return None
    winner_id = last_bid.bidder_id
    amount = last_bid.amount  # già validato sopra (bid_amount >= min_bid)
    rteam = await db.execute(
        select(FantasyTeam).where(
            FantasyTeam.league_id == session.league_id,
            FantasyTeam.user_id == winner_id,
        )
    )
    team = rteam.scalar_one_or_none()
    if not team or team.budget_remaining < amount:
        session.current_player_id = None
        session.timer_ends_at = None
        await db.commit()
        await _advance_turn(db, session)
        return None
    ok, err = await can_team_sign_player(db, team.id, player.position or "CEN")
    if not ok:
        session.current_player_id = None
        session.timer_ends_at = None
        await db.commit()
        await _advance_turn(db, session)
        return None
    db.add(AuctionResult(session_id=session_id, player_id=player_id, winner_id=winner_id, final_price=amount))
    db.add(FantasyRoster(
        fantasy_team_id=team.id,
        league_id=session.league_id,
        player_id=player_id,
        purchase_price=amount,
        is_active=True,
    ))
    team.budget_remaining = team.budget_remaining - amount
    session.current_player_id = None
    session.timer_ends_at = None
    await db.commit()
    await db.refresh(team)
    ruser = await db.execute(select(User.full_name, User.username).where(User.id == winner_id))
    row = ruser.one_or_none()
    winner_name = (row[0] or row[1] or "Vincitore") if row else "Vincitore"
    await _broadcast_expire_assigned(db, session.league_id, player.name, winner_name, winner_id, float(amount))
    await _advance_turn(db, session)
    return {"player_id": player_id, "player_name": player.name, "winner_id": winner_id, "winner_name": winner_name, "final_price": amount}


async def _broadcast_expire_no_sale(db: AsyncSession, league_id: UUID, player_name: str) -> None:
    try:
        from app.api.websocket import broadcast_auction_update
        await broadcast_auction_update(league_id, "expired_no_sale", {"player_name": player_name})
    except Exception:
        pass


async def _broadcast_expire_assigned(
    db: AsyncSession, league_id: UUID, player_name: str, winner_name: str, winner_id: UUID, amount: float
) -> None:
    try:
        from app.api.websocket import broadcast_auction_update
        from app.services.push_service import send_push_to_users
        await broadcast_auction_update(
            league_id, "assigned",
            {"player_name": player_name, "winner_name": winner_name, "winner_id": str(winner_id), "amount": amount},
        )
        r = await db.execute(select(FantasyTeam.user_id).where(FantasyTeam.league_id == league_id).distinct())
        user_ids = [row[0] for row in r.all()]
        if user_ids:
            await send_push_to_users(
                db, user_ids,
                "Aggiudicato!",
                f"🏆 {player_name} aggiudicato a {winner_name} per {amount:.0f} cr!",
            )
    except Exception as e:
        logger.exception("Broadcast/push expire: %s", e)


async def place_bid(
    db: AsyncSession, league_id: UUID, bidder_id: UUID, amount: Decimal
) -> dict:
    """Registra offerta. Verifica membro, budget, limite ruolo, amount > ultima offerta. Resetta timer 60s."""
    session = await get_active_session(db, league_id)
    if not session or session.status != "active":
        raise ValueError("Nessuna asta attiva")
    if not session.current_player_id:
        raise ValueError("Nessun giocatore attualmente all'asta")
    r = await db.execute(
        select(FantasyTeam).where(
            FantasyTeam.league_id == league_id,
            FantasyTeam.user_id == bidder_id,
        )
    )
    team = r.scalar_one_or_none()
    if not team:
        raise ValueError("Non sei membro di questa lega con una squadra")
    if team.budget_remaining < amount:
        raise ValueError(f"Budget insufficiente (disponibile: {team.budget_remaining})")
    rp = await db.execute(select(Player).where(Player.id == session.current_player_id))
    player = rp.scalar_one_or_none()
    if not player:
        raise ValueError("Giocatore non trovato")
    ok, err = await can_team_sign_player(db, team.id, player.position or "CEN")
    if not ok:
        raise ValueError(err)
    rlast = await db.execute(
        select(AuctionBid).where(
            AuctionBid.session_id == session.id,
            AuctionBid.player_id == session.current_player_id,
        ).order_by(AuctionBid.amount.desc()).limit(1)
    )
    last_bid = rlast.scalar_one_or_none()
    min_bid = session.current_min_bid
    if last_bid and last_bid.amount >= min_bid:
        min_bid = last_bid.amount + Decimal("1")
    if amount < min_bid:
        raise ValueError(f"Offerta minima: {min_bid} (incremento 1 credito)")
    if last_bid and last_bid.bidder_id == bidder_id:
        raise ValueError("Sei già l'ultimo offerente")
    db.add(AuctionBid(session_id=session.id, player_id=session.current_player_id, bidder_id=bidder_id, amount=amount))
    session.timer_ends_at = _now() + timedelta(seconds=AUCTION_TIMER_SECONDS)
    await db.commit()
    await db.refresh(session)
    _cancel_expire(session.id)
    _schedule_expire(session.id, session.timer_ends_at)
    ruser = await db.execute(select(User.full_name, User.username).where(User.id == bidder_id))
    row = ruser.one_or_none()
    bidder_name = (row[0] or row[1] or "Qualcuno") if row else "Qualcuno"
    try:
        from app.api.websocket import broadcast_auction_update
        await broadcast_auction_update(
            session.league_id, "bid",
            {"amount": float(amount), "bidder": bidder_name, "bidder_id": str(bidder_id), "timer_remaining": AUCTION_TIMER_SECONDS},
        )
        from app.services.push_service import send_push_to_users
        r2 = await db.execute(select(FantasyTeam.user_id).where(FantasyTeam.league_id == league_id).distinct())
        user_ids = [row[0] for row in r2.all() if row[0] != bidder_id]
        if user_ids:
            await send_push_to_users(
                db, user_ids,
                "Nuova offerta",
                f"💰 {bidder_name} offre {amount:.0f} cr per {player.name}! Timer reset 60s",
            )
    except Exception:
        pass
    return {
        "message": "Offerta registrata",
        "amount": amount,
        "is_leading": True,
        "timer_remaining": AUCTION_TIMER_SECONDS,
    }


async def get_status(db: AsyncSession, league_id: UUID, current_user_id: UUID | None = None) -> dict:
    """Stato corrente: status, current_player, current_bid, timer_remaining, participants, turni (current_category, current_turn_*, category_progress, is_my_turn)."""
    r = await db.execute(
        select(AuctionSession).where(AuctionSession.league_id == league_id)
        .order_by(AuctionSession.id.desc()).limit(1)
    )
    session = r.scalar_one_or_none()
    if not session:
        return {"status": "idle", "participants": [], "eligible_bidders": []}
    participants = []
    rteams = await db.execute(
        select(FantasyTeam.id, FantasyTeam.user_id, FantasyTeam.name, FantasyTeam.budget_remaining).where(
            FantasyTeam.league_id == league_id
        )
    )
    current_player_id = session.current_player_id
    category = (session.current_category or "POR")[:3].upper()
    required = ROLE_LIMITS.get(category, 8)
    category_progress = {}
    current_turn_user_id = None
    current_turn_user_name = None
    is_my_turn = False
    order = _turn_order_uids(session)
    if order and session.current_turn_index is not None and 0 <= session.current_turn_index < len(order):
        current_turn_user_id = order[session.current_turn_index]
        rn = await db.execute(select(User.full_name, User.username).where(User.id == current_turn_user_id))
        un = rn.one_or_none()
        current_turn_user_name = (un[0] or un[1] or "Squadra") if un else "Squadra"
        if current_user_id:
            is_my_turn = current_turn_user_id == current_user_id
    for uid in order:
        n = await _count_role_in_roster_for_user(db, league_id, uid, category)
        category_progress[str(uid)] = {"completed": n, "required": required}
    active_in_category = await _get_active_user_ids_for_category(db, session)
    is_only_one_left = (
        len(active_in_category) == 1
        and current_user_id is not None
        and current_user_id in active_in_category
    )
    player_position = None
    if current_player_id:
        rp = await db.execute(select(Player.position).where(Player.id == current_player_id))
        player_position = (rp.scalar_one_or_none() or "CEN")[:3].upper()
    eligible_bidders = []
    for (team_id, user_id, team_name, budget) in rteams.all():
        roster_count = await _roster_total_count(db, team_id)
        can_bid = True
        if session.status != "active" or not current_player_id:
            can_bid = False
        elif budget < session.current_min_bid:
            can_bid = False
        elif player_position:
            counts = await _count_roles_in_roster(db, team_id)
            total = sum(counts.values())
            if total >= TOTAL_ROSTER_LIMIT:
                can_bid = False
            elif counts.get(player_position, 0) >= ROLE_LIMITS.get(player_position, 8):
                can_bid = False
        if can_bid and current_player_id:
            rlast = await db.execute(
                select(AuctionBid.bidder_id).where(
                    AuctionBid.session_id == session.id,
                    AuctionBid.player_id == current_player_id,
                ).order_by(AuctionBid.amount.desc()).limit(1)
            )
            last = rlast.scalar_one_or_none()
            if last and last == user_id:
                can_bid = False  # già ultimo offerente
        if can_bid:
            eligible_bidders.append(user_id)
        ruser = await db.execute(select(User.full_name, User.username).where(User.id == user_id))
        urow = ruser.one_or_none()
        name = (urow[0] or urow[1] or team_name or "Squadra") if urow else (team_name or "Squadra")
        prog = category_progress.get(str(user_id), {"completed": 0, "required": required})
        participants.append({
            "id": user_id,
            "name": name,
            "budget": budget,
            "roster_count": roster_count,
            "can_bid": can_bid,
            "current_role_completed": prog["completed"],
            "current_role_required": prog["required"],
        })
    out = {
        "status": session.status,
        "current_player": None,
        "current_bid": None,
        "timer_remaining": None,
        "eligible_bidders": eligible_bidders,
        "participants": participants,
        "current_category": category,
        "current_turn_user_id": current_turn_user_id,
        "current_turn_user_name": current_turn_user_name,
        "category_progress": category_progress,
        "is_my_turn": is_my_turn,
        "is_only_one_left_in_category": is_only_one_left,
    }
    if current_player_id:
        rp = await db.execute(
            select(
                Player.id,
                Player.name,
                Player.position,
                Player.photo_url,
                Player.photo_local,
                Player.cutout_url,
                Player.cutout_local,
                Player.initial_price,
                Player.real_team_id,
            ).where(Player.id == current_player_id)
        )
        prow = rp.one_or_none()
        if prow:
            real_team_name = None
            if prow[8]:
                rtn = await db.execute(select(RealTeam.name).where(RealTeam.id == prow[8]))
                real_team_name = rtn.scalar_one_or_none()
            photo_url = f"/static/{prow[4]}" if prow[4] else prow[3]
            cutout_url = f"/static/{prow[6]}" if prow[6] else prow[5]
            out["current_player"] = {
                "id": prow[0],
                "name": prow[1],
                "role": (prow[2] or "CEN")[:3],
                "team": real_team_name,
                "photo_url": photo_url,
                "cutout_url": cutout_url,
                "base_price": prow[7] or Decimal("1"),
            }
        if session.timer_ends_at:
            out["timer_remaining"] = max(0, int((session.timer_ends_at - _now()).total_seconds()))
        rbid = await db.execute(
            select(AuctionBid.amount, AuctionBid.bidder_id).where(
                AuctionBid.session_id == session.id,
                AuctionBid.player_id == current_player_id,
            ).order_by(AuctionBid.amount.desc()).limit(1)
        )
        last_bid_row = rbid.one_or_none()
        if last_bid_row:
            bidder_id = last_bid_row[1]
            ruser = await db.execute(select(User.full_name, User.username).where(User.id == bidder_id))
            urow = ruser.one_or_none()
            bidder_name = (urow[0] or urow[1] or "Offerente") if urow else "Offerente"
            out["current_bid"] = {"amount": last_bid_row[0], "bidder": bidder_name, "bidder_id": bidder_id}
    return out


async def pause_session(db: AsyncSession, league_id: UUID, user_id: UUID) -> dict:
    """Mette in pausa l'asta (solo admin). Il timer non viene eseguito finché non si riattiva (stesso status active con current_player)."""
    session = await get_active_session(db, league_id)
    if not session:
        raise ValueError("Nessuna asta attiva")
    session.status = "paused"
    _cancel_expire(session.id)
    await db.commit()
    return {"message": "Asta in pausa", "status": "paused"}


async def stop_session(db: AsyncSession, league_id: UUID, user_id: UUID) -> dict:
    """Termina la sessione d'asta (solo admin)."""
    session = await get_active_session(db, league_id)
    if not session:
        raise ValueError("Nessuna asta attiva")
    session.status = "completed"
    session.current_player_id = None
    session.timer_ends_at = None
    _cancel_expire(session.id)
    await db.commit()
    return {"message": "Asta terminata", "status": "completed"}


# --- Compat con vecchio flusso (GET current, history) ---

async def get_current(db: AsyncSession, league_id: UUID) -> dict | None:
    """Ritorna stato asta corrente in formato legacy (current_player, highest_bid, ends_at) per GET /auction/current."""
    data = await get_status(db, league_id)
    if data["status"] == "idle" or not data.get("current_player"):
        return None
    cp = data["current_player"]
    cb = data.get("current_bid")
    ends_at = None
    if data.get("timer_remaining") is not None:
        from datetime import timedelta
        ends_at = _now() + timedelta(seconds=data["timer_remaining"])
    return {
        "player_id": cp["id"],
        "player_name": cp["name"],
        "position": cp["role"],
        "real_team_name": cp.get("team"),
        "highest_bid": cb["amount"] if cb else Decimal("0"),
        "highest_bidder_team_id": None,
        "highest_bidder_team_name": cb["bidder"] if cb else None,
        "ends_at": ends_at or _now(),
        "seconds_remaining": data.get("timer_remaining") or 0,
        "round_number": None,
    }


async def get_history(db: AsyncSession, league_id: UUID) -> list[dict]:
    """Storico acquisti asta (roster con purchase_price)."""
    r = await db.execute(
        select(
            Player.id,
            Player.name,
            Player.position,
            FantasyTeam.id.label("team_id"),
            FantasyTeam.name.label("team_name"),
            FantasyRoster.purchase_price,
            FantasyRoster.purchased_at,
        )
        .join(FantasyRoster, FantasyRoster.player_id == Player.id)
        .join(FantasyTeam, FantasyTeam.id == FantasyRoster.fantasy_team_id)
        .where(
            FantasyTeam.league_id == league_id,
            FantasyRoster.is_active == True,
            FantasyRoster.purchase_price.isnot(None),
        )
        .order_by(FantasyRoster.purchased_at.desc())
    )
    rows = r.all()
    return [
        {
            "player_id": row.id,
            "player_name": row.name,
            "position": row.position or "CEN",
            "fantasy_team_id": row.team_id,
            "team_name": row.team_name,
            "amount": row.purchase_price,
            "purchased_at": row.purchased_at,
        }
        for row in rows
    ]

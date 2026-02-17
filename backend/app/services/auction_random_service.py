"""
Asta random: busta chiusa, turni con N giocatori per ruolo, timer, offerte segrete.
Ruoli: P=POR, D=DIF, C=CEN, A=ATT.
"""
import logging
import random
from datetime import datetime, timedelta
from uuid import UUID

from sqlalchemy import select, func, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.auction_config import AuctionConfig
from app.models.league import FantasyLeague
from app.models.auction_turn import AuctionTurn
from app.models.auction_turn_player import AuctionTurnPlayer
from app.models.auction_turn_bid import AuctionTurnBid
from app.models.auction_player_order import AuctionPlayerOrder
from app.models.fantasy_league_member import FantasyLeagueMember
from app.models.fantasy_team import FantasyTeam
from app.models.fantasy_roster import FantasyRoster
from app.models.auction_purchase import AuctionPurchase
from app.models.player import Player
from app.models.real_team import RealTeam
from app.models.user import User

logger = logging.getLogger(__name__)

ROLE_TO_POSITION = {"P": "POR", "D": "DIF", "C": "CEN", "A": "ATT"}
ROLE_ORDER = ["P", "D", "C", "A"]


def _role_to_position(role: str) -> str:
    return ROLE_TO_POSITION.get(role.upper(), "CEN")


async def get_config(db: AsyncSession, league_id: UUID) -> AuctionConfig | None:
    r = await db.execute(
        select(AuctionConfig).where(AuctionConfig.league_id == league_id)
    )
    return r.scalar_one_or_none()


def _config_to_dict(c: AuctionConfig) -> dict:
    """Serializza config per GET API."""
    return {
        "budget_per_team": c.budget_per_team,
        "max_roster_size": c.max_roster_size,
        "min_goalkeepers": c.min_goalkeepers,
        "min_defenders": c.min_defenders,
        "min_midfielders": c.min_midfielders,
        "min_attackers": c.min_attackers,
        "base_price": getattr(c, "base_price", 1),
        "bid_timer_seconds": getattr(c, "bid_timer_seconds", None) or 60,
        "min_raise": getattr(c, "min_raise", None) or 1,
        "call_order": getattr(c, "call_order", None) or "random",
        "allow_nomination": getattr(c, "allow_nomination", True) if hasattr(c, "allow_nomination") else True,
        "pause_between_players": getattr(c, "pause_between_players", None) or 10,
        "players_per_turn_p": c.players_per_turn_p,
        "players_per_turn_d": c.players_per_turn_d,
        "players_per_turn_c": c.players_per_turn_c,
        "players_per_turn_a": c.players_per_turn_a,
        "turn_duration_hours": c.turn_duration_hours,
        "rounds_count": getattr(c, "rounds_count", None) or 3,
        "reveal_bids": getattr(c, "reveal_bids", False) if hasattr(c, "reveal_bids") else False,
        "allow_same_player_bids": getattr(c, "allow_same_player_bids", True) if hasattr(c, "allow_same_player_bids") else True,
        "max_bids_per_round": getattr(c, "max_bids_per_round", None) or 5,
        "tie_breaker": getattr(c, "tie_breaker", None) or "budget",
        "status": c.status,
    }


async def configure(
    db: AsyncSession,
    league_id: UUID,
    *,
    players_per_turn_p: int = 3,
    players_per_turn_d: int = 5,
    players_per_turn_c: int = 5,
    players_per_turn_a: int = 3,
    turn_duration_hours: int = 24,
    budget_per_team: int = 500,
    max_roster_size: int = 25,
    min_goalkeepers: int = 3,
    min_defenders: int = 8,
    min_midfielders: int = 8,
    min_attackers: int = 6,
    base_price: int = 1,
    bid_timer_seconds: int | None = 60,
    min_raise: int | None = 1,
    call_order: str | None = "random",
    allow_nomination: bool | None = True,
    pause_between_players: int | None = 10,
    rounds_count: int | None = 3,
    reveal_bids: bool | None = False,
    allow_same_player_bids: bool | None = True,
    max_bids_per_round: int | None = 5,
    tie_breaker: str | None = "budget",
) -> AuctionConfig:
    """Crea o aggiorna auction_config (rosa + classica/busta). Per tipo random genera ordine giocatori."""
    r_league = await db.execute(select(FantasyLeague).where(FantasyLeague.id == league_id))
    league = r_league.scalar_one_or_none()
    auction_type = (league.auction_type if league else "classic") or "classic"

    config = await get_config(db, league_id)
    if not config:
        config = AuctionConfig(league_id=league_id, auction_type=auction_type)
        db.add(config)
    config.auction_type = auction_type
    config.players_per_turn_p = max(1, players_per_turn_p)
    config.players_per_turn_d = max(1, players_per_turn_d)
    config.players_per_turn_c = max(1, players_per_turn_c)
    config.players_per_turn_a = max(1, players_per_turn_a)
    config.turn_duration_hours = turn_duration_hours
    config.budget_per_team = budget_per_team
    config.max_roster_size = max_roster_size
    config.min_goalkeepers = min_goalkeepers
    config.min_defenders = min_defenders
    config.min_midfielders = min_midfielders
    config.min_attackers = min_attackers
    config.base_price = base_price
    config.bid_timer_seconds = bid_timer_seconds
    config.min_raise = min_raise
    config.call_order = call_order or "random"
    config.allow_nomination = allow_nomination if allow_nomination is not None else True
    config.pause_between_players = pause_between_players
    config.rounds_count = rounds_count
    config.reveal_bids = reveal_bids if reveal_bids is not None else False
    config.allow_same_player_bids = allow_same_player_bids if allow_same_player_bids is not None else True
    config.max_bids_per_round = max_bids_per_round
    config.tie_breaker = tie_breaker or "budget"
    config.status = "pending"
    config.current_role = "P"
    config.current_turn = 0
    await db.flush()

    if auction_type == "random":
        await db.execute(delete(AuctionPlayerOrder).where(AuctionPlayerOrder.auction_config_id == config.id))
        await db.flush()
        r = await db.execute(
            select(Player.id, Player.position).where(Player.is_active == True)
        )
        players_by_role: dict[str, list[int]] = {"P": [], "D": [], "C": [], "A": []}
        for (pid, pos) in r.all():
            pos = (pos or "")[:3].upper()
            if pos == "POR":
                players_by_role["P"].append(pid)
            elif pos == "DIF":
                players_by_role["D"].append(pid)
            elif pos == "CEN":
                players_by_role["C"].append(pid)
            elif pos == "ATT":
                players_by_role["A"].append(pid)
        for role in ROLE_ORDER:
            ids = players_by_role.get(role, [])
            random.shuffle(ids)
            for i, player_id in enumerate(ids):
                order = AuctionPlayerOrder(
                    auction_config_id=config.id,
                    player_id=player_id,
                    role=role,
                    random_order=i,
                    proposed=False,
                )
                db.add(order)
    await db.commit()
    await db.refresh(config)
    return config


async def start(db: AsyncSession, league_id: UUID) -> dict:
    """Verifica che tutti i partecipanti abbiano una fantasy_team, imposta status=active, crea primo turno."""
    config = await get_config(db, league_id)
    if not config:
        raise ValueError("Configura prima l'asta con POST /auction/configure")
    if config.status != "pending":
        raise ValueError("L'asta è già stata avviata o completata")

    # Tutti i membri della lega (non bloccati) devono avere una squadra
    r = await db.execute(
        select(FantasyLeagueMember.user_id).where(
            FantasyLeagueMember.league_id == league_id,
            FantasyLeagueMember.status != "blocked",
        )
    )
    member_ids = [row[0] for row in r.all()]
    r2 = await db.execute(
        select(FantasyTeam.user_id).where(FantasyTeam.league_id == league_id).distinct()
    )
    team_user_ids = {row[0] for row in r2.all()}
    missing = set(member_ids) - team_user_ids
    if missing:
        raise ValueError("Tutti i partecipanti devono avere una squadra fantasy prima di avviare l'asta")

    # Imposta budget iniziale per tutte le squadre della lega
    r3 = await db.execute(select(FantasyTeam).where(FantasyTeam.league_id == league_id))
    for team in r3.scalars().all():
        team.budget_remaining = config.budget_per_team
    config.status = "active"
    config.started_at = datetime.utcnow()
    config.current_role = "P"
    config.current_turn = 0
    await db.flush()

    # Crea primo turno (portieri)
    turn = await _create_next_turn(db, config)
    await db.commit()
    await db.refresh(config)
    return {
        "status": "active",
        "config_id": config.id,
        "first_turn_id": turn.id if turn else None,
        "expires_at": turn.expires_at.isoformat() if turn else None,
    }


def _players_per_turn(config: AuctionConfig, role: str) -> int:
    if role == "P":
        return config.players_per_turn_p
    if role == "D":
        return config.players_per_turn_d
    if role == "C":
        return config.players_per_turn_c
    return config.players_per_turn_a


async def _create_next_turn(db: AsyncSession, config: AuctionConfig) -> AuctionTurn | None:
    """Crea il prossimo turno: prende i prossimi N giocatori del ruolo corrente non ancora proposti."""
    role = config.current_role
    n = _players_per_turn(config, role)
    r = await db.execute(
        select(AuctionPlayerOrder)
        .where(
            AuctionPlayerOrder.auction_config_id == config.id,
            AuctionPlayerOrder.role == role,
            AuctionPlayerOrder.proposed == False,
        )
        .order_by(AuctionPlayerOrder.random_order)
        .limit(n)
    )
    orders = list(r.scalars().all())
    if not orders:
        # Passa al ruolo successivo
        idx = ROLE_ORDER.index(role)
        if idx + 1 >= len(ROLE_ORDER):
            config.status = "completed"
            config.completed_at = datetime.utcnow()
            return None
        config.current_role = ROLE_ORDER[idx + 1]
        config.current_turn = 0
        await db.flush()
        return await _create_next_turn(db, config)

    config.current_turn += 1
    expires_at = datetime.utcnow() + timedelta(hours=config.turn_duration_hours)
    turn = AuctionTurn(
        auction_config_id=config.id,
        turn_number=config.current_turn,
        role=role,
        status="active",
        expires_at=expires_at,
    )
    db.add(turn)
    await db.flush()

    for o in orders:
        o.proposed = True
        atp = AuctionTurnPlayer(
            auction_turn_id=turn.id,
            player_id=o.player_id,
            status="available",
        )
        db.add(atp)
    await db.flush()
    return turn


async def get_current_turn_info(db: AsyncSession, league_id: UUID, user_id: UUID) -> dict | None:
    """Ritorna il turno attivo con giocatori, tempo rimanente, le MIE offerte, il mio budget."""
    config = await get_config(db, league_id)
    if not config or config.status != "active":
        return None
    r = await db.execute(
        select(AuctionTurn)
        .where(
            AuctionTurn.auction_config_id == config.id,
            AuctionTurn.status == "active",
        )
        .order_by(AuctionTurn.started_at.desc())
        .limit(1)
    )
    turn = r.scalar_one_or_none()
    if not turn:
        return None

    # Giocatori del turno con dettagli
    r2 = await db.execute(
        select(AuctionTurnPlayer, Player, RealTeam.name)
        .join(Player, AuctionTurnPlayer.player_id == Player.id)
        .outerjoin(RealTeam, Player.real_team_id == RealTeam.id)
        .where(AuctionTurnPlayer.auction_turn_id == turn.id)
    )
    rows = r2.all()
    team_id_r = await db.execute(
        select(FantasyTeam.id).where(
            FantasyTeam.league_id == league_id,
            FantasyTeam.user_id == user_id,
        )
    )
    my_team_id = team_id_r.scalar_one_or_none()
    if not my_team_id:
        my_team_id = None

    my_bids = {}
    if my_team_id:
        r3 = await db.execute(
            select(AuctionTurnBid.auction_turn_player_id, AuctionTurnBid.bid_amount).where(
                AuctionTurnBid.fantasy_team_id == my_team_id,
                AuctionTurnBid.auction_turn_player_id.in_(
                    [atp.id for atp, _, _ in rows]
                ),
            )
        )
        for (atp_id, amount) in r3.all():
            my_bids[atp_id] = amount

    budget_remaining = None
    if my_team_id:
        r4 = await db.execute(select(FantasyTeam.budget_remaining).where(FantasyTeam.id == my_team_id))
        budget_remaining = float(r4.scalar_one() or 0)

    now = datetime.utcnow()
    seconds_left = max(0, int((turn.expires_at - now).total_seconds()))

    players_list = []
    for atp, player, real_team_name in rows:
        players_list.append({
            "auction_turn_player_id": atp.id,
            "player_id": player.id,
            "name": player.name,
            "position": player.position,
            "real_team": real_team_name,
            "initial_price": float(player.initial_price or 1),
            "photo_url": getattr(player, "photo_url", None) or getattr(player, "avatar_url", None),
            "cutout_url": getattr(player, "cutout_url", None),
            "my_bid": my_bids.get(atp.id),
        })

    return {
        "turn_id": turn.id,
        "turn_number": turn.turn_number,
        "role": turn.role,
        "expires_at": turn.expires_at.isoformat(),
        "seconds_remaining": seconds_left,
        "players": players_list,
        "my_budget_remaining": budget_remaining,
        "config_budget": config.budget_per_team,
    }


async def place_bid(
    db: AsyncSession, league_id: UUID, user_id: UUID, player_id: int, amount: int
) -> dict:
    """Registra o aggiorna offerta segreta. Verifica: turno attivo, tempo non scaduto, budget, limiti rosa."""
    if amount < 1:
        raise ValueError("L'offerta minima è 1 credito")

    config = await get_config(db, league_id)
    if not config or config.status != "active":
        raise ValueError("Nessuna asta attiva")

    r = await db.execute(
        select(AuctionTurn).where(
            AuctionTurn.auction_config_id == config.id,
            AuctionTurn.status == "active",
        ).limit(1)
    )
    turn = r.scalar_one_or_none()
    if not turn:
        raise ValueError("Nessun turno attivo")
    if datetime.utcnow() >= turn.expires_at:
        raise ValueError("Il turno è già scaduto")

    r2 = await db.execute(
        select(AuctionTurnPlayer).where(
            AuctionTurnPlayer.auction_turn_id == turn.id,
            AuctionTurnPlayer.player_id == player_id,
        )
    )
    atp = r2.scalar_one_or_none()
    if not atp:
        raise ValueError("Questo giocatore non è in questo turno")

    r3 = await db.execute(
        select(FantasyTeam).where(
            FantasyTeam.league_id == league_id,
            FantasyTeam.user_id == user_id,
        )
    )
    team = r3.scalar_one_or_none()
    if not team:
        raise ValueError("Non hai una squadra in questa lega")

    # Budget disponibile = budget_remaining - somme offerte attive in QUESTO turno (per non doppio impegno)
    r4 = await db.execute(
        select(func.coalesce(func.sum(AuctionTurnBid.bid_amount), 0)).where(
            AuctionTurnBid.fantasy_team_id == team.id,
            AuctionTurnBid.auction_turn_player_id.in_(
                select(AuctionTurnPlayer.id).where(AuctionTurnPlayer.auction_turn_id == turn.id)
            ),
        )
    )
    current_turn_bids_sum = (r4.scalar_one() or 0) or 0
    r5 = await db.execute(
        select(AuctionTurnBid.bid_amount).where(
            AuctionTurnBid.auction_turn_player_id == atp.id,
            AuctionTurnBid.fantasy_team_id == team.id,
        )
    )
    existing_bid = r5.scalar_one_or_none()
    available = float(team.budget_remaining) - current_turn_bids_sum + (existing_bid or 0)
    if amount > available:
        raise ValueError(f"Budget insufficiente. Disponibile: {int(available)} crediti")

    # Rosa: non superare max per ruolo
    r6 = await db.execute(select(Player).where(Player.id == player_id))
    player = r6.scalar_one_or_none()
    if not player:
        raise ValueError("Giocatore non trovato")
    pos = (player.position or "CEN")[:3].upper()
    limits = {"POR": config.min_goalkeepers, "DIF": config.min_defenders, "CEN": config.min_midfielders, "ATT": config.min_attackers}
    limit = limits.get(pos, config.max_roster_size)
    r7 = await db.execute(
        select(func.count(FantasyRoster.id))
        .select_from(FantasyRoster)
        .join(Player, FantasyRoster.player_id == Player.id)
        .where(
            FantasyRoster.fantasy_team_id == team.id,
            FantasyRoster.is_active == True,
            Player.position == pos,
        )
    )
    current_role_count = r7.scalar_one() or 0
    if current_role_count >= limit:
        raise ValueError(f"Rosa: limite ruolo {pos} raggiunto (max {limit})")

    # Upsert bid
    r8 = await db.execute(
        select(AuctionTurnBid).where(
            AuctionTurnBid.auction_turn_player_id == atp.id,
            AuctionTurnBid.fantasy_team_id == team.id,
        )
    )
    bid = r8.scalar_one_or_none()
    if bid:
        bid.bid_amount = amount
    else:
        bid = AuctionTurnBid(
            auction_turn_player_id=atp.id,
            fantasy_team_id=team.id,
            bid_amount=amount,
        )
        db.add(bid)
    await db.commit()
    return {"message": "Offerta registrata", "player_id": player_id, "amount": amount}


async def get_turn_results(db: AsyncSession, league_id: UUID, turn_number: int) -> dict | None:
    """Risultati di un turno completato: per ogni giocatore vincitore, importo, tutte le offerte."""
    config = await get_config(db, league_id)
    if not config:
        return None
    r = await db.execute(
        select(AuctionTurn).where(
            AuctionTurn.auction_config_id == config.id,
            AuctionTurn.turn_number == turn_number,
            AuctionTurn.status == "completed",
        )
    )
    turn = r.scalar_one_or_none()
    if not turn:
        return None

    r2 = await db.execute(
        select(AuctionTurnPlayer, Player, RealTeam.name, FantasyTeam.name, User.username)
        .join(Player, AuctionTurnPlayer.player_id == Player.id)
        .outerjoin(RealTeam, Player.real_team_id == RealTeam.id)
        .outerjoin(FantasyTeam, AuctionTurnPlayer.winner_team_id == FantasyTeam.id)
        .outerjoin(User, FantasyTeam.user_id == User.id)
        .where(AuctionTurnPlayer.auction_turn_id == turn.id)
    )
    rows = r2.all()
    r3 = await db.execute(
        select(AuctionTurnBid.auction_turn_player_id, AuctionTurnBid.bid_amount, User.username)
        .join(FantasyTeam, AuctionTurnBid.fantasy_team_id == FantasyTeam.id)
        .join(User, FantasyTeam.user_id == User.id)
        .where(
            AuctionTurnBid.auction_turn_player_id.in_([atp.id for atp, *_ in rows])
        )
        .order_by(AuctionTurnBid.bid_amount.desc(), AuctionTurnBid.created_at.asc())
    )
    bids_by_atp: dict[int, list[tuple[int, str]]] = {}
    for (atp_id, amount, username) in r3.all():
        bids_by_atp.setdefault(atp_id, []).append((amount, username or ""))

    results = []
    for atp, player, real_team_name, winner_team_name, winner_username in rows:
        bids = bids_by_atp.get(atp.id, [])
        results.append({
            "player_id": player.id,
            "player_name": player.name,
            "position": player.position,
            "real_team": real_team_name,
            "winner_team_name": winner_team_name,
            "winner_username": winner_username,
            "winning_bid": atp.winning_bid,
            "status": atp.status,
            "all_bids": [{"amount": a, "username": u} for a, u in bids],
        })
    return {
        "turn_id": turn.id,
        "turn_number": turn.turn_number,
        "role": turn.role,
        "completed_at": turn.completed_at.isoformat() if turn.completed_at else None,
        "results": results,
    }


async def get_random_auction_status(db: AsyncSession, league_id: UUID) -> dict | None:
    """Stato generale asta random: ruolo corrente, turno, budget di tutti, rose."""
    config = await get_config(db, league_id)
    if not config or config.auction_type != "random":
        return None
    r = await db.execute(
        select(FantasyTeam, User.username).join(User, FantasyTeam.user_id == User.id).where(
            FantasyTeam.league_id == league_id
        )
    )
    teams = []
    for team, username in r.all():
        r2 = await db.execute(
            select(func.count(FantasyRoster.id)).where(
                FantasyRoster.fantasy_team_id == team.id,
                FantasyRoster.is_active == True,
            )
        )
        roster_count = r2.scalar_one() or 0
        teams.append({
            "team_id": str(team.id),
            "team_name": team.name,
            "username": username,
            "budget_remaining": float(team.budget_remaining or 0),
            "roster_size": roster_count,
        })
    active_turn = None
    r3 = await db.execute(
        select(AuctionTurn).where(
            AuctionTurn.auction_config_id == config.id,
            AuctionTurn.status == "active",
        ).limit(1)
    )
    t = r3.scalar_one_or_none()
    if t:
        active_turn = {"turn_number": t.turn_number, "role": t.role, "expires_at": t.expires_at.isoformat()}
    return {
        "config_id": config.id,
        "status": config.status,
        "current_role": config.current_role,
        "current_turn": config.current_turn,
        "teams": teams,
        "active_turn": active_turn,
    }


async def resolve_expired_turns(db: AsyncSession, league_id: UUID | None = None) -> int:
    """Trova turni scaduti (status=active, expires_at <= now), risolvi ciascuno e crea il successivo. Ritorna numero risolti.
    Se league_id è fornito, risolve solo i turni di quella lega."""
    now = datetime.utcnow()
    q = select(AuctionTurn).where(
        AuctionTurn.status == "active",
        AuctionTurn.expires_at <= now,
    )
    if league_id is not None:
        subq = select(AuctionConfig.id).where(AuctionConfig.league_id == league_id)
        q = q.where(AuctionTurn.auction_config_id.in_(subq))
    r = await db.execute(q)
    turns = list(r.scalars().all())
    count = 0
    for turn in turns:
        try:
            await _resolve_one_turn(db, turn)
            count += 1
        except Exception as e:
            logger.exception("resolve turn %s: %s", turn.id, e)
    return count


async def _resolve_one_turn(db: AsyncSession, turn: AuctionTurn) -> None:
    """Assegna ogni giocatore al miglior offerente, scala budget, aggiorna rosa; crea turno successivo."""
    r0 = await db.execute(select(AuctionConfig).where(AuctionConfig.id == turn.auction_config_id))
    config = r0.scalar_one_or_none()
    if not config:
        return

    r = await db.execute(
        select(AuctionTurnPlayer).where(AuctionTurnPlayer.auction_turn_id == turn.id)
    )
    atp_list = list(r.scalars().all())
    for atp in atp_list:
        r2 = await db.execute(
            select(AuctionTurnBid)
            .where(AuctionTurnBid.auction_turn_player_id == atp.id)
            .order_by(AuctionTurnBid.bid_amount.desc(), AuctionTurnBid.created_at.asc())
        )
        bids = list(r2.scalars().all())
        if not bids:
            atp.status = "unsold"
            continue
        winner_bid = bids[0]
        atp.winner_team_id = winner_bid.fantasy_team_id
        atp.winning_bid = winner_bid.bid_amount
        atp.status = "sold"
        # Scala budget
        r3 = await db.execute(select(FantasyTeam).where(FantasyTeam.id == winner_bid.fantasy_team_id))
        team = r3.scalar_one_or_none()
        if team:
            team.budget_remaining = (team.budget_remaining or 0) - winner_bid.bid_amount
        # Aggiungi a rosa
        roster = FantasyRoster(
            fantasy_team_id=winner_bid.fantasy_team_id,
            league_id=config.league_id,
            player_id=atp.player_id,
            purchase_price=winner_bid.bid_amount,
        )
        db.add(roster)
        db.add(AuctionPurchase(
            league_id=config.league_id,
            team_id=winner_bid.fantasy_team_id,
            player_id=atp.player_id,
            price=int(winner_bid.bid_amount),
        ))

    turn.status = "completed"
    turn.completed_at = datetime.utcnow()
    await db.flush()
    next_turn = await _create_next_turn(db, config)
    if next_turn:
        await db.flush()
    await db.commit()

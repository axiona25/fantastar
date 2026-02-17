"""
API Leghe fantasy: create, list, detail, join, roster, generate-calendar, standings, admin (delete, members).
"""
from datetime import datetime
from decimal import Decimal
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, func, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import aliased

from app.database import get_db
from app.models.user import User
from app.models.league import FantasyLeague
from app.models.fantasy_league_member import FantasyLeagueMember
from app.models.fantasy_team import FantasyTeam
from app.models.fantasy_roster import FantasyRoster
from app.services.market_service import buy_free_agent
from app.services.push_service import send_push_to_users
from app.models.fantasy_calendar import FantasyCalendar
from app.schemas.league import (
    LeagueCreate,
    LeagueJoin,
    LeagueResponse,
    LeagueDetailResponse,
    StandingRow,
    MatchdayResultRow,
    MatchdayResultDetailRow,
    PlayerScoreDetail,
    CalendarMatchRow,
    LeagueMemberRow,
    LeagueBlockRequest,
    PostponedMatchCreate,
)
from app.models.serie_a_postponed import SerieAPostponed
from app.dependencies import get_current_user
from app.services.league_service import generate_invite_code, generate_calendar_for_league
from app.services.scoring_engine import ScoringEngine, get_postponed_team_ids

router = APIRouter(prefix="/leagues", tags=["leagues"])


async def _get_league_or_404(db: AsyncSession, league_id: UUID) -> FantasyLeague | None:
    """Ritorna la lega se esiste e is_active=True, altrimenti None (chiamante solleva 404)."""
    r = await db.execute(
        select(FantasyLeague).where(FantasyLeague.id == league_id, FantasyLeague.is_active == True)
    )
    return r.scalar_one_or_none()


def _league_gone_404():
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Questa lega non esiste più")


PUBLIC_LEAGUE_SPLIT_THRESHOLD = 1000


async def _get_root_league(db: AsyncSession, league: FantasyLeague) -> FantasyLeague:
    """Ritorna la lega root (senza parent)."""
    if not league.parent_league_id:
        return league
    r = await db.execute(select(FantasyLeague).where(FantasyLeague.id == league.parent_league_id))
    parent = r.scalar_one_or_none()
    if not parent:
        return league
    return await _get_root_league(db, parent)


async def _get_display_name(db: AsyncSession, league: FantasyLeague) -> str:
    """Per leghe figlie (auto_created) ritorna il nome della root; altrimenti league.name."""
    if not getattr(league, "parent_league_id", None):
        return league.name
    root = await _get_root_league(db, league)
    return root.name


@router.post("", response_model=LeagueResponse)
async def create_league(
    body: LeagueCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Crea lega fantasy (l'utente corrente diventa admin)."""
    if body.league_type == "private" and (body.max_members is None or body.max_members < 2 or body.max_members > 20):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Il numero di partecipanti deve essere tra 2 e 20",
        )
    if body.league_type == "private" and body.max_members is not None and body.max_members % 2 != 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Il numero di partecipanti deve essere pari (4, 6, 8, ..., 20)",
        )
    n_teams = body.max_members if (body.league_type == "private" and body.max_members) else (body.max_teams or 10)
    total_rounds = (n_teams - 1) * 2
    max_start = 38 - total_rounds + 1
    if body.start_matchday < 1 or body.start_matchday > max_start:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"La giornata di inizio deve essere tra 1 e {max_start}",
        )
    invite = body.invite_code or generate_invite_code()
    r = await db.execute(select(FantasyLeague).where(FantasyLeague.invite_code == invite))
    while r.scalar_one_or_none():
        invite = generate_invite_code()
        r = await db.execute(select(FantasyLeague).where(FantasyLeague.invite_code == invite))
    max_members = body.max_members if body.league_type == "private" else None
    max_teams = max_members if (body.league_type == "private" and max_members) else body.max_teams
    logo = (body.logo or "trophy").strip() or "trophy"
    if len(logo) > 50:
        logo = logo[:50]
    league = FantasyLeague(
        name=body.name,
        logo=logo,
        admin_user_id=current_user.id,
        invite_code=invite,
        max_teams=max_teams,
        league_type=body.league_type,
        max_members=max_members,
        budget=body.budget,
        start_matchday=body.start_matchday,
        auction_type=body.auction_type,
    )
    db.add(league)
    await db.commit()
    await db.refresh(league)
    # Auto-join creator: fantasy_league_members + squadra fantasy
    team_name = (current_user.username or "La mia squadra").strip() or "La mia squadra"
    member = FantasyLeagueMember(
        league_id=league.id,
        user_id=current_user.id,
        role="admin",
        team_name=team_name,
        budget_remaining=league.budget,
    )
    db.add(member)
    team = FantasyTeam(
        league_id=league.id,
        user_id=current_user.id,
        name=team_name,
        budget_remaining=league.budget,
    )
    db.add(team)
    await db.commit()
    await db.refresh(league)
    return league


@router.get("", response_model=list[LeagueResponse])
async def list_leagues(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Lista leghe a cui partecipa l'utente (admin, squadra o membro)."""
    subq_team = select(FantasyTeam.league_id).where(FantasyTeam.user_id == current_user.id)
    subq_member = select(FantasyLeagueMember.league_id).where(FantasyLeagueMember.user_id == current_user.id)
    r = await db.execute(
        select(FantasyLeague)
        .where(
            FantasyLeague.is_active == True,
            (FantasyLeague.admin_user_id == current_user.id)
            | (FantasyLeague.id.in_(subq_team))
            | (FantasyLeague.id.in_(subq_member)),
        )
        .order_by(FantasyLeague.created_at.desc())
    )
    leagues = list(r.scalars().all())
    out = []
    for league in leagues:
        display_name = await _get_display_name(db, league)
        out.append(LeagueResponse.model_validate(league).model_copy(update={"display_name": display_name}))
    return out


@router.get("/lookup", response_model=LeagueResponse)
async def lookup_league_by_invite_code(
    invite_code: Annotated[str, Query(description="Codice invito 8 caratteri")],
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Cerca lega per codice invito (per unisciti a lega)."""
    code = (invite_code or "").strip().upper()
    if not code:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="invite_code required")
    r = await db.execute(
        select(FantasyLeague).where(FantasyLeague.invite_code == code, FantasyLeague.is_active == True)
    )
    league = r.scalar_one_or_none()
    if not league:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="League not found or invalid invite code")
    return league


@router.get("/{league_id}", response_model=LeagueDetailResponse)
async def get_league(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Dettaglio lega."""
    league = await _get_league_or_404(db, league_id)
    if not league:
        _league_gone_404()
    count_r = await db.execute(select(func.count(FantasyTeam.id)).where(FantasyTeam.league_id == league_id))
    team_count = count_r.scalar() or 0
    display_name = await _get_display_name(db, league)
    return LeagueDetailResponse.model_validate(league).model_copy(
        update={"team_count": team_count, "display_name": display_name}
    )


@router.post("/{league_id}/roster")
async def add_to_roster(
    league_id: UUID,
    body: dict,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Aggiungi giocatore alla rosa (acquisto dal mercato). Solo leghe pubbliche; leghe private acquistano solo tramite asta."""
    league = await _get_league_or_404(db, league_id)
    if not league:
        _league_gone_404()
    if league.league_type == "private":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Acquisto solo tramite asta per leghe private",
        )
    r = await db.execute(
        select(FantasyTeam.id).where(FantasyTeam.league_id == league_id, FantasyTeam.user_id == current_user.id)
    )
    row = r.one_or_none()
    if not row:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nessuna squadra in questa lega")
    team_id = row[0]
    player_id = body.get("player_id")
    if player_id is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="player_id required")
    price = body.get("price")
    if price is not None:
        try:
            price = Decimal(str(price))
        except (TypeError, ValueError):
            price = None
    try:
        out = await buy_free_agent(db, league_id, team_id, int(player_id), price=price, allow_duplicate_players=True)
        return out
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


async def _find_or_create_child_league(db: AsyncSession, root: FantasyLeague) -> FantasyLeague:
    """Trova una lega figlia con posti liberi (< 1000) o creane una nuova."""
    r_children = await db.execute(
        select(FantasyLeague.id).where(
            FantasyLeague.parent_league_id == root.id,
            FantasyLeague.is_active == True,
        ).order_by(FantasyLeague.created_at)
    )
    child_ids = [row[0] for row in r_children.all()]
    for cid in child_ids:
        cnt = await db.execute(select(func.count(FantasyTeam.id)).where(FantasyTeam.league_id == cid))
        if (cnt.scalar() or 0) < PUBLIC_LEAGUE_SPLIT_THRESHOLD:
            r = await db.execute(select(FantasyLeague).where(FantasyLeague.id == cid))
            return r.scalar_one()
    # Nessuna con posti: crea nuova figlia
    n = len(child_ids) + 2  # #2, #3, ...
    name = f"{root.name} #{n}"
    invite = generate_invite_code()
    r = await db.execute(select(FantasyLeague).where(FantasyLeague.invite_code == invite))
    while r.scalar_one_or_none():
        invite = generate_invite_code()
        r = await db.execute(select(FantasyLeague).where(FantasyLeague.invite_code == invite))
    child = FantasyLeague(
        name=name,
        admin_user_id=root.admin_user_id,
        invite_code=invite,
        max_teams=PUBLIC_LEAGUE_SPLIT_THRESHOLD,
        league_type="public",
        max_members=PUBLIC_LEAGUE_SPLIT_THRESHOLD,
        budget=root.budget,
        parent_league_id=root.id,
        auto_created=True,
    )
    db.add(child)
    await db.flush()
    await db.refresh(child)
    return child


@router.post("/{league_id}/join", response_model=LeagueResponse)
async def join_league(
  league_id: UUID,
  body: LeagueJoin,
  current_user: Annotated[User, Depends(get_current_user)],
  db: Annotated[AsyncSession, Depends(get_db)],
):
    """Unisciti alla lega con invite_code. Leghe pubbliche: auto-split ogni 1000 membri (unisce a figlia o crea nuova)."""
    code = body.invite_code.strip().upper()
    r = await db.execute(
        select(FantasyLeague).where(
            FantasyLeague.id == league_id,
            FantasyLeague.invite_code == code,
            FantasyLeague.is_active == True,
        )
    )
    league = r.scalar_one_or_none()
    if not league:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="League not found or invalid invite code")
    target_league = league
    if league.league_type == "public":
        root = await _get_root_league(db, league)
        count_r = await db.execute(select(func.count(FantasyTeam.id)).where(FantasyTeam.league_id == root.id))
        root_members = count_r.scalar() or 0
        if root_members >= PUBLIC_LEAGUE_SPLIT_THRESHOLD:
            target_league = await _find_or_create_child_league(db, root)
    target_id = target_league.id
    r_blocked = await db.execute(
        select(FantasyLeagueMember.id).where(
            FantasyLeagueMember.league_id == target_id,
            FantasyLeagueMember.user_id == current_user.id,
            FantasyLeagueMember.status == "blocked",
        )
    )
    if r_blocked.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sei stato bloccato da questa lega")
    existing = await db.execute(
        select(FantasyTeam).where(FantasyTeam.league_id == target_id, FantasyTeam.user_id == current_user.id)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Already in this league")
    count_r = await db.execute(select(func.count(FantasyTeam.id)).where(FantasyTeam.league_id == target_id))
    member_count = count_r.scalar() or 0
    if target_league.league_type == "private" and target_league.max_members is not None and member_count >= target_league.max_members:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Lega piena ({member_count}/{target_league.max_members} partecipanti)",
        )
    team_name_join = (current_user.username or "Squadra") + " FC"
    member = FantasyLeagueMember(
        league_id=target_id,
        user_id=current_user.id,
        role="member",
        team_name=team_name_join,
        budget_remaining=target_league.budget,
    )
    db.add(member)
    team = FantasyTeam(
        league_id=target_id,
        user_id=current_user.id,
        name=team_name_join,
        budget_remaining=target_league.budget,
    )
    db.add(team)
    await db.commit()
    await db.refresh(target_league)
    existing_users = await db.execute(
        select(FantasyTeam.user_id).where(
            FantasyTeam.league_id == target_id,
            FantasyTeam.user_id != current_user.id,
        )
    )
    user_ids = [row[0] for row in existing_users.all()]
    display_name = await _get_display_name(db, target_league)
    if user_ids:
        await send_push_to_users(
            db,
            user_ids,
            "Nuovo membro!",
            f"{current_user.username} si è unito alla lega {display_name}",
        )
    return LeagueResponse.model_validate(target_league).model_copy(update={"display_name": display_name})


@router.post("/{league_id}/generate-calendar")
async def generate_calendar(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Genera calendario round-robin (andata e ritorno). Solo admin. Una sola volta per lega."""
    league = await _get_league_or_404(db, league_id)
    if not league:
        _league_gone_404()
    if league.admin_user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Solo l'admin può generare il calendario")
    try:
        count = await generate_calendar_for_league(db, league_id)
        await db.commit()
    except ValueError as e:
        await db.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception:
        await db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Generazione calendario fallita")
    return {"message": "Calendario generato", "total_rounds": (count // 2), "total_matches": count}


@router.get("/{league_id}/standings", response_model=list[StandingRow])
async def get_standings(
  league_id: UUID,
  current_user: Annotated[User, Depends(get_current_user)],
  db: Annotated[AsyncSession, Depends(get_db)],
):
    """Classifica fantasy della lega. Leghe pubbliche root: aggrega tutte le leghe figlie."""
    league = await _get_league_or_404(db, league_id)
    if not league:
        _league_gone_404()
    league_ids = [league_id]
    if league.league_type == "public" and not getattr(league, "parent_league_id", None):
        r_children = await db.execute(
            select(FantasyLeague.id).where(
                FantasyLeague.parent_league_id == league_id,
                FantasyLeague.is_active == True,
            )
        )
        league_ids.extend(row[0] for row in r_children.all())
    r = await db.execute(
        select(FantasyTeam)
        .where(FantasyTeam.league_id.in_(league_ids))
        .order_by(FantasyTeam.total_points.desc(), FantasyTeam.goals_for.desc())
    )
    teams = r.scalars().all()
    return [
        StandingRow(
            rank=i + 1,
            fantasy_team_id=t.id,
            team_name=t.name,
            user_id=t.user_id,
            total_points=t.total_points,
            wins=t.wins,
            draws=t.draws,
            losses=t.losses,
            goals_for=t.goals_for,
            goals_against=t.goals_against,
            logo_url=t.logo_url,
            coach_avatar_url=t.coach_avatar_url,
            budget_remaining=t.budget_remaining,
            is_configured=t.is_configured,
        )
        for i, t in enumerate(teams)
    ]


@router.get("/{league_id}/calendar", response_model=list[CalendarMatchRow])
async def get_league_calendar(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Calendario lega: tutte le partite fantasy (matchday, home, away)."""
    league = await _get_league_or_404(db, league_id)
    if not league:
        _league_gone_404()
    HomeTeam = aliased(FantasyTeam)
    AwayTeam = aliased(FantasyTeam)
    r = await db.execute(
        select(FantasyCalendar.matchday, HomeTeam.name.label("home_team_name"), AwayTeam.name.label("away_team_name"))
        .select_from(FantasyCalendar)
        .join(HomeTeam, FantasyCalendar.home_team_id == HomeTeam.id)
        .join(AwayTeam, FantasyCalendar.away_team_id == AwayTeam.id)
        .where(FantasyCalendar.league_id == league_id)
        .order_by(FantasyCalendar.matchday, FantasyCalendar.id)
    )
    rows = r.all()
    return [CalendarMatchRow(matchday=row.matchday, home_team_name=row.home_team_name or "", away_team_name=row.away_team_name or "") for row in rows]


@router.post("/postponed-matches", response_model=dict)
async def add_postponed_match(
    body: PostponedMatchCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Segna una partita di Serie A come rinviata per una giornata (6 politico). Solo admin o backend."""
    from sqlalchemy.dialects.postgresql import insert
    stmt = insert(SerieAPostponed).values(
        matchday=body.matchday,
        home_team_id=body.home_team_id,
        away_team_id=body.away_team_id,
        reason=body.reason,
    ).on_conflict_do_nothing(index_elements=["matchday", "home_team_id", "away_team_id"])
    await db.execute(stmt)
    await db.commit()
    return {"message": "Partita segnata come rinviata"}


@router.get("/{league_id}/matchday/{matchday}/results", response_model=list[MatchdayResultRow])
async def get_matchday_results(
    league_id: UUID,
    matchday: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Risultati della giornata fantasy (partite tra squadre della lega)."""
    league = await _get_league_or_404(db, league_id)
    if not league:
        _league_gone_404()
    engine = ScoringEngine(db)
    results = await engine.calculate_matchday_results(league_id, matchday)
    out = []
    for res in results:
        r_h = await db.execute(select(FantasyTeam.name).where(FantasyTeam.id == res.home_team_id))
        r_a = await db.execute(select(FantasyTeam.name).where(FantasyTeam.id == res.away_team_id))
        home_name = (r_h.scalar_one_or_none() or "") or ""
        away_name = (r_a.scalar_one_or_none() or "") or ""
        out.append(MatchdayResultRow(
            home_team_id=res.home_team_id,
            away_team_id=res.away_team_id,
            home_team_name=home_name,
            away_team_name=away_name,
            home_score=float(res.home_score),
            away_score=float(res.away_score),
            home_goals=res.home_goals,
            away_goals=res.away_goals,
            home_result=res.home_result,
            away_result=res.away_result,
        ))
    return out


@router.get("/{league_id}/matchday/{matchday}/results/details", response_model=list[MatchdayResultDetailRow])
async def get_matchday_results_details(
    league_id: UUID,
    matchday: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Risultati della giornata con pagelle (player_scores) e flag is_postponed per 6 politico."""
    league = await _get_league_or_404(db, league_id)
    if not league:
        _league_gone_404()
    start_matchday = getattr(league, "start_matchday", 1)
    serie_a_matchday = start_matchday + (matchday - 1)
    postponed_team_ids = await get_postponed_team_ids(db, serie_a_matchday)
    cal = await db.execute(
        select(FantasyCalendar).where(
            FantasyCalendar.league_id == league_id,
            FantasyCalendar.matchday == matchday,
        )
    )
    rows = cal.scalars().all()
    threshold = float(league.goal_threshold or 66)
    step = float(league.goal_step or 8)
    engine = ScoringEngine(db)
    out = []
    for fc in rows:
        home = await engine.calculate_team_score(
            fc.home_team_id, matchday, league_id=None, threshold=threshold, step=step,
            serie_a_matchday=serie_a_matchday, postponed_team_ids=postponed_team_ids,
        )
        away = await engine.calculate_team_score(
            fc.away_team_id, matchday, league_id=None, threshold=threshold, step=step,
            serie_a_matchday=serie_a_matchday, postponed_team_ids=postponed_team_ids,
        )
        if not home or not away:
            continue
        home_goals = home.fantasy_goals
        away_goals = away.fantasy_goals
        if home_goals > away_goals:
            home_res, away_res = "W", "L"
        elif home_goals < away_goals:
            home_res, away_res = "L", "W"
        else:
            home_res = away_res = "D"
        home_scores = [
            PlayerScoreDetail(
                player_id=p.player_id,
                total_score=float(p.total_score),
                base_score=float(p.base_score),
                advanced_score=float(p.advanced_score),
                was_subbed_in=p.was_subbed_in,
                is_postponed=p.is_postponed,
            )
            for p in home.player_scores
        ]
        away_scores = [
            PlayerScoreDetail(
                player_id=p.player_id,
                total_score=float(p.total_score),
                base_score=float(p.base_score),
                advanced_score=float(p.advanced_score),
                was_subbed_in=p.was_subbed_in,
                is_postponed=p.is_postponed,
            )
            for p in away.player_scores
        ]
        r_h = await db.execute(select(FantasyTeam.name).where(FantasyTeam.id == fc.home_team_id))
        r_a = await db.execute(select(FantasyTeam.name).where(FantasyTeam.id == fc.away_team_id))
        home_name = (r_h.scalar_one_or_none() or "") or ""
        away_name = (r_a.scalar_one_or_none() or "") or ""
        out.append(MatchdayResultDetailRow(
            home_team_id=fc.home_team_id,
            away_team_id=fc.away_team_id,
            home_team_name=home_name,
            away_team_name=away_name,
            home_score=float(home.total_score),
            away_score=float(away.total_score),
            home_goals=home_goals,
            away_goals=away_goals,
            home_result=home_res,
            away_result=away_res,
            home_player_scores=home_scores,
            away_player_scores=away_scores,
        ))
    return out


# --- Admin: gestione lega e membri ---


async def _require_league_admin(db: AsyncSession, league_id: UUID, user: User) -> FantasyLeague:
    """Solo il creatore (admin) della lega. Ritorna la lega attiva o 404."""
    league = await _get_league_or_404(db, league_id)
    if not league:
        _league_gone_404()
    if league.admin_user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Solo l'admin della lega può eseguire questa azione")
    return league


@router.delete("/{league_id}", response_model=dict)
async def delete_league(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Elimina la lega (soft delete). Solo admin. is_active=False, deleted_at=now(). Push a tutti."""
    league = await _require_league_admin(db, league_id, current_user)
    league.is_active = False
    league.deleted_at = datetime.utcnow()
    await db.commit()
    r = await db.execute(select(FantasyTeam.user_id).where(FantasyTeam.league_id == league_id).distinct())
    user_ids = [row[0] for row in r.all()]
    if user_ids:
        await send_push_to_users(
            db, user_ids,
            "Lega eliminata",
            f"⚠️ La lega {league.name} è stata eliminata",
        )
    return {"message": "Lega eliminata"}


@router.post("/{league_id}/start", response_model=dict)
async def start_league(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Avvia la lega: configura l'asta, salva, invia notifiche in-app a tutti i partecipanti. Solo admin."""
    league = await _require_league_admin(db, league_id, current_user)
    if league.asta_started:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La lega è già stata avviata",
        )
    league.asta_started = True
    await db.commit()
    await db.refresh(league)
    r = await db.execute(select(FantasyTeam.user_id).where(FantasyTeam.league_id == league_id).distinct())
    user_ids = [row[0] for row in r.all()]
    if user_ids:
        await send_push_to_users(
            db,
            user_ids,
            "Lega avviata",
            f"La lega {league.name} è stata avviata. L'asta è disponibile in La mia Squadra!",
        )
    return {"message": "Lega avviata", "asta_started": True}


@router.post("/{league_id}/reset-asta", response_model=dict)
async def reset_asta(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Resetta lo stato asta della lega (asta_started = False). Solo admin. Consente di riavviare l'asta da zero."""
    league = await _require_league_admin(db, league_id, current_user)
    league.asta_started = False
    await db.commit()
    await db.refresh(league)
    return {"message": "Asta resettata", "asta_started": False}


@router.get("/{league_id}/members", response_model=list[LeagueMemberRow])
async def list_league_members(
    league_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Lista membri della lega con ruolo, status, budget, roster_count. Solo partecipanti della lega."""
    league = await _get_league_or_404(db, league_id)
    if not league:
        _league_gone_404()
    r = await db.execute(
        select(FantasyTeam.id).where(
            FantasyTeam.league_id == league_id,
            FantasyTeam.user_id == current_user.id,
        )
    )
    if not r.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Non sei membro di questa lega")
    r2 = await db.execute(
        select(
            FantasyLeagueMember.user_id,
            FantasyLeagueMember.role,
            FantasyLeagueMember.status,
            FantasyLeagueMember.budget_remaining,
            FantasyLeagueMember.joined_at,
            User.full_name,
            User.username,
        )
        .join(User, User.id == FantasyLeagueMember.user_id)
        .where(FantasyLeagueMember.league_id == league_id)
        .order_by(FantasyLeagueMember.joined_at)
    )
    rows = r2.all()
    out = []
    for row in rows:
        uid, role, status_val, budget, joined_at, full_name, username = row
        name = (full_name or username or "Utente") or "Utente"
        subq = select(FantasyTeam.id).where(FantasyTeam.league_id == league_id, FantasyTeam.user_id == uid)
        rc = await db.execute(
            select(func.count(FantasyRoster.id)).where(
                FantasyRoster.fantasy_team_id.in_(subq),
                FantasyRoster.is_active == True,
            )
        )
        roster_count = rc.scalar() or 0
        out.append(LeagueMemberRow(
            user_id=uid,
            name=name,
            role=role,
            status=status_val or "active",
            budget=budget,
            roster_count=roster_count,
            joined_at=joined_at,
        ))
    return out


@router.delete("/{league_id}/members/{user_id}", response_model=dict)
async def remove_league_member(
    league_id: UUID,
    user_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Rimuovi un membro dalla lega (kicked). Solo admin. Non può rimuovere se stesso. Libera la sua rosa. Se asta attiva → pausa."""
    league = await _require_league_admin(db, league_id, current_user)
    if user_id == current_user.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Non puoi rimuovere te stesso")
    r = await db.execute(
        select(FantasyLeagueMember).where(
            FantasyLeagueMember.league_id == league_id,
            FantasyLeagueMember.user_id == user_id,
        )
    )
    member = r.scalar_one_or_none()
    if not member:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Membro non trovato")
    r_team = await db.execute(select(FantasyTeam.id).where(FantasyTeam.league_id == league_id, FantasyTeam.user_id == user_id))
    team_id_row = r_team.scalar_one_or_none()
    if team_id_row:
        team_id = team_id_row[0]
        await db.execute(update(FantasyRoster).where(FantasyRoster.fantasy_team_id == team_id).values(is_active=False))
    member.status = "kicked"
    await db.commit()
    try:
        from app.services.auction_service import get_active_session, pause_session
        session = await get_active_session(db, league_id)
        if session and session.status == "active":
            await pause_session(db, league_id, current_user.id)
    except Exception:
        pass
    await send_push_to_users(db, [user_id], "Rimosso dalla lega", f"⚠️ Sei stato rimosso dalla lega {league.name}")
    return {"message": "Utente rimosso"}


@router.post("/{league_id}/members/{user_id}/block", response_model=dict)
async def block_league_member(
    league_id: UUID,
    user_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    body: LeagueBlockRequest | None = None,
):
    """Blocca un membro. Solo admin. Non può bloccare se stesso. L'utente non può più rientrare."""
    league = await _require_league_admin(db, league_id, current_user)
    if user_id == current_user.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Non puoi bloccare te stesso")
    r = await db.execute(
        select(FantasyLeagueMember).where(
            FantasyLeagueMember.league_id == league_id,
            FantasyLeagueMember.user_id == user_id,
        )
    )
    member = r.scalar_one_or_none()
    if not member:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Membro non trovato")
    member.status = "blocked"
    member.blocked_at = datetime.utcnow()
    member.blocked_reason = (body.reason if body else None) or None
    await db.commit()
    await send_push_to_users(db, [user_id], "Bloccato", f"🚫 Sei stato bloccato dalla lega {league.name}")
    return {"message": "Utente bloccato"}


@router.post("/{league_id}/members/{user_id}/unblock", response_model=dict)
async def unblock_league_member(
    league_id: UUID,
    user_id: UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Sblocca un membro. Solo admin."""
    league = await _require_league_admin(db, league_id, current_user)
    r = await db.execute(
        select(FantasyLeagueMember).where(
            FantasyLeagueMember.league_id == league_id,
            FantasyLeagueMember.user_id == user_id,
        )
    )
    member = r.scalar_one_or_none()
    if not member:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Membro non trovato")
    member.status = "active"
    member.blocked_at = None
    member.blocked_reason = None
    await db.commit()
    await send_push_to_users(db, [user_id], "Sbloccato", f"✅ Sei stato sbloccato nella lega {league.name}")
    return {"message": "Utente sbloccato"}

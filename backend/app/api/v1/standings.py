"""
API Classifica Serie A: GET /standings/serie-a.
Legge da real_team_standings (stagione corrente) se presente, altrimenti da cache Redis.
"""
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.real_team import RealTeam
from app.models.real_team_standing import RealTeamStanding
from app.utils.cache import cache_get
from app.tasks.sync_standings import CACHE_KEY_STANDINGS, sync_standings

router = APIRouter(prefix="/standings", tags=["standings"])

CURRENT_SEASON_YEAR = 2025


@router.get("/current-matchday")
async def get_current_matchday(db: Annotated[AsyncSession, Depends(get_db)]):
    """
    Giornata corrente di Serie A (per picker Crea Lega).
    Ritorna il massimo di games_played dalla classifica stagione corrente (1 se nessun dato).
    """
    try:
        r = await db.execute(
            select(func.max(RealTeamStanding.games_played)).where(
                RealTeamStanding.season_year == CURRENT_SEASON_YEAR
            )
        )
        value = r.scalar_one_or_none()
        current = max(1, int(value)) if value is not None else 1
        return {"current_matchday": current}
    except Exception:
        return {"current_matchday": 1}

# Stemmi in static/media/team_badges_serie_A/ sono 21.png ... 40.png.
# I file corrispondono a real_teams.id 21-40 (nomi esatti dal DB).
# Mappa verificata: SELECT id, name FROM real_teams ORDER BY id → 21=AC Milan, 22=ACF Fiorentina,
# 23=AS Roma, 24=Atalanta BC, 25=Bologna FC 1909, 26=Cagliari Calcio, 27=Genoa CFC,
# 28=FC Internazionale Milano, 29=Juventus FC, 30=SS Lazio, 31=Parma Calcio 1913,
# 32=SSC Napoli, 33=Udinese Calcio, 34=Hellas Verona FC, 35=US Cremonese,
# 36=US Sassuolo Calcio, 37=AC Pisa 1909, 38=Torino FC, 39=US Lecce, 40=Como 1907.
# Per real_teams.id 1-20 (nomi brevi) usiamo questa mappa verso il file corretto.
REAL_TEAM_ID_TO_BADGE_FILE = {
    1: 28,   # Inter → 28.png (FC Internazionale Milano)
    2: 29,   # Juventus → 29.png
    3: 21,   # Milan → 21.png (AC Milan)
    4: 32,   # Napoli → 32.png (SSC Napoli)
    5: 23,   # Roma → 23.png (AS Roma)
    6: 30,   # Lazio → 30.png (SS Lazio)
    7: 24,   # Atalanta → 24.png
    8: 22,   # Fiorentina → 22.png (ACF Fiorentina)
    9: 25,   # Bologna → 25.png
    10: 38,  # Torino → 38.png
    11: 27,  # Genoa → 27.png
    12: 21,  # Monza → fallback (no 21-40 per Monza)
    13: 39,  # Lecce → 39.png (US Lecce)
    14: 33,  # Udinese → 33.png
    15: 26,  # Cagliari → 26.png
    16: 34,  # Hellas Verona → 34.png
    17: 21,  # Empoli → fallback
    18: 21,  # Frosinone → fallback
    19: 21,  # Salernitana → fallback
    20: 21,  # Venezia → fallback
}
LOGO_BASE = "/static/media/team_badges_serie_A"


@router.get("/serie-a")
async def get_serie_a_standings(db: Annotated[AsyncSession, Depends(get_db)]):
    """
    Classifica Serie A reale.
    Se esiste classifica in DB per stagione corrente (2025), la restituisce.
    Altrimenti usa cache Redis (sync_standings).
    Ritorna: rank, team_name, team_logo, played, wins, draws, losses,
    goals_for, goals_against, goal_diff, points.
    """
    # 1) Prova da DB (real_team_standings per stagione corrente)
    try:
        r = await db.execute(
            select(RealTeamStanding, RealTeam)
            .join(RealTeam, RealTeamStanding.real_team_id == RealTeam.id)
            .where(RealTeamStanding.season_year == CURRENT_SEASON_YEAR)
            .order_by(RealTeamStanding.rank)
        )
        rows = r.all()
        if rows:
            result = []
            for st, team in rows:
                if 21 <= team.id <= 40:
                    badge_file = team.id
                else:
                    badge_file = REAL_TEAM_ID_TO_BADGE_FILE.get(team.id, 21)
                logo = f"{LOGO_BASE}/{badge_file}.png"
                result.append({
                    "rank": st.rank,
                    "team_name": team.name,
                    "team_logo": logo,
                    "played": st.games_played,
                    "wins": st.wins,
                    "draws": st.draws,
                    "losses": st.losses,
                    "goals_for": st.goals_for,
                    "goals_against": st.goals_against,
                    "goal_diff": st.goal_difference,
                    "points": st.points,
                })
            return result
    except Exception:
        pass

    # 2) Fallback: cache Redis (sync_standings)
    data = await cache_get(CACHE_KEY_STANDINGS)
    if not data:
        await sync_standings()
        data = await cache_get(CACHE_KEY_STANDINGS)
    if not data or "standings" not in data:
        return []
    tables = data.get("standings") or []
    rows_raw = []
    for t in tables:
        if t.get("type") == "TOTAL" and "table" in t:
            rows_raw = t["table"]
            break
    if not rows_raw:
        return []

    team_logos: dict[str, str] = {}
    try:
        r = await db.execute(select(RealTeam.name, RealTeam.crest_url, RealTeam.crest_local))
        for name, crest_url, crest_local in r.all():
            if name:
                team_logos[name] = crest_local if crest_local else (crest_url or "")
    except Exception:
        pass

    result = []
    for row in rows_raw:
        team = row.get("team") or {}
        team_name = team.get("name") or ""
        crest_api = team.get("crest") or ""
        logo = team_logos.get(team_name) or crest_api
        if logo and not logo.startswith(("http://", "https://")) and logo.strip():
            logo = f"/static/{logo.lstrip('/')}" if not logo.startswith("/static") else logo
        played = row.get("played", 0) or (row.get("won", 0) + row.get("draw", 0) + row.get("lost", 0))
        goals_for = row.get("goalsFor", 0)
        goals_against = row.get("goalsAgainst", 0)
        result.append({
            "rank": row.get("position", 0),
            "team_name": team_name,
            "team_logo": logo or None,
            "played": played,
            "wins": row.get("won", 0),
            "draws": row.get("draw", 0),
            "losses": row.get("lost", 0),
            "goals_for": goals_for,
            "goals_against": goals_against,
            "goal_diff": goals_for - goals_against,
            "points": row.get("points", 0),
        })
    return result

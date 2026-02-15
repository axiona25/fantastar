"""
Servizio leghe: generazione calendario round-robin, invite code.
"""
import secrets
from typing import List, Tuple

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.league import FantasyLeague
from app.models.fantasy_team import FantasyTeam
from app.models.fantasy_calendar import FantasyCalendar


def generate_invite_code(length: int = 8) -> str:
    """Genera codice invito univoco (alfanumerico)."""
    return secrets.token_urlsafe(length)[:length].upper().replace("-", "X").replace("_", "Y")


def round_robin_pairings(team_ids: List) -> List[Tuple[int, Tuple, Tuple]]:
    """
    Genera abbinamenti round-robin (andata).
    team_ids: lista di identificativi (UUID o int) delle squadre.
    Ritorna lista di (matchday, (home_id, away_id), ...) per ogni giornata.
    """
    n = len(team_ids)
    if n < 2:
        return []
    # Algoritmo classico: fissiamo la prima, ruotiamo le altre
    ids = list(team_ids)
    pairings = []
    for day in range(n - 1):
        round_matches = []
        for i in range(n // 2):
            home, away = ids[i], ids[n - 1 - i]
            round_matches.append((home, away))
        pairings.append((day + 1, round_matches))
        # Ruota: primo fisso, gli altri shift
        ids = [ids[0]] + [ids[-1]] + ids[1:-1]
    return pairings


async def generate_calendar_for_league(db: AsyncSession, league_id) -> int:
    """
    Genera calendario fantasy per la lega (round-robin andata e ritorno).
    Ogni giornata ha N/2 partite. Giornate totali: (N-1)*2.
    Ritorna il numero di righe inserite in fantasy_calendar.
    """
    r = await db.execute(select(FantasyTeam.id).where(FantasyTeam.league_id == league_id))
    team_ids = list(r.scalars().all())
    if len(team_ids) < 2:
        return 0
    pairings = round_robin_pairings(team_ids)
    count = 0
    # Andata
    for matchday, matches in pairings:
        for home_id, away_id in matches:
            existing = await db.execute(
                select(FantasyCalendar).where(
                    FantasyCalendar.league_id == league_id,
                    FantasyCalendar.matchday == matchday,
                    FantasyCalendar.home_team_id == home_id,
                )
            )
            if existing.scalar_one_or_none():
                continue
            db.add(FantasyCalendar(league_id=league_id, matchday=matchday, home_team_id=home_id, away_team_id=away_id))
            count += 1
    # Ritorno (stessi abbinamenti con campi invertiti)
    total_days = len(pairings)
    for matchday, matches in pairings:
        return_matchday = matchday + total_days
        for home_id, away_id in matches:
            existing = await db.execute(
                select(FantasyCalendar).where(
                    FantasyCalendar.league_id == league_id,
                    FantasyCalendar.matchday == return_matchday,
                    FantasyCalendar.home_team_id == away_id,
                )
            )
            if existing.scalar_one_or_none():
                continue
            db.add(FantasyCalendar(league_id=league_id, matchday=return_matchday, home_team_id=away_id, away_team_id=home_id))
            count += 1
    return count

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
from app.models.league_match import LeagueMatch
from app.utils.round_robin import generate_round_robin


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
    Usa league.start_matchday per serie_a_matchday e scrive in league_matches + fantasy_calendar.
    Imposta league.calendar_generated = True.
    Ritorna il numero di partite inserite.
    Solleva ValueError se calendario già generato, squadre insufficienti o non pari, o numero diverso da max_teams.
    """
    r = await db.execute(select(FantasyLeague).where(FantasyLeague.id == league_id))
    league = r.scalar_one_or_none()
    if not league:
        return 0
    if getattr(league, "calendar_generated", False):
        raise ValueError("Il calendario è già stato generato")
    r = await db.execute(select(FantasyTeam.id).where(FantasyTeam.league_id == league_id))
    team_ids = [row[0] for row in r.all()]
    n = len(team_ids)
    if n < 2:
        raise ValueError("Servono almeno 2 squadre")
    if n % 2 != 0:
        raise ValueError("Il numero di squadre deve essere pari")
    max_teams = league.max_teams or league.max_members or 10
    if n != max_teams:
        raise ValueError(f"La lega richiede {max_teams} squadre, ne sono iscritte {n}")
    start = getattr(league, "start_matchday", 1)
    rounds_andata = generate_round_robin(team_ids)
    count = 0
    # Andata
    for round_idx, round_matches in enumerate(rounds_andata):
        round_number = round_idx + 1
        serie_a_day = start + round_idx
        for home_id, away_id in round_matches:
            db.add(LeagueMatch(
                league_id=league_id,
                round_number=round_number,
                serie_a_matchday=serie_a_day,
                home_team_id=home_id,
                away_team_id=away_id,
                is_return_leg=False,
            ))
            db.add(FantasyCalendar(league_id=league_id, matchday=round_number, home_team_id=home_id, away_team_id=away_id))
            count += 1
    # Ritorno (stessi match invertiti casa/trasferta)
    n_andata = len(rounds_andata)
    for round_idx, round_matches in enumerate(rounds_andata):
        round_number = n_andata + round_idx + 1
        serie_a_day = start + n_andata + round_idx
        for home_id, away_id in round_matches:
            db.add(LeagueMatch(
                league_id=league_id,
                round_number=round_number,
                serie_a_matchday=serie_a_day,
                home_team_id=away_id,
                away_team_id=home_id,
                is_return_leg=True,
            ))
            db.add(FantasyCalendar(league_id=league_id, matchday=round_number, home_team_id=away_id, away_team_id=home_id))
            count += 1
    league.calendar_generated = True
    return count

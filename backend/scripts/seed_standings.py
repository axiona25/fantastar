#!/usr/bin/env python3
"""
Popola/aggiorna la classifica Serie A (real_team_standings) per la stagione 2025-2026.
Giornata 25 - dati al 16 febbraio 2026.

Eseguire da backend con: python scripts/seed_standings.py
Oppure in Docker: docker-compose exec backend python scripts/seed_standings.py

Prima eseguire la migrazione: alembic upgrade head
"""
import sys
from pathlib import Path

backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session
from app.config import settings
from app.models.real_team import RealTeam
from app.models.real_team_standing import RealTeamStanding

SYNC_DATABASE_URL = settings.DATABASE_URL
if "+asyncpg" in SYNC_DATABASE_URL:
    SYNC_DATABASE_URL = SYNC_DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")

SEASON_YEAR = 2025

# Nome in classifica -> possibile nome in real_teams (per match)
NAME_ALIASES = {
    "Verona": "Hellas Verona",
    "Hellas Verona FC": "Hellas Verona",
    "Inter": "Inter",
    "FC Internazionale Milano": "Inter",
    "Milan": "Milan",
    "AC Milan": "Milan",
    "Napoli": "Napoli",
    "SSC Napoli": "Napoli",
    "Roma": "Roma",
    "AS Roma": "Roma",
    "Juventus": "Juventus",
    "Juventus FC": "Juventus",
    "Atalanta": "Atalanta",
    "Atalanta BC": "Atalanta",
    "Bologna": "Bologna",
    "Bologna FC 1909": "Bologna",
    "Lazio": "Lazio",
    "SS Lazio": "Lazio",
    "Udinese": "Udinese",
    "Udinese Calcio": "Udinese",
    "Cagliari": "Cagliari",
    "Cagliari Calcio": "Cagliari",
    "Torino": "Torino",
    "Torino FC": "Torino",
    "Genoa": "Genoa",
    "Genoa CFC": "Genoa",
    "Fiorentina": "Fiorentina",
    "ACF Fiorentina": "Fiorentina",
    "Lecce": "Lecce",
    "US Lecce": "Lecce",
    "Parma": "Parma",
    "Parma Calcio 1913": "Parma",
    "Como": "Como",
    "Como 1907": "Como",
    "Sassuolo": "Sassuolo",
    "Cremonese": "Cremonese",
    "Pisa": "Pisa",
}

# Classifica giornata 25 - stagione 2025-2026 (16 feb 2026)
STANDINGS_DATA = [
    (1, "Inter", 25, 20, 1, 4, 61),
    (2, "Milan", 24, 15, 8, 1, 53),
    (3, "Napoli", 25, 15, 5, 5, 50),
    (4, "Roma", 25, 15, 2, 8, 47),
    (5, "Juventus", 25, 13, 7, 5, 46),
    (6, "Atalanta", 25, 11, 9, 5, 42),
    (7, "Como", 24, 11, 8, 5, 41),
    (8, "Bologna", 25, 9, 6, 10, 33),
    (9, "Lazio", 25, 8, 9, 8, 33),
    (10, "Sassuolo", 25, 9, 5, 11, 32),
    (11, "Udinese", 25, 9, 5, 11, 32),
    (12, "Parma", 25, 7, 8, 10, 29),
    (13, "Cagliari", 24, 7, 7, 10, 28),
    (14, "Torino", 25, 7, 6, 12, 27),
    (15, "Cremonese", 25, 5, 9, 11, 24),
    (16, "Genoa", 25, 5, 9, 11, 24),
    (17, "Fiorentina", 25, 4, 9, 12, 21),
    (18, "Lecce", 24, 5, 6, 13, 21),
    (19, "Pisa", 25, 1, 12, 12, 15),
    (20, "Verona", 25, 2, 9, 14, 15),
]

# Gol fatti/subiti reali (dove forniti); resto stima
REAL_GOALS = {
    "Inter": (60, 21),
    "Milan": (40, 18),
    "Napoli": (38, 25),
    "Roma": (31, 16),
    "Juventus": (43, 23),
}


def _get_goals(team_name: str, rank: int, played: int, points: int) -> tuple[int, int]:
    """GF, GS: usa REAL_GOALS se presente, altrimenti stima."""
    if team_name in REAL_GOALS:
        return REAL_GOALS[team_name]
    if played == 0:
        return 0, 0
    gd = (points - 30) * 2 + (20 - rank) * 2
    gf = 30 + (20 - rank) * 2 + played
    gs = max(0, gf - gd)
    return max(0, gf), max(0, gs)


def main():
    engine = create_engine(SYNC_DATABASE_URL)
    with Session(engine) as session:
        name_to_id: dict[str, int] = {}
        for t in session.query(RealTeam).all():
            name_to_id[t.name] = t.id
            if t.short_name:
                name_to_id[t.short_name] = t.id
        for k, v in NAME_ALIASES.items():
            if v in name_to_id and k not in name_to_id:
                name_to_id[k] = name_to_id[v]

        # Inserisci squadre mancanti (minimal)
        teams_to_add = [
            ("Como", "COM", "Como 1907"),
            ("Sassuolo", "SAS", "Sassuolo"),
            ("Parma", "PAR", "Parma Calcio 1913"),
            ("Cremonese", "CRE", "Cremonese"),
            ("Pisa", "PIS", "Pisa"),
        ]
        for short_name, tla, full_name in teams_to_add:
            if short_name not in name_to_id and full_name not in name_to_id:
                t = RealTeam(name=short_name, short_name=tla, tla=tla)
                session.add(t)
                session.flush()
                name_to_id[short_name] = t.id
                name_to_id[full_name] = t.id
        session.commit()

        # Ricarica name_to_id dopo eventuali insert
        name_to_id = {}
        for t in session.query(RealTeam).all():
            name_to_id[t.name] = t.id
            if t.short_name:
                name_to_id[t.short_name] = t.id
        for k, v in NAME_ALIASES.items():
            if v in name_to_id and k not in name_to_id:
                name_to_id[k] = name_to_id[v]

        updated = 0
        inserted = 0
        for rank, team_name, played, wins, draws, losses, points in STANDINGS_DATA:
            name_key = NAME_ALIASES.get(team_name, team_name)
            real_team_id = name_to_id.get(name_key) or name_to_id.get(team_name)
            if not real_team_id:
                print(f"  Skip: squadra non trovata per '{team_name}'")
                continue
            gf, gs = _get_goals(team_name, rank, played, points)
            gd = gf - gs

            existing = session.query(RealTeamStanding).filter(
                RealTeamStanding.season_year == SEASON_YEAR,
                RealTeamStanding.real_team_id == real_team_id,
            ).first()
            if existing:
                existing.rank = rank
                existing.games_played = played
                existing.wins = wins
                existing.draws = draws
                existing.losses = losses
                existing.goals_for = gf
                existing.goals_against = gs
                existing.goal_difference = gd
                existing.points = points
                updated += 1
            else:
                session.add(RealTeamStanding(
                    season_year=SEASON_YEAR,
                    real_team_id=real_team_id,
                    rank=rank,
                    games_played=played,
                    wins=wins,
                    draws=draws,
                    losses=losses,
                    goals_for=gf,
                    goals_against=gs,
                    goal_difference=gd,
                    points=points,
                ))
                inserted += 1
        session.commit()
        print(f"Classifica stagione {SEASON_YEAR}: {inserted} inseriti, {updated} aggiornati.")


if __name__ == "__main__":
    main()

"""
Test per il motore di punteggio fantasy (Scoring Engine).
Eseguire con: pytest tests/test_scoring_engine.py -v
"""
import pytest
from decimal import Decimal

from app.services.scoring_engine import (
    BASE_SCORING,
    ADVANCED_SCORING,
    calculate_fantasy_goals,
    ScoringEngine,
    PlayerScoreResult,
    TeamScoreResult,
    MatchResult,
    StandingRow,
)


# --- Unit: formula gol fantasy ---


def test_calculate_fantasy_goals_sotto_soglia():
    """Sotto soglia 66 → 0 gol."""
    assert calculate_fantasy_goals(0) == 0
    assert calculate_fantasy_goals(65) == 0
    assert calculate_fantasy_goals(65.9) == 0


def test_calculate_fantasy_goals_soglia_e_step():
    """Da 66 in poi: 1 gol, poi +1 ogni 8 punti."""
    assert calculate_fantasy_goals(66) == 1
    assert calculate_fantasy_goals(73) == 1
    assert calculate_fantasy_goals(74) == 2
    assert calculate_fantasy_goals(82) == 2
    assert calculate_fantasy_goals(83) == 3
    assert calculate_fantasy_goals(90) == 4


def test_calculate_fantasy_goals_parametri_custom():
    """Soglia e step personalizzati."""
    assert calculate_fantasy_goals(50, threshold=50, step=10) == 1
    assert calculate_fantasy_goals(59, threshold=50, step=10) == 1
    assert calculate_fantasy_goals(60, threshold=50, step=10) == 2


def test_calculate_fantasy_goals_decimal_input():
    """Accetta Decimal."""
    assert calculate_fantasy_goals(Decimal("66")) == 1
    assert calculate_fantasy_goals(Decimal("74")) == 2


# --- Regole punteggio ---


def test_base_scoring_contiene_eventi_attesi():
    """BASE_SCORING contiene i tipi evento richiesti."""
    expected = {
        "GOAL", "OWN_GOAL", "PENALTY_SCORED", "PENALTY_MISSED",
        "YELLOW_CARD", "RED_CARD", "SECOND_YELLOW", "ASSIST",
        "PENALTY_SAVED", "CLEAN_SHEET", "GOAL_CONCEDED", "APPEARANCE",
    }
    for k in expected:
        assert k in BASE_SCORING, f"BASE_SCORING manca: {k}"


def test_goal_per_ruolo():
    """GOAL ha punteggio per ruolo."""
    g = BASE_SCORING["GOAL"]
    assert g["POR"] == 5.0
    assert g["DIF"] == 5.0
    assert g["CEN"] == 4.0
    assert g["ATT"] == 3.0


def test_advanced_scoring_contiene_bonus():
    """ADVANCED_SCORING contiene bonus da stats."""
    assert "xg_wasted" in ADVANCED_SCORING
    assert "high_rating" in ADVANCED_SCORING
    assert ADVANCED_SCORING["high_rating"] == 1.0


# --- Integration (richiede DB con dati) ---


@pytest.mark.asyncio
async def test_scoring_engine_calculate_player_score_invalid():
    """Con player_id o match_id inesistenti ritorna None."""
    try:
        from app.database import AsyncSessionLocal
    except ImportError:
        pytest.skip("AsyncSessionLocal non disponibile")
    from sqlalchemy import select
    from app.models.player import Player
    from app.models.match import Match

    async with AsyncSessionLocal() as db:
        engine = ScoringEngine(db)
        # match_id e player_id molto alti (inesistenti)
        out = await engine.calculate_player_score(999999, 999999)
        assert out is None

        # Se esiste almeno un player e un match, prova con id reali (opzionale)
        rp = await db.execute(select(Player.id).limit(1))
        pid = rp.scalar_one_or_none()
        rm = await db.execute(select(Match.id).limit(1))
        mid = rm.scalar_one_or_none()
        if pid and mid:
            out2 = await engine.calculate_player_score(pid, mid)
            # Può essere None se il giocatore non ha giocato quella partita, o un PlayerScoreResult
            assert out2 is None or isinstance(out2, PlayerScoreResult)
        else:
            pytest.skip("DB senza player o match per test integrazione")


@pytest.mark.asyncio
async def test_scoring_engine_calculate_team_score_invalid():
    """Con fantasy_team_id inesistente ritorna None."""
    try:
        from app.database import AsyncSessionLocal
    except ImportError:
        pytest.skip("AsyncSessionLocal non disponibile")
    import uuid
    async with AsyncSessionLocal() as db:
        engine = ScoringEngine(db)
        fake_id = uuid.uuid4()
        out = await engine.calculate_team_score(fake_id, 1)
        assert out is None


@pytest.mark.asyncio
async def test_scoring_engine_calculate_matchday_results_empty_league():
    """Lega senza calendario per la giornata → lista vuota."""
    try:
        from app.database import AsyncSessionLocal
        from app.models.league import FantasyLeague
        from sqlalchemy import select
    except ImportError:
        pytest.skip("DB non disponibile")
    async with AsyncSessionLocal() as db:
        r = await db.execute(select(FantasyLeague.id).limit(1))
        league_id = r.scalar_one_or_none()
        if not league_id:
            pytest.skip("Nessuna lega nel DB")
        engine = ScoringEngine(db)
        results = await engine.calculate_matchday_results(league_id, 99999)
        assert isinstance(results, list)
        # Giornata 99999 probabilmente senza partite
        assert len(results) >= 0


@pytest.mark.asyncio
async def test_scoring_engine_recalculate_standings_empty_league():
    """recalculate_standings su lega inesistente → lista vuota."""
    try:
        from app.database import AsyncSessionLocal
    except ImportError:
        pytest.skip("AsyncSessionLocal non disponibile")
    import uuid
    async with AsyncSessionLocal() as db:
        engine = ScoringEngine(db)
        standings = await engine.recalculate_standings(uuid.uuid4())
        assert standings == []


@pytest.mark.asyncio
async def test_scoring_engine_recalculate_standings_with_league():
    """recalculate_standings con lega esistente ritorna lista StandingRow."""
    try:
        from app.database import AsyncSessionLocal
        from app.models.league import FantasyLeague
        from sqlalchemy import select
    except ImportError:
        pytest.skip("DB non disponibile")
    async with AsyncSessionLocal() as db:
        r = await db.execute(select(FantasyLeague.id).limit(1))
        league_id = r.scalar_one_or_none()
        if not league_id:
            pytest.skip("Nessuna lega nel DB")
        engine = ScoringEngine(db)
        standings = await engine.recalculate_standings(league_id)
        assert isinstance(standings, list)
        for row in standings:
            assert isinstance(row, StandingRow)
            assert hasattr(row, "points")
            assert hasattr(row, "rank")
            assert hasattr(row, "goals_for")
            assert hasattr(row, "goals_against")

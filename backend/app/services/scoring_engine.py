"""
Motore di calcolo punteggi fantasy event-based.

Regole base da match_events, regole avanzate da player_stats (BZZoiro).
Supporta sostituzioni panchina: titolare non in campo → primo panchinaro stesso ruolo.
"""
from dataclasses import dataclass, field
from datetime import datetime
from decimal import Decimal
from typing import Any

from sqlalchemy import select, and_, or_, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.match import Match
from app.models.match_event import MatchEvent
from app.models.player import Player
from app.models.player_stats import PlayerStats
from app.models.fantasy_team import FantasyTeam
from app.models.fantasy_lineup import FantasyLineup
from app.models.fantasy_roster import FantasyRoster
from app.models.fantasy_score import FantasyScore
from app.models.fantasy_player_score import FantasyPlayerScore
from app.models.fantasy_calendar import FantasyCalendar
from app.models.league import FantasyLeague
from app.models.player_ai_rating import PlayerAIRating
from app.models.serie_a_postponed import SerieAPostponed

# --- Punteggio base (da match_events) ---
BASE_SCORING: dict[str, Any] = {
    "GOAL": {"POR": 5.0, "DIF": 5.0, "CEN": 4.0, "ATT": 3.0},
    "OWN_GOAL": -2.0,
    "PENALTY_SCORED": 3.0,
    "PENALTY_MISSED": -3.0,
    "YELLOW_CARD": -0.5,
    "RED_CARD": -1.0,
    "SECOND_YELLOW": -1.0,
    "ASSIST": 1.0,
    "PENALTY_SAVED": 3.0,  # Solo POR
    "CLEAN_SHEET": {"POR": 1.0, "DIF": 1.0},
    "GOAL_CONCEDED": {"POR": -1.0},
    "APPEARANCE": 1.0,
}

# --- Bonus/malus da AI rating (cronaca live, keyword locale) ---
AI_RATING_BONUS: list[tuple[tuple[float, float], float]] = [
    ((9.0, 10.0), 1.5),
    ((8.0, 9.0), 1.0),
    ((7.0, 8.0), 0.5),
    ((6.0, 7.0), 0),
    ((5.5, 6.0), -0.25),
    ((5.0, 5.5), -0.5),
    ((3.0, 5.0), -1.0),
]


def _ai_rating_bonus(rating: float) -> float:
    for (lo, hi), bonus in AI_RATING_BONUS:
        if lo <= rating < hi:
            return bonus
    return 0.0


# --- Punteggio avanzato (da player_stats BZZoiro) ---
ADVANCED_SCORING: dict[str, float] = {
    "xg_wasted": -0.5,
    "xa_wasted": -0.25,
    "key_passes_3plus": 0.5,
    "tackles_5plus": 0.5,
    "pass_accuracy_90plus": 0.5,
    "high_rating": 1.0,
}


@dataclass
class PlayerScoreResult:
    """Risultato calcolo punteggio singolo giocatore (per una partita)."""
    player_id: int
    match_id: int
    matchday: int
    base_score: Decimal
    advanced_score: Decimal
    total_score: Decimal
    is_starter: bool = True
    was_subbed_in: bool = False
    events_json: list[dict] | None = None
    minutes_played: int = 0
    played: bool = False  # True se ha giocato (minuti o eventi)
    ai_rating_bonus: Decimal = field(default_factory=lambda: _decimal(0))
    is_postponed: bool = False  # True = 6 politico (partita Serie A rinviata)


@dataclass
class TeamScoreResult:
    """Risultato calcolo punteggio squadra fantasy per una giornata."""
    fantasy_team_id: Any
    matchday: int
    total_score: Decimal
    fantasy_goals: int
    player_scores: list[PlayerScoreResult] = field(default_factory=list)
    opponent_id: Any = None
    opponent_score: Decimal | None = None
    opponent_goals: int | None = None
    result: str | None = None  # W, D, L
    points_earned: int | None = None
    detail_json: dict | None = None


@dataclass
class MatchResult:
    """Risultato confronto tra due squadre fantasy in una giornata."""
    home_team_id: Any
    away_team_id: Any
    home_score: Decimal
    away_score: Decimal
    home_goals: int
    away_goals: int
    home_result: str  # W, D, L
    away_result: str


@dataclass
class StandingRow:
    """Riga classifica lega."""
    fantasy_team_id: Any
    team_name: str
    rank: int
    points: int
    wins: int
    draws: int
    losses: int
    goals_for: int
    goals_against: int


def _decimal(v: float | Decimal) -> Decimal:
    return Decimal(str(v))


async def get_postponed_team_ids(db: AsyncSession, matchday: int) -> set[int]:
    """
    Ritorna l'insieme degli ID delle squadre reali (real_teams) che hanno la partita
    rinviata in una data giornata di Serie A. Per la regola 6 politico.
    """
    r = await db.execute(
        select(SerieAPostponed.home_team_id, SerieAPostponed.away_team_id).where(
            SerieAPostponed.matchday == matchday
        )
    )
    ids: set[int] = set()
    for row in r.all():
        ids.add(row[0])
        ids.add(row[1])
    return ids


def calculate_fantasy_goals(total_score: float | Decimal, threshold: float = 66, step: float = 8) -> int:
    """Converte punteggio totale in gol fantasy (soglia e step configurabili)."""
    t = float(total_score)
    if t < threshold:
        return 0
    return 1 + int((t - threshold) / step)


class ScoringEngine:
    """Motore calcolo punteggi event-based."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def calculate_player_score(
        self,
        player_id: int,
        match_id: int,
        postponed_team_ids: set[int] | None = None,
    ) -> PlayerScoreResult | None:
        """
        Calcola punteggio di un giocatore per una partita.
        Se postponed_team_ids contiene la squadra reale del giocatore → 6 politico (partita rinviata).
        Altrimenti usa match_events (base) e player_stats (avanzato).
        """
        r = await self.db.execute(select(Player, Match).where(Player.id == player_id, Match.id == match_id))
        row = r.one_or_none()
        if not row:
            return None
        player, match = row
        if postponed_team_ids is not None and player.real_team_id is not None and player.real_team_id in postponed_team_ids:
            return PlayerScoreResult(
                player_id=player_id,
                match_id=match_id,
                matchday=match.matchday,
                base_score=_decimal(6),
                advanced_score=_decimal(0),
                total_score=_decimal(6),
                is_postponed=True,
                played=True,
            )
        position = (player.position or "CEN")[:3].upper()
        if position not in ("POR", "DIF", "CEN", "ATT"):
            position = "CEN"

        base_score = _decimal(0)
        events_list: list[dict] = []

        # Eventi che coinvolgono il giocatore (come autore o assist)
        events = await self.db.execute(
            select(MatchEvent).where(
                MatchEvent.match_id == match_id,
                or_(MatchEvent.player_id == player_id, MatchEvent.assist_player_id == player_id),
            ).order_by(MatchEvent.minute)
        )
        for ev in events.scalars().all():
            ev_dict = {"type": ev.event_type, "minute": ev.minute}
            events_list.append(ev_dict)
            if ev.player_id == player_id:
                rule = BASE_SCORING.get(ev.event_type)
                if isinstance(rule, dict):
                    points = rule.get(position, 0)
                else:
                    points = rule if rule is not None else 0
                base_score += _decimal(points)
            if ev.assist_player_id == player_id and ev.event_type == "GOAL":
                base_score += _decimal(BASE_SCORING.get("ASSIST", 1.0))
                if not any(e.get("type") == "ASSIST" for e in events_list[-1:]):
                    events_list.append({"type": "ASSIST", "minute": ev.minute})

        # PENALTY_SAVED solo per POR (evento sul portiere)
        if position == "POR":
            r_ps = await self.db.execute(
                select(MatchEvent).where(
                    MatchEvent.match_id == match_id,
                    MatchEvent.event_type == "PENALTY_SAVED",
                    MatchEvent.player_id == player_id,
                )
            )
            if r_ps.scalar_one_or_none():
                base_score += _decimal(BASE_SCORING.get("PENALTY_SAVED", 3.0))

        # Statistiche partita (minuti, clean sheet, goal conceded)
        stats = await self.db.execute(
            select(PlayerStats).where(
                PlayerStats.player_id == player_id,
                PlayerStats.match_id == match_id,
            )
        )
        ps = stats.scalar_one_or_none()
        minutes_played = ps.minutes_played if ps else 0
        played = minutes_played > 0 or len(events_list) > 0

        if played and BASE_SCORING.get("APPEARANCE"):
            base_score += _decimal(BASE_SCORING["APPEARANCE"])

        # Clean sheet e goal conceded (solo se partita finita)
        if match.status == "FINISHED" and match.home_score is not None and match.away_score is not None:
            if player.real_team_id == match.home_team_id:
                goals_conceded = match.away_score or 0
            else:
                goals_conceded = match.home_score or 0
            if position in ("POR", "DIF") and goals_conceded == 0 and played:
                cs = BASE_SCORING.get("CLEAN_SHEET") or {}
                base_score += _decimal(cs.get(position, 0))
            if position == "POR" and goals_conceded > 0:
                gc = BASE_SCORING.get("GOAL_CONCEDED") or {}
                base_score += _decimal((gc.get("POR") or 0) * goals_conceded)

        # Avanzato da player_stats
        advanced_score = _decimal(0)
        if ps:
            xg = float(ps.expected_goals or 0)
            xa = float(ps.expected_assists or 0)
            if xg > 0.5 and (ps.goals or 0) == 0:
                advanced_score += _decimal(ADVANCED_SCORING.get("xg_wasted", -0.5))
            if xa > 0.3 and (ps.assists or 0) == 0:
                advanced_score += _decimal(ADVANCED_SCORING.get("xa_wasted", -0.25))
            if (ps.key_passes or 0) >= 3:
                advanced_score += _decimal(ADVANCED_SCORING.get("key_passes_3plus", 0.5))
            if position in ("DIF", "CEN") and (ps.total_tackles or 0) >= 5:
                advanced_score += _decimal(ADVANCED_SCORING.get("tackles_5plus", 0.5))
            if (ps.total_passes or 0) >= 30 and ps.total_passes > 0:
                acc = (ps.accurate_passes or 0) / ps.total_passes
                if acc >= 0.9:
                    advanced_score += _decimal(ADVANCED_SCORING.get("pass_accuracy_90plus", 0.5))
            if (float(ps.rating or 0)) >= 8.0:
                advanced_score += _decimal(ADVANCED_SCORING.get("high_rating", 1.0))

        # Bonus/malus da AI rating (player_ai_ratings, keyword locale)
        ai_bonus = _decimal(0)
        r_ai = await self.db.execute(
            select(PlayerAIRating.rating)
            .where(
                PlayerAIRating.player_id == player_id,
                PlayerAIRating.match_id == match_id,
            )
            .order_by(PlayerAIRating.is_final.desc(), PlayerAIRating.minute.desc())
            .limit(1)
        )
        row_ai = r_ai.scalar_one_or_none()
        if row_ai is not None:
            ai_bonus = _decimal(_ai_rating_bonus(float(row_ai)))

        total_score = base_score + advanced_score + ai_bonus
        return PlayerScoreResult(
            player_id=player_id,
            match_id=match_id,
            matchday=match.matchday,
            base_score=base_score,
            advanced_score=advanced_score,
            total_score=total_score,
            events_json=events_list if events_list else None,
            minutes_played=minutes_played,
            played=played,
            ai_rating_bonus=ai_bonus,
            is_postponed=False,
        )

    async def _get_match_for_player_in_matchday(self, player_id: int, serie_a_matchday: int) -> int | None:
        """Ritorna match_id della partita Serie A in cui il giocatore ha giocato in questa giornata (squadra reale)."""
        r = await self.db.execute(select(Player.real_team_id).where(Player.id == player_id))
        real_team_id = r.scalar_one_or_none()
        if not real_team_id:
            return None
        r2 = await self.db.execute(
            select(Match.id).where(
                Match.matchday == serie_a_matchday,
                or_(Match.home_team_id == real_team_id, Match.away_team_id == real_team_id),
            )
        )
        return r2.scalar_one_or_none()

    async def calculate_team_score(
        self,
        fantasy_team_id: Any,
        matchday: int,
        league_id: Any = None,
        threshold: float = 66,
        step: float = 8,
        serie_a_matchday: int | None = None,
        postponed_team_ids: set[int] | None = None,
    ) -> TeamScoreResult | None:
        """
        Calcola punteggio squadra fantasy per una giornata.
        serie_a_matchday = giornata Serie A (se None si usa matchday). postponed_team_ids → 6 politico.
        """
        r = await self.db.execute(select(FantasyTeam).where(FantasyTeam.id == fantasy_team_id))
        team = r.scalar_one_or_none()
        if not team:
            return None
        effective_serie_a = serie_a_matchday if serie_a_matchday is not None else matchday

        # Lineup: titolari + panchina ordinata
        lineup = await self.db.execute(
            select(FantasyLineup, Player.position)
            .join(Player, FantasyLineup.player_id == Player.id)
            .where(
                FantasyLineup.fantasy_team_id == fantasy_team_id,
                FantasyLineup.matchday == matchday,
            )
            .order_by(FantasyLineup.is_starter.desc(), FantasyLineup.bench_order.asc().nulls_last())
        )
        rows = lineup.all()
        starters: list[tuple[int, str, int | None]] = []  # (player_id, position, bench_order)
        bench: list[tuple[int, str, int]] = []
        for (line, pos) in rows:
            pos = (pos or "CEN")[:3].upper()
            if line.is_starter:
                starters.append((line.player_id, pos, line.bench_order))
            else:
                bench.append((line.player_id, pos, line.bench_order or 999))

        if len(starters) < 11:
            # Meno di 11 titolari: usiamo quelli che ci sono e riempiamo con 0 o panchina
            pass

        # Per ogni slot titolare (primi 11), calcola punteggio; se non ha giocato, sostituisci con panchina stesso ruolo
        used_bench: set[int] = set()
        player_scores: list[PlayerScoreResult] = []
        total_score = _decimal(0)

        for i, (player_id, position, _) in enumerate(starters[:11]):
            match_id = await self._get_match_for_player_in_matchday(player_id, effective_serie_a)
            score_result: PlayerScoreResult | None = None
            if match_id:
                score_result = await self.calculate_player_score(player_id, match_id, postponed_team_ids=postponed_team_ids)
            if score_result is None and postponed_team_ids:
                r_p = await self.db.execute(select(Player.real_team_id).where(Player.id == player_id))
                real_tid = r_p.scalar_one_or_none()
                if real_tid is not None and real_tid in postponed_team_ids:
                    score_result = PlayerScoreResult(
                        player_id=player_id,
                        match_id=0,
                        matchday=matchday,
                        base_score=_decimal(6),
                        advanced_score=_decimal(0),
                        total_score=_decimal(6),
                        is_starter=True,
                        played=True,
                        is_postponed=True,
                    )
            if score_result is None:
                score_result = PlayerScoreResult(
                    player_id=player_id,
                    match_id=0,
                    matchday=matchday,
                    base_score=_decimal(0),
                    advanced_score=_decimal(0),
                    total_score=_decimal(0),
                    is_starter=True,
                    played=False,
                )
            if not score_result.played and bench:
                # Cerca primo panchinaro stesso ruolo non ancora usato
                for bid, (b_player_id, b_pos, b_ord) in enumerate(sorted(bench, key=lambda x: x[2])):
                    if b_player_id in used_bench:
                        continue
                    if b_pos != position:
                        continue
                    b_match_id = await self._get_match_for_player_in_matchday(b_player_id, effective_serie_a)
                    sub_score = await self.calculate_player_score(b_player_id, b_match_id, postponed_team_ids=postponed_team_ids) if b_match_id else None
                    if sub_score is None and postponed_team_ids:
                        r_b = await self.db.execute(select(Player.real_team_id).where(Player.id == b_player_id))
                        b_real_tid = r_b.scalar_one_or_none()
                        if b_real_tid is not None and b_real_tid in postponed_team_ids:
                            sub_score = PlayerScoreResult(
                                player_id=b_player_id,
                                match_id=0,
                                matchday=matchday,
                                base_score=_decimal(6),
                                advanced_score=_decimal(0),
                                total_score=_decimal(6),
                                is_starter=False,
                                was_subbed_in=True,
                                played=True,
                                is_postponed=True,
                            )
                    if sub_score is None:
                        sub_score = PlayerScoreResult(
                            player_id=b_player_id,
                            match_id=0,
                            matchday=matchday,
                            base_score=_decimal(0),
                            advanced_score=_decimal(0),
                            total_score=_decimal(0),
                            is_starter=False,
                            was_subbed_in=True,
                            played=False,
                        )
                    sub_score.was_subbed_in = True
                    sub_score.is_starter = False
                    score_result = sub_score
                    used_bench.add(b_player_id)
                    break
            score_result.is_starter = True
            player_scores.append(score_result)
            total_score += score_result.total_score

        fantasy_goals = calculate_fantasy_goals(total_score, threshold=threshold, step=step)
        detail_json = {
            "player_scores": [
                {
                    "player_id": p.player_id,
                    "total_score": float(p.total_score),
                    "base_score": float(p.base_score),
                    "advanced_score": float(p.advanced_score),
                    "was_subbed_in": p.was_subbed_in,
                    "is_postponed": p.is_postponed,
                }
                for p in player_scores
            ],
        }

        result = TeamScoreResult(
            fantasy_team_id=fantasy_team_id,
            matchday=matchday,
            total_score=total_score,
            fantasy_goals=fantasy_goals,
            player_scores=player_scores,
            detail_json=detail_json,
        )

        if league_id:
            cal = await self.db.execute(
                select(FantasyCalendar).where(
                    FantasyCalendar.league_id == league_id,
                    FantasyCalendar.matchday == matchday,
                    or_(
                        FantasyCalendar.home_team_id == fantasy_team_id,
                        FantasyCalendar.away_team_id == fantasy_team_id,
                    ),
                )
            )
            cal_row = cal.one_or_none()
            if cal_row:
                home_id = cal_row.home_team_id
                away_id = cal_row.away_team_id
                opponent_id = away_id if fantasy_team_id == home_id else home_id
                result.opponent_id = opponent_id
                opp = await self.calculate_team_score(
                    opponent_id, matchday, league_id=None, threshold=threshold, step=step,
                    serie_a_matchday=serie_a_matchday, postponed_team_ids=postponed_team_ids,
                )
                if opp:
                    result.opponent_score = opp.total_score
                    result.opponent_goals = opp.fantasy_goals
                    if result.fantasy_goals > opp.fantasy_goals:
                        result.result = "W"
                        result.points_earned = 3
                    elif result.fantasy_goals < opp.fantasy_goals:
                        result.result = "L"
                        result.points_earned = 0
                    else:
                        result.result = "D"
                        result.points_earned = 1

        return result

    async def calculate_matchday_results(self, league_id: Any, matchday: int) -> list[MatchResult]:
        """Calcola risultati di tutte le partite fantasy della giornata (coppie da fantasy_calendar)."""
        cal = await self.db.execute(
            select(FantasyCalendar).where(
                FantasyCalendar.league_id == league_id,
                FantasyCalendar.matchday == matchday,
            )
        )
        rows = cal.scalars().all()
        league = await self.db.execute(select(FantasyLeague).where(FantasyLeague.id == league_id))
        league_obj = league.scalar_one_or_none()
        if not league_obj:
            return []
        threshold = float(league_obj.goal_threshold or 66)
        step = float(league_obj.goal_step or 8)
        start_matchday = getattr(league_obj, "start_matchday", 1)
        serie_a_matchday = start_matchday + (matchday - 1)
        postponed_team_ids = await get_postponed_team_ids(self.db, serie_a_matchday)
        results_list: list[MatchResult] = []
        for fc in rows:
            home = await self.calculate_team_score(
                fc.home_team_id, matchday, league_id=None, threshold=threshold, step=step,
                serie_a_matchday=serie_a_matchday, postponed_team_ids=postponed_team_ids,
            )
            away = await self.calculate_team_score(
                fc.away_team_id, matchday, league_id=None, threshold=threshold, step=step,
                serie_a_matchday=serie_a_matchday, postponed_team_ids=postponed_team_ids,
            )
            if not home or not away:
                continue
            hg, ag = home.fantasy_goals, away.fantasy_goals
            if hg > ag:
                home_res, away_res = "W", "L"
            elif hg < ag:
                home_res, away_res = "L", "W"
            else:
                home_res = away_res = "D"
            results_list.append(MatchResult(
                home_team_id=fc.home_team_id,
                away_team_id=fc.away_team_id,
                home_score=home.total_score,
                away_score=away.total_score,
                home_goals=hg,
                away_goals=ag,
                home_result=home_res,
                away_result=away_res,
            ))
        return results_list

    async def recalculate_standings(self, league_id: Any) -> list[StandingRow]:
        """
        Ricalcola la classifica della lega (punti, vittorie, pareggi, sconfitte, gol fatti/subiti).
        Presume che fantasy_scores sia aggiornato per tutte le giornate giocate; altrimenti
        si può usare calculate_matchday_results per ogni matchday e aggregare.
        """
        # Ottieni tutte le squadre della lega
        teams = await self.db.execute(
            select(FantasyTeam).where(FantasyTeam.league_id == league_id)
        )
        team_list = list(teams.scalars().all())
        if not team_list:
            return []

        # Aggrega da FantasyScore (total_points, wins, draws, losses, goals_for, goals_against)
        # Se non abbiamo fantasy_scores compilati, calcoliamo da calendar + team_score
        league = await self.db.execute(select(FantasyLeague).where(FantasyLeague.id == league_id))
        league_obj = league.scalar_one_or_none()
        if not league_obj:
            return []

        # Usa i totali già sul FantasyTeam (total_points, wins, draws, losses, goals_for, goals_against)
        # dopo averli ricalcolati da fantasy_scores, oppure calcola da zero
        standings: list[tuple[Any, str, int, int, int, int, int, int]] = []
        for t in team_list:
            scores = await self.db.execute(
                select(FantasyScore).where(
                    FantasyScore.fantasy_team_id == t.id,
                )
            )
            rows = list(scores.scalars().all())
            points = sum((r.points_earned or 0) for r in rows)
            wins = sum(1 for r in rows if r.result == "W")
            draws = sum(1 for r in rows if r.result == "D")
            losses = sum(1 for r in rows if r.result == "L")
            goals_for = sum(r.fantasy_goals or 0 for r in rows)
            goals_against = sum(r.opponent_goals or 0 for r in rows)
            standings.append((t.id, t.name, points, wins, draws, losses, goals_for, goals_against))

        # Ordina per punti (e differenza reti, poi gol fatti)
        standings.sort(key=lambda x: (-x[2], -(x[5] - x[6]), -x[5]))
        result = []
        for rank, (tid, name, pts, w, d, l, gf, ga) in enumerate(standings, 1):
            result.append(StandingRow(
                fantasy_team_id=tid,
                team_name=name,
                rank=rank,
                points=pts,
                wins=w,
                draws=d,
                losses=l,
                goals_for=gf,
                goals_against=ga,
            ))
        return result

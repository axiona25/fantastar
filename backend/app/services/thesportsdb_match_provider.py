"""
Provider TheSportsDB per dettaglio partita: cronaca, formazioni, statistiche.
API gratuita (key=3), rate limit 1 req/sec.
Serie A league id=4332.
"""
import asyncio
import logging
import re
from datetime import datetime

import httpx

logger = logging.getLogger(__name__)

BASE_URL = "https://www.thesportsdb.com/api/v1/json/3"
SERIE_A_LEAGUE_ID = "4332"
RATE_LIMIT = 1.0  # secondi tra richieste


def _normalize_team_name(name: str) -> str:
    """Normalizza nome squadra per match fuzzy (lowercase, spazi, sigle comuni)."""
    if not name:
        return ""
    s = re.sub(r"\s+", " ", name.strip().lower())
    # Mappature comuni DB -> TheSportsDB
    aliases = {
        "fc internazionale": "inter",
        "internazionale": "inter",
        "inter milan": "inter",
        "ac milan": "milan",
        "ssc napoli": "napoli",
        "juventus fc": "juventus",
        "as roma": "roma",
        "ss lazio": "lazio",
        "atalanta bc": "atalanta",
        "bologna fc": "bologna",
        "acf fiorentina": "fiorentina",
        "torino fc": "torino",
        "genoa cfc": "genoa",
        "udinese calcio": "udinese",
        "cagliari calcio": "cagliari",
        "us lecce": "lecce",
        "empoli fc": "empoli",
        "hellas verona": "verona",
        "monza": "monza",
        "parma calcio 1913": "parma",
        "como": "como",
        "venezia fc": "venezia",
    }
    return aliases.get(s, s)


def _team_names_match(a: str, b: str) -> bool:
    """True se i due nomi squadra coincidono (fuzzy)."""
    na, nb = _normalize_team_name(a), _normalize_team_name(b)
    if na == nb:
        return True
    if na in nb or nb in na:
        return True
    # Prime parole (es. "Inter" vs "Inter Milan")
    wa, wb = na.split(), nb.split()
    if wa and wb and wa[0] == wb[0]:
        return True
    return False


class TheSportsDBMatchProvider:
    """Client TheSportsDB per eventi round, timeline, lineup, stats. Rate limit 1 req/sec."""

    def __init__(self, base_url: str = BASE_URL, rate_limit: float = RATE_LIMIT):
        self.base_url = base_url.rstrip("/")
        self.rate_limit = rate_limit
        self._last_request: datetime | None = None
        self._client = httpx.AsyncClient(timeout=15.0)

    async def _request(self, endpoint: str, params: dict | None = None) -> dict:
        if self.rate_limit > 0 and self._last_request:
            elapsed = (datetime.now() - self._last_request).total_seconds()
            if elapsed < self.rate_limit:
                await asyncio.sleep(self.rate_limit - elapsed)
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        try:
            resp = await self._client.get(url, params=params or None)
            self._last_request = datetime.now()
            resp.raise_for_status()
            return resp.json() or {}
        except Exception as e:
            logger.warning("TheSportsDB %s %s: %s", endpoint, params, e)
            return {}

    async def close(self) -> None:
        await self._client.aclose()

    async def get_events_round(
        self,
        league_id: str = SERIE_A_LEAGUE_ID,
        matchday: int = 1,
        season: str = "2025-2026",
    ) -> list[dict]:
        """GET eventsround.php?id=4332&r={matchday}&s={season}. Ritorna lista eventi."""
        data = await self._request(
            "eventsround.php",
            params={"id": league_id, "r": matchday, "s": season},
        )
        return data.get("events") or []

    def find_event_for_match(
        self,
        events: list[dict],
        home_team_name: str,
        away_team_name: str,
    ) -> dict | None:
        """Trova l'evento TheSportsDB che corrisponde a casa/trasferta (fuzzy su strHomeTeam/strAwayTeam)."""
        for ev in events:
            home = (ev.get("strHomeTeam") or "").strip()
            away = (ev.get("strAwayTeam") or "").strip()
            if _team_names_match(home, home_team_name) and _team_names_match(away, away_team_name):
                return ev
        return None

    async def get_event_timeline(self, event_id: str) -> dict:
        """GET eventtimeline.php?id={event_id}."""
        return await self._request("eventtimeline.php", params={"id": event_id})

    async def get_event_lineup(self, event_id: str) -> dict:
        """GET eventlineup.php?id={event_id}."""
        return await self._request("eventlineup.php", params={"id": event_id})

    async def get_event_stats(self, event_id: str) -> dict:
        """GET eventstats.php?id={event_id}."""
        return await self._request("eventstats.php", params={"id": event_id})

    @staticmethod
    def build_events_from_timeline(timeline_data: dict, home_team_name: str, away_team_name: str) -> list[dict]:
        """
        Estrae lista eventi nel formato nostro da risposta eventtimeline.
        Formato atteso: { "timeline": [ { "strTimeline": "Goal", "strPlayer", "intMinute", "strTeam" } ] }
        oppure chiavi alternative (eventi, events, ecc.).
        Ogni evento output: { "minute", "type", "team", "player", "detail", "player_in", "player_out" }.
        """
        events = []
        raw = (
            timeline_data.get("timeline")
            or timeline_data.get("events")
            or timeline_data.get("event")
            or []
        )
        if not isinstance(raw, list):
            return events
        for t in raw:
            if not isinstance(t, dict):
                continue
            minute = t.get("intMinute") or t.get("minute") or t.get("min") or 0
            if isinstance(minute, str) and minute.isdigit():
                minute = int(minute)
            minute = int(minute) if minute is not None else 0
            player = (t.get("strPlayer") or t.get("player") or "").strip() or None
            team_raw = (t.get("strTeam") or t.get("team") or "").strip()
            team = None
            if team_raw and home_team_name and _team_names_match(team_raw, home_team_name):
                team = "home"
            elif team_raw and away_team_name and _team_names_match(team_raw, away_team_name):
                team = "away"
            kind = (t.get("strTimeline") or t.get("type") or t.get("strEvent") or "").strip().upper()
            if "GOAL" in kind or kind == "GOL":
                etype = "GOAL"
            elif "YELLOW" in kind or "CARD" in kind and "RED" not in kind:
                etype = "YELLOW_CARD"
            elif "RED" in kind:
                etype = "RED_CARD"
            elif "SUB" in kind or "REPLACEMENT" in kind:
                etype = "SUBSTITUTION"
                player_in = (t.get("strPlayerIn") or t.get("player_in") or "").strip() or None
                player_out = (t.get("strPlayerOut") or t.get("player_out") or "").strip() or None
                events.append({
                    "minute": minute,
                    "type": etype,
                    "team": team,
                    "player": player,
                    "detail": None,
                    "player_in": player_in,
                    "player_out": player_out,
                })
                continue
            else:
                etype = kind or "OTHER"
            detail = (t.get("strDetail") or t.get("detail") or "").strip() or None
            events.append({
                "minute": minute,
                "type": etype,
                "team": team,
                "player": player,
                "detail": detail,
                "player_in": None,
                "player_out": None,
            })
        events.sort(key=lambda x: (x["minute"], x["type"]))
        return events

    @staticmethod
    def build_lineups_from_response(lineup_data: dict, home_team_name: str, away_team_name: str) -> dict:
        """
        Formato output: { "home": { "formation", "starting": [...], "substitutes": [...] }, "away": {...} }.
        TheSportsDB può restituire "lineup", "teams", "homeLineup"/"awayLineup", "strStartXI"/"strSubstitutes".
        """
        result = {"home": {"formation": None, "starting": [], "substitutes": []}, "away": {"formation": None, "starting": [], "substitutes": []}}

        def parse_players(arr: list) -> list[dict]:
            out = []
            for p in (arr or []):
                if not isinstance(p, dict):
                    continue
                out.append({
                    "name": (p.get("strPlayer") or p.get("name") or p.get("strName") or "").strip(),
                    "number": p.get("intShirtNumber") or p.get("strNumber") or p.get("number"),
                    "position": (p.get("strPosition") or p.get("position") or "").strip() or None,
                })
                if isinstance(out[-1]["number"], str) and out[-1]["number"].isdigit():
                    out[-1]["number"] = int(out[-1]["number"])
            return out

        teams = lineup_data.get("teams") or lineup_data.get("lineup") or []
        if isinstance(teams, dict):
            teams = [teams]
        for t in teams:
            name = (t.get("strTeam") or t.get("team") or "").strip()
            side = None
            if name and _team_names_match(name, home_team_name):
                side = "home"
            elif name and _team_names_match(name, away_team_name):
                side = "away"
            if not side:
                continue
            result[side]["formation"] = (t.get("strFormation") or t.get("formation") or "").strip() or None
            result[side]["starting"] = parse_players(t.get("strStartXI") or t.get("startXI") or t.get("lineup") or [])
            result[side]["substitutes"] = parse_players(t.get("strSubstitutes") or t.get("substitutes") or t.get("bench") or [])

        if not result["home"]["starting"] and not result["away"]["starting"]:
            home_lineup = lineup_data.get("homeLineup") or lineup_data.get("home")
            away_lineup = lineup_data.get("awayLineup") or lineup_data.get("away")
            if isinstance(home_lineup, dict):
                result["home"]["formation"] = result["home"]["formation"] or home_lineup.get("strFormation") or home_lineup.get("formation")
                result["home"]["starting"] = parse_players(home_lineup.get("strStartXI") or home_lineup.get("startXI") or home_lineup.get("lineup") or [])
                result["home"]["substitutes"] = parse_players(home_lineup.get("strSubstitutes") or home_lineup.get("substitutes") or [])
            if isinstance(away_lineup, dict):
                result["away"]["formation"] = result["away"]["formation"] or away_lineup.get("strFormation") or away_lineup.get("formation")
                result["away"]["starting"] = parse_players(away_lineup.get("strStartXI") or away_lineup.get("startXI") or away_lineup.get("lineup") or [])
                result["away"]["substitutes"] = parse_players(away_lineup.get("strSubstitutes") or away_lineup.get("substitutes") or [])

        return result

    @staticmethod
    def build_statistics_from_response(stats_data: dict, home_team_name: str, away_team_name: str) -> dict | None:
        """
        Formato output: { "possession": [h, a], "shots": [h, a], ... }.
        TheSportsDB può restituire "statistics", "teams", "stats" con intPossession, intShots, ecc.
        """
        teams = stats_data.get("teams") or stats_data.get("statistics") or stats_data.get("stats") or []
        if isinstance(teams, dict):
            teams = [teams]
        home_vals = {}
        away_vals = {}
        for t in teams:
            name = (t.get("strTeam") or t.get("team") or "").strip()
            side = None
            if name and _team_names_match(name, home_team_name):
                side = "home_vals"
            elif name and _team_names_match(name, away_team_name):
                side = "away_vals"
            if not side:
                continue
            target = home_vals if side == "home_vals" else away_vals
            target["possession"] = t.get("intPossession") or t.get("possession") or 0
            target["shots"] = t.get("intShots") or t.get("shots") or 0
            target["shots_on_goal"] = t.get("intShotsOnGoal") or t.get("shotsOnGoal") or t.get("shots_on_goal") or 0
            target["corners"] = t.get("intCorners") or t.get("corners") or 0
            target["fouls"] = t.get("intFouls") or t.get("fouls") or 0
            target["offsides"] = t.get("intOffsides") or t.get("offsides") or 0
            target["yellow_cards"] = t.get("intYellowCards") or t.get("yellowCards") or t.get("yellow_cards") or 0
            target["red_cards"] = t.get("intRedCards") or t.get("redCards") or t.get("red_cards") or 0
        if not home_vals and not away_vals:
            return None
        def v(d: dict, k: str) -> int:
            val = d.get(k, 0)
            return int(val) if val is not None else 0
        return {
            "possession": [v(home_vals, "possession"), v(away_vals, "possession")],
            "shots": [v(home_vals, "shots"), v(away_vals, "shots")],
            "shots_on_target": [v(home_vals, "shots_on_goal"), v(away_vals, "shots_on_goal")],
            "corners": [v(home_vals, "corners"), v(away_vals, "corners")],
            "fouls": [v(home_vals, "fouls"), v(away_vals, "fouls")],
            "offsides": [v(home_vals, "offsides"), v(away_vals, "offsides")],
            "yellow_cards": [v(home_vals, "yellow_cards"), v(away_vals, "yellow_cards")],
            "red_cards": [v(home_vals, "red_cards"), v(away_vals, "red_cards")],
        }

    async def fetch_match_details(
        self,
        matchday: int,
        home_team_name: str,
        away_team_name: str,
        season: str = "2025-2026",
    ) -> dict | None:
        """
        1. Cerca partita per matchday e squadre (eventsround).
        2. Scarica timeline, lineup, stats (con rate limit).
        3. Ritorna payload pronto per match_details_cache: { "events", "lineups", "statistics" }.
        """
        events_round = await self.get_events_round(league_id=SERIE_A_LEAGUE_ID, matchday=matchday, season=season)
        event = self.find_event_for_match(events_round, home_team_name, away_team_name)
        if not event:
            logger.info("TheSportsDB: no event for %s vs %s round %s", home_team_name, away_team_name, matchday)
            return None
        event_id = event.get("idEvent") or event.get("id")
        if not event_id:
            return None
        event_id = str(event_id)
        timeline_data = await self.get_event_timeline(event_id)
        lineup_data = await self.get_event_lineup(event_id)
        stats_data = await self.get_event_stats(event_id)
        home_name_ts = (event.get("strHomeTeam") or "").strip()
        away_name_ts = (event.get("strAwayTeam") or "").strip()
        events = self.build_events_from_timeline(timeline_data, home_name_ts, away_name_ts)
        lineups = self.build_lineups_from_response(lineup_data, home_name_ts, away_name_ts)
        statistics = self.build_statistics_from_response(stats_data, home_name_ts, away_name_ts)
        return {"events": events, "lineups": lineups, "statistics": statistics}

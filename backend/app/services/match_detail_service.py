"""
Dettaglio partita: risultato, stadio, arbitro (football-data.org).
Eventi, formazioni, statistiche (IT), cronaca da ESPN API (gratuita); cache 30s se IN_PLAY, permanente se FINISHED.
Per IN_PLAY: chiama ESPN summary ad ogni richiesta; non tradurre in background (restituisci subito).
"""
import logging
from datetime import datetime, timezone
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import aliased

from fastapi import BackgroundTasks

from app.data_providers.football_data_org import FootballDataOrgProvider
from app.models.match import Match
from app.models.match_details_cache import MatchDetailsCache
from app.models.real_team import RealTeam
from app.schemas.match_schema import (
    MatchDetailFullResponse,
    TeamSummary,
    RefereeSummary,
    MatchEventDetail,
    TeamLineup,
    LineupPlayer,
    MatchStatistics,
    StatisticsEntry,
    CommentaryEntry,
)
from app.services.espn_provider import (
    get_scoreboard,
    get_summary,
    find_espn_event,
    get_team_ids_from_event,
    get_team_ids_from_summary,
    build_detail_payload,
    translate_batch,
)
from app.database import AsyncSessionLocal

logger = logging.getLogger(__name__)

HomeTeam = aliased(RealTeam)
AwayTeam = aliased(RealTeam)


def _team_summary(name: str | None, short: str | None, crest: str | None) -> TeamSummary:
    return TeamSummary(
        name=name or "",
        short=short or None,
        crest=crest or None,
    )


def _payload_to_response(
    base: MatchDetailFullResponse,
    payload: dict,
) -> MatchDetailFullResponse:
    """Arricchisce base con referee/venue, events, lineups, statistics (IT), commentary da cache/ESPN."""
    ref = payload.get("referee")
    if ref and isinstance(ref, dict):
        base.referee = RefereeSummary(name=ref.get("name") or "", nationality=ref.get("nationality"))
    venue_val = payload.get("venue")
    if venue_val is not None and str(venue_val).strip():
        base.venue = str(venue_val).strip()
    events_raw = payload.get("events") or []
    base.events = [
        MatchEventDetail(
            minute=e.get("minute", 0) if e.get("minute") is not None else "—",
            type=e.get("type") or "",
            team=e.get("team"),
            player=e.get("player"),
            detail=e.get("detail"),
            player_in=e.get("player_in"),
            player_out=e.get("player_out"),
        )
        for e in events_raw
    ]
    lineups_raw = payload.get("lineups") or {}
    base.lineups = {}
    for side in ("home", "away"):
        lr = lineups_raw.get(side) or {}
        starters_raw = lr.get("starters") or lr.get("starting") or []
        subs_raw = lr.get("substitutes") or []
        # Solo formazione partita: max 11 titolari, panchina convocati (no rosa completa).
        starters = starters_raw[:11] if starters_raw else []
        subs = list(subs_raw) if subs_raw else []
        base.lineups[side] = TeamLineup(
            formation=lr.get("formation"),
            starting=[LineupPlayer(name=p.get("name") or "", number=p.get("number"), position=p.get("position")) for p in starters],
            substitutes=[LineupPlayer(name=p.get("name") or "", number=p.get("number"), position=p.get("position")) for p in subs],
        )
    stats_list = payload.get("statistics")
    if isinstance(stats_list, list):
        base.statistics = [
            StatisticsEntry(name=s.get("name") or "", home=str(s.get("home", "")), away=str(s.get("away", "")))
            for s in stats_list if isinstance(s, dict)
        ]
    stats_legacy = payload.get("statistics_legacy")
    if stats_legacy and isinstance(stats_legacy, dict):
        base.statistics_legacy = MatchStatistics(
            possession=stats_legacy.get("possession") or [],
            shots=stats_legacy.get("shots") or [],
            shots_on_target=stats_legacy.get("shots_on_target") or [],
            corners=stats_legacy.get("corners") or [],
            fouls=stats_legacy.get("fouls") or [],
            offsides=stats_legacy.get("offsides") or [],
            yellow_cards=stats_legacy.get("yellow_cards") or [],
            red_cards=stats_legacy.get("red_cards") or [],
        )
    comm = payload.get("commentary") or []
    if isinstance(comm, list):
        base.commentary = [
            CommentaryEntry(minute=str(c.get("minute", "")), text=(c.get("text") or "").strip())
            for c in comm if isinstance(c, dict) and (c.get("text") or "").strip()
        ]
    base.translated = payload.get("translated", True)
    return base


async def get_match_detail_full(
    match_id: int,
    db: AsyncSession,
    background_tasks: BackgroundTasks | None = None,
) -> MatchDetailFullResponse | None:
    """
    Restituisce dettaglio partita: risultato, kick_off, stadio, arbitro.
    Eventi/formazioni/statistiche (IT)/commentary da ESPN; cache 30s se IN_PLAY, permanente se FINISHED.
    """
    q = (
        select(
            Match.id,
            Match.matchday,
            Match.status,
            Match.minute,
            Match.kick_off,
            Match.home_score,
            Match.away_score,
            Match.external_id,
            Match.espn_event_id,
            HomeTeam.name.label("home_name"),
            HomeTeam.tla.label("home_tla"),
            HomeTeam.crest_url.label("home_crest"),
            HomeTeam.stadium.label("home_stadium"),
            AwayTeam.name.label("away_name"),
            AwayTeam.tla.label("away_tla"),
            AwayTeam.crest_url.label("away_crest"),
        )
        .select_from(Match)
        .outerjoin(HomeTeam, Match.home_team_id == HomeTeam.id)
        .outerjoin(AwayTeam, Match.away_team_id == AwayTeam.id)
        .where(Match.id == match_id)
    )
    r = await db.execute(q)
    row = r.one_or_none()
    if not row:
        return None

    home_name = (row.home_name or "").strip()
    away_name = (row.away_name or "").strip()
    home_team = _team_summary(row.home_name, row.home_tla, row.home_crest)
    away_team = _team_summary(row.away_name, row.away_tla, row.away_crest)
    kick_off = row.kick_off
    if kick_off and getattr(kick_off, "tzinfo", None):
        kick_off = kick_off.replace(tzinfo=None)

    base = MatchDetailFullResponse(
        id=row.id,
        matchday=row.matchday,
        status=row.status or "SCHEDULED",
        minute=row.minute,
        kick_off=kick_off,
        home_team=home_team,
        away_team=away_team,
        home_score=row.home_score,
        away_score=row.away_score,
        referee=None,
        venue=(row.home_stadium or "").strip() or None,
        events=[],
        lineups={},
        statistics=[],
        commentary=[],
    )

    cache_row = await db.execute(select(MatchDetailsCache).where(MatchDetailsCache.match_id == match_id))
    cached = cache_row.scalar_one_or_none()
    status = (row.status or "").strip().upper()
    now = datetime.now(timezone.utc)
    use_cache = False
    if cached and cached.payload:
        if status == "FINISHED":
            use_cache = True
        elif status == "IN_PLAY" and cached.fetched_at:
            fetched = cached.fetched_at
            if fetched.tzinfo is None:
                fetched = fetched.replace(tzinfo=timezone.utc)
            delta = (now - fetched).total_seconds()
            if delta < 30:
                use_cache = True
    if use_cache:
        out = _payload_to_response(base, cached.payload)
        _apply_espn_match_to_base(out, cached.payload.get("match"))
        if status != "IN_PLAY" and status != "PAUSED" and status != "HALFTIME" and background_tasks is not None and cached.payload.get("translated") is not True:
            background_tasks.add_task(translate_remaining_in_background, match_id)
        return out

    espn_event_id = (row.espn_event_id or "").strip()
    event_from_scoreboard = None

    if not espn_event_id and kick_off and home_name and away_name:
        date_str = kick_off.strftime("%Y%m%d")
        events = await get_scoreboard(date_str)
        ev = find_espn_event(events, str(home_name), str(away_name))
        if ev:
            espn_event_id = str(ev.get("id") or "").strip()
            if espn_event_id:
                match_entity = (await db.execute(select(Match).where(Match.id == match_id))).scalar_one()
                match_entity.espn_event_id = espn_event_id
                await db.commit()
                event_from_scoreboard = ev

    if not espn_event_id:
        if row.external_id:
            try:
                provider = FootballDataOrgProvider(rate_limit=0)
                api = await provider.get_match_detail(row.external_id)
                for ref in (api.get("referees") or []):
                    if (ref.get("type") or "").upper() == "REFEREE":
                        base.referee = RefereeSummary(
                            name=(ref.get("name") or "").strip(),
                            nationality=(ref.get("nationality") or "").strip() or None,
                        )
                        break
                await provider.close()
            except Exception as e:
                logger.debug("football-data get_match_detail %s: %s", row.external_id, e)
        return base

    summary = await get_summary(espn_event_id)
    logger.info("ESPN event_id: %s", espn_event_id)
    logger.info("Summary rosters: %s", len(summary.get("rosters") or summary.get("roster") or []))
    logger.info("Summary keyEvents: %s", len(summary.get("keyEvents") or []))
    if not summary:
        if cached:
            return _payload_to_response(base, cached.payload)
        return base

    if event_from_scoreboard:
        home_id_espn, away_id_espn = get_team_ids_from_event(event_from_scoreboard)
        payload_espn = build_detail_payload(
            summary, home_name, away_name, home_id_espn, away_id_espn, event=event_from_scoreboard
        )
    else:
        home_id_espn, away_id_espn = get_team_ids_from_summary(summary)
        payload_espn = build_detail_payload(
            summary, home_name, away_name, home_id_espn, away_id_espn, event=None
        )

    logger.info(
        "build_detail_payload result: events=%s lineups_keys=%s statistics=%s commentary=%s",
        len(payload_espn.get("events") or []),
        list((payload_espn.get("lineups") or {}).keys()),
        len(payload_espn.get("statistics") or []),
        len(payload_espn.get("commentary") or []),
    )

    # Usa sempre i dati ESPN (dizionario già applicato); traduzione residua in background
    payload = dict(cached.payload) if cached and cached.payload else {}
    payload["events"] = payload_espn.get("events") or []
    payload["lineups"] = payload_espn.get("lineups") or {}
    payload["statistics"] = payload_espn.get("statistics") or []
    payload["commentary"] = payload_espn.get("commentary") or []
    payload["match"] = payload_espn.get("match") or {}
    payload["translated"] = payload_espn.get("translated", False)
    payload["commentary_to_translate_indices"] = payload_espn.get("commentary_to_translate_indices") or []
    payload["event_type_to_translate_indices"] = payload_espn.get("event_type_to_translate_indices") or []
    payload["event_detail_to_translate_indices"] = payload_espn.get("event_detail_to_translate_indices") or []

    if base.referee is None and payload.get("referee"):
        ref = payload["referee"]
        if isinstance(ref, dict):
            base.referee = RefereeSummary(name=ref.get("name") or "", nationality=ref.get("nationality"))
    if not base.venue and payload.get("venue"):
        base.venue = str(payload["venue"]).strip() or None

    if row.external_id and base.referee is None:
        try:
            provider = FootballDataOrgProvider(rate_limit=0)
            api = await provider.get_match_detail(row.external_id)
            for ref in (api.get("referees") or []):
                if (ref.get("type") or "").upper() == "REFEREE":
                    base.referee = RefereeSummary(
                        name=(ref.get("name") or "").strip(),
                        nationality=(ref.get("nationality") or "").strip() or None,
                    )
                    break
            if base.referee:
                payload["referee"] = {"name": base.referee.name, "nationality": base.referee.nationality}
            await provider.close()
        except Exception as e:
            logger.debug("football-data get_match_detail %s: %s", row.external_id, e)

    if base.venue:
        payload["venue"] = base.venue

    if cached:
        cached.payload = payload
    else:
        db.add(MatchDetailsCache(match_id=match_id, payload=payload))
    await db.commit()
    if cached:
        await db.refresh(cached)

    # Voti live: calcolati al volo da GET /matches/{id}/ratings (nessun salvataggio in DB per ora; in futuro voti Gazzetta).

    # Traduzione in background solo per partite non live (IN_PLAY: restituisci subito)
    if status not in ("IN_PLAY", "PAUSED", "HALFTIME") and background_tasks is not None and payload.get("translated") is not True:
        background_tasks.add_task(translate_remaining_in_background, match_id)

    out = _payload_to_response(base, payload)
    _apply_espn_match_to_base(out, payload.get("match"))
    return out


BATCH_SIZE = 20


async def translate_remaining_in_background(match_id: int) -> None:
    """
    Traduce con Google solo le frasi rimaste in inglese (commentary e event type/detail agli indici salvati).
    Batch da BATCH_SIZE; aggiorna cache e imposta translated=True.
    """
    async with AsyncSessionLocal() as db:
        try:
            r = await db.execute(select(MatchDetailsCache).where(MatchDetailsCache.match_id == match_id))
            cached = r.scalar_one_or_none()
            if not cached or not cached.payload:
                return
            payload = dict(cached.payload)
            if payload.get("translated") is True:
                return
            commentary_indices = payload.pop("commentary_to_translate_indices", None) or []
            event_type_indices = payload.pop("event_type_to_translate_indices", None) or []
            event_detail_indices = payload.pop("event_detail_to_translate_indices", None) or []

            events = payload.get("events") or []
            commentary = payload.get("commentary") or []

            # Commentary: batch da BATCH_SIZE
            for start in range(0, len(commentary_indices), BATCH_SIZE):
                batch_idx = commentary_indices[start : start + BATCH_SIZE]
                texts = [commentary[i].get("text") or "" for i in batch_idx if i < len(commentary)]
                if not texts:
                    continue
                translated = translate_batch(texts)
                k = 0
                for i in batch_idx:
                    if i < len(commentary) and k < len(translated):
                        commentary[i]["text"] = translated[k]
                        k += 1

            # Event type: batch
            type_texts = [events[i].get("type") or "" for i in event_type_indices if i < len(events)]
            if type_texts:
                for start in range(0, len(type_texts), BATCH_SIZE):
                    batch = type_texts[start : start + BATCH_SIZE]
                    batch_idx = event_type_indices[start : start + BATCH_SIZE]
                    tr = translate_batch(batch)
                    for j, i in enumerate(batch_idx):
                        if i < len(events) and j < len(tr):
                            events[i]["type"] = tr[j]

            # Event detail: batch
            detail_texts = [events[i].get("detail") or "" for i in event_detail_indices if i < len(events)]
            if detail_texts:
                for start in range(0, len(detail_texts), BATCH_SIZE):
                    batch = detail_texts[start : start + BATCH_SIZE]
                    batch_idx = event_detail_indices[start : start + BATCH_SIZE]
                    tr = translate_batch(batch)
                    for j, i in enumerate(batch_idx):
                        if i < len(events) and j < len(tr):
                            events[i]["detail"] = tr[j]

            payload["events"] = events
            payload["commentary"] = commentary
            payload["translated"] = True
            cached.payload = payload
            await db.commit()
            logger.info("translate_remaining_in_background: match_id=%s done", match_id)
        except Exception as e:
            logger.exception("translate_remaining_in_background match_id=%s: %s", match_id, e)


def _apply_espn_match_to_base(base: MatchDetailFullResponse, match_payload: dict | None) -> None:
    """Aggiorna score, status, minute da payload match ESPN se presenti."""
    if not match_payload or not isinstance(match_payload, dict):
        return
    if match_payload.get("home_score") is not None:
        base.home_score = int(match_payload["home_score"])
    if match_payload.get("away_score") is not None:
        base.away_score = int(match_payload["away_score"])
    if match_payload.get("status"):
        base.status = str(match_payload["status"]).strip()
    if match_payload.get("minute_display"):
        try:
            base.minute = int(str(match_payload["minute_display"]).replace("'", "").split("+")[0].strip())
        except (ValueError, TypeError):
            pass
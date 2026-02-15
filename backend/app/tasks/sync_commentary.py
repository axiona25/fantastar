"""
Sync cronache testuali live ogni 2 min durante partite live (Parte 5).
Scarica cronache, analisi locale (keyword), aggiorna player_ai_ratings, broadcast WebSocket.
"""
import logging
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.models.match import Match
from app.models.player import Player
from app.models.player_ai_rating import PlayerAIRating
from app.data_providers.live_commentary import LiveCommentaryProvider
from app.services.local_rating_service import LocalRatingService

logger = logging.getLogger(__name__)


async def _get_players_for_match(session: AsyncSession, match_id: int) -> list[tuple[int, str]]:
    """Ritorna [(player_id, name)] per i giocatori delle due squadre della partita."""
    r = await session.execute(select(Match.home_team_id, Match.away_team_id).where(Match.id == match_id))
    row = r.one_or_none()
    if not row or not row[0] or not row[1]:
        return []
    home_id, away_id = row[0], row[1]
    r2 = await session.execute(
        select(Player.id, Player.name).where(
            Player.real_team_id.in_([home_id, away_id]),
            Player.is_active == True,
        )
    )
    return [tuple(row) for row in r2.all()]


def _match_player_name(rating_name: str, players: list[tuple[int, str]]) -> int | None:
    """Trova player_id per player_name (rating). Match su cognome o nome completo."""
    rn = rating_name.lower().strip()
    for pid, pname in players:
        if not pname:
            continue
        pn = pname.lower()
        if rn in pn or pn in rn:
            return pid
        parts = rn.split()
        if any(part in pn for part in parts if len(part) > 2):
            return pid
    return None


async def sync_live_commentary() -> dict:
    """
    Ogni 2 minuti durante partite live:
    1. Trova partite IN_PLAY
    2. Per ogni partita: scarica cronache, analisi locale (keyword), aggiorna player_ai_ratings
    3. Broadcast player_ratings_update su ws/match/{match_id}
    """
    result = {"matches_processed": 0, "entries": 0, "errors": []}
    async with AsyncSessionLocal() as session:
        r = await session.execute(
            select(Match.id, Match.external_id, Match.minute).where(Match.status == "IN_PLAY")
        )
        live_matches = r.all()
    if not live_matches:
        return result

    provider = LiveCommentaryProvider()
    try:
        for match_id, external_id, current_minute in live_matches:
            if not external_id:
                continue
            try:
                entries = await provider.fetch_all_sources(str(external_id))
                if not entries:
                    continue
                async with AsyncSessionLocal() as session:
                    players = await _get_players_for_match(session, match_id)
                if not players:
                    continue
                known_names = [n for (_, n) in players]
                service = LocalRatingService()
                for entry in entries:
                    service.analyze_entry(entry, known_names)
                ratings = service.get_all_ratings()
                minute = current_minute or 0
                if entries:
                    minute = max(e.get("minute") or 0 for e in entries)

                async with AsyncSessionLocal() as session:
                    for rating in ratings:
                        player_id = _match_player_name(rating["player_name"], players)
                        if player_id is None:
                            continue
                        rec = PlayerAIRating(
                            player_id=player_id,
                            match_id=match_id,
                            minute=minute,
                            rating=float(rating["rating"]),
                            trend=rating.get("trend") or "stable",
                            mentions=rating.get("mentions") or 0,
                            key_actions=[],
                            source="local",
                            is_final=False,
                        )
                        session.add(rec)
                    await session.commit()

                # Broadcast WebSocket
                try:
                    from app.api.websocket import broadcast_match_update
                    payload = {
                        "type": "player_ratings_update",
                        "match_id": match_id,
                        "minute": minute,
                        "ratings": [
                            {
                                "player_name": r["player_name"],
                                "rating": r["rating"],
                                "trend": r.get("trend", "stable"),
                                "last_action": r.get("last_action"),
                            }
                            for r in ratings
                        ],
                    }
                    await broadcast_match_update(match_id, payload)
                except Exception as e:
                    logger.debug("broadcast_match_update ratings %s: %s", match_id, e)

                result["matches_processed"] += 1
                result["entries"] += len(entries)
            except Exception as e:
                logger.exception("sync_commentary match_id=%s: %s", match_id, e)
                result["errors"].append(f"match {match_id}: {e}")
    except Exception as e:
        logger.exception("sync_live_commentary: %s", e)
        result["errors"].append(str(e))
    return result

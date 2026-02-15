"""
Gestione disponibilità giocatori: squalifiche da cartellini, sync infortuni da API,
check disponibilità per formazione.
"""
from datetime import datetime, date
from typing import Any

from sqlalchemy import select, func, and_, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.player import Player
from app.models.match import Match
from app.models.match_event import MatchEvent
from app.models.suspension import PlayerSuspension
from app.config import settings

# Soglie accumulo gialli: { numero_giallo: giornate_squalifica }
DEFAULT_YELLOW_THRESHOLDS: dict[int, int] = {
    5: 1,
    10: 2,
    15: 3,
}
RED_CARD_SUSPENSION = 1
SECOND_YELLOW_SUSPENSION = 1

# Mapping keyword TheSportsDB strInjured -> nostro status
INJURY_STATUS_MAP: list[tuple[str, str]] = [
    ("suspended", "SUSPENDED"),
    ("banned", "SUSPENDED"),
    ("doubtful", "DOUBTFUL"),
    ("doubt", "DOUBTFUL"),
    ("minor", "DOUBTFUL"),
    ("injured", "INJURED"),
    ("out", "INJURED"),
    ("muscle", "INJURED"),
    ("knee", "INJURED"),
    ("ankle", "INJURED"),
    ("hamstring", "INJURED"),
]

STATUS_ICONS = {
    "AVAILABLE": "🟢",
    "DOUBTFUL": "🟠",
    "INJURED": "🔴",
    "SUSPENDED": "🔴",
    "NOT_CALLED": "🔴",
    "NATIONAL_TEAM": "🔵",
}


def _warning_level(status: str) -> str:
    if status in ("INJURED", "SUSPENDED", "NOT_CALLED"):
        return "red"
    if status == "DOUBTFUL":
        return "orange"
    return "green"


class AvailabilityService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def update_suspensions_after_matchday(
        self, matchday: int, season: str = "2025"
    ) -> int:
        """
        Dopo ogni giornata: calcola squalifiche da rosso diretto, doppio giallo,
        accumulo gialli (5°=1 gg, 10°=2 gg, 15°=3 gg). Crea PlayerSuspension e
        imposta availability_status = SUSPENDED.
        """
        count = 0
        # Eventi della giornata appena conclusa (matchday)
        r = await self.db.execute(
            select(Match.id).where(Match.matchday == matchday, Match.season == season)
        )
        match_ids = [row[0] for row in r.all()]
        if not match_ids:
            return 0
        # Rossi diretti e doppio giallo in questa giornata
        r2 = await self.db.execute(
            select(MatchEvent.player_id, MatchEvent.event_type).where(
                MatchEvent.match_id.in_(match_ids),
                MatchEvent.player_id.isnot(None),
                MatchEvent.event_type.in_(["RED_CARD", "SECOND_YELLOW"]),
            )
        )
        for (player_id, ev_type) in r2.all():
            if not player_id:
                continue
            days = RED_CARD_SUSPENSION if ev_type == "RED_CARD" else SECOND_YELLOW_SUSPENSION
            reason = "RED_CARD" if ev_type == "RED_CARD" else "SECOND_YELLOW"
            matchday_from = matchday + 1
            matchday_to = matchday + days
            existing = await self.db.execute(
                select(PlayerSuspension).where(
                    PlayerSuspension.player_id == player_id,
                    PlayerSuspension.matchday_from == matchday_from,
                    PlayerSuspension.reason == reason,
                )
            )
            if existing.scalar_one_or_none():
                continue
            self.db.add(PlayerSuspension(
                player_id=player_id,
                reason=reason,
                matchday_from=matchday_from,
                matchday_to=matchday_to,
                matches_count=days,
                season=season,
            ))
            await self.db.execute(
                update(Player).where(Player.id == player_id).values(
                    availability_status="SUSPENDED",
                    availability_detail=f"Squalifica {days} giornata/e ({reason})",
                    availability_updated_at=datetime.utcnow(),
                )
            )
            count += 1
        # Accumulo gialli: conta gialli stagione fino a questa giornata
        r3 = await self.db.execute(
            select(Match.id).where(Match.matchday <= matchday, Match.season == season)
        )
        all_match_ids = [row[0] for row in r3.all()]
        if not all_match_ids:
            await self.db.commit()
            return count
        r4 = await self.db.execute(
            select(MatchEvent.player_id, func.count(MatchEvent.id)).where(
                MatchEvent.match_id.in_(all_match_ids),
                MatchEvent.player_id.isnot(None),
                MatchEvent.event_type == "YELLOW_CARD",
            ).group_by(MatchEvent.player_id)
        )
        for (player_id, yellow_count) in r4.all():
            for threshold, days in sorted(DEFAULT_YELLOW_THRESHOLDS.items(), reverse=True):
                if yellow_count < threshold:
                    continue
                # Squalifica dalla prossima giornata
                matchday_from = matchday + 1
                matchday_to = matchday + days
                existing = await self.db.execute(
                    select(PlayerSuspension).where(
                        PlayerSuspension.player_id == player_id,
                        PlayerSuspension.reason == "YELLOW_ACCUMULATION",
                        PlayerSuspension.season == season,
                        PlayerSuspension.matchday_from == matchday_from,
                    )
                )
                if existing.scalar_one_or_none():
                    break
                self.db.add(PlayerSuspension(
                    player_id=player_id,
                    reason="YELLOW_ACCUMULATION",
                    matchday_from=matchday_from,
                    matchday_to=matchday_to,
                    matches_count=days,
                    season=season,
                ))
                await self.db.execute(
                    update(Player).where(Player.id == player_id).values(
                        availability_status="SUSPENDED",
                        availability_detail=f"Accumulo gialli ({yellow_count}°): squalifica {days} giornata/e",
                        availability_updated_at=datetime.utcnow(),
                    )
                )
                count += 1
                break
        await self.db.commit()
        return count

    async def check_suspension_expiry(self, matchday: int, season: str = "2025") -> int:
        """Squalifiche scadute (matchday > matchday_to): imposta availability_status = AVAILABLE."""
        r = await self.db.execute(
            select(PlayerSuspension).where(
                PlayerSuspension.matchday_to < matchday,
                PlayerSuspension.is_active == True,
                PlayerSuspension.season == season,
            )
        )
        count = 0
        for susp in r.scalars().all():
            susp.is_active = False
            await self.db.execute(
                update(Player).where(Player.id == susp.player_id).values(
                    availability_status="AVAILABLE",
                    availability_detail=None,
                    availability_updated_at=datetime.utcnow(),
                )
            )
            count += 1
        await self.db.commit()
        return count

    async def sync_injuries_from_api(self) -> int:
        """Sync infortuni da TheSportsDB (strInjured). Aggiorna Player.availability_*."""
        from app.data_providers.thesportsdb import TheSportsDBProvider
        from app.models.real_team import RealTeam
        count = 0
        provider = TheSportsDBProvider(rate_limit=0.5)
        try:
            r = await self.db.execute(select(Player.id, Player.thesportsdb_id).where(Player.thesportsdb_id.isnot(None)))
            players_ts = {row[1]: row[0] for row in r.all()}
            if not players_ts:
                return 0
            r2 = await self.db.execute(select(RealTeam.thesportsdb_id).where(RealTeam.thesportsdb_id.isnot(None)))
            team_ids = [row[0] for row in r2.all()]
            for tid in team_ids[:20]:
                data = await provider.get_team_players(tid)
                players = data.get("player") or data.get("players") or []
                if isinstance(players, dict):
                    players = [players]
                for p in players:
                    pid = p.get("idPlayer") or p.get("id")
                    if not pid or str(pid) not in players_ts:
                        continue
                    our_id = players_ts[str(pid)]
                    raw = (p.get("strInjured") or p.get("strInjury") or "").strip().lower()
                    status = "AVAILABLE"
                    detail = None
                    for keyword, st in INJURY_STATUS_MAP:
                        if keyword in raw:
                            status = st
                            detail = (p.get("strInjured") or p.get("strInjury") or "").strip() or raw[:200]
                            break
                    if status != "AVAILABLE" or raw:
                        await self.db.execute(
                            update(Player).where(Player.id == our_id).values(
                                availability_status=status,
                                availability_detail=detail[:200] if detail else None,
                                availability_updated_at=datetime.utcnow(),
                            )
                        )
                        count += 1
        finally:
            await provider.close()
        await self.db.commit()
        return count

    async def get_player_availability(
        self, player_id: int, matchday: int
    ) -> dict[str, Any]:
        """Stato completo disponibilità per un giocatore in una giornata."""
        r = await self.db.execute(select(Player).where(Player.id == player_id))
        player = r.scalar_one_or_none()
        if not player:
            return {
                "status": "AVAILABLE",
                "detail": None,
                "return_date": None,
                "matches_missed": 0,
                "is_available_for_matchday": True,
                "warning_level": "green",
                "player_name": "",
            }
        status = player.availability_status or "AVAILABLE"
        # Sospensione attiva per questa giornata?
        r2 = await self.db.execute(
            select(PlayerSuspension).where(
                PlayerSuspension.player_id == player_id,
                PlayerSuspension.is_active == True,
                PlayerSuspension.matchday_from <= matchday,
                PlayerSuspension.matchday_to >= matchday,
            )
        )
        susp = r2.scalar_one_or_none()
        if susp:
            status = "SUSPENDED"
            detail = player.availability_detail or f"Squalifica fino a giornata {susp.matchday_to}"
        else:
            detail = player.availability_detail
        return_date = player.availability_return_date.isoformat() if player.availability_return_date else None
        unavailable = status in ("INJURED", "SUSPENDED", "NOT_CALLED")
        if status == "DOUBTFUL":
            unavailable = False
        return {
            "player_id": player_id,
            "player_name": player.name,
            "status": status,
            "detail": detail,
            "return_date": return_date,
            "matches_missed": 0,
            "is_available_for_matchday": not unavailable,
            "warning_level": _warning_level(status),
        }

    async def get_squad_availability(
        self, team_roster_player_ids: list[int], matchday: int
    ) -> list[dict[str, Any]]:
        """Disponibilità di tutta la rosa per una giornata."""
        result = []
        for pid in team_roster_player_ids:
            avail = await self.get_player_availability(pid, matchday)
            result.append(avail)
        return result

    async def get_squad_availability_with_icons(
        self, team_roster_player_ids: list[int], matchday: int
    ) -> list[dict[str, Any]]:
        """Come get_squad_availability ma con icon e position per UI formazione."""
        result = []
        r = await self.db.execute(
            select(Player.id, Player.name, Player.position).where(Player.id.in_(team_roster_player_ids))
        )
        players = {row[0]: (row[1], row[2]) for row in r.all()}
        for pid in team_roster_player_ids:
            avail = await self.get_player_availability(pid, matchday)
            name, position = players.get(pid, ("", "CEN"))
            result.append({
                "player_id": pid,
                "name": name,
                "position": position or "CEN",
                "status": avail["status"],
                "icon": STATUS_ICONS.get(avail["status"], "🟢"),
                "detail": avail["detail"],
            })
        return result

    async def manually_set_availability(
        self,
        player_id: int,
        status: str,
        detail: str | None = None,
        return_date: date | None = None,
    ) -> None:
        """Imposta manualmente stato disponibilità (admin)."""
        await self.db.execute(
            update(Player).where(Player.id == player_id).values(
                availability_status=status,
                availability_detail=detail[:200] if detail else None,
                availability_return_date=return_date,
                availability_updated_at=datetime.utcnow(),
            )
        )
        await self.db.commit()

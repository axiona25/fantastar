"""
Scraping voti ufficiali Gazzetta (e altri) da fantacalcio.it.
Eseguito 2 ore dopo fine partita per importare voti in player_match_ratings.
"""
import logging
import re
from datetime import datetime, timezone, timedelta

import httpx
from bs4 import BeautifulSoup
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.match import Match
from app.models.real_team import RealTeam
from app.models.player_match_rating import PlayerMatchRating
from app.services.player_rating_service import calculate_fantasy_score

logger = logging.getLogger(__name__)

BASE_URL = "https://www.fantacalcio.it/voti-fantacalcio-serie-a"
USER_AGENT = "Mozilla/5.0 (compatible; Fantastar/1.0)"


def _normalize_name(name: str | None) -> str:
    if not name or not isinstance(name, str):
        return ""
    return " ".join(re.sub(r"\s+", " ", name.strip()).split()).lower()


def _names_match(a: str, b: str) -> bool:
    na, nb = _normalize_name(a), _normalize_name(b)
    if not na or not nb:
        return False
    if na == nb:
        return True
    if na in nb or nb in na:
        return True
    a_words = set(na.split())
    b_words = set(nb.split())
    return bool(a_words & b_words and len(a_words) >= 1 and len(b_words) >= 1)


async def fetch_voti_serie_a_matchday(matchday: int) -> list[dict]:
    """
    Scarica voti fantacalcio Serie A per una giornata.
    Ritorna lista di: { "team_name": str, "players": [ {"name": str, "voto": float} ] }.
    Per ogni partita ci sono due elementi (casa e trasferta).
    Struttura pagina fantacalcio.it può cambiare: adattare i selettori se necessario.
    """
    out: list[dict] = []
    url = f"{BASE_URL}/{matchday}" if matchday > 0 else BASE_URL
    try:
        async with httpx.AsyncClient(timeout=15.0, follow_redirects=True, headers={"User-Agent": USER_AGENT}) as client:
            resp = await client.get(url)
            resp.raise_for_status()
            html = resp.text
    except Exception as e:
        logger.warning("gazzetta_scraper fetch %s: %s", url, e)
        return out

    try:
        soup = BeautifulSoup(html, "lxml")
        # Esempio generico: cerchiamo tabelle o div con pattern "nome giocatore" + "voto"
        # Fantacalcio.it spesso ha .table o [data-giornata] / sezioni per partita
        tables = soup.find_all("table", class_=re.compile(r"voti|rating|pagelle", re.I)) or soup.find_all("table")
        for table in tables:
            rows = table.find_all("tr") if table else []
            current_team: str | None = None
            team_players: list[dict] = []
            for tr in rows:
                cells = tr.find_all(["td", "th"])
                if not cells:
                    continue
                texts = [c.get_text(strip=True) for c in cells]
                if len(texts) >= 2:
                    # Ultima colonna spesso è il voto (numero 4.0-10.0)
                    voto_str = None
                    name_str = None
                    for i, t in enumerate(texts):
                        if re.match(r"^\d+[,.]?\d*$", t.replace(",", ".")):
                            try:
                                v = float(t.replace(",", "."))
                                if 4.0 <= v <= 10.0:
                                    voto_str = v
                                    name_str = " ".join(texts[:i]) if i else (texts[0] if texts else "")
                                    break
                            except ValueError:
                                pass
                    if name_str and voto_str is not None and len(name_str) > 1:
                        team_players.append({"name": name_str.strip(), "voto": voto_str})
            if team_players and current_team:
                out.append({"team_name": current_team, "players": team_players})
            elif team_players:
                out.append({"team_name": "Squadra", "players": team_players})

        # Alternativa: div per partita con due blocchi casa/trasferta
        sections = soup.find_all(["div", "section"], class_=re.compile(r"match|partita|voti", re.I))
        for sec in sections:
            team_heading = sec.find(["h3", "h4", "strong"])
            team_name = team_heading.get_text(strip=True) if team_heading else "Squadra"
            spans = sec.find_all(string=re.compile(r"^\d[,.]\d$"))
            for s in spans:
                parent = s.parent
                if parent:
                    prev = parent.find_previous_sibling() or parent.get_text(strip=True)
                    name = prev if isinstance(prev, str) else (prev.get_text(strip=True) if prev else "")
                    if name and len(name) > 1:
                        try:
                            v = float(s.replace(",", "."))
                            if 4.0 <= v <= 10.0:
                                out.append({"team_name": team_name, "players": [{"name": name, "voto": v}]})
                        except ValueError:
                            pass
    except Exception as e:
        logger.exception("gazzetta_scraper parse: %s", e)
    return out


async def import_gazzetta_ratings_for_match(db: AsyncSession, match_id: int) -> int:
    """
    Per una partita FINISHED: scarica voti giornata, abbina per matchday e nomi squadre,
    aggiorna player_match_ratings con gazzetta_rating e is_final=True.
    Ritorna numero di giocatori aggiornati.
    """
    r = await db.execute(
        select(Match.matchday, Match.home_team_id, Match.away_team_id)
        .where(Match.id == match_id, Match.status == "FINISHED")
    )
    row = r.one_or_none()
    if not row:
        return 0
    matchday, home_team_id, away_team_id = row.matchday, row.home_team_id, row.away_team_id
    home_name = away_name = ""
    if home_team_id:
        rh = await db.execute(select(RealTeam.name).where(RealTeam.id == home_team_id))
        home_name = (rh.scalar_one_or_none() or "") or ""
    if away_team_id:
        ra = await db.execute(select(RealTeam.name).where(RealTeam.id == away_team_id))
        away_name = (ra.scalar_one_or_none() or "") or ""
    if not home_name and not away_name:
        return 0

    voti_entries = await fetch_voti_serie_a_matchday(matchday)
    if not voti_entries:
        return 0

    by_team: dict[str, list[dict]] = {}
    for entry in voti_entries:
        tn = (entry.get("team_name") or "").strip()
        if tn:
            by_team.setdefault(tn, []).extend(entry.get("players") or [])

    # Abbina quale entry è casa e quale trasferta (per nome squadra)
    home_players: list[dict] = []
    away_players: list[dict] = []
    for team_name, players in by_team.items():
        if _names_match(team_name, home_name):
            home_players = players
        elif _names_match(team_name, away_name):
            away_players = players

    if not home_players and not away_players:
        return 0

    r_ratings = await db.execute(
        select(PlayerMatchRating).where(PlayerMatchRating.match_id == match_id)
    )
    ratings = list(r_ratings.scalars().all())
    updated = 0
    for r in ratings:
        voto = None
        if r.team == home_name or _names_match(r.team, home_name):
            for p in home_players:
                if _names_match(p.get("name", ""), r.player_name):
                    voto = p.get("voto")
                    break
        elif r.team == away_name or _names_match(r.team, away_name):
            for p in away_players:
                if _names_match(p.get("name", ""), r.player_name):
                    voto = p.get("voto")
                    break
        if voto is not None:
            r.gazzetta_rating = voto
            r.live_rating = voto
            r.source = "gazzetta"
            r.is_final = True
            r.updated_at = datetime.utcnow()
            base = float(voto)
            r.fantasy_score = calculate_fantasy_score(
                base_rating=base,
                goals=r.goals,
                assists=r.assists,
                own_goals=r.own_goals,
                yellow_cards=r.yellow_cards,
                red_cards=r.red_cards,
                penalty_saved=r.penalty_saved,
                penalty_missed=r.penalty_missed,
                goals_conceded=r.goals_conceded,
                clean_sheet=r.clean_sheet,
                minutes_played=r.minutes_played,
                role="POR" if r.goals_conceded > 0 and r.goals == 0 and r.assists == 0 and r.minutes_played >= 60 else "CEN",
            )
            updated += 1
    return updated


async def import_gazzetta_ratings_finished_matches(db: AsyncSession) -> dict:
    """
    Trova partite FINISHED da almeno 2 ore, senza ancora voti Gazzetta, e importa.
    Ritorna { "processed": int, "updated": int }.
    """
    now = datetime.now(timezone.utc)
    threshold = now - timedelta(hours=2)
    r = await db.execute(
        select(Match.id)
        .where(
            Match.status == "FINISHED",
            Match.kick_off.isnot(None),
            Match.kick_off <= threshold,
        )
    )
    match_ids = [row[0] for row in r.all()]
    processed = 0
    total_updated = 0
    for match_id in match_ids:
        r_check = await db.execute(
            select(PlayerMatchRating.id).where(
                PlayerMatchRating.match_id == match_id,
                PlayerMatchRating.source == "gazzetta",
            ).limit(1)
        )
        if r_check.scalar_one_or_none():
            continue
        n = await import_gazzetta_ratings_for_match(db, match_id)
        processed += 1
        total_updated += n
    if total_updated:
        await db.commit()
    return {"processed": processed, "updated": total_updated}

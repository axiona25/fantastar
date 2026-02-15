"""
ESPN API (gratuita, no key) per dettaglio partita Serie A.
- Scoreboard: partite del giorno
- Summary: cronaca, formazioni, statistiche, commentary
- Traduzione EN->IT con deep-translator (Google), risultati cachati.
"""
import logging
import re
from datetime import datetime

import httpx
from deep_translator import GoogleTranslator

logger = logging.getLogger(__name__)

_translator = GoogleTranslator(source="en", target="it")


def translate_to_italian(text: str) -> str:
    """Traduce testo da inglese a italiano usando Google Translate."""
    if not text or not isinstance(text, str) or not text.strip():
        return text or ""
    try:
        return _translator.translate(text.strip())
    except Exception as e:
        logger.debug("translate_to_italian: %s", e)
        return text


def translate_batch(texts: list[str], max_chars_per_batch: int = 5000) -> list[str]:
    """Traduce una lista di testi in batch (chunk da max 5000 caratteri per chiamata)."""
    if not texts:
        return []
    result: list[str] = []
    batch: list[str] = []
    batch_chars = 0
    for t in texts:
        s = (t or "").strip() if isinstance(t, str) else ""
        if batch and batch_chars + len(s) > max_chars_per_batch:
            try:
                result.extend(_translator.translate_batch(batch))
            except Exception as e:
                logger.debug("translate_batch: %s", e)
                result.extend(batch)
            batch = []
            batch_chars = 0
        batch.append(s or "")
        batch_chars += len(s or "")
    if batch:
        try:
            result.extend(_translator.translate_batch(batch))
        except Exception as e:
            logger.debug("translate_batch: %s", e)
            result.extend(batch)
    return result

BASE_URL = "https://site.api.espn.com/apis/site/v2/sports/soccer/ita.1"

# Traduzione tipi evento ESPN -> italiano
TRADUZIONI_EVENTI = {
    "Goal": "Gol",
    "Goal - Header": "Gol - Colpo di testa",
    "Goal - Free-kick": "Gol - Punizione",
    "Penalty - Scored": "Rigore - Segnato",
    "Penalty - Missed": "Rigore - Sbagliato",
    "Yellow Card": "Cartellino giallo",
    "Red Card": "Cartellino rosso",
    "Substitution": "Sostituzione",
    "Corner": "Calcio d'angolo",
    "Offside": "Fuorigioco",
    "Free Kick": "Punizione",
    "Foul": "Fallo",
    "Attempt blocked": "Tiro bloccato",
    "Attempt missed": "Tiro fuori",
    "Attempt saved": "Tiro parato",
    "Delay in match": "Interruzione",
    "Delay over": "Gioco ripreso",
    "VAR Decision": "Decisione VAR",
}


def translate_event(event_type: str) -> str:
    """Traduce il tipo evento da inglese a italiano."""
    if not event_type or not isinstance(event_type, str):
        return event_type or ""
    return TRADUZIONI_EVENTI.get(event_type.strip(), event_type)


# Traduzione frasi comuni nei commentary ESPN -> italiano
TRADUZIONI_COMMENTARY = {
    "Goal!": "Gol!",
    "Substitution": "Sostituzione",
    "replaces": "sostituisce",
    "wins a free kick": "conquista una punizione",
    "wins a corner": "conquista un corner",
    "is caught offside": "è in fuorigioco",
    "right footed shot": "tiro di destro",
    "left footed shot": "tiro di sinistro",
    "header": "colpo di testa",
    "from the centre of the box": "dal centro dell'area",
    "from outside the box": "da fuori area",
    "is high and wide": "è alto e largo",
    "to the centre of the goal": "al centro della porta",
    "to the bottom left corner": "nell'angolo in basso a sinistra",
    "to the bottom right corner": "nell'angolo in basso a destra",
    "to the top left corner": "nell'angolo in alto a sinistra",
    "to the top right corner": "nell'angolo in alto a destra",
    "Assisted by": "Assist di",
    "Conceded by": "Concesso da",
    "Foul by": "Fallo di",
    "Corner,": "Calcio d'angolo,",
    "Offside,": "Fuorigioco,",
    "Attempt blocked.": "Tiro bloccato.",
    "Attempt missed.": "Tiro fuori.",
    "Attempt saved.": "Tiro parato.",
    "Match ends,": "Fine partita,",
    "First Half ends,": "Fine primo tempo,",
    "Second Half begins": "Inizio secondo tempo",
    "First Half begins": "Inizio primo tempo",
    "Delay in match": "Interruzione",
    "Delay over. They are ready to continue.": "Gioco ripreso.",
    "Penalty missed!": "Rigore sbagliato!",
    "Still": "Ancora",
    "in the attacking half": "nella metà campo avversaria",
    "in the defensive half": "nella propria metà campo",
    "is blocked": "è bloccato",
    "the right side of the box": "il lato destro dell'area",
    "the left side of the box": "il lato sinistro dell'area",
    "is shown the yellow card": "riceve il cartellino giallo",
    "for excessive celebration": "per esultanza eccessiva",
    "is saved": "è parato",
    "in the top centre of the goal": "al centro alto della porta",
    "Fourth official has announced": "Il quarto uomo annuncia",
    "minutes of added time": "minuti di recupero",
    "with a cross": "con un cross",
    "wins a free kick in the defensive half": "conquista una punizione nella propria metà campo",
    "wins a free kick in the attacking half": "conquista una punizione nella metà campo avversaria",
    "Hand ball": "Fallo di mano",
    "on the right wing": "sulla fascia destra",
    "on the left wing": "sulla fascia sinistra",
    "for a bad foul": "per un brutto fallo",
    "Second yellow card to": "Secondo cartellino giallo per",
    "Second Half ends,": "Fine secondo tempo,",
    "First Half ends,": "Fine primo tempo,",
    "from a difficult angle": "da posizione difficile",
    "and long range": "e da lunga distanza",
    "on the right": "sulla destra",
    "on the left": "sulla sinistra",
    "close range": "da distanza ravvicinata",
    "very close range": "da distanza molto ravvicinata",
    "the right side": "il lato destro",
    "the left side": "il lato sinistro",
    "too high": "troppo alto",
    "misses to the right": "fuori a destra",
    "misses to the left": "fuori a sinistra",
    "the six yard box": "l'area piccola",
    "the box": "l'area",
    "a cross": "un cross",
    "a through ball": "un passaggio filtrante",
    "a fast break": "un contropiede",
    "following a set piece situation": "su calcio piazzato",
    "following a corner": "su calcio d'angolo",
}

# Fallback: applicato dopo le sostituzioni principali per frasi che non hanno matchato (varianti, ecc.)
TRADUZIONI_COMMENTARY_FALLBACK = {
    "wins a free kick": "conquista una punizione",
    "wins a corner": "conquista un corner",
}

# "by" va dopo "is saved" / "in the top centre" per evitare sostituzioni parziali
TRADUZIONI_COMMENTARY_BY = ("by", "da")

# Parole/frasi inglesi comuni per segnalare testo ancora da tradurre con Google
ENGLISH_MARKERS = {
    "the ", " is ", " from ", " with ", " and ", " to ", " in ", " on ", " for ",
    "attempt", "blocked", "saved", "missed", "wins a", "following", " shot ", "footed",
    "header", "corner", "goal", "card", "substitution", "foul", "offside",
}


def has_english_words(text: str) -> bool:
    """True se il testo contiene ancora almeno 2 marker inglesi (da tradurre con Google)."""
    if not text or not isinstance(text, str):
        return False
    text_lower = text.lower()
    count = sum(1 for m in ENGLISH_MARKERS if m in text_lower)
    return count >= 2


def apply_dictionary(text: str) -> str:
    """Prima passata: applica solo il dizionario (istantaneo)."""
    return translate_commentary(text)


def translate_commentary_hybrid(texts: list[str]) -> tuple[list[str], list[int]]:
    """
    Traduzione ibrida: dizionario istantaneo + segna indici da tradurre con Google.
    Ritorna (testi dopo dizionario, indici delle frasi che contengono ancora inglese).
    """
    result: list[str] = []
    to_translate_indices: list[int] = []
    for i, text in enumerate(texts):
        translated = apply_dictionary(text or "")
        result.append(translated)
        if has_english_words(translated):
            to_translate_indices.append(i)
    return result, to_translate_indices


def translate_commentary(text: str) -> str:
    """Sostituisce frasi comuni inglesi con italiano nel testo commentary."""
    if not text or not isinstance(text, str):
        return text or ""
    for en, it in TRADUZIONI_COMMENTARY.items():
        text = text.replace(en, it)
    # "by" -> "da" (dopo le altre sostituzioni per evitare match parziali)
    text = text.replace(TRADUZIONI_COMMENTARY_BY[0], TRADUZIONI_COMMENTARY_BY[1])
    # Fallback: seconda passata per frasi non matchate (varianti, contesti diversi)
    for en, it in TRADUZIONI_COMMENTARY_FALLBACK.items():
        text = text.replace(en, it)
    return text


# Posizioni ESPN -> codice italiano (POR, DIF, CEN, ATT, RIS)
POSIZIONI = {
    "G": "POR",
    "GK": "POR",
    "D": "DIF",
    "CB": "DIF",
    "CD": "DIF",
    "CD-L": "DIF",
    "CD-R": "DIF",
    "LB": "DIF",
    "RB": "DIF",
    "M": "CEN",
    "CM": "CEN",
    "CM-L": "CEN",
    "CM-R": "CEN",
    "LM": "CEN",
    "RM": "CEN",
    "AM": "CEN",
    "DM": "CEN",
    "F": "ATT",
    "FW": "ATT",
    "CF": "ATT",
    "CF-L": "ATT",
    "CF-R": "ATT",
    "LW": "ATT",
    "RW": "ATT",
    "SUB": "RIS",
    "Goalkeeper": "POR",
    "Defender": "DIF",
    "Midfielder": "CEN",
    "Forward": "ATT",
}


def translate_position(pos: str | None) -> str | None:
    """Traduce posizione ESPN in codice italiano (POR, DIF, CEN, ATT, RIS)."""
    if pos is None or not isinstance(pos, str):
        return pos
    key = pos.strip()
    return POSIZIONI.get(key) or POSIZIONI.get(key.upper()) or key


SCOREBOARD_URL = f"{BASE_URL}/scoreboard"
SUMMARY_URL = f"{BASE_URL}/summary"


def _normalize_team(s: str | None) -> str:
    if s is None:
        return ""
    if not isinstance(s, str):
        s = str(s)
    return re.sub(r"\s+", " ", s.strip().lower())


async def get_scoreboard(date: datetime | str) -> list[dict]:
    """
    GET scoreboard?dates=YYYYMMDD. Ritorna lista eventi del giorno.
    date: stringa "YYYYMMDD" o oggetto datetime.
    Ogni evento: id, name, competitors [{ homeAway, team.displayName, score }], details (key events).
    """
    if isinstance(date, str):
        date_str = date
    else:
        date_str = date.strftime("%Y%m%d")
    url = f"{SCOREBOARD_URL}?dates={date_str}"
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            r = await client.get(url)
            r.raise_for_status()
            data = r.json()
    except Exception as e:
        logger.warning("ESPN scoreboard %s: %s", date_str, e)
        return []
    events = data.get("events") or []
    return events


def find_espn_event(events: list[dict], home_name: str, away_name: str) -> dict | None:
    """
    Match ESPN events con i nomi del nostro DB usando fuzzy matching.
    ESPN può usare "Pisa", il DB "AC Pisa 1909": normalizziamo prefissi/suffissi e confrontiamo.
    Usa il campo homeAway per identificare casa/trasferta (non dare per scontato che [0] sia home).
    """

    def normalize(name: str | None) -> str:
        """Rimuove prefissi/suffissi comuni per matching migliore."""
        if name is None or not isinstance(name, str):
            name = str(name) if name is not None else ""
        name = name.lower().strip()
        for prefix in (
            "ac ",
            "fc ",
            "us ",
            "ss ",
            "ssc ",
            "afc ",
            "as ",
            "acf ",
            "ssd ",
            "usc ",
        ):
            if name.startswith(prefix):
                name = name[len(prefix) :]
        for suffix in (
            " fc",
            " ac",
            " calcio",
            " 1909",
            " 1907",
            " 1913",
            " 1899",
            " bc",
        ):
            if name.endswith(suffix):
                name = name[: -len(suffix)]
        return name.strip()

    def names_match(db_name: str, espn_name: str) -> bool:
        db_norm = normalize(db_name)
        espn_norm = normalize(espn_name)
        if not db_norm or not espn_norm:
            return False
        if db_norm == espn_norm:
            return True
        if db_norm in espn_norm or espn_norm in db_norm:
            return True
        db_first = (db_norm.split() or [""])[0]
        espn_first = (espn_norm.split() or [""])[0]
        if db_first and db_first == espn_first:
            return True
        return False

    for event in events:
        comps = event.get("competitions") or []
        if not comps:
            continue
        comp = comps[0]
        competitors = comp.get("competitors") or []
        espn_home = None
        espn_away = None
        for c in competitors:
            ha = (c.get("homeAway") or "").strip().lower()
            team = c.get("team") or {}
            if not isinstance(team, dict):
                continue
            display = (team.get("displayName") or team.get("name") or "").strip()
            if ha == "home":
                espn_home = display
            elif ha == "away":
                espn_away = display
        if espn_home and espn_away and names_match(home_name, espn_home) and names_match(away_name, espn_away):
            return event
    return None


async def get_summary(espn_event_id: str) -> dict:
    """GET summary?event={id}. Ritorna boxscore, rosters, keyEvents, commentary."""
    url = f"{SUMMARY_URL}?event={espn_event_id}"
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            r = await client.get(url)
            r.raise_for_status()
            return r.json()
    except Exception as e:
        logger.warning("ESPN summary %s: %s", espn_event_id, e)
        return {}


# Nomi statistiche in italiano
STAT_LABELS = {
    "possessionPct": "Possesso palla",
    "totalShots": "Tiri totali",
    "shotsOnTarget": "Tiri in porta",
    "wonCorners": "Calci d'angolo",
    "foulsCommitted": "Falli",
    "yellowCards": "Cartellini gialli",
    "redCards": "Cartellini rossi",
    "offsides": "Fuori gioco",
}


def parse_events_from_scoreboard(event: dict, home_team_id: str, away_team_id: str) -> list[dict]:
    """
    Da event.competitions[0].details (o da summary keyEvents) costruisce lista eventi.
    Ogni item: minute (string "15'"), type (Goal, Yellow Card, etc.), player, team ("home"/"away"), detail.
    """
    comp = (event.get("competitions") or [{}])[0]
    details = comp.get("details") or []
    home_id = (home_team_id or "").strip()
    away_id = (away_team_id or "").strip()
    out = []
    for d in details:
        clock = d.get("clock") or {}
        minute = clock.get("displayValue") or str(clock.get("value", 0))
        type_info = d.get("type") or {}
        type_text = (type_info.get("text") or "").strip() or "Event"
        team_id = (d.get("team") or {}).get("id") if isinstance(d.get("team"), dict) else None
        team = "home" if str(team_id) == home_id else ("away" if str(team_id) == away_id else None)
        athletes = d.get("athletesInvolved") or []
        player = (athletes[0].get("displayName") or athletes[0].get("shortName") or "").strip() if athletes else None
        detail = None
        if "Goal" in type_text and "Own" not in type_text:
            type_norm = "Goal"
        elif "Own Goal" in type_text:
            type_norm = "Own Goal"
            detail = "Autogol"
        elif "Yellow" in type_text:
            type_norm = "Yellow Card"
        elif "Red" in type_text:
            type_norm = "Red Card"
        elif "Substitution" in type_text or "Sub" in type_text:
            type_norm = "Substitution"
            if len(athletes) >= 2:
                player_out = (athletes[0].get("displayName") or "").strip()
                player_in = (athletes[1].get("displayName") or "").strip()
                detail = f"{player_out} → {player_in}"
        else:
            type_norm = type_text
        out.append({
            "minute": minute,
            "type": type_norm,
            "team": team,
            "player": player,
            "detail": detail,
        })
    # Ordine per minuto (converti clock value se possibile)
    def sort_key(e):
        val = e.get("minute", "0")
        if isinstance(val, str):
            m = re.match(r"(\d+)(?:\'+(\d+)?)?", val.replace("'", "'"))
            if m:
                a, b = int(m.group(1)), int(m.group(2) or 0)
                return (a, b)
        return (0, 0)
    out.sort(key=sort_key)
    return out


def parse_lineups_from_summary(summary: dict, home_id: str, away_id: str) -> dict:
    """
    Da summary.roster o boxscore: roster[0]=home, roster[1]=away.
    Ogni roster: athletes con displayName, jersey, position, starter.
    Ritorna { home: { formation, starters, substitutes }, away: {...} }.
    Se home_id/away_id sono vuoti, assegna per indice (0=home, 1=away).
    """
    result = {"home": {"formation": None, "starters": [], "substitutes": []}, "away": {"formation": None, "starters": [], "substitutes": []}}
    rosters = summary.get("rosters") or summary.get("roster") or []
    if isinstance(rosters, dict):
        rosters = list(rosters.values()) if rosters else []
    have_ids = bool(home_id and away_id)
    for i, roster in enumerate(rosters[:2]):
        side = "home" if i == 0 else "away"
        roster_team_id = (roster.get("team") or {}).get("id") if isinstance(roster.get("team"), dict) else None
        if have_ids and roster_team_id and str(roster_team_id) != (home_id if side == "home" else away_id):
            continue
        formation = (roster.get("formation") or roster.get("form") or "").strip() or None
        result[side]["formation"] = formation
        roster_list = roster.get("roster") or roster.get("athletes") or roster.get("players") or []
        for p in roster_list:
            if not isinstance(p, dict):
                continue
            # ESPN: roster[i].athlete.displayName, roster[i].jersey, roster[i].position, roster[i].starter
            athlete = p.get("athlete") or {}
            if not isinstance(athlete, dict):
                athlete = {}
            name = (athlete.get("displayName") or athlete.get("fullName") or athlete.get("shortName") or "").strip() or "—"
            jersey_raw = p.get("jersey") or athlete.get("jersey") or p.get("number")
            jersey = str(jersey_raw).strip() if jersey_raw is not None and str(jersey_raw).strip() else None
            pos_raw = p.get("position") or athlete.get("position") or {}
            if isinstance(pos_raw, dict):
                pos_abbr = (pos_raw.get("abbreviation") or pos_raw.get("name") or "").strip()
            else:
                pos_abbr = str(pos_raw).strip() if pos_raw else ""
            position = translate_position(pos_abbr) if pos_abbr else None
            is_starter = p.get("starter", False) is True or p.get("start", False) is True
            entry = {"name": name, "number": jersey, "position": position}
            if is_starter:
                result[side]["starters"].append(entry)
            else:
                result[side]["substitutes"].append(entry)
    return result


def parse_statistics_from_summary(summary: dict, home_id: str, away_id: str) -> list[dict]:
    """
    Da boxscore.teams[].statistics costruisce lista { name (IT), home, away }.
    name in italiano da STAT_LABELS.
    """
    box = summary.get("boxscore") or {}
    teams = box.get("teams") or []
    home_stats = {}
    away_stats = {}
    for t in teams:
        ha = (t.get("homeAway") or "").strip().lower()
        if ha != "home" and ha != "away":
            continue
        for s in (t.get("statistics") or []):
            if not isinstance(s, dict):
                continue
            key = s.get("name") or s.get("abbreviation")
            val = s.get("displayValue") or s.get("value") or "0"
            if key:
                if ha == "home":
                    home_stats[key] = str(val).strip()
                else:
                    away_stats[key] = str(val).strip()
    # Ordine desiderato
    order_keys = ["possessionPct", "totalShots", "shotsOnTarget", "wonCorners", "foulsCommitted", "yellowCards", "redCards", "offsides"]
    out = []
    for key in order_keys:
        label = STAT_LABELS.get(key, key)
        h = home_stats.get(key, "0")
        a = away_stats.get(key, "0")
        if "%" in h or "percent" in key.lower() or key == "possessionPct":
            if not h.endswith("%"):
                h = f"{h}%"
            if not a.endswith("%"):
                a = f"{a}%"
        out.append({"name": label, "home": h, "away": a})
    return out


def parse_commentary_from_summary(summary: dict) -> list[dict]:
    """Da summary.commentary: { minute: time.displayValue, text } ordinati per minuto desc."""
    comm = summary.get("commentary") or summary.get("playByPlay") or []
    if isinstance(comm, dict):
        comm = comm.get("comments") or comm.get("items") or []
    out = []
    for c in comm:
        if not isinstance(c, dict):
            continue
        time_obj = c.get("time") or c.get("clock") or {}
        minute = (time_obj.get("displayValue") or time_obj.get("value") or "").strip() or "—"
        text = (c.get("text") or c.get("comment") or "").strip()
        if text:
            out.append({"minute": minute, "text": text})
    # Ordine per minuto decrescente (più recenti prima)
    def sort_key(x):
        m = re.match(r"(\d+)(?:\'+(\d+)?)?", str(x.get("minute", "0")).replace("'", "'"))
        if m:
            return (-int(m.group(1)), -int(m.group(2) or 0))
        return (0, 0)
    out.sort(key=sort_key)
    return out


def _event_from_key_event(ke: dict, home_id: str, away_id: str) -> dict | None:
    """Converte un keyEvent ESPN in { minute, type, team, player, detail }."""
    clock = ke.get("clock") or {}
    minute = (clock.get("displayValue") or str(clock.get("value", 0))).strip()
    type_info = ke.get("type") or {}
    type_text = (type_info.get("text") or "").strip() or "Event"
    team_obj = ke.get("team") or {}
    team_id = team_obj.get("id") if isinstance(team_obj, dict) else None
    team = "home" if str(team_id) == home_id else ("away" if str(team_id) == away_id else None)
    participants = ke.get("participants") or []
    player = None
    detail = None
    if participants:
        ath = participants[0].get("athlete") if isinstance(participants[0], dict) else participants[0]
        if isinstance(ath, dict):
            player = (ath.get("displayName") or ath.get("shortName") or "").strip()
    if "Goal" in type_text and "Own" not in type_text:
        type_norm = "Goal"
    elif "Own Goal" in type_text:
        type_norm = "Own Goal"
        detail = "Autogol"
    elif "Yellow" in type_text:
        type_norm = "Yellow Card"
    elif "Red" in type_text:
        type_norm = "Red Card"
    elif "Substitution" in type_text or "Sub" in type_text:
        type_norm = "Substitution"
        if len(participants) >= 2:
            p0 = participants[0].get("athlete") if isinstance(participants[0], dict) else participants[0]
            p1 = participants[1].get("athlete") if isinstance(participants[1], dict) else participants[1]
            n0 = (p0.get("displayName") or "").strip() if isinstance(p0, dict) else ""
            n1 = (p1.get("displayName") or "").strip() if isinstance(p1, dict) else ""
            detail = f"{n0} → {n1}"
    else:
        type_norm = type_text
    return {"minute": minute, "type": type_norm, "team": team, "player": player, "detail": detail}


def parse_events_from_summary_key_events(summary: dict, home_id: str, away_id: str) -> list[dict]:
    """Eventi da summary.keyEvents (clock.displayValue, type.text, participants[0].athlete.displayName, team)."""
    key_events = summary.get("keyEvents") or summary.get("events") or []
    out = []
    for ke in key_events:
        if not isinstance(ke, dict):
            continue
        e = _event_from_key_event(ke, home_id, away_id)
        if e:
            out.append(e)
    def sort_key(e):
        val = e.get("minute", "0")
        if isinstance(val, str):
            m = re.match(r"(\d+)(?:\'+(\d+)?)?", val.replace("'", "'"))
            if m:
                return (int(m.group(1)), int(m.group(2) or 0))
        return (0, 0)
    out.sort(key=sort_key)
    return out


def _event_from_summary_header(summary: dict) -> dict:
    """Costruisce un dict stile scoreboard event da summary.header per score/status."""
    header = summary.get("header") or {}
    comps = header.get("competitions") or summary.get("competitions") or [{}]
    comp = comps[0] if comps else {}
    return {"competitions": [comp], "date": comp.get("startDate") or ""}


def get_team_ids_from_event(event: dict) -> tuple[str, str]:
    """Ritorna (home_team_id_espn, away_team_id_espn) da event.competitions[0].competitors."""
    comp = (event.get("competitions") or [{}])[0]
    home_id = away_id = ""
    for c in (comp.get("competitors") or []):
        ha = (c.get("homeAway") or "").strip().lower()
        team = c.get("team") or {}
        tid = team.get("id") if isinstance(team, dict) else None
        if tid is not None:
            tid = str(tid).strip()
        if ha == "home":
            home_id = tid or ""
        elif ha == "away":
            away_id = tid or ""
    return home_id, away_id


def get_team_ids_from_summary(summary: dict) -> tuple[str, str]:
    """Ritorna (home_team_id_espn, away_team_id_espn) da header.competitions o boxscore.teams."""
    home_id = away_id = ""
    comp = (_event_from_summary_header(summary).get("competitions") or [{}])[0]
    for c in (comp.get("competitors") or []):
        ha = (c.get("homeAway") or "").strip().lower()
        team = c.get("team") or {}
        tid = team.get("id") if isinstance(team, dict) else None
        if tid is not None:
            tid = str(tid).strip()
        if ha == "home":
            home_id = tid or ""
        elif ha == "away":
            away_id = tid or ""
    if home_id and away_id:
        return home_id, away_id
    # Fallback: da boxscore.teams (homeAway + team.id)
    box = summary.get("boxscore") or {}
    for t in (box.get("teams") or []):
        ha = (t.get("homeAway") or "").strip().lower()
        team = t.get("team") or {}
        tid = team.get("id") if isinstance(team, dict) else None
        if tid is not None:
            tid = str(tid).strip()
        if ha == "home":
            home_id = tid or home_id
        elif ha == "away":
            away_id = tid or away_id
    return home_id, away_id


def build_detail_payload(
    summary: dict,
    home_team_name: str,
    away_team_name: str,
    home_team_id_espn: str,
    away_team_id_espn: str,
    event: dict | None = None,
) -> dict:
    """
    Costruisce payload per match_details_cache e API response.
    event opzionale: se fornito (da scoreboard) usa quello per score/status e details; altrimenti usa summary.header e keyEvents.
    """
    if event:
        comp = (event.get("competitions") or [{}])[0]
    else:
        comp = (_event_from_summary_header(summary).get("competitions") or [{}])[0]
    competitors = comp.get("competitors") or []
    home_score = away_score = None
    for c in competitors:
        if (c.get("homeAway") or "").strip().lower() == "home":
            home_score = c.get("score")
        else:
            away_score = c.get("score")
    status_obj = comp.get("status") or {}
    status_type = status_obj.get("type") or {}
    state = (status_type.get("state") or "").strip().lower()
    if state == "post" or status_type.get("completed"):
        status = "FINISHED"
    elif state == "in":
        status = "IN_PLAY"
    else:
        status = "SCHEDULED"
    display_clock = (status_obj.get("displayClock") or "").strip()
    start_date = (comp.get("startDate") or "").strip()

    if event:
        events = parse_events_from_scoreboard(event, home_team_id_espn, away_team_id_espn)
    else:
        events = parse_events_from_summary_key_events(summary, home_team_id_espn, away_team_id_espn)

    # Prima passata eventi: dizionario (istantaneo)
    event_type_to_translate: list[int] = []
    event_detail_to_translate: list[int] = []
    for i, e in enumerate(events):
        e["type"] = translate_event(e.get("type") or "")
        if has_english_words(e.get("type") or ""):
            event_type_to_translate.append(i)
        detail = e.get("detail") or ""
        if detail and has_english_words(detail):
            event_detail_to_translate.append(i)

    lineups = parse_lineups_from_summary(summary, home_team_id_espn, away_team_id_espn)
    statistics = parse_statistics_from_summary(summary, home_team_id_espn, away_team_id_espn)
    commentary = parse_commentary_from_summary(summary)

    # Prima passata commentary: dizionario (istantaneo) + indici da tradurre con Google
    commentary_texts = [c.get("text") or "" for c in commentary]
    translated_commentary_texts, commentary_to_translate_indices = translate_commentary_hybrid(commentary_texts)
    for i, c in enumerate(commentary):
        if i < len(translated_commentary_texts):
            c["text"] = translated_commentary_texts[i]

    needs_background = bool(
        commentary_to_translate_indices or event_type_to_translate or event_detail_to_translate
    )

    return {
        "match": {
            "home_team_name": home_team_name,
            "away_team_name": away_team_name,
            "home_score": int(home_score) if home_score is not None else None,
            "away_score": int(away_score) if away_score is not None else None,
            "status": status,
            "minute_display": display_clock,
            "kick_off": start_date,
        },
        "events": events,
        "lineups": lineups,
        "statistics": statistics,
        "commentary": commentary,
        "translated": not needs_background,
        "commentary_to_translate_indices": commentary_to_translate_indices,
        "event_type_to_translate_indices": event_type_to_translate,
        "event_detail_to_translate_indices": event_detail_to_translate,
    }

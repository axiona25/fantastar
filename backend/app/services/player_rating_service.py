"""
Voti live da eventi ESPN + assist estratti dalla cronaca.
Algoritmo: eventi (gol, cartellini, rigori) + parsing cronaca "Gol!" / "Assist di [Nome]".
"""
import logging
import re
import unicodedata
from datetime import datetime
from difflib import SequenceMatcher

logger = logging.getLogger(__name__)


def _normalize_for_match(name: str) -> str:
    """Normalizza per confronto: minuscolo, spazi collassati, accenti rimossi (NFKD + strip)."""
    if not name:
        return ""
    s = " ".join((name or "").strip().split()).lower()
    nfd = unicodedata.normalize("NFKD", s)
    ascii_s = nfd.encode("ascii", "ignore").decode("ascii")
    return " ".join(ascii_s.split())


def _find_best_lineup_match(event_player: str | None, lineup_names: list[str], threshold: float = 0.8) -> str | None:
    """
    Trova il giocatore in lineup che meglio corrisponde a event_player.
    Confronta nome normalizzato, cognome, e ratio fuzzy (difflib) >= threshold.
    """
    if not event_player or not lineup_names:
        return None
    ep_norm = _normalize_for_match(event_player)
    if not ep_norm:
        return None
    ep_parts = ep_norm.split()
    ep_last = ep_parts[-1] if ep_parts else ""

    best_name: str | None = None
    best_ratio = 0.0

    for lineup_name in lineup_names:
        ln_norm = _normalize_for_match(lineup_name)
        if not ln_norm:
            continue
        ln_parts = ln_norm.split()
        ln_last = ln_parts[-1] if ln_parts else ""

        if ep_norm == ln_norm:
            return lineup_name
        if ep_last == ln_last:
            r = SequenceMatcher(None, ep_norm, ln_norm).ratio()
            if r > best_ratio:
                best_ratio = r
                best_name = lineup_name
        r = SequenceMatcher(None, ep_norm, ln_norm).ratio()
        if r >= threshold and r > best_ratio:
            best_ratio = r
            best_name = lineup_name
        if ln_norm in ep_norm or ep_norm in ln_norm:
            if 1.0 > best_ratio:
                best_ratio = 1.0
                best_name = lineup_name
    return best_name if best_ratio >= threshold else None


def _player_matches_event(player_name: str, event_player: str | None) -> bool:
    """True se event_player corrisponde a player_name (normalizzato, confronto flessibile)."""
    if not event_player or not player_name:
        return False
    a = _normalize_for_match(player_name)
    b = _normalize_for_match(event_player)
    if a == b:
        return True
    if a in b or b in a:
        return True
    a_parts = a.split()
    b_parts = b.split()
    if a_parts and b_parts and a_parts[-1] == b_parts[-1]:
        return True
    return SequenceMatcher(None, a, b).ratio() >= 0.8


def get_player_event_counts_from_events(
    player_name: str,
    events: list[dict],
    team_side: str | None,
) -> dict:
    """
    Da lista eventi (type, player, team, detail) estrae conteggi per il giocatore.
    Ritorna: goals, own_goals, yellow_cards, red_cards, penalty_missed.
    """
    goals = own_goals = yellow_cards = red_cards = penalty_missed = 0
    for e in events:
        if not _player_matches_event(player_name, e.get("player")):
            continue
        t = (e.get("type") or "").strip().lower()
        if "gol" in t or "goal" in t:
            if "own" in t or "autogol" in (e.get("detail") or "").lower():
                own_goals += 1
            else:
                goals += 1
        elif "giallo" in t or "yellow" in t:
            yellow_cards += 1
        elif "rosso" in t or "red" in t:
            red_cards += 1
        elif "penalty" in t and ("missed" in t or "sbagliato" in t or "hit woodwork" in t):
            penalty_missed += 1
    return {
        "goals": goals,
        "own_goals": own_goals,
        "yellow_cards": yellow_cards,
        "red_cards": red_cards,
        "penalty_missed": penalty_missed,
    }


def extract_goal_assists(commentary: list) -> tuple[dict[str, str], dict[str, int]]:
    """
    Dalla cronaca, estrai per ogni gol chi ha fatto l'assist.
    Restituisce: (assists, assist_counts) con assists[scorer] = assistman, assist_counts[assistman] = n.
    """
    assists: dict[str, str] = {}
    assist_counts: dict[str, int] = {}
    for entry in commentary:
        text = (entry.get("text") if isinstance(entry, dict) else getattr(entry, "text", None)) or ""
        if not isinstance(text, str):
            continue
        text = text.strip()
        if not (text.startswith("Gol!") or text.startswith("Goal!")):
            continue
        assist_match = re.search(
            r"Assist di ([A-Za-zÀ-ÿ\s\-']+?)(?:\s+con\b|\.|,|\s*$)",
            text,
            re.IGNORECASE,
        )
        if assist_match:
            assistman = assist_match.group(1).strip()
            scorer_match = re.search(
                r"(?:Gol!|Goal!).*?\.\s*([A-Za-zÀ-ÿ\s\-']+?)\s*\(",
                text,
            )
            if scorer_match:
                scorer = scorer_match.group(1).strip()
                assists[scorer] = assistman
                assist_counts[assistman] = assist_counts.get(assistman, 0) + 1
    return assists, assist_counts


def _assists_for_player(player_name: str, assist_counts: dict[str, int]) -> int:
    """Conteggio assist per un giocatore: somma count per ogni key che matcha il nome (cronaca può usare nome/cognome)."""
    if not player_name or not assist_counts:
        return 0
    return sum(c for k, c in assist_counts.items() if _player_matches_event(player_name, k))


def _role_order(pos: str) -> int:
    p = (pos or "CEN").upper()
    if p == "POR":
        return 0
    if p == "DIF":
        return 1
    if p == "CEN":
        return 2
    if p == "ATT":
        return 3
    return 2


def _parse_minute(minute_val) -> int | None:
    """Estrae minuto numerico da stringa tipo \"46'\", \"90+4\" o int."""
    if minute_val is None:
        return None
    if isinstance(minute_val, int):
        return minute_val if minute_val >= 0 else None
    s = str(minute_val).strip().replace("'", "").replace("′", "")
    if not s:
        return None
    m = re.match(r"^(\d+)(?:\+(\d+))?$", s)
    if m:
        base = int(m.group(1))
        extra = int(m.group(2) or 0)
        return base + extra
    return None


def calculate_ratings(
    lineups: dict,
    events: list,
    commentary: list,
    home_score: int | None = None,
    away_score: int | None = None,
) -> dict:
    """
    Calcola voti GAZZETTA STIMATI (tab VOTI partite live). Non fantavoti.
    Base 6.0; bonus/malus contenuti; max 8.0, min 4.0; arrotondamento a 0.5.
    Subentrati dopo 75': bonus/malus dimezzati. Chi non entra: rating null.
    events: [{"type", "player", "team", "detail", "minute"?}, ...]
    Ritorna: {"home": [{"name", "rating", "played", ...}], "away": [...]}
    """
    goal_assists, assist_counts = extract_goal_assists(commentary or [])

    # Eventi per giocatore (nome -> conteggi e flag)
    player_events: dict[str, dict] = {}
    # Chi ha giocato per squadra: side -> set di nomi
    who_played: dict[str, set[str]] = {"home": set(), "away": set()}
    # Minuto ingresso/uscita per squadra e nome: side -> name -> int | None
    minute_in: dict[str, dict[str, int | None]] = {"home": {}, "away": {}}
    minute_out: dict[str, dict[str, int | None]] = {"home": {}, "away": {}}

    def ensure_player_events(pname: str) -> dict:
        if pname not in player_events:
            player_events[pname] = {
                "goals": 0,
                "yellow": 0,
                "red": 0,
                "penalty_missed": 0,
                "penalty_saved": 0,
                "own_goal": 0,
                "subbed_in": False,
                "subbed_out": False,
                "injury": False,
                "minute_in": None,
                "minute_out": None,
                "event_list": [],
            }
        return player_events[pname]

    # Build lineup names per side first (for resolving event players to lineup names)
    side_lineup_names: dict[str, list[str]] = {"home": [], "away": []}
    side_all_players: dict[str, list[dict]] = {"home": [], "away": []}
    for side in ("home", "away"):
        lineup_raw = (lineups or {}).get(side) or {}
        starting_list = lineup_raw.get("starting", lineup_raw.get("starters", []))
        subs_list = lineup_raw.get("substitutes", [])
        if hasattr(lineup_raw, "starting"):
            starting_list = getattr(lineup_raw, "starting", None) or getattr(lineup_raw, "starters", [])
        if hasattr(lineup_raw, "substitutes"):
            subs_list = getattr(lineup_raw, "substitutes", [])
        # Solo giocatori della partita: 11 titolari + panchina dalla formazione ESPN. Nessun fallback su roster/DB.
        starting_list = list(starting_list or [])[:11]
        subs_list = list(subs_list or [])
        for p in list(starting_list or []):
            d = p if isinstance(p, dict) else {"name": getattr(p, "name", ""), "number": getattr(p, "number", None), "position": getattr(p, "position", "CEN")}
            d["is_starter"] = True
            side_all_players[side].append(d)
            name = (d.get("name") or "").strip()
            if name:
                side_lineup_names[side].append(name)
                who_played[side].add(name)
        for p in list(subs_list or []):
            d = p if isinstance(p, dict) else {"name": getattr(p, "name", ""), "number": getattr(p, "number", None), "position": getattr(p, "position", "RIS")}
            d["is_starter"] = False
            side_all_players[side].append(d)
            name = (d.get("name") or "").strip()
            if name:
                side_lineup_names[side].append(name)

    for event in events or []:
        ev = event if isinstance(event, dict) else getattr(event, "__dict__", event)
        etype = (ev.get("type") if isinstance(ev, dict) else getattr(event, "type", None)) or ""
        etype_lower = etype.lower()
        detail = (ev.get("detail") if isinstance(ev, dict) else getattr(event, "detail", None)) or ""
        team = ev.get("team") if isinstance(ev, dict) else getattr(event, "team", None)
        minute_val = ev.get("minute") if isinstance(ev, dict) else getattr(event, "minute", None)
        minute_int = _parse_minute(minute_val)

        if "sostituzione" in etype_lower or "substitution" in etype_lower or "sub" in etype_lower:
            if ("→" in detail or "->" in detail) and team in ("home", "away"):
                sep = "→" if "→" in detail else "->"
                parts = detail.split(sep, 1)
                player_out_raw = (parts[0].strip() if parts else "").strip()
                player_in_raw = (parts[1].strip() if len(parts) > 1 else "").strip()
                lineup_names = side_lineup_names.get(team) or []
                player_out = _find_best_lineup_match(player_out_raw, lineup_names) or player_out_raw
                player_in = _find_best_lineup_match(player_in_raw, lineup_names) or player_in_raw
                if player_out:
                    who_played[team].add(player_out)
                    ensure_player_events(player_out)["subbed_out"] = True
                    ensure_player_events(player_out)["minute_out"] = minute_int
                    minute_out[team][player_out] = minute_int
                if player_in:
                    who_played[team].add(player_in)
                    ensure_player_events(player_in)["subbed_in"] = True
                    ensure_player_events(player_in)["minute_in"] = minute_int
                    minute_in[team][player_in] = minute_int
            continue

        player_raw = ev.get("player") if isinstance(ev, dict) else getattr(event, "player", None)
        if not player_raw:
            continue
        is_own_goal = (
            "own" in etype_lower
            or "autogol" in (detail or "").lower()
            or "og" in etype_lower
        )
        if is_own_goal:
            # L'autogol è fatto dal giocatore della squadra che SUBISCE il gol (non quella che segna).
            # event.team = squadra che "segna" (beneficiaria) → conceding = l'altra.
            conceding_side = "away" if team == "home" else "home" if team == "away" else team
            lineup_names = side_lineup_names.get(conceding_side, []) if conceding_side in ("home", "away") else []
        else:
            lineup_names = side_lineup_names.get(team, []) if team in ("home", "away") else []
        pname = _find_best_lineup_match((player_raw or "").strip(), lineup_names) if lineup_names else (player_raw or "").strip()
        if not pname:
            pname = (player_raw or "").strip()
            if lineup_names and ("gol" in etype_lower or "goal" in etype_lower):
                logger.info(
                    "Goal event: no lineup match for player=%r team=%r detail=%r (candidates=%s)",
                    player_raw, team, detail, lineup_names[:20],
                )
        pe = ensure_player_events(pname)

        if "gol" in etype_lower or "goal" in etype_lower or "og" in etype_lower:
            if is_own_goal:
                pe["own_goal"] += 1
                pe["event_list"].append({"type": "own_goal", "minute": minute_int})
            else:
                pe["goals"] += 1
                pe["event_list"].append({"type": "goal", "minute": minute_int})
                logger.info(
                    "Goal event: type=%r player=%r team=%r detail=%r -> resolved lineup player=%r (candidates=%s)",
                    etype, player_raw, team, detail, pname, lineup_names[:20],
                )
        elif "giallo" in etype_lower or "yellow" in etype_lower:
            pe["yellow"] += 1
            pe["event_list"].append({"type": "yellow_card", "minute": minute_int})
        elif "rosso" in etype_lower or "red" in etype_lower:
            pe["red"] += 1
            pe["event_list"].append({"type": "red_card", "minute": minute_int})
        elif "penalty" in etype_lower and ("missed" in etype_lower or "sbagliato" in etype_lower or "woodwork" in etype_lower):
            pe["penalty_missed"] += 1
            pe["event_list"].append({"type": "penalty_missed", "minute": minute_int})
        elif "penalty" in etype_lower and ("saved" in etype_lower or "parato" in etype_lower):
            pe["penalty_saved"] += 1
            pe["event_list"].append({"type": "penalty_saved", "minute": minute_int})
        elif "injury" in etype_lower or "infortunio" in etype_lower:
            pe["injury"] = True
            pe["event_list"].append({"type": "injury", "minute": minute_int})

    home_goals_conceded = 0
    away_goals_conceded = 0
    for event in events or []:
        ev = event if isinstance(event, dict) else getattr(event, "__dict__", event)
        t = ev.get("type", "") if isinstance(ev, dict) else getattr(event, "type", "") or ""
        team = ev.get("team") if isinstance(ev, dict) else getattr(event, "team", None)
        if "gol" in t.lower() or "goal" in t.lower() or "og" in t.lower():
            # Per gol normale e autogol: la squadra che subisce è l'avversaria di event.team (che ha "segna-to").
            if team == "home":
                away_goals_conceded += 1
            elif team == "away":
                home_goals_conceded += 1

    result: dict = {"home": {"starters": [], "bench": []}, "away": {"starters": [], "bench": []}}
    for side in ("home", "away"):
        goals_conceded = home_goals_conceded if side == "home" else away_goals_conceded
        clean_sheet = goals_conceded == 0
        all_players = side_all_players.get(side) or []

        for player in all_players:
            name = (player.get("name") or getattr(player, "name", "") or "").strip()
            if not name:
                continue
            pos = (player.get("position") or getattr(player, "position", "RIS") or "RIS")
            pos = pos.upper() if isinstance(pos, str) else "CEN"
            if pos == "RIS":
                pos = "CEN"
            number = player.get("number", getattr(player, "number", None))
            if number is not None and not isinstance(number, str):
                number = str(number) if number else None
            is_starter = player.get("is_starter", True)

            pe = {}
            for k, v in (player_events or {}).items():
                if _player_matches_event(name, k):
                    pe = v
                    break
            subbed_in = pe.get("subbed_in", False)
            subbed_out = pe.get("subbed_out", False)
            played = name in who_played[side]

            if not played:
                row = {
                    "name": name,
                    "number": number,
                    "position": pos,
                    "is_starter": is_starter,
                    "played": False,
                    "subbed_in": False,
                    "subbed_out": False,
                    "minute_in": None,
                    "minute_out": None,
                    "rating": None,
                    "fantasy_score": None,
                    "events": {
                        "goals": 0,
                        "assists": 0,
                        "yellow_cards": 0,
                        "red_cards": 0,
                        "penalty_missed": 0,
                        "penalty_saved": 0,
                        "own_goals": 0,
                        "goals_conceded": 0,
                        "clean_sheet": False,
                        "minutes_played": 0,
                        "subbed_in": 0,
                        "subbed_out": 0,
                        "injury": 0,
                    },
                    "event_list": pe.get("event_list", []),
                }
                (result[side]["bench"] if not is_starter else result[side]["starters"]).append(row)
                continue

            assists = _assists_for_player(name, assist_counts)
            goals = pe.get("goals", 0)
            yellow = pe.get("yellow", 0)
            red = pe.get("red", 0)
            pen_missed = pe.get("penalty_missed", 0)
            pen_saved = pe.get("penalty_saved", 0)
            own_goal = pe.get("own_goal", 0)

            # Subentrato dopo 75': bonus/malus dimezzati
            minute_in_val = minute_in.get(side, {}).get(name) or pe.get("minute_in")
            is_sub_after_75 = subbed_in and minute_in_val is not None and minute_in_val > 75
            factor = 0.5 if is_sub_after_75 else 1.0

            # Voto Gazzetta stimato: base 6.0, bonus/malus contenuti
            base = 6.0
            base += goals * 0.5 * factor
            base += min(assists * 0.25, 0.75) * factor
            if pos == "POR":
                base += pen_saved * 0.5 * factor
                if clean_sheet:
                    base += 0.5 * factor
                base -= min(goals_conceded * 0.5, 2.0) * factor
            base -= (red * 1.0 + max(0, yellow - red) * 0.5) * factor
            base -= own_goal * 1.0 * factor
            base -= pen_missed * 0.5 * factor
            # Arrotondamento a 0.5 (6.25→6.5, 5.8→6.0)
            rating = max(4.0, min(8.0, int(base * 2 + 0.5) / 2.0))
            rating = round(rating, 1)

            # Fantavoto (per pagina separata lega): base 6.0 + bonus fantacalcio
            fantasy = 6.0
            fantasy += goals * 3.0
            fantasy += assists * 1.0
            fantasy -= (red * 1.0 + max(0, yellow - red) * 0.5)
            fantasy -= pen_missed * 3.0
            fantasy -= own_goal * 2.0
            if pos == "POR":
                fantasy += pen_saved * 3.0
                fantasy -= goals_conceded * 1.0
                if clean_sheet:
                    fantasy += 1.0
            elif pos == "DIF" and clean_sheet:
                fantasy += 1.0
            fantasy = round(max(0.0, fantasy), 1)

            min_in = minute_in.get(side, {}).get(name) or pe.get("minute_in")
            min_out = minute_out.get(side, {}).get(name) or pe.get("minute_out")
            minutes_played = 90 if (is_starter and not subbed_out) else (90 - (min_in or 0) if min_in else (min_out or 90) if subbed_out else 0)
            if min_in is not None and min_out is not None:
                minutes_played = min_out - min_in
            elif min_in is not None:
                minutes_played = 90 - min_in
            elif subbed_out and min_out is not None:
                minutes_played = min_out
            elif is_starter:
                minutes_played = 90

            row = {
                "name": name,
                "number": number,
                "position": pos,
                "is_starter": is_starter,
                "played": True,
                "subbed_in": subbed_in,
                "subbed_out": subbed_out,
                "minute_in": min_in,
                "minute_out": min_out,
                "rating": rating,
                "fantasy_score": fantasy,
                "events": {
                    "goals": goals,
                    "assists": assists,
                    "yellow_cards": yellow,
                    "red_cards": red,
                    "penalty_missed": pen_missed,
                    "penalty_saved": pen_saved,
                    "own_goals": own_goal,
                    "goals_conceded": goals_conceded if pos == "POR" else 0,
                    "clean_sheet": clean_sheet if pos in ("POR", "DIF") else False,
                    "minutes_played": minutes_played,
                    "subbed_in": 1 if subbed_in else 0,
                    "subbed_out": 1 if subbed_out else 0,
                    "injury": 1 if pe.get("injury") else 0,
                },
                "event_list": pe.get("event_list", []),
            }
            (result[side]["bench"] if not is_starter else result[side]["starters"]).append(row)

    for side in ("home", "away"):
        for key in ("starters", "bench"):
            result[side][key].sort(key=lambda x: (_role_order(x["position"]), (x["number"] or "")))
    return result


def calculate_live_rating_from_events(
    player_name: str,
    position: str,
    events: list[dict],
    team_side: str | None,
    home_score: int | None,
    away_score: int | None,
) -> float:
    """
    Calcola voto live 4.0-10.0 SOLO da eventi (ESPN non fornisce passaggi/tiri/tackle).
    position: POR | DIF | CEN | ATT | RIS (RIS trattato come CEN).
    """
    base = 6.0
    role = (position or "CEN").upper()
    if role == "RIS":
        role = "CEN"
    counts = get_player_event_counts_from_events(player_name, events, team_side)
    for e in events:
        if not _player_matches_event(player_name, e.get("player")):
            continue
        t = (e.get("type") or "").strip().lower()
        if "gol" in t or "goal" in t:
            if "own" in t or "autogol" in (e.get("detail") or "").lower():
                base -= 1.0
            else:
                base += 1.0 if role in ("ATT", "CEN") else 1.5
        elif "giallo" in t or "yellow" in t:
            base -= 0.5
        elif "rosso" in t or "red" in t:
            base -= 1.0
        elif "penalty" in t and ("missed" in t or "sbagliato" in t or "hit woodwork" in t):
            base -= 1.0
    if role == "POR":
        goals_conceded = (away_score or 0) if team_side == "home" else (home_score or 0)
        base -= goals_conceded * 0.5
    out = max(4.0, min(10.0, round(base * 2) / 2))
    return round(out, 1)


def calculate_live_rating(player_data: dict, role: str) -> float:
    """
    Calcola voto live da 4.0 a 10.0 basato su statistiche (ESPN/eventi).
    player_data: minutes_played, goals, assists, yellow_card, red_card, saves,
                 shots, shots_on_target, passes_completed, passes_attempted,
                 tackles, interceptions, fouls_committed, fouls_drawn, goals_conceded, clean_sheet.
    role: POR | DIF | CEN | ATT
    """
    def get_int(d: dict, key: str, default: int = 0) -> int:
        v = d.get(key, default)
        if v is None:
            return default
        try:
            return int(v)
        except (TypeError, ValueError):
            return default

    def get_float(d: dict, key: str, default: float = 0.0) -> float:
        v = d.get(key, default)
        if v is None:
            return default
        try:
            return float(v)
        except (TypeError, ValueError):
            return default

    goals = get_int(player_data, "goals")
    assists = get_int(player_data, "assists")
    yellow_cards = get_int(player_data, "yellow_cards") + get_int(player_data, "yellow_card")
    red_cards = get_int(player_data, "red_cards") + get_int(player_data, "red_card")
    saves = get_int(player_data, "saves")
    goals_conceded = get_int(player_data, "goals_conceded")
    minutes = get_int(player_data, "minutes_played")
    clean_sheet = bool(player_data.get("clean_sheet", False))
    shots_on_target = get_int(player_data, "shots_on_target")
    passes_completed = get_int(player_data, "passes_completed")
    passes_attempted = max(get_int(player_data, "passes_attempted"), 1)
    tackles = get_int(player_data, "tackles")
    interceptions = get_int(player_data, "interceptions")

    base = 6.0

    if role in ("ATT", "CEN"):
        base += goals * 0.5
    elif role in ("DIF", "POR"):
        base += goals * 1.0

    base += assists * 0.3
    base -= yellow_cards * 0.5
    base -= red_cards * 1.0

    if role == "POR":
        base += saves * 0.15
        base -= goals_conceded * 0.5
        if clean_sheet and minutes >= 60:
            base += 1.0

    if role == "DIF":
        base += tackles * 0.05
        base += interceptions * 0.05
        if clean_sheet and minutes >= 60:
            base += 0.5

    if role == "CEN":
        pass_accuracy = passes_completed / passes_attempted
        base += (pass_accuracy - 0.75) * 2

    if role == "ATT":
        base += shots_on_target * 0.1

    if minutes < 30:
        base -= 0.5

    out = max(4.0, min(10.0, round(base * 2) / 2))
    return round(out, 1)


def calculate_fantasy_score(
    base_rating: float,
    goals: int = 0,
    assists: int = 0,
    own_goals: int = 0,
    yellow_cards: int = 0,
    red_cards: int = 0,
    penalty_saved: int = 0,
    penalty_missed: int = 0,
    goals_conceded: int = 0,
    clean_sheet: bool = False,
    minutes_played: int = 0,
    role: str = "CEN",
) -> float:
    """
    fantasy_score = voto_base + bonus - malus (regole fantacalcio).
    clean_sheet +1 solo per POR/DIF se minutes >= 60.
    """
    score = float(base_rating)
    score += goals * 3.0
    score += assists * 1.0
    score += penalty_saved * 3.0
    score -= yellow_cards * 0.5
    score -= red_cards * 1.0
    score -= penalty_missed * 3.0
    score -= own_goals * 2.0
    if role == "POR":
        score -= goals_conceded * 1.0
    if role in ("POR", "DIF") and clean_sheet and minutes_played >= 60:
        score += 1.0
    return round(max(0.0, score), 1)


def _normalize_name(name: str | None) -> str:
    if name is None:
        return ""
    return " ".join((name or "").strip().split())


def build_player_stats_from_payload(
    payload: dict,
    home_team_name: str,
    away_team_name: str,
    home_score: int | None,
    away_score: int | None,
    status: str,
    current_minute: int | None,
) -> list[dict]:
    """
    Da payload (events, lineups) costruisce una lista di dict per giocatore:
    { team_side, team_name, player_name, number, role, player_data }.
    player_data: goals, assists, yellow_cards, red_cards, own_goals, penalty_missed,
                 goals_conceded, minutes_played, clean_sheet, saves (0 se non disponibile).
    """
    import re
    events = payload.get("events") or []
    lineups = payload.get("lineups") or {}
    status_upper = (status or "").strip().upper()
    is_live = status_upper in ("IN_PLAY", "PAUSED", "HALFTIME")
    minutes_cap = 90
    if is_live and current_minute is not None:
        minutes_cap = max(0, min(90, current_minute))

    home_goals = home_score if home_score is not None else 0
    away_goals = away_score if away_score is not None else 0

    stats: dict[str, dict[str, dict]] = {"home": {}, "away": {}}
    for side in ("home", "away"):
        for _ in ("goals", "assists", "own_goals", "yellow_cards", "red_cards", "penalty_missed", "penalty_saved"):
            pass
        stats[side] = {}

    for e in events:
        if not isinstance(e, dict):
            continue
        team_side = e.get("team")
        if team_side not in ("home", "away"):
            continue
        player = _normalize_name(e.get("player"))
        type_str = (e.get("type") or "").strip()
        detail = (e.get("detail") or "").strip()

        if not player:
            continue
        if player not in stats[team_side]:
            stats[team_side][player] = {
                "goals": 0, "assists": 0, "own_goals": 0, "yellow_cards": 0, "red_cards": 0,
                "penalty_missed": 0, "penalty_saved": 0,
            }
        s = stats[team_side][player]

        if "Goal" in type_str and "Own" not in type_str:
            s["goals"] += 1
            if "Assist:" in detail or "Assist di" in detail:
                m = re.search(r"(?:Assist:?\s*|Assist di\s*)(.+?)(?:\s*[\.\)]|$)", detail, re.I)
                if m:
                    assister = _normalize_name(m.group(1).strip())
                    if assister and assister != player:
                        if team_side not in stats:
                            stats[team_side] = {}
                        if assister not in stats[team_side]:
                            stats[team_side][assister] = {
                                "goals": 0, "assists": 0, "own_goals": 0, "yellow_cards": 0, "red_cards": 0,
                                "penalty_missed": 0, "penalty_saved": 0,
                            }
                        stats[team_side][assister]["assists"] += 1
        elif "Own Goal" in type_str:
            s["own_goals"] += 1
        elif "Yellow" in type_str:
            s["yellow_cards"] += 1
        elif "Red" in type_str:
            s["red_cards"] += 1
        elif "Penalty" in type_str and "Missed" in type_str:
            s["penalty_missed"] += 1

    team_names = {"home": home_team_name or "Casa", "away": away_team_name or "Trasferta"}
    goals_conceded = {"home": away_goals, "away": home_goals}
    clean_sheet_team = {"home": away_goals == 0, "away": home_goals == 0}

    out = []
    for side in ("home", "away"):
        lr = lineups.get(side) or {}
        starters = (lr.get("starters") or lr.get("starting") or [])[:11]
        subs = lr.get("substitutes") or []
        for p in starters + subs:
            if not isinstance(p, dict):
                continue
            name = _normalize_name(p.get("name"))
            if not name:
                continue
            number = p.get("number") or p.get("jersey")
            if number is not None:
                number = str(number).strip() or None
            position = p.get("position") or ""
            if isinstance(position, dict):
                position = (position.get("abbreviation") or position.get("name") or "").strip()
            role = (position or "CEN").upper()
            if role not in ("POR", "DIF", "CEN", "ATT"):
                role = "CEN"
            is_starter = p in starters
            minutes_played = minutes_cap if is_starter else 0
            player_stats = stats.get(side, {}).get(name, {})
            goals = player_stats.get("goals", 0)
            assists = player_stats.get("assists", 0)
            own_goals = player_stats.get("own_goals", 0)
            yellow_cards = player_stats.get("yellow_cards", 0)
            red_cards = player_stats.get("red_cards", 0)
            penalty_missed = player_stats.get("penalty_missed", 0)
            penalty_saved = player_stats.get("penalty_saved", 0)
            gc = goals_conceded[side] if role == "POR" else 0
            cs = clean_sheet_team[side] and role in ("POR", "DIF") and minutes_played >= 60
            player_data = {
                "minutes_played": minutes_played,
                "goals": goals,
                "assists": assists,
                "own_goals": own_goals,
                "yellow_cards": yellow_cards,
                "red_cards": red_cards,
                "penalty_saved": penalty_saved,
                "penalty_missed": penalty_missed,
                "goals_conceded": gc,
                "clean_sheet": cs,
                "saves": 0,
                "shots_on_target": 0,
                "passes_completed": 0,
                "passes_attempted": 1,
                "tackles": 0,
                "interceptions": 0,
            }
            out.append({
                "team_side": side,
                "team_name": team_names[side],
                "player_name": name,
                "number": number,
                "role": role,
                "player_data": player_data,
            })
    return out


async def upsert_ratings_for_match(
    db,
    match_id: int,
    home_team_name: str,
    away_team_name: str,
    home_score: int | None,
    away_score: int | None,
    status: str,
    minute: int | None,
    payload: dict,
) -> None:
    """
    Calcola voti live da payload (events + lineups) e upsert in player_match_ratings.
    Chiamato quando match è IN_PLAY o FINISHED dopo aver costruito/aggiornato la cache.
    """
    from sqlalchemy import select
    from app.models.player_match_rating import PlayerMatchRating

    players_with_stats = build_player_stats_from_payload(
        payload, home_team_name, away_team_name, home_score, away_score, status, minute
    )
    if not players_with_stats:
        return

    for item in players_with_stats:
        team_name = item["team_name"]
        player_name = item["player_name"]
        role = item["role"]
        player_data = item["player_data"]
        live = calculate_live_rating(player_data, role)
        fantasy = calculate_fantasy_score(
            base_rating=live,
            goals=player_data["goals"],
            assists=player_data["assists"],
            own_goals=player_data["own_goals"],
            yellow_cards=player_data["yellow_cards"],
            red_cards=player_data["red_cards"],
            penalty_saved=player_data["penalty_saved"],
            penalty_missed=player_data["penalty_missed"],
            goals_conceded=player_data["goals_conceded"],
            clean_sheet=player_data["clean_sheet"],
            minutes_played=player_data["minutes_played"],
            role=role,
        )
        r = await db.execute(
            select(PlayerMatchRating).where(
                PlayerMatchRating.match_id == match_id,
                PlayerMatchRating.player_name == player_name,
                PlayerMatchRating.team == team_name,
            )
        )
        existing = r.scalar_one_or_none()
        if existing:
            existing.live_rating = live
            existing.fantasy_score = fantasy
            existing.goals = player_data["goals"]
            existing.assists = player_data["assists"]
            existing.own_goals = player_data["own_goals"]
            existing.yellow_cards = player_data["yellow_cards"]
            existing.red_cards = player_data["red_cards"]
            existing.penalty_saved = player_data["penalty_saved"]
            existing.penalty_missed = player_data["penalty_missed"]
            existing.goals_conceded = player_data["goals_conceded"]
            existing.minutes_played = player_data["minutes_played"]
            existing.clean_sheet = player_data["clean_sheet"]
            existing.source = "algorithm"
            existing.updated_at = datetime.utcnow()
        else:
            db.add(PlayerMatchRating(
                match_id=match_id,
                player_name=player_name,
                player_id=None,
                team=team_name,
                live_rating=live,
                fantasy_score=fantasy,
                goals=player_data["goals"],
                assists=player_data["assists"],
                own_goals=player_data["own_goals"],
                yellow_cards=player_data["yellow_cards"],
                red_cards=player_data["red_cards"],
                penalty_saved=player_data["penalty_saved"],
                penalty_missed=player_data["penalty_missed"],
                goals_conceded=player_data["goals_conceded"],
                minutes_played=player_data["minutes_played"],
                clean_sheet=player_data["clean_sheet"],
                source="algorithm",
                is_final=False,
            ))

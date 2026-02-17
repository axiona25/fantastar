#!/usr/bin/env python3
"""
Allinea la lista giocatori del DB con una lista (CSV) che hai esportato (es. da FantaMaster).
- Se il giocatore esiste (match per squadra + nome/cognome): aggiorna initial_price e position.
- Se non esiste: lo inserisce.

Formato CSV (separatore ; o ,), intestazione obbligatoria:
  nome;squadra;ruolo;quotazione
  Audero;Cremonese;P;17
  Bijlow;Genoa;P;4

Oppure: cognome,squadra,ruolo,quotazione (ruolo: P=portiere, D=difensore, C=centrocampista, A=attaccante).

Esecuzione:
  python scripts/align_players_from_csv.py backend/scripts/lista_quotazioni.csv
  docker-compose exec backend python scripts/align_players_from_csv.py /path/to/lista.csv
"""
import csv
import sys
from pathlib import Path
from decimal import Decimal

backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

_root = backend_dir.parent
_env = _root / ".env"
if _env.exists():
    from dotenv import load_dotenv
    load_dotenv(_env)

from sqlalchemy import create_engine, select, or_, func
from sqlalchemy.orm import Session
from app.config import settings
from app.models.real_team import RealTeam
from app.models.player import Player

SYNC_DATABASE_URL = settings.DATABASE_URL
if "+asyncpg" in SYNC_DATABASE_URL:
    SYNC_DATABASE_URL = SYNC_DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")

RUOLO_MAP = {"P": "POR", "D": "DIF", "C": "CEN", "A": "ATT"}


def _normalize_ruolo(v: str) -> str:
    v = (v or "").strip().upper()
    if v in RUOLO_MAP:
        return RUOLO_MAP[v]
    if v in ("POR", "DIF", "CEN", "ATT"):
        return v
    return "CEN"


def _name_matches(db_name: str, list_name: str) -> bool:
    """True se list_name (es. cognome) corrisponde a db_name (es. 'Marco Audero')."""
    a, b = (db_name or "").strip().lower(), (list_name or "").strip().lower()
    if not b:
        return False
    if a == b:
        return True
    # Cognome: "Audero" matcha "Marco Audero" o "Audero Marco"
    if a.endswith(" " + b) or a.startswith(b + " "):
        return True
    if " " in a and a.split()[-1] == b:
        return True
    if " " in a and a.split()[0] == b:
        return True
    return False


def main():
    if len(sys.argv) < 2:
        print("Uso: python scripts/align_players_from_csv.py <file.csv>")
        print("CSV: nome;squadra;ruolo;quotazione  (o con virgola, intestazione obbligatoria)")
        sys.exit(1)
    path = Path(sys.argv[1])
    if not path.exists():
        print(f"File non trovato: {path}")
        sys.exit(1)

    # Leggi CSV (; o ,), intestazione flessibile
    with open(path, newline="", encoding="utf-8-sig") as f:
        content = f.read()
    lines = [ln.strip() for ln in content.splitlines() if ln.strip()]
    if len(lines) < 2:
        print("CSV vuoto o senza righe dati.")
        sys.exit(1)
    try:
        dialect = csv.Sniffer().sniff(lines[0])
    except csv.Error:
        dialect = csv.excel
    reader = csv.DictReader(lines, dialect=dialect)
    headers = [h.strip() for h in (reader.fieldnames or [])]
    def col(key_candidates):
        for k in key_candidates:
            for h in headers:
                if h and h.strip().lower() == k.lower():
                    return h
        return None
    name_h = col(("nome", "cognome", "name", "giocatore"))
    squad_h = col(("squadra", "team", "squad"))
    ruolo_h = col(("ruolo", "role"))
    quota_h = col(("quotazione", "quota", "prezzo", "initial_price", "price"))
    if not name_h or not squad_h or not quota_h:
        print("Colonne richieste: nome/cognome, squadra, quotazione. Trovate:", headers)
        sys.exit(1)
    ruolo_h = ruolo_h or "ruolo"

    rows = []
    for r in reader:
        nome = (r.get(name_h) or "").strip()
        squadra = (r.get(squad_h) or "").strip()
        ruolo = (r.get(ruolo_h) or "C").strip()
        quota = (r.get(quota_h) or "1").strip().replace(",", ".")
        if not nome or not squadra:
            continue
        try:
            q = float(quota)
            if q < 0:
                q = 1
        except ValueError:
            q = 1
        rows.append({"nome": nome, "squadra": squadra, "ruolo": _normalize_ruolo(ruolo), "quotazione": Decimal(str(q))})

    if not rows:
        print("Nessuna riga valida nel CSV.")
        sys.exit(1)

    engine = create_engine(SYNC_DATABASE_URL)
    stats = {"updated": 0, "inserted": 0, "team_missing": 0, "skipped": 0}
    with Session(engine) as session:
        all_teams = session.execute(select(RealTeam)).scalars().all()
        def find_team(squadra: str):
            s = squadra.lower()
            for t in all_teams:
                n = (t.name or "").lower()
                if n == s or s in n or n.endswith(" " + s) or n.startswith(s + " "):
                    return t
            return None
        for r in rows:
            rt = find_team(r["squadra"])
            if not rt:
                stats["team_missing"] += 1
                continue
            # Cerca giocatore: stesso real_team e nome che matcha (esatto o cognome)
            players = session.execute(select(Player).where(Player.real_team_id == rt.id)).scalars().all()
            found = next((p for p in players if _name_matches(p.name, r["nome"])), None)
            if found:
                found.initial_price = r["quotazione"]
                found.position = r["ruolo"]
                stats["updated"] += 1
            else:
                session.add(Player(
                    name=r["nome"],
                    position=r["ruolo"],
                    initial_price=r["quotazione"],
                    real_team_id=rt.id,
                    is_active=True,
                ))
                stats["inserted"] += 1
        session.commit()

    print("Allineamento completato:", stats)
    if stats["team_missing"]:
        print("  (squadre non trovate nel DB: verifica nomi nel CSV, es. 'Verona' vs 'Hellas Verona')")


if __name__ == "__main__":
    main()

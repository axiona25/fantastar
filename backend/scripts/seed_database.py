#!/usr/bin/env python3
"""
Popola il database con le 20 squadre di Serie A (nomi, abbreviazioni, colori).
Eseguire da backend con: python scripts/seed_database.py
Oppure in Docker: docker-compose exec backend python scripts/seed_database.py
"""
import sys
from pathlib import Path

# Aggiungi backend alla path
backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from app.config import settings
from app.database import Base
from app.models.real_team import RealTeam

# URL sincrono per script (psycopg2)
SYNC_DATABASE_URL = settings.DATABASE_URL
if "+asyncpg" in SYNC_DATABASE_URL:
    SYNC_DATABASE_URL = SYNC_DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")

# 20 squadre Serie A 2024/2025 - dati base
SERIE_A_TEAMS = [
    {"name": "Inter", "short_name": "INT", "tla": "INT", "primary_color": "#003DA5", "secondary_color": "#000000", "city": "Milano"},
    {"name": "Juventus", "short_name": "JUV", "tla": "JUV", "primary_color": "#000000", "secondary_color": "#FFFFFF", "city": "Torino"},
    {"name": "Milan", "short_name": "MIL", "tla": "MIL", "primary_color": "#FB090B", "secondary_color": "#000000", "city": "Milano"},
    {"name": "Napoli", "short_name": "NAP", "tla": "NAP", "primary_color": "#00A651", "secondary_color": "#00A651", "city": "Napoli"},
    {"name": "Roma", "short_name": "ROM", "tla": "ROM", "primary_color": "#8B1538", "secondary_color": "#F4B400", "city": "Roma"},
    {"name": "Lazio", "short_name": "LAZ", "tla": "LAZ", "primary_color": "#6699FF", "secondary_color": "#FFFFFF", "city": "Roma"},
    {"name": "Atalanta", "short_name": "ATA", "tla": "ATA", "primary_color": "#005293", "secondary_color": "#000000", "city": "Bergamo"},
    {"name": "Fiorentina", "short_name": "FIO", "tla": "FIO", "primary_color": "#482E92", "secondary_color": "#FFFFFF", "city": "Firenze"},
    {"name": "Bologna", "short_name": "BOL", "tla": "BOL", "primary_color": "#A50044", "secondary_color": "#003366", "city": "Bologna"},
    {"name": "Torino", "short_name": "TOR", "tla": "TOR", "primary_color": "#7B2639", "secondary_color": "#FFFFFF", "city": "Torino"},
    {"name": "Genoa", "short_name": "GEN", "tla": "GEN", "primary_color": "#AD0A0A", "secondary_color": "#0D0D0D", "city": "Genova"},
    {"name": "Monza", "short_name": "MON", "tla": "MON", "primary_color": "#8B0000", "secondary_color": "#FFFFFF", "city": "Monza"},
    {"name": "Lecce", "short_name": "LEC", "tla": "LEC", "primary_color": "#FECE00", "secondary_color": "#E32219", "city": "Lecce"},
    {"name": "Udinese", "short_name": "UDI", "tla": "UDI", "primary_color": "#000000", "secondary_color": "#FFFFFF", "city": "Udine"},
    {"name": "Cagliari", "short_name": "CAG", "tla": "CAG", "primary_color": "#E32219", "secondary_color": "#003399", "city": "Cagliari"},
    {"name": "Hellas Verona", "short_name": "VER", "tla": "VER", "primary_color": "#003399", "secondary_color": "#FFCC00", "city": "Verona"},
    {"name": "Empoli", "short_name": "EMP", "tla": "EMP", "primary_color": "#003399", "secondary_color": "#FFFFFF", "city": "Empoli"},
    {"name": "Frosinone", "short_name": "FRO", "tla": "FRO", "primary_color": "#F5A623", "secondary_color": "#003366", "city": "Frosinone"},
    {"name": "Salernitana", "short_name": "SAL", "tla": "SAL", "primary_color": "#682B47", "secondary_color": "#FFFFFF", "city": "Salerno"},
    {"name": "Venezia", "short_name": "VEN", "tla": "VEN", "primary_color": "#FF8C00", "secondary_color": "#003366", "city": "Venezia"},
]


def main():
    engine = create_engine(SYNC_DATABASE_URL)
    with Session(engine) as session:
        existing = session.query(RealTeam).count()
        if existing > 0:
            print(f"Trovate già {existing} squadre nel database. Nessuna inserzione.")
            return
        for data in SERIE_A_TEAMS:
            team = RealTeam(**data)
            session.add(team)
        session.commit()
        print(f"Inserite {len(SERIE_A_TEAMS)} squadre di Serie A.")


if __name__ == "__main__":
    main()

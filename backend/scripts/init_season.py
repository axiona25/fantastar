#!/usr/bin/env python3
"""
Script one-shot per inizio stagione:
1. Sync squadre Serie A (real_teams con external_id)
2. Sync tutte le rose (giocatori)
3. Sync tutte le partite della stagione
4. Download stemmi e foto
5. Sync classifica iniziale
6. Sync news

Eseguire da backend: python scripts/init_season.py
In Docker: docker-compose exec backend python scripts/init_season.py
"""
import asyncio
import sys
from pathlib import Path

backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

# Carica .env dalla root progetto
_root = backend_dir.parent
_env = _root / ".env"
if _env.exists():
    from dotenv import load_dotenv
    load_dotenv(_env)


async def main():
    from app.tasks.sync_matches import sync_real_teams, sync_all_matches
    from app.tasks.sync_standings import sync_standings
    from app.tasks.sync_players import sync_all_players
    from app.tasks.sync_media import download_all_badges, download_all_player_photos, generate_missing_avatars
    from app.tasks.sync_news import sync_news

    print("1. Sync squadre Serie A...")
    r1 = await sync_real_teams()
    print("   ", r1)

    print("2. Sync rose (giocatori)...")
    r2 = await sync_all_players()
    print("   ", r2)

    print("3. Sync partite stagione...")
    r3 = await sync_all_matches()
    print("   ", r3)

    print("4. Download stemmi e foto...")
    r4a = await download_all_badges()
    r4b = await download_all_player_photos()
    r4c = await generate_missing_avatars()
    print("   badges:", r4a, "photos:", r4b, "avatars:", r4c)

    print("5. Sync classifica...")
    r5 = await sync_standings()
    print("   cached:", r5 is not None)

    print("6. Sync news...")
    r6 = await sync_news()
    print("   ", r6)

    print("Init season completed.")


if __name__ == "__main__":
    asyncio.run(main())

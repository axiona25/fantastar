import os
from pathlib import Path

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    from app.tasks.scheduler import start_scheduler, stop_scheduler
    start_scheduler()
    yield
    stop_scheduler()


app = FastAPI(
    title="FANTASTAR API",
    description="API per il fantacalcio event-based Serie A",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: restringere in produzione
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.api.v1 import auth as auth_router
from app.api.v1 import leagues as leagues_router
from app.api.v1 import teams as teams_router
from app.api.v1 import auction as auction_router
from app.api.v1 import players as players_router
from app.api.v1 import market as market_router
from app.api.v1 import stats as stats_router
from app.api.v1 import standings as standings_router
from app.api.v1 import matches as matches_router
from app.api.v1 import news as news_router
from app.api import websocket as websocket_router

app.include_router(auth_router.router, prefix="/api/v1")
app.include_router(leagues_router.router, prefix="/api/v1")
app.include_router(teams_router.router, prefix="/api/v1")
app.include_router(auction_router.router, prefix="/api/v1")
app.include_router(players_router.router, prefix="/api/v1")
app.include_router(market_router.router, prefix="/api/v1")
app.include_router(stats_router.router, prefix="/api/v1")
app.include_router(standings_router.router, prefix="/api/v1")
app.include_router(matches_router.router, prefix="/api/v1")
app.include_router(news_router.router, prefix="/api/v1")
app.include_router(websocket_router.router)

# Static files (foto giocatori in static/photos)
_static_dir = Path(__file__).resolve().parent.parent / "static"
if _static_dir.exists():
    app.mount("/static", StaticFiles(directory=str(_static_dir)), name="static")


@app.get("/")
async def root():
    return {"app": "FANTASTAR", "status": "running", "version": "0.1.0"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


@app.get("/api/league-badges")
async def get_league_badges():
    """Lista file immagine nella cartella static/media/league_badges/3d (per stemmi lega)."""
    base = Path(__file__).resolve().parent.parent
    badges_dir = base / "static" / "media" / "league_badges" / "3d"
    if not badges_dir.is_dir():
        return []
    files = sorted(
        f for f in os.listdir(badges_dir)
        if f.lower().endswith((".png", ".jpg", ".jpeg", ".webp"))
    )
    return [f"/static/media/league_badges/3d/{f}" for f in files]


def _badge_display_name(filename: str, names_map: dict) -> str:
    """Nome visivo per uno stemma: da badges_names.json (testo sull'immagine) o filename pulito."""
    if filename in names_map:
        return names_map[filename]
    name = os.path.splitext(filename)[0]
    name = name.replace("_", " ").replace("-", " ").strip()
    return name.title() if name else filename


@app.get("/api/team-badges")
async def get_team_badges():
    """Lista stemmi per le squadre fantasy: { url, name } (name = nome visivo da badges_names.json)."""
    import json
    base = Path(__file__).resolve().parent.parent
    badges_dir = base / "static" / "media" / "team_badges"
    names_map = {}
    map_file = badges_dir / "badges_names.json"
    if map_file.exists():
        try:
            with open(map_file, encoding="utf-8") as f:
                names_map = json.load(f)
        except Exception:
            pass
    if not badges_dir.is_dir():
        return {"badges": []}
    files = sorted(
        f for f in os.listdir(badges_dir)
        if f.lower().endswith((".png", ".jpg", ".jpeg", ".webp"))
    )
    badges = [
        {
            "url": f"/static/media/team_badges/{f}",
            "name": _badge_display_name(f, names_map),
        }
        for f in files
    ]
    return {"badges": badges}


@app.get("/api/coach-avatars")
async def get_coach_avatars():
    """Lista avatar allenatore 3D (solo file in static/media/fanta_allenatori/, esclusi source/ e nascosti)."""
    base = Path(__file__).resolve().parent.parent
    avatar_dir = base / "static" / "media" / "fanta_allenatori"
    if not avatar_dir.is_dir():
        return {"avatars": []}
    files = sorted(
        f
        for f in os.listdir(avatar_dir)
        if not f.startswith(".")
        and (avatar_dir / f).is_file()
        and f.lower().endswith((".png", ".jpg", ".jpeg", ".webp"))
    )
    avatars = [
        {
            "url": f"/static/media/fanta_allenatori/{f}",
            "name": os.path.splitext(f)[0].replace("_", " ").replace("-", " ").strip().title(),
        }
        for f in files
    ]
    return {"avatars": avatars}

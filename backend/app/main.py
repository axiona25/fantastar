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

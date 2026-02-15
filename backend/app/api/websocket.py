"""
WebSocket: canali per asta, live punteggi lega e eventi partita.
- ws/auction/{league_id}: offerte asta in tempo reale
- ws/live/{league_id}: punteggi fantasy in tempo reale (partite in corso)
- ws/match/{match_id}: eventi partita (gol, cartellini) in tempo reale
"""
import json
from typing import Any
from uuid import UUID

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.models.league import FantasyLeague
from app.models.match import Match


class ConnectionManager:
    """Gestione connessioni WebSocket per canale (es. auction per league_id)."""
    def __init__(self):
        self.active_connections: dict[str, list[WebSocket]] = {}

    async def connect(self, channel: str, websocket: WebSocket) -> None:
        await websocket.accept()
        if channel not in self.active_connections:
            self.active_connections[channel] = []
        self.active_connections[channel].append(websocket)

    def disconnect(self, channel: str, websocket: WebSocket) -> None:
        if channel in self.active_connections:
            try:
                self.active_connections[channel].remove(websocket)
            except ValueError:
                pass
            if not self.active_connections[channel]:
                del self.active_connections[channel]

    async def broadcast(self, channel: str, data: dict[str, Any]) -> None:
        if channel not in self.active_connections:
            return
        payload = json.dumps(data, default=str)
        dead = []
        for ws in self.active_connections[channel]:
            try:
                await ws.send_text(payload)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(channel, ws)


# Singleton per canale asta
auction_connection_manager = ConnectionManager()
# Singleton per canale live punteggi lega
live_connection_manager = ConnectionManager()
# Singleton per canale eventi partita
match_connection_manager = ConnectionManager()


def auction_channel(league_id: UUID) -> str:
    return f"auction:{league_id}"


def live_channel(league_id: UUID) -> str:
    return f"live:{league_id}"


def match_channel(match_id: int) -> str:
    return f"match:{match_id}"


async def broadcast_auction_update(league_id: UUID, event: str, payload: dict) -> None:
    """Chiamato dopo start/bid/assign per notificare i client WS."""
    await auction_connection_manager.broadcast(
        auction_channel(league_id),
        {"event": event, **payload},
    )


async def broadcast_live_update(league_id: UUID, payload: dict) -> None:
    """Broadcast aggiornamenti punteggi fantasy in tempo reale (partite in corso)."""
    await live_connection_manager.broadcast(live_channel(league_id), payload)


async def broadcast_match_update(match_id: int, payload: dict) -> None:
    """Broadcast eventi partita (gol, cartellini, score) in tempo reale."""
    await match_connection_manager.broadcast(match_channel(match_id), payload)


router = APIRouter(prefix="/ws", tags=["websocket"])


@router.websocket("/auction/{league_id}")
async def websocket_auction(websocket: WebSocket, league_id: UUID):
    """
    Canale asta: ricevi aggiornamenti in tempo reale (asta avviata, nuova offerta, assegnato).
    Query: ?token=JWT (opzionale; senza token la connessione è accettata ma si può limitare in futuro).
    """
    channel = auction_channel(league_id)
    await auction_connection_manager.connect(channel, websocket)
    try:
        # Verifica che la lega esista (opzionale)
        async with AsyncSessionLocal() as db:
            r = await db.execute(select(FantasyLeague.id).where(FantasyLeague.id == league_id))
            if not r.scalar_one_or_none():
                await websocket.close(code=4000)
                return
        while True:
            data = await websocket.receive_text()
            # Il client può inviare ping o richiesta stato; rispondiamo con ok o stato corrente
            try:
                msg = json.loads(data) if data else {}
                if msg.get("type") == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))
            except Exception:
                pass
    except WebSocketDisconnect:
        pass
    finally:
        auction_connection_manager.disconnect(channel, websocket)


@router.websocket("/live/{league_id}")
async def websocket_live(websocket: WebSocket, league_id: UUID):
    """
    Canale live: ricevi aggiornamenti punteggi fantasy in tempo reale per la lega.
    Quando partite in corso vengono aggiornate (eventi, score), il server ricalcola
    i punteggi e invia live_scores con risultati giornata e/o classifica.
    """
    channel = live_channel(league_id)
    await live_connection_manager.connect(channel, websocket)
    try:
        async with AsyncSessionLocal() as db:
            r = await db.execute(select(FantasyLeague.id).where(FantasyLeague.id == league_id))
            if not r.scalar_one_or_none():
                await websocket.close(code=4000)
                return
        while True:
            data = await websocket.receive_text()
            try:
                msg = json.loads(data) if data else {}
                if msg.get("type") == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))
            except Exception:
                pass
    except WebSocketDisconnect:
        pass
    finally:
        live_connection_manager.disconnect(channel, websocket)


@router.websocket("/match/{match_id}")
async def websocket_match(websocket: WebSocket, match_id: int):
    """
    Canale partita: ricevi eventi partita (gol, cartellini) e aggiornamento score in tempo reale.
    """
    channel = match_channel(match_id)
    await match_connection_manager.connect(channel, websocket)
    try:
        async with AsyncSessionLocal() as db:
            r = await db.execute(select(Match.id).where(Match.id == match_id))
            if not r.scalar_one_or_none():
                await websocket.close(code=4000)
                return
        while True:
            data = await websocket.receive_text()
            try:
                msg = json.loads(data) if data else {}
                if msg.get("type") == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))
            except Exception:
                pass
    except WebSocketDisconnect:
        pass
    finally:
        match_connection_manager.disconnect(channel, websocket)

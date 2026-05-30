import asyncio
from contextlib import asynccontextmanager
from collections.abc import AsyncGenerator

from fastapi import FastAPI
from fastapi import WebSocket
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.core.middleware import RequestLoggingMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None]:
    from app.db.database import engine
    from app.redis.client import redis_pool
    from app.ws.manager import manager

    await redis_pool.initialize()
    pubsub_task = asyncio.create_task(manager.run_pubsub_listener())
    yield
    pubsub_task.cancel()
    try:
        await pubsub_task
    except asyncio.CancelledError:
        pass
    await redis_pool.close()
    await engine.dispose()


app = FastAPI(
    title="InGame API",
    version="0.1.0",
    docs_url="/api/v1/docs",
    openapi_url="/api/v1/openapi.json",
    lifespan=lifespan,
)

app.add_middleware(RequestLoggingMiddleware)

_cors_origins: list[str] = settings.cors_origins
if settings.debug or settings.cors_allow_all:
    _cors_origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.api.v1.router import v1_router  # noqa: E402
from app.ws.handlers import websocket_endpoint  # noqa: E402

app.include_router(v1_router, prefix="/api/v1")


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.websocket("/api/v1/ws")
async def ws_endpoint_v1(websocket: WebSocket, token: str | None = None):
    await websocket_endpoint(websocket, token)


@app.websocket("/ws")
async def ws_endpoint_legacy(websocket: WebSocket, token: str | None = None):
    await websocket_endpoint(websocket, token)

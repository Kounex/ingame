import asyncio
import logging
from contextlib import asynccontextmanager
from collections.abc import AsyncGenerator

from fastapi import FastAPI, Request, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings
from app.core.exceptions import AppHTTPException
from app.core.middleware import RequestLoggingMiddleware

logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None]:
    from app.db.database import engine
    from app.jobs.avatar_upload_janitor import run_avatar_upload_janitor_loop
    from app.jobs.stale_token_janitor import run_stale_token_janitor_loop
    from app.notifications.fcm import initialize_firebase
    from app.redis.client import redis_pool
    from app.ws.manager import manager

    await redis_pool.initialize()
    initialize_firebase()
    pubsub_task = asyncio.create_task(manager.run_pubsub_listener())
    avatar_upload_janitor_task = asyncio.create_task(run_avatar_upload_janitor_loop())
    stale_token_janitor_task = asyncio.create_task(run_stale_token_janitor_loop())
    yield
    stale_token_janitor_task.cancel()
    try:
        await stale_token_janitor_task
    except asyncio.CancelledError:
        pass
    avatar_upload_janitor_task.cancel()
    try:
        await avatar_upload_janitor_task
    except asyncio.CancelledError:
        pass
    pubsub_task.cancel()
    try:
        await pubsub_task
    except asyncio.CancelledError:
        pass
    await redis_pool.close()
    await engine.dispose()


app = FastAPI(
    title="InGame API",
    version="0.7.8",
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


@app.exception_handler(AppHTTPException)
async def handle_app_http_exception(_: Request, exc: AppHTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail, "code": exc.code.value},
        headers=exc.headers,
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

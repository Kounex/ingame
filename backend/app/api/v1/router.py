from fastapi import APIRouter

from app.api.v1.auth.routes import router as auth_router
from app.api.v1.coordination.routes import router as coordination_router
from app.api.v1.groups.routes import router as groups_router
from app.api.v1.join_requests.routes import router as join_requests_router
from app.api.v1.notifications.routes import router as notifications_router
from app.api.v1.users.routes import router as users_router

v1_router = APIRouter()


@v1_router.get("/health")
async def health_check() -> dict[str, str]:
    return {"status": "ok"}


v1_router.include_router(auth_router)
v1_router.include_router(users_router)
v1_router.include_router(groups_router)
v1_router.include_router(coordination_router)
v1_router.include_router(join_requests_router)
v1_router.include_router(notifications_router)

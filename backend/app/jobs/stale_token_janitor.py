import asyncio
import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.db.database import async_session_factory
from app.db.repositories.device_registration_repo import DeviceRegistrationRepository

logger = logging.getLogger(__name__)
_STALE_TOKEN_POLL_INTERVAL_SECONDS = 24 * 60 * 60
_STALE_TOKEN_CUTOFF_DAYS = 60


async def run_stale_token_janitor_once(db: AsyncSession) -> int:
    cutoff = datetime.now(timezone.utc) - timedelta(days=_STALE_TOKEN_CUTOFF_DAYS)
    repo = DeviceRegistrationRepository(db)
    stale = await repo.list_stale(cutoff)
    revoked_count = 0

    for registration in stale:
        try:
            await repo.revoke(registration.id)
            revoked_count += 1
        except Exception:
            logger.exception("Failed to revoke stale token %s", registration.id)

    if revoked_count > 0:
        logger.info("Stale token janitor revoked %d tokens", revoked_count)

    return revoked_count


async def run_stale_token_janitor_loop(
    session_factory: async_sessionmaker[AsyncSession] = async_session_factory,
) -> None:
    while True:
        try:
            async with session_factory() as session:
                await run_stale_token_janitor_once(session)
                await session.commit()
        except asyncio.CancelledError:
            raise
        except Exception:
            logger.exception("Stale token janitor loop failed")

        await asyncio.sleep(_STALE_TOKEN_POLL_INTERVAL_SECONDS)

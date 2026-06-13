import asyncio
import logging

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.api.v1.users.service import avatar_upload_unclaimed_cutoff
from app.db.database import async_session_factory
from app.db.repositories.avatar_upload_ledger_repo import AvatarUploadLedgerRepository
from app.storage.avatar_uploads import delete_avatar_object_by_key

logger = logging.getLogger(__name__)
_AVATAR_UPLOAD_JANITOR_POLL_INTERVAL_SECONDS = 60 * 60


async def run_avatar_upload_janitor_once(db: AsyncSession) -> int:
    repo = AvatarUploadLedgerRepository(db)
    expired_uploads = await repo.list_expired_pending(
        created_before=avatar_upload_unclaimed_cutoff()
    )
    deleted_count = 0

    for record in expired_uploads:
        current = await repo.get_by_id(record.id)
        if current is None or current.committed_at is not None:
            continue

        try:
            delete_avatar_object_by_key(current.object_key)
            await repo.delete(current.id)
            await db.commit()
            deleted_count += 1
        except Exception:
            await db.rollback()
            logger.exception("Avatar upload janitor failed")

    return deleted_count


async def run_avatar_upload_janitor_loop(
    session_factory: async_sessionmaker[AsyncSession] = async_session_factory,
) -> None:
    while True:
        try:
            async with session_factory() as session:
                await run_avatar_upload_janitor_once(session)
        except asyncio.CancelledError:
            raise
        except Exception:
            logger.exception("Avatar upload janitor loop failed")

        await asyncio.sleep(_AVATAR_UPLOAD_JANITOR_POLL_INTERVAL_SECONDS)

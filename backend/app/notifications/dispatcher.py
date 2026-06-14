import asyncio
import logging
import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import async_session_factory
from app.db.repositories.device_registration_repo import DeviceRegistrationRepository
from app.db.repositories.group_repo import GroupRepository
from app.db.repositories.notification_preference_repo import NotificationPreferenceRepository
from app.db.repositories.user_repo import UserRepository
from app.notifications.copy import build_notification_copy
from app.notifications.evaluator import should_notify
from app.notifications.fcm import InvalidTokenError, send_push

logger = logging.getLogger(__name__)


def enqueue_notification(
    *,
    event_type: str,
    group_id: uuid.UUID,
    actor_user_id: uuid.UUID,
    payload: dict,
) -> None:
    asyncio.create_task(
        _dispatch_with_own_session(
            event_type=event_type,
            group_id=group_id,
            actor_user_id=actor_user_id,
            payload=payload,
        )
    )


async def _dispatch_with_own_session(
    *,
    event_type: str,
    group_id: uuid.UUID,
    actor_user_id: uuid.UUID,
    payload: dict,
) -> None:
    try:
        async with async_session_factory() as db:
            await dispatch_notification(
                db=db,
                event_type=event_type,
                group_id=group_id,
                actor_user_id=actor_user_id,
                payload=payload,
            )
    except Exception:
        logger.exception("Notification dispatch failed for %s in group %s", event_type, group_id)


async def dispatch_notification(
    *,
    db: AsyncSession,
    event_type: str,
    group_id: uuid.UUID,
    actor_user_id: uuid.UUID,
    payload: dict,
) -> None:
    group_repo = GroupRepository(db)
    user_repo = UserRepository(db)
    device_repo = DeviceRegistrationRepository(db)
    pref_repo = NotificationPreferenceRepository(db)

    group = await group_repo.get_by_id(group_id)
    if group is None:
        return

    actor = await user_repo.get_by_id(actor_user_id)
    actor_name = actor.display_name if actor else "Someone"

    members = await group_repo.list_members(group_id)

    for membership in members:
        member_user_id = membership.user_id

        context = {
            "user_role": membership.role,
        }
        if "user_rsvps" in payload and str(member_user_id) in payload["user_rsvps"]:
            context["user_rsvp"] = payload["user_rsvps"][str(member_user_id)]
        if "positive_rsvp_count" in payload:
            context["positive_rsvp_count"] = payload["positive_rsvp_count"]

        pref = await pref_repo.get_for_user_event(member_user_id, event_type)
        preference_enabled = pref.enabled if pref is not None else True
        conditions = pref.conditions if pref is not None else None

        group_pref = await pref_repo.get_group_preference(member_user_id, group_id)
        group_muted = group_pref is not None and not group_pref.enabled

        quiet_hours = None
        if pref is not None and pref.quiet_hours_start is not None and pref.quiet_hours_end is not None:
            quiet_hours = {
                "start": pref.quiet_hours_start,
                "end": pref.quiet_hours_end,
                "tz": pref.quiet_hours_tz or "UTC",
            }

        if not should_notify(
            user_id=member_user_id,
            actor_user_id=actor_user_id,
            event_type=event_type,
            preference_enabled=preference_enabled,
            group_muted=group_muted,
            conditions=conditions,
            context=context,
            quiet_hours=quiet_hours,
        ):
            continue

        title, body = build_notification_copy(
            event_type=event_type,
            actor_name=actor_name,
            group_name=group.name,
            session_title=payload.get("session_title"),
            game=payload.get("game"),
            formatted_time=payload.get("formatted_time"),
            rsvp_response=payload.get("rsvp_response"),
        )

        devices = await device_repo.list_active_for_user(member_user_id)
        for device in devices:
            try:
                await send_push(
                    token=device.token,
                    title=title,
                    body=body,
                    data={
                        "event_type": event_type,
                        "group_id": str(group_id),
                        "deep_link": f"/groups/{group_id}/coordination",
                    },
                )
            except InvalidTokenError:
                await device_repo.revoke_by_token(member_user_id, device.token)
                logger.info("Revoked invalid token for user %s", member_user_id)

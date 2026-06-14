import json
import logging

from app.config import settings

logger = logging.getLogger(__name__)

_firebase_app = None


def initialize_firebase() -> None:
    global _firebase_app

    if not settings.notifications_enabled:
        logger.info("Notifications disabled, skipping Firebase init")
        return

    sa_json = settings.firebase_service_account_json
    if not sa_json:
        logger.warning(
            "INGAME_FIREBASE_SERVICE_ACCOUNT_JSON not set, push notifications unavailable"
        )
        return

    try:
        import firebase_admin
        from firebase_admin import credentials

        cred_dict = json.loads(sa_json)
        cred = credentials.Certificate(cred_dict)
        _firebase_app = firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin SDK initialized")
    except Exception:
        logger.exception("Failed to initialize Firebase Admin SDK")


async def send_push(
    *,
    token: str,
    title: str,
    body: str,
    data: dict[str, str] | None = None,
) -> bool:
    if not settings.notifications_enabled:
        return False

    if settings.notifications_dry_run:
        logger.info("DRY RUN push → %s: %s / %s", token[:20], title, body)
        return True

    if _firebase_app is None:
        logger.debug("Firebase not initialized, skipping push")
        return False

    try:
        from firebase_admin import messaging

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data=data or {},
            token=token,
        )
        messaging.send(message)
        return True
    except Exception as exc:
        if is_token_invalid_error(exc):
            logger.info("FCM token invalid (%s), revoking: %s", getattr(exc, "code", None), token[:20])
            raise InvalidTokenError(token) from exc
        logger.exception("FCM send failed for token %s", token[:20])
        return False


class InvalidTokenError(Exception):
    def __init__(self, token: str) -> None:
        self.token = token


def is_token_invalid_error(exc: Exception) -> bool:
    error_code = getattr(exc, "code", None)
    return error_code in ("NOT_FOUND", "UNREGISTERED", "INVALID_ARGUMENT")

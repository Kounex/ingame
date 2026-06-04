import uuid
from urllib.parse import urlsplit, urlunsplit

from app.config import settings
from app.core.error_codes import ErrorCode
from app.core.exceptions import ServiceUnavailableError

ALLOWED_AVATAR_CONTENT_TYPES = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
}


def _avatar_upload_client():
    try:
        import boto3
    except ImportError as exc:
        raise ServiceUnavailableError(
            "Avatar uploads are temporarily unavailable",
            code=ErrorCode.USER_AVATAR_UPLOAD_UNAVAILABLE,
        ) from exc

    try:
        return boto3.client(
            "s3",
            region_name=settings.avatar_storage_region,
            endpoint_url=settings.avatar_storage_endpoint_url or None,
            aws_access_key_id=settings.avatar_storage_access_key_id or None,
            aws_secret_access_key=settings.avatar_storage_secret_access_key or None,
        )
    except Exception as exc:
        raise ServiceUnavailableError(
            "Avatar uploads are temporarily unavailable",
            code=ErrorCode.USER_AVATAR_UPLOAD_UNAVAILABLE,
        ) from exc


def _resolve_upload_url(presigned_url: str) -> str:
    upload_base_url = settings.avatar_storage_upload_base_url.strip()
    if not upload_base_url:
        return presigned_url

    base_parts = urlsplit(upload_base_url)
    if not base_parts.scheme or not base_parts.netloc:
        raise ServiceUnavailableError(
            "Avatar uploads are temporarily unavailable",
            code=ErrorCode.USER_AVATAR_UPLOAD_UNAVAILABLE,
        )

    presigned_parts = urlsplit(presigned_url)
    base_path = base_parts.path.rstrip("/")
    upload_path = f"{base_path}{presigned_parts.path}" if base_path else presigned_parts.path

    return urlunsplit(
        (
            base_parts.scheme,
            base_parts.netloc,
            upload_path,
            presigned_parts.query,
            presigned_parts.fragment,
        )
    )


def generate_avatar_upload(
    *,
    user_id: uuid.UUID,
    content_type: str,
) -> dict[str, object]:
    if (
        not settings.avatar_storage_bucket
        or not settings.avatar_storage_public_base_url
    ):
        raise ServiceUnavailableError(
            "Avatar uploads are not configured",
            code=ErrorCode.USER_AVATAR_UPLOAD_UNAVAILABLE,
        )

    extension = ALLOWED_AVATAR_CONTENT_TYPES[content_type]
    object_key = f"users/{user_id}/avatars/{uuid.uuid4()}.{extension}"
    try:
        presigned = _avatar_upload_client().generate_presigned_post(
            Bucket=settings.avatar_storage_bucket,
            Key=object_key,
            Fields={
                "Content-Type": content_type,
                "success_action_status": "201",
            },
            Conditions=[
                {"Content-Type": content_type},
                {"success_action_status": "201"},
                ["content-length-range", 1, settings.avatar_upload_max_file_size_bytes],
            ],
            ExpiresIn=settings.avatar_upload_presign_expires_seconds,
        )
    except ServiceUnavailableError:
        raise
    except Exception as exc:
        raise ServiceUnavailableError(
            "Avatar uploads are temporarily unavailable",
            code=ErrorCode.USER_AVATAR_UPLOAD_UNAVAILABLE,
        ) from exc

    public_base_url = settings.avatar_storage_public_base_url.rstrip("/")
    return {
        "upload_url": _resolve_upload_url(presigned["url"]),
        "upload_fields": presigned["fields"],
        "object_key": object_key,
        "avatar_url": f"{public_base_url}/{object_key}",
        "expires_in_seconds": settings.avatar_upload_presign_expires_seconds,
        "max_file_size_bytes": settings.avatar_upload_max_file_size_bytes,
        "allowed_content_types": list(ALLOWED_AVATAR_CONTENT_TYPES.keys()),
    }

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


def managed_avatar_object_key_from_public_url(avatar_url: str | None) -> str | None:
    if not avatar_url:
        return None

    public_base_url = settings.avatar_storage_public_base_url.strip().rstrip("/")
    if not public_base_url:
        return None

    base_parts = urlsplit(public_base_url)
    avatar_parts = urlsplit(avatar_url)
    if (
        not base_parts.scheme
        or not base_parts.netloc
        or (avatar_parts.scheme, avatar_parts.netloc)
        != (base_parts.scheme, base_parts.netloc)
        or avatar_parts.query
        or avatar_parts.fragment
    ):
        return None

    base_path = base_parts.path.rstrip("/")
    path_prefix = f"{base_path}/" if base_path else "/"
    if not avatar_parts.path.startswith(path_prefix):
        return None

    object_key = avatar_parts.path.removeprefix(path_prefix).lstrip("/")
    return object_key or None


def avatar_object_prefix(*, user_id: uuid.UUID) -> str:
    return f"users/{user_id}/avatars/"


def delete_avatar_object_by_key(object_key: str | None) -> None:
    if object_key is None or not settings.avatar_storage_bucket:
        return

    try:
        _avatar_upload_client().delete_object(
            Bucket=settings.avatar_storage_bucket,
            Key=object_key,
        )
    except ServiceUnavailableError:
        raise
    except Exception as exc:
        raise ServiceUnavailableError(
            "Avatar uploads are temporarily unavailable",
            code=ErrorCode.USER_AVATAR_UPLOAD_UNAVAILABLE,
        ) from exc


def delete_avatar_object_by_public_url(avatar_url: str | None) -> None:
    delete_avatar_object_by_key(managed_avatar_object_key_from_public_url(avatar_url))


def sweep_user_avatar_prefix(user_id: uuid.UUID, keep_avatar_url: str | None) -> None:
    if (
        not settings.avatar_storage_bucket
        or not settings.avatar_storage_public_base_url
    ):
        return

    keep_object_key = managed_avatar_object_key_from_public_url(keep_avatar_url)
    client = _avatar_upload_client()
    prefix = avatar_object_prefix(user_id=user_id)
    stale_keys: list[str] = []
    continuation_token: str | None = None

    try:
        while True:
            request: dict[str, object] = {
                "Bucket": settings.avatar_storage_bucket,
                "Prefix": prefix,
            }
            if continuation_token:
                request["ContinuationToken"] = continuation_token

            response = client.list_objects_v2(**request)
            for item in response.get("Contents", []):
                key = item.get("Key")
                if isinstance(key, str) and key != keep_object_key:
                    stale_keys.append(key)

            if not response.get("IsTruncated"):
                break
            continuation_token = response.get("NextContinuationToken")
            if not continuation_token:
                break

        if not stale_keys:
            return

        client.delete_objects(
            Bucket=settings.avatar_storage_bucket,
            Delete={"Objects": [{"Key": key} for key in stale_keys]},
        )
    except ServiceUnavailableError:
        raise
    except Exception as exc:
        raise ServiceUnavailableError(
            "Avatar uploads are temporarily unavailable",
            code=ErrorCode.USER_AVATAR_UPLOAD_UNAVAILABLE,
        ) from exc


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
    object_key = f"{avatar_object_prefix(user_id=user_id)}{uuid.uuid4()}.{extension}"
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

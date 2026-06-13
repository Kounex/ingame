from types import SimpleNamespace
from unittest.mock import MagicMock, patch
from uuid import uuid4

from app.storage import avatar_uploads


def _settings_stub(
    *,
    bucket: str = "ingame-avatars",
    public_base_url: str = "https://cdn.test/ingame-avatars",
):
    return SimpleNamespace(
        avatar_storage_bucket=bucket,
        avatar_storage_public_base_url=public_base_url,
    )


def test_sweep_user_avatar_prefix_deletes_stale_siblings_only():
    sweep = getattr(avatar_uploads, "sweep_user_avatar_prefix", None)
    assert callable(sweep)

    user_id = uuid4()
    prefix = f"users/{user_id}/avatars/"
    keep_key = f"{prefix}keep.webp"
    stale_key = f"{prefix}stale.webp"
    client = MagicMock()
    client.list_objects_v2.return_value = {
        "Contents": [{"Key": stale_key}, {"Key": keep_key}],
    }

    with (
        patch("app.storage.avatar_uploads.settings", _settings_stub()),
        patch("app.storage.avatar_uploads._avatar_upload_client", return_value=client),
    ):
        sweep(user_id, f"https://cdn.test/ingame-avatars/{keep_key}")

    client.delete_objects.assert_called_once_with(
        Bucket="ingame-avatars",
        Delete={"Objects": [{"Key": stale_key}]},
    )


def test_sweep_user_avatar_prefix_deletes_all_when_keep_avatar_missing():
    sweep = getattr(avatar_uploads, "sweep_user_avatar_prefix", None)
    assert callable(sweep)

    user_id = uuid4()
    prefix = f"users/{user_id}/avatars/"
    first_key = f"{prefix}first.webp"
    second_key = f"{prefix}second.webp"
    client = MagicMock()
    client.list_objects_v2.return_value = {
        "Contents": [{"Key": first_key}, {"Key": second_key}],
    }

    with (
        patch("app.storage.avatar_uploads.settings", _settings_stub()),
        patch("app.storage.avatar_uploads._avatar_upload_client", return_value=client),
    ):
        sweep(user_id, None)

    client.delete_objects.assert_called_once_with(
        Bucket="ingame-avatars",
        Delete={"Objects": [{"Key": first_key}, {"Key": second_key}]},
    )


def test_sweep_user_avatar_prefix_noops_when_prefix_has_no_objects():
    sweep = getattr(avatar_uploads, "sweep_user_avatar_prefix", None)
    assert callable(sweep)

    client = MagicMock()
    client.list_objects_v2.return_value = {}

    with (
        patch("app.storage.avatar_uploads.settings", _settings_stub()),
        patch("app.storage.avatar_uploads._avatar_upload_client", return_value=client),
    ):
        sweep(uuid4(), None)

    client.delete_objects.assert_not_called()


def test_sweep_user_avatar_prefix_noops_without_storage_config():
    sweep = getattr(avatar_uploads, "sweep_user_avatar_prefix", None)
    assert callable(sweep)

    client = MagicMock()

    with (
        patch(
            "app.storage.avatar_uploads.settings",
            _settings_stub(bucket="", public_base_url=""),
        ),
        patch("app.storage.avatar_uploads._avatar_upload_client", return_value=client),
    ):
        sweep(uuid4(), None)

    client.list_objects_v2.assert_not_called()
    client.delete_objects.assert_not_called()


def test_delete_avatar_object_by_key_deletes_object_when_configured():
    delete_by_key = getattr(avatar_uploads, "delete_avatar_object_by_key", None)
    assert callable(delete_by_key)

    client = MagicMock()

    with (
        patch("app.storage.avatar_uploads.settings", _settings_stub()),
        patch("app.storage.avatar_uploads._avatar_upload_client", return_value=client),
    ):
        delete_by_key("users/test/avatars/avatar.webp")

    client.delete_object.assert_called_once_with(
        Bucket="ingame-avatars",
        Key="users/test/avatars/avatar.webp",
    )


def test_delete_avatar_object_by_key_noops_without_storage_bucket():
    delete_by_key = getattr(avatar_uploads, "delete_avatar_object_by_key", None)
    assert callable(delete_by_key)

    client = MagicMock()

    with (
        patch(
            "app.storage.avatar_uploads.settings",
            _settings_stub(bucket="", public_base_url=""),
        ),
        patch("app.storage.avatar_uploads._avatar_upload_client", return_value=client),
    ):
        delete_by_key("users/test/avatars/avatar.webp")

    client.delete_object.assert_not_called()

from app.core.provider_identity import capabilities_for_provider
from app.db.models.provider_identity import ProviderIdentity
from app.db.models.user import User
from app.db.repositories.provider_identity_repo import ProviderIdentityRepository
from app.db.repositories.user_repo import UserRepository
from sqlalchemy.ext.asyncio import AsyncSession


def _serialize_identity(identity: ProviderIdentity) -> dict[str, object | None]:
    capabilities = capabilities_for_provider(identity.provider)
    return {
        "provider": identity.provider,
        "auth_mode": identity.auth_mode,
        "external_id": identity.external_id,
        "username": identity.username,
        "display_name": identity.display_name,
        "email": identity.email,
        "avatar_url": identity.avatar_url,
        "profile_url": identity.profile_url,
        "metadata": identity.metadata_json,
        "last_synced_at": identity.last_synced_at,
        **capabilities,
    }


async def build_user_response(
    db: AsyncSession,
    user: User,
) -> dict[str, object | None]:
    identity_repo = ProviderIdentityRepository(db)
    identities = await identity_repo.list_for_user(user.id)

    steam_identity = next(
        (identity for identity in identities if identity.provider == "steam"),
        None,
    )
    apple_identity = next(
        (identity for identity in identities if identity.provider == "apple"),
        None,
    )

    return {
        "id": user.id,
        "email": user.email,
        "display_name": user.display_name,
        "has_password_login": user.has_password_login,
        "avatar_url": user.avatar_url,
        "bio": user.bio,
        "timezone": user.timezone,
        "preferred_gaming_hours": user.preferred_gaming_hours,
        "steam_id": steam_identity.external_id if steam_identity else user.steam_id,
        "apple_id": apple_identity.external_id if apple_identity else user.apple_id,
        "provider_identities": [_serialize_identity(identity) for identity in identities],
        "created_at": user.created_at,
        "updated_at": user.updated_at,
    }


async def build_auth_response(
    db: AsyncSession,
    *,
    access_token: str,
    refresh_token: str,
    user: User,
) -> dict[str, object]:
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "user": await build_user_response(db, user),
    }


async def sync_legacy_provider_identities(db: AsyncSession, user: User) -> None:
    identity_repo = ProviderIdentityRepository(db)
    user_repo = UserRepository(db)

    if user.steam_id and await identity_repo.get_for_user(user.id, "steam") is None:
        await identity_repo.upsert(
            user_id=user.id,
            provider="steam",
            auth_mode="official_openid",
            external_id=user.steam_id,
            display_name=user.display_name,
            avatar_url=user.avatar_url,
        )

    if user.apple_id and await identity_repo.get_for_user(user.id, "apple") is None:
        await identity_repo.upsert(
            user_id=user.id,
            provider="apple",
            auth_mode="official_oauth",
            external_id=user.apple_id,
            email=user.email,
        )

    if user.steam_id or user.apple_id:
        await user_repo.update(user.id, steam_id=user.steam_id, apple_id=user.apple_id)

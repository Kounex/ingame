from collections.abc import Mapping

AUTH_PROVIDER_KEYS = frozenset({"steam", "discord", "apple"})
MANUAL_PROVIDER_KEYS = frozenset({"xbox", "playstation", "nintendo"})

PROVIDER_CAPABILITIES: dict[str, dict[str, bool]] = {
    "steam": {
        "supports_login": True,
        "supports_refresh": True,
        "supports_direct_profile_link": True,
        "supports_manual_entry": False,
        "supports_copy_only_action": False,
        "is_social_identity": True,
    },
    "discord": {
        "supports_login": True,
        "supports_refresh": True,
        "supports_direct_profile_link": True,
        "supports_manual_entry": False,
        "supports_copy_only_action": False,
        "is_social_identity": True,
    },
    "apple": {
        "supports_login": True,
        "supports_refresh": False,
        "supports_direct_profile_link": False,
        "supports_manual_entry": False,
        "supports_copy_only_action": False,
        "is_social_identity": False,
    },
    "xbox": {
        "supports_login": False,
        "supports_refresh": False,
        "supports_direct_profile_link": True,
        "supports_manual_entry": True,
        "supports_copy_only_action": False,
        "is_social_identity": True,
    },
    "playstation": {
        "supports_login": False,
        "supports_refresh": False,
        "supports_direct_profile_link": True,
        "supports_manual_entry": True,
        "supports_copy_only_action": False,
        "is_social_identity": True,
    },
    "nintendo": {
        "supports_login": False,
        "supports_refresh": False,
        "supports_direct_profile_link": False,
        "supports_manual_entry": True,
        "supports_copy_only_action": True,
        "is_social_identity": True,
    },
}


def capabilities_for_provider(provider: str) -> Mapping[str, bool]:
    return PROVIDER_CAPABILITIES[provider]


def provider_supports_login(provider: str) -> bool:
    return PROVIDER_CAPABILITIES[provider]["supports_login"]

from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path


_MODULE_PATH = Path("scripts/ci/validate-api-contract.py")
_SPEC = spec_from_file_location("validate_api_contract", _MODULE_PATH)
_MODULE = module_from_spec(_SPEC)
assert _SPEC is not None and _SPEC.loader is not None
_SPEC.loader.exec_module(_MODULE)
extract_spec_model_columns = _MODULE.extract_spec_model_columns
load_spec_bundle = _MODULE.load_spec_bundle


def test_load_spec_bundle_includes_linked_child_specs_for_split_spec_set():
    spec_text = load_spec_bundle("docs/specs/2026-05-30-core-platform-design.md")

    assert "# InGame -- Core Platform Overview Spec" in spec_text
    assert "# InGame -- Core Platform Auth Spec" in spec_text
    assert "# InGame -- Core Platform Profiles Spec" in spec_text
    assert "# InGame -- Core Platform Groups Spec" in spec_text
    assert "# InGame -- Core Platform Implementation Spec" in spec_text


def test_extract_user_columns_from_split_specs_aggregates_user_contract():
    spec_text = load_spec_bundle("docs/specs/2026-05-30-core-platform-design.md")

    columns = extract_spec_model_columns(spec_text, "User")

    assert "id" in columns
    assert "has_password_login" in columns
    assert "display_name" in columns
    assert "avatar_url" in columns
    assert "provider" not in columns
    assert "external_id" not in columns
    assert "revoked_at" not in columns
    assert "email" in columns
    assert "steam_id" in columns


def test_extract_group_columns_ignores_overview_groups_heading_collision():
    spec_text = load_spec_bundle("docs/specs/2026-05-30-core-platform-design.md")

    columns = extract_spec_model_columns(spec_text, "Group")

    assert "id" in columns
    assert "name" in columns
    assert "invite_code" in columns
    assert "created_at" in columns
    assert "updated_at" in columns
    assert "Date" not in columns

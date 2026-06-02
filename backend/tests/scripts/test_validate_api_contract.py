from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path


_MODULE_PATH = Path("scripts/ci/validate-api-contract.py")
_SPEC = spec_from_file_location("validate_api_contract", _MODULE_PATH)
_MODULE = module_from_spec(_SPEC)
assert _SPEC is not None and _SPEC.loader is not None
_SPEC.loader.exec_module(_MODULE)
extract_spec_model_columns = _MODULE.extract_spec_model_columns


def test_extract_user_columns_stops_before_revoked_auth_link_table():
    spec_text = Path("docs/specs/2026-05-30-core-platform-design.md").read_text()

    columns = extract_spec_model_columns(spec_text, "User")

    assert "has_password_login" in columns
    assert "provider" not in columns
    assert "external_id" not in columns
    assert "revoked_at" not in columns
    assert "email" in columns
    assert "steam_id" in columns

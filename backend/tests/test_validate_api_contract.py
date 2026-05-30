from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path


SCRIPT_PATH = (
    Path(__file__).resolve().parents[2] / "scripts" / "ci" / "validate-api-contract.py"
)
SPEC = spec_from_file_location("validate_api_contract", SCRIPT_PATH)
validate_api_contract = module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(validate_api_contract)


def test_check_routes_accepts_root_health_endpoint_when_spec_documents_it():
    openapi = {
        "paths": {
            "/health": {
                "get": {
                    "summary": "Health check",
                }
            }
        }
    }
    spec_text = """
## Backend Architecture

Health endpoint: GET /health returns {"status": "ok"} for deployment probes.
"""

    errors = validate_api_contract.check_routes(openapi, spec_text)

    assert errors == []

#!/usr/bin/env python3
"""Validate the live OpenAPI spec against the design spec.

Checks:
  1. All OpenAPI routes belong to documented feature modules
  2. Response schema fields for key models match the spec's data model columns

Usage:
  python scripts/ci/validate-api-contract.py [--api-url URL] [--spec PATH]

Requires the API to be running (locally or in CI).
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.request

SPEC_MODEL_HEADERS = [
    "**User**",
    "**RevokedAuthLink**",
    "**Group**",
    "**GroupMembership**",
    "**JoinRequest**",
]

OPENAPI_TO_SPEC_MODEL = {
    "UserResponse": "User",
    "GroupResponse": "Group",
    "GroupMemberResponse": "GroupMembership",
    "JoinRequestResponse": "JoinRequest",
}

IGNORED_OPENAPI_FIELDS: dict[str, set[str]] = {
    "GroupMemberResponse": {"user_id", "display_name", "avatar_url"},
    "GroupResponse": {"member_count"},
    "JoinRequestResponse": {"user"},
}

IGNORED_SPEC_COLUMNS: dict[str, set[str]] = {
    "User": {"password_hash"},
    "GroupMembership": {"group_id", "user_id"},
    "JoinRequest": {"user_id"},
}

KNOWN_ROUTE_PREFIXES = {
    "/health",
    "/api/v1/health",
    "/api/v1/auth/",
    "/api/v1/users/",
    "/api/v1/groups/",
    "/api/v1/join-requests/",
}


def load_openapi(api_url: str) -> dict:
    url = f"{api_url}/openapi.json"
    try:
        with urllib.request.urlopen(url, timeout=10) as resp:
            return json.loads(resp.read())
    except Exception as e:
        print(f"FAIL: Could not fetch OpenAPI spec from {url}: {e}")
        sys.exit(2)


def load_spec(spec_path: str) -> str:
    with open(spec_path) as f:
        return f.read()


def extract_spec_model_columns(spec_text: str, model_name: str) -> set[str]:
    """Extract column names from a single model's table in the spec."""
    header = f"**{model_name}**"
    start = spec_text.find(header)
    if start == -1:
        return set()

    after_header = spec_text[start + len(header):]

    end = len(after_header)
    for other_header in SPEC_MODEL_HEADERS:
        if other_header == header:
            continue
        pos = after_header.find(other_header)
        if pos != -1 and pos < end:
            end = pos

    section_break = after_header.find("\n### ")
    if section_break != -1 and section_break < end:
        end = section_break

    hr_break = after_header.find("\n---")
    if hr_break != -1 and hr_break < end:
        end = hr_break

    table_text = after_header[:end]

    columns = set()
    row_pattern = re.compile(r"^\|\s*(\w+)\s*\|", re.MULTILINE)
    for match in row_pattern.finditer(table_text):
        col = match.group(1)
        if col.lower() not in ("column", "unique"):
            columns.add(col)

    return columns


def check_routes(openapi: dict, spec_text: str) -> list[str]:
    """Check that all OpenAPI routes belong to documented feature modules."""
    errors = []
    openapi_paths = set(openapi.get("paths", {}).keys())

    backend_section = spec_text[spec_text.find("## Backend Architecture"):]
    documented_modules = set()
    for module in ["auth", "users", "groups", "join_requests", "join-requests"]:
        if module in backend_section.lower():
            documented_modules.add(module.replace("_", "-"))

    for path in openapi_paths:
        if path in {"/health", "/api/v1/health"}:
            continue

        matched = False
        for prefix in KNOWN_ROUTE_PREFIXES:
            if path.startswith(prefix) or path == prefix.rstrip("/"):
                module = prefix.split("/")[3] if len(prefix.split("/")) > 3 else ""
                if module in documented_modules or module == "health":
                    matched = True
                    break

        if not matched:
            errors.append(
                f"Route '{path}' does not belong to any documented feature module"
            )

    return errors


def check_model_fields(openapi: dict, spec_text: str) -> list[str]:
    """Check that OpenAPI response schema fields align with spec data model columns."""
    errors = []
    schemas = openapi.get("components", {}).get("schemas", {})

    for openapi_schema, spec_model in OPENAPI_TO_SPEC_MODEL.items():
        schema = schemas.get(openapi_schema)
        if not schema:
            errors.append(f"Schema '{openapi_schema}' not found in OpenAPI spec")
            continue

        openapi_fields = set(schema.get("properties", {}).keys())
        ignored_api = IGNORED_OPENAPI_FIELDS.get(openapi_schema, set())
        openapi_fields -= ignored_api

        spec_columns = extract_spec_model_columns(spec_text, spec_model)
        ignored_spec = IGNORED_SPEC_COLUMNS.get(spec_model, set())
        spec_columns -= ignored_spec

        if not spec_columns:
            errors.append(f"Could not parse columns for spec model '{spec_model}'")
            continue

        in_api_not_spec = openapi_fields - spec_columns
        in_spec_not_api = spec_columns - openapi_fields

        for field in sorted(in_api_not_spec):
            errors.append(
                f"[{spec_model}] Field '{field}' in OpenAPI schema "
                f"'{openapi_schema}' but not in spec"
            )

        for col in sorted(in_spec_not_api):
            errors.append(
                f"[{spec_model}] Column '{col}' in spec but not in OpenAPI schema "
                f"'{openapi_schema}'"
            )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--api-url",
        default="http://localhost:8000/api/v1",
        help="Base URL of the API (default: http://localhost:8000/api/v1)",
    )
    parser.add_argument(
        "--spec",
        default="docs/specs/2026-05-30-core-platform-design.md",
        help="Path to the design spec markdown file",
    )
    args = parser.parse_args()

    print(f"Validating API contract...")
    print(f"  API: {args.api_url}")
    print(f"  Spec: {args.spec}")
    print()

    openapi = load_openapi(args.api_url)
    spec_text = load_spec(args.spec)

    all_errors: list[str] = []

    print("Check 1: Route ownership...")
    route_errors = check_routes(openapi, spec_text)
    all_errors.extend(route_errors)
    print(f"  {'FAIL' if route_errors else 'PASS'}: {len(route_errors)} issue(s)")

    print("Check 2: Model field alignment...")
    field_errors = check_model_fields(openapi, spec_text)
    all_errors.extend(field_errors)
    print(f"  {'FAIL' if field_errors else 'PASS'}: {len(field_errors)} issue(s)")

    print()

    if all_errors:
        print(f"FAILED with {len(all_errors)} issue(s):\n")
        for err in all_errors:
            print(f"  - {err}")
        print()
        print("Fix the code or update the spec, then re-run this check.")
        return 1

    print("ALL CHECKS PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())

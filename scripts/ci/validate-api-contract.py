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
from pathlib import Path

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
    "GroupResponse": {"member_count", "has_pending_join_request"},
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

MODEL_SECTION_HEADERS = {
    "User": (
        "**User**",
        "### User",
        "### User Table",
        "## Auth-Related User Fields",
    ),
    "RevokedAuthLink": ("**RevokedAuthLink**",),
    "Group": ("**Group**", "### Group"),
    "GroupMembership": ("**GroupMembership**", "### GroupMembership"),
    "JoinRequest": ("**JoinRequest**", "### JoinRequest"),
}

MODULE_KEYWORDS = {
    "auth": ("/api/v1/auth/", "auth flow", "auth failure contract"),
    "users": ("/api/v1/users/", "user profile", "profile editing"),
    "groups": ("/api/v1/groups/", "group detail", "discoverable groups"),
    "join-requests": ("/api/v1/join-requests/", "join request", "join requests"),
}

MARKDOWN_LINK_PATTERN = re.compile(r"\(([^)#]+\.md)\)")
TABLE_ROW_PATTERN = re.compile(r"^\|\s*`?([a-zA-Z_][\w]*)`?\s*\|")


def load_openapi(api_url: str) -> dict:
    url = f"{api_url}/openapi.json"
    try:
        with urllib.request.urlopen(url, timeout=10) as resp:
            return json.loads(resp.read())
    except Exception as e:
        print(f"FAIL: Could not fetch OpenAPI spec from {url}: {e}")
        sys.exit(2)


def load_spec_bundle(spec_path: str) -> str:
    root = Path(spec_path)
    root_text = root.read_text()
    texts = [root_text]
    seen_paths = {root.resolve()}

    for match in MARKDOWN_LINK_PATTERN.finditer(root_text):
        linked_path = root.parent / match.group(1)
        if not linked_path.exists():
            continue
        resolved = linked_path.resolve()
        if resolved in seen_paths:
            continue
        seen_paths.add(resolved)
        texts.append(linked_path.read_text())

    return "\n\n".join(texts)


def load_spec(spec_path: str) -> str:
    return load_spec_bundle(spec_path)


def _extract_first_table_columns_after_header(
    spec_text: str, header: str
) -> set[str]:
    all_lines = spec_text.splitlines()
    start_index = None
    for index, line in enumerate(all_lines):
        if line.strip() == header:
            start_index = index + 1
            break

    if start_index is None:
        return set()

    lines = all_lines[start_index:]
    columns = set()
    in_table = False

    for line in lines:
        stripped = line.strip()
        if not in_table:
            if not stripped.startswith("|"):
                continue
            in_table = True

        if not stripped.startswith("|"):
            break

        match = TABLE_ROW_PATTERN.match(stripped)
        if not match:
            continue

        column = match.group(1)
        if column.lower() in {"column", "field", "unique"}:
            continue
        columns.add(column)

    return columns


def infer_documented_modules(spec_text: str) -> set[str]:
    lower_text = spec_text.lower()
    backend_start = lower_text.find("## backend architecture")
    searchable_text = lower_text[backend_start:] if backend_start != -1 else lower_text

    documented_modules = set()
    for module, keywords in MODULE_KEYWORDS.items():
        if any(keyword in searchable_text for keyword in keywords):
            documented_modules.add(module)

    return documented_modules


def extract_spec_model_columns(spec_text: str, model_name: str) -> set[str]:
    """Extract column names from one or more model tables in the spec set."""
    headers = MODEL_SECTION_HEADERS.get(model_name, (f"**{model_name}**",))
    columns = set()
    for header in headers:
        columns.update(_extract_first_table_columns_after_header(spec_text, header))
    return columns


def check_routes(openapi: dict, spec_text: str) -> list[str]:
    """Check that all OpenAPI routes belong to documented feature modules."""
    errors = []
    openapi_paths = set(openapi.get("paths", {}).keys())
    documented_modules = infer_documented_modules(spec_text)

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

from __future__ import annotations

import argparse
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
PUBSPEC_PATH = REPO_ROOT / "pubspec.yaml"
BACKEND_MAIN_PATH = REPO_ROOT / "backend" / "app" / "main.py"
HELM_CHART_PATH = REPO_ROOT / "deploy" / "helm" / "ingame-api" / "Chart.yaml"
HELM_VALUES_PATH = REPO_ROOT / "deploy" / "helm" / "ingame-api" / "values.yaml"


def read_pubspec_semver(content: str) -> str:
    match = re.search(r"^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+\d+)?\s*$", content, re.M)
    if match is None:
        raise ValueError("Unable to find semver in pubspec.yaml")
    return match.group(1)


def normalize_release_tag(tag: str) -> str:
    match = re.fullmatch(r"v([0-9]+\.[0-9]+\.[0-9]+)", tag.strip())
    if match is None:
        raise ValueError("Release tags must use the format vX.Y.Z")
    return match.group(1)


def sync_fastapi_version(content: str, version: str) -> str:
    updated, count = re.subn(
        r'version="[^"]+"',
        f'version="{version}"',
        content,
        count=1,
    )
    if count != 1:
        raise ValueError("Unable to update FastAPI version in backend/app/main.py")
    return updated


def sync_chart_versions(content: str, version: str) -> str:
    updated, version_count = re.subn(
        r"^version:\s*.+$",
        f"version: {version}",
        content,
        count=1,
        flags=re.M,
    )
    updated, app_version_count = re.subn(
        r'^appVersion:\s*".+"$',
        f'appVersion: "{version}"',
        updated,
        count=1,
        flags=re.M,
    )
    if version_count != 1 or app_version_count != 1:
        raise ValueError("Unable to update Helm chart versions in Chart.yaml")
    return updated


def sync_values_image_refs(content: str, owner: str, version: str) -> str:
    owner = owner.strip().lower()
    if not owner:
        raise ValueError("GHCR owner cannot be empty")

    api_repo = f"ghcr.io/{owner}/ingame-api"
    web_repo = f"ghcr.io/{owner}/ingame-web"

    updated, api_repo_count = re.subn(
        r"(^image:\n\s+repository:\s*).+$",
        rf"\1{api_repo}",
        content,
        count=1,
        flags=re.M,
    )
    updated, api_tag_count = re.subn(
        r"(^image:\n(?:\s+.+\n)*?\s+tag:\s*).+$",
        rf"\g<1>{version}",
        updated,
        count=1,
        flags=re.M,
    )
    updated, web_repo_count = re.subn(
        r"(^web:\n(?:\s+.+\n)*?\s+image:\n\s+repository:\s*).+$",
        rf"\g<1>{web_repo}",
        updated,
        count=1,
        flags=re.M,
    )
    updated, web_tag_count = re.subn(
        r"(^web:\n(?:\s+.+\n)*?\s+image:\n(?:\s+.+\n)*?\s+tag:\s*).+$",
        rf"\g<1>{version}",
        updated,
        count=1,
        flags=re.M,
    )
    if api_repo_count != 1 or api_tag_count != 1 or web_repo_count != 1 or web_tag_count != 1:
        raise ValueError("Unable to update Helm image references in values.yaml")
    return updated


def _write_if_changed(path: Path, content: str) -> None:
    if path.read_text() != content:
        path.write_text(content)


def cmd_validate_tag(tag: str, check_aligned: bool) -> int:
    pubspec_version = read_pubspec_semver(PUBSPEC_PATH.read_text())
    tag_version = normalize_release_tag(tag)
    if tag_version != pubspec_version:
        raise ValueError(
            f"Release tag {tag!r} does not match pubspec.yaml version {pubspec_version!r}"
        )
    if check_aligned:
        backend_content = BACKEND_MAIN_PATH.read_text()
        chart_content = HELM_CHART_PATH.read_text()
        if sync_fastapi_version(backend_content, pubspec_version) != backend_content:
            raise ValueError("backend/app/main.py is not aligned with pubspec.yaml")
        if sync_chart_versions(chart_content, pubspec_version) != chart_content:
            raise ValueError("deploy/helm/ingame-api/Chart.yaml is not aligned with pubspec.yaml")
    return 0


def cmd_sync_metadata(write: bool) -> int:
    version = read_pubspec_semver(PUBSPEC_PATH.read_text())
    backend_content = sync_fastapi_version(BACKEND_MAIN_PATH.read_text(), version)
    chart_content = sync_chart_versions(HELM_CHART_PATH.read_text(), version)
    if write:
        _write_if_changed(BACKEND_MAIN_PATH, backend_content)
        _write_if_changed(HELM_CHART_PATH, chart_content)
    return 0


def cmd_check_aligned() -> int:
    version = read_pubspec_semver(PUBSPEC_PATH.read_text())
    backend_content = BACKEND_MAIN_PATH.read_text()
    chart_content = HELM_CHART_PATH.read_text()
    if sync_fastapi_version(backend_content, version) != backend_content:
        raise ValueError("backend/app/main.py is not aligned with pubspec.yaml")
    if sync_chart_versions(chart_content, version) != chart_content:
        raise ValueError("deploy/helm/ingame-api/Chart.yaml is not aligned with pubspec.yaml")
    return 0


def cmd_set_image_refs(owner: str, version: str | None, write: bool) -> int:
    release_version = version or read_pubspec_semver(PUBSPEC_PATH.read_text())
    values_content = sync_values_image_refs(HELM_VALUES_PATH.read_text(), owner=owner, version=release_version)
    if write:
        _write_if_changed(HELM_VALUES_PATH, values_content)
    return 0


def cmd_prepare_release(owner: str, write: bool) -> int:
    version = read_pubspec_semver(PUBSPEC_PATH.read_text())
    backend_content = sync_fastapi_version(BACKEND_MAIN_PATH.read_text(), version)
    chart_content = sync_chart_versions(HELM_CHART_PATH.read_text(), version)
    values_content = sync_values_image_refs(HELM_VALUES_PATH.read_text(), owner=owner, version=version)
    if write:
        _write_if_changed(BACKEND_MAIN_PATH, backend_content)
        _write_if_changed(HELM_CHART_PATH, chart_content)
        _write_if_changed(HELM_VALUES_PATH, values_content)
    return 0


def cmd_print_version() -> int:
    print(read_pubspec_semver(PUBSPEC_PATH.read_text()))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Release version utilities for the InGame stack")
    subparsers = parser.add_subparsers(dest="command", required=True)

    validate = subparsers.add_parser("validate-tag")
    validate.add_argument("--tag", required=True)
    validate.add_argument("--check-aligned", action="store_true")

    sync = subparsers.add_parser("sync-metadata")
    sync.add_argument("--write", action="store_true")

    subparsers.add_parser("check-aligned")

    image_refs = subparsers.add_parser("set-image-refs")
    image_refs.add_argument("--owner", required=True)
    image_refs.add_argument("--version")
    image_refs.add_argument("--write", action="store_true")

    prepare = subparsers.add_parser("prepare-release")
    prepare.add_argument("--owner", required=True)
    prepare.add_argument("--write", action="store_true")

    subparsers.add_parser("print-version")

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.command == "validate-tag":
        return cmd_validate_tag(args.tag, args.check_aligned)
    if args.command == "sync-metadata":
        return cmd_sync_metadata(args.write)
    if args.command == "check-aligned":
        return cmd_check_aligned()
    if args.command == "set-image-refs":
        return cmd_set_image_refs(args.owner, args.version, args.write)
    if args.command == "prepare-release":
        return cmd_prepare_release(args.owner, args.write)
    if args.command == "print-version":
        return cmd_print_version()
    parser.error(f"Unknown command: {args.command}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

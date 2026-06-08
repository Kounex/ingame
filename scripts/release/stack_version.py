from __future__ import annotations

import argparse
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
PUBSPEC_PATH = REPO_ROOT / "pubspec.yaml"
BACKEND_MAIN_PATH = REPO_ROOT / "backend" / "app" / "main.py"
API_HELM_CHART_PATH = REPO_ROOT / "deploy" / "helm" / "ingame-api" / "Chart.yaml"
WEB_HELM_CHART_PATH = REPO_ROOT / "deploy" / "helm" / "ingame-web" / "Chart.yaml"
API_HELM_VALUES_PATH = REPO_ROOT / "deploy" / "helm" / "ingame-api" / "values.yaml"
WEB_HELM_VALUES_PATH = REPO_ROOT / "deploy" / "helm" / "ingame-web" / "values.yaml"


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


def sync_api_values_image_refs(content: str, owner: str, version: str) -> str:
    owner = owner.strip().lower()
    if not owner:
        raise ValueError("GHCR owner cannot be empty")

    api_repo = f"ghcr.io/{owner}/ingame-api"

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
    if api_repo_count != 1 or api_tag_count != 1:
        raise ValueError("Unable to update API Helm image references in values.yaml")
    return updated


def sync_web_values_image_refs(content: str, owner: str, version: str) -> str:
    owner = owner.strip().lower()
    if not owner:
        raise ValueError("GHCR owner cannot be empty")

    web_repo = f"ghcr.io/{owner}/ingame-web"

    updated, repo_count = re.subn(
        r"(^image:\n\s+repository:\s*).+$",
        rf"\1{web_repo}",
        content,
        count=1,
        flags=re.M,
    )
    updated, tag_count = re.subn(
        r"(^image:\n(?:\s+.+\n)*?\s+tag:\s*).+$",
        rf"\g<1>{version}",
        updated,
        count=1,
        flags=re.M,
    )
    if repo_count != 1 or tag_count != 1:
        raise ValueError("Unable to update web Helm image references in values.yaml")
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
        api_chart_content = API_HELM_CHART_PATH.read_text()
        web_chart_content = WEB_HELM_CHART_PATH.read_text()
        api_values_content = API_HELM_VALUES_PATH.read_text()
        web_values_content = WEB_HELM_VALUES_PATH.read_text()
        if sync_fastapi_version(backend_content, pubspec_version) != backend_content:
            raise ValueError("backend/app/main.py is not aligned with pubspec.yaml")
        if sync_chart_versions(api_chart_content, pubspec_version) != api_chart_content:
            raise ValueError("deploy/helm/ingame-api/Chart.yaml is not aligned with pubspec.yaml")
        if sync_chart_versions(web_chart_content, pubspec_version) != web_chart_content:
            raise ValueError("deploy/helm/ingame-web/Chart.yaml is not aligned with pubspec.yaml")
        if sync_api_values_image_refs(
            api_values_content, owner="kounex", version=pubspec_version
        ) != api_values_content:
            raise ValueError("deploy/helm/ingame-api/values.yaml is not aligned with pubspec.yaml")
        if sync_web_values_image_refs(
            web_values_content, owner="kounex", version=pubspec_version
        ) != web_values_content:
            raise ValueError("deploy/helm/ingame-web/values.yaml is not aligned with pubspec.yaml")
    return 0


def cmd_sync_metadata(write: bool) -> int:
    version = read_pubspec_semver(PUBSPEC_PATH.read_text())
    backend_content = sync_fastapi_version(BACKEND_MAIN_PATH.read_text(), version)
    api_chart_content = sync_chart_versions(API_HELM_CHART_PATH.read_text(), version)
    web_chart_content = sync_chart_versions(WEB_HELM_CHART_PATH.read_text(), version)
    if write:
        _write_if_changed(BACKEND_MAIN_PATH, backend_content)
        _write_if_changed(API_HELM_CHART_PATH, api_chart_content)
        _write_if_changed(WEB_HELM_CHART_PATH, web_chart_content)
    return 0


def cmd_check_aligned() -> int:
    version = read_pubspec_semver(PUBSPEC_PATH.read_text())
    backend_content = BACKEND_MAIN_PATH.read_text()
    api_chart_content = API_HELM_CHART_PATH.read_text()
    web_chart_content = WEB_HELM_CHART_PATH.read_text()
    api_values_content = API_HELM_VALUES_PATH.read_text()
    web_values_content = WEB_HELM_VALUES_PATH.read_text()
    if sync_fastapi_version(backend_content, version) != backend_content:
        raise ValueError("backend/app/main.py is not aligned with pubspec.yaml")
    if sync_chart_versions(api_chart_content, version) != api_chart_content:
        raise ValueError("deploy/helm/ingame-api/Chart.yaml is not aligned with pubspec.yaml")
    if sync_chart_versions(web_chart_content, version) != web_chart_content:
        raise ValueError("deploy/helm/ingame-web/Chart.yaml is not aligned with pubspec.yaml")
    if sync_api_values_image_refs(
        api_values_content, owner="kounex", version=version
    ) != api_values_content:
        raise ValueError("deploy/helm/ingame-api/values.yaml is not aligned with pubspec.yaml")
    if sync_web_values_image_refs(
        web_values_content, owner="kounex", version=version
    ) != web_values_content:
        raise ValueError("deploy/helm/ingame-web/values.yaml is not aligned with pubspec.yaml")
    return 0


def cmd_set_image_refs(owner: str, version: str | None, write: bool) -> int:
    release_version = version or read_pubspec_semver(PUBSPEC_PATH.read_text())
    api_values_content = sync_api_values_image_refs(
        API_HELM_VALUES_PATH.read_text(), owner=owner, version=release_version
    )
    web_values_content = sync_web_values_image_refs(
        WEB_HELM_VALUES_PATH.read_text(), owner=owner, version=release_version
    )
    if write:
        _write_if_changed(API_HELM_VALUES_PATH, api_values_content)
        _write_if_changed(WEB_HELM_VALUES_PATH, web_values_content)
    return 0


def cmd_prepare_release(owner: str, write: bool) -> int:
    version = read_pubspec_semver(PUBSPEC_PATH.read_text())
    backend_content = sync_fastapi_version(BACKEND_MAIN_PATH.read_text(), version)
    api_chart_content = sync_chart_versions(API_HELM_CHART_PATH.read_text(), version)
    web_chart_content = sync_chart_versions(WEB_HELM_CHART_PATH.read_text(), version)
    api_values_content = sync_api_values_image_refs(
        API_HELM_VALUES_PATH.read_text(), owner=owner, version=version
    )
    web_values_content = sync_web_values_image_refs(
        WEB_HELM_VALUES_PATH.read_text(), owner=owner, version=version
    )
    if write:
        _write_if_changed(BACKEND_MAIN_PATH, backend_content)
        _write_if_changed(API_HELM_CHART_PATH, api_chart_content)
        _write_if_changed(WEB_HELM_CHART_PATH, web_chart_content)
        _write_if_changed(API_HELM_VALUES_PATH, api_values_content)
        _write_if_changed(WEB_HELM_VALUES_PATH, web_values_content)
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

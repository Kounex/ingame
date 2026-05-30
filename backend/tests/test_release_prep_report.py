import subprocess

import pytest

from scripts.release import release_prep_report
from scripts.release.release_prep_report import (
    _git,
    categorize_paths,
    next_versions,
    render_report,
)


def test_categorize_paths_groups_major_areas():
    paths = [
        "lib/features/groups/presentation/screens/join_group_screen.dart",
        "backend/app/main.py",
        "deploy/helm/ingame-api/values.yaml",
        "docs/specs/2026-05-30-core-platform-design.md",
        ".github/workflows/release-images.yml",
    ]

    categories = categorize_paths(paths)

    assert categories["frontend"] == [
        "lib/features/groups/presentation/screens/join_group_screen.dart"
    ]
    assert categories["backend"] == ["backend/app/main.py"]
    assert categories["deployment"] == ["deploy/helm/ingame-api/values.yaml"]
    assert categories["docs-and-rules"] == [
        "docs/specs/2026-05-30-core-platform-design.md"
    ]
    assert categories["automation"] == [".github/workflows/release-images.yml"]


def test_next_versions_returns_patch_minor_major_candidates():
    assert next_versions("0.1.0") == {
        "patch": "0.1.1",
        "minor": "0.2.0",
        "major": "1.0.0",
    }


def test_render_report_includes_release_note_inputs():
    report = render_report(
        branch="dev",
        base_branch="main",
        current_version="0.1.0",
        commits=[
            "fix onboarding exit after profile completion",
            "add tag-triggered GHCR release workflow",
        ],
        categorized_paths={
            "frontend": ["lib/features/onboarding/presentation/screens/onboarding_screen.dart"],
            "automation": [".github/workflows/release-images.yml"],
        },
    )

    assert "# Release Prep Snapshot" in report
    assert "Current version: `0.1.0`" in report
    assert "Patch: `0.1.1`" in report
    assert "Minor: `0.2.0`" in report
    assert "Major: `1.0.0`" in report
    assert "fix onboarding exit after profile completion" in report
    assert "add tag-triggered GHCR release workflow" in report


def test_git_wraps_called_process_error_with_readable_message(monkeypatch):
    def _fail(*args, **kwargs):
        raise subprocess.CalledProcessError(
            128,
            ["git", "status"],
            stderr="fatal: not a git repository",
        )

    monkeypatch.setattr(release_prep_report.subprocess, "run", _fail)

    with pytest.raises(RuntimeError, match="fatal: not a git repository"):
        _git("status")

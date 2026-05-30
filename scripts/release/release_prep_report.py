from __future__ import annotations

import argparse
import subprocess
from collections import OrderedDict
from pathlib import Path

from scripts.release.stack_version import PUBSPEC_PATH, read_pubspec_semver

REPO_ROOT = Path(__file__).resolve().parents[2]


def categorize_paths(paths: list[str]) -> OrderedDict[str, list[str]]:
    buckets: OrderedDict[str, list[str]] = OrderedDict(
        [
            ("frontend", []),
            ("backend", []),
            ("deployment", []),
            ("automation", []),
            ("docs-and-rules", []),
            ("other", []),
        ]
    )

    for path in paths:
        if path.startswith(("lib/", "test/", "pubspec.yaml", "web/")):
            buckets["frontend"].append(path)
        elif path.startswith("backend/"):
            buckets["backend"].append(path)
        elif path.startswith(("deploy/", "docker-compose.yml", "Dockerfile", "Dockerfile.web")):
            buckets["deployment"].append(path)
        elif path.startswith((".github/", "scripts/release/")):
            buckets["automation"].append(path)
        elif path.startswith(("docs/", ".cursor/rules/", ".agents/skills/")):
            buckets["docs-and-rules"].append(path)
        else:
            buckets["other"].append(path)

    return OrderedDict((name, values) for name, values in buckets.items() if values)


def next_versions(current_version: str) -> dict[str, str]:
    major, minor, patch = (int(part) for part in current_version.split("."))
    return {
        "patch": f"{major}.{minor}.{patch + 1}",
        "minor": f"{major}.{minor + 1}.0",
        "major": f"{major + 1}.0.0",
    }


def render_report(
    *,
    branch: str,
    base_branch: str,
    current_version: str,
    commits: list[str],
    categorized_paths: OrderedDict[str, list[str]],
) -> str:
    versions = next_versions(current_version)

    sections = [
        "# Release Prep Snapshot",
        "",
        f"Current branch: `{branch}`",
        f"Compare against: `{base_branch}`",
        f"Current version: `{current_version}`",
        "",
        "## Next Version Candidates",
        f"- Patch: `{versions['patch']}`",
        f"- Minor: `{versions['minor']}`",
        f"- Major: `{versions['major']}`",
        "",
        "## Commit Summary",
    ]

    if commits:
        sections.extend(f"- {commit}" for commit in commits)
    else:
        sections.append("- No commits found between the compared refs.")

    sections.extend(["", "## Changed Areas"])
    if categorized_paths:
        for category, paths in categorized_paths.items():
            sections.append(f"- `{category}` ({len(paths)} files)")
            sections.extend(f"  - `{path}`" for path in paths[:8])
            if len(paths) > 8:
                sections.append(f"  - ... and {len(paths) - 8} more")
    else:
        sections.append("- No changed files found between the compared refs.")

    sections.extend(
        [
            "",
            "## Release Notes Inputs",
            "- User-visible changes: pull from frontend/backend feature work in the commit summary and changed areas above.",
            "- Operational changes: call out deployment, workflow, or runtime updates from `deployment` and `automation` changes.",
            "- Docs/spec changes: mention only if they materially change rollout, upgrade, or runtime expectations.",
        ]
    )

    return "\n".join(sections) + "\n"


def _git(*args: str) -> str:
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=REPO_ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as exc:
        message = exc.stderr.strip() or exc.stdout.strip() or str(exc)
        raise RuntimeError(f"Git command failed: {message}") from exc
    return result.stdout.strip()


def build_report(base_branch: str, head_ref: str) -> str:
    branch = _git("rev-parse", "--abbrev-ref", head_ref)
    merge_base = _git("merge-base", base_branch, head_ref)
    commit_lines = _git("log", "--format=%s", f"{merge_base}..{head_ref}")
    path_lines = _git("diff", "--name-only", f"{merge_base}..{head_ref}")
    current_version = read_pubspec_semver(PUBSPEC_PATH.read_text())
    commits = [line for line in commit_lines.splitlines() if line]
    paths = [line for line in path_lines.splitlines() if line]
    return render_report(
        branch=branch,
        base_branch=base_branch,
        current_version=current_version,
        commits=commits,
        categorized_paths=categorize_paths(paths),
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Generate a release-prep snapshot for semver and release-note review")
    parser.add_argument("--base", default="main", help="Base branch to compare against")
    parser.add_argument("--head", default="HEAD", help="Head ref or branch to examine")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        print(build_report(base_branch=args.base, head_ref=args.head), end="")
    except RuntimeError as exc:
        raise SystemExit(str(exc))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

---
name: release-prep
description: Review the current dev branch against main, recommend the appropriate semantic version bump, and draft release notes before a release. Use when the user says a build should become a release, wants help deciding patch/minor/major, or wants release notes and release-prep guidance for this repository.
disable-model-invocation: true
---

# Release Prep

Use this skill when the team is preparing a new release from `dev`.

## Workflow

1. Generate the release-prep snapshot:

```bash
python3 -m scripts.release.release_prep_report --base main --head dev
```

2. Review the output and decide the recommended semver bump:
   - `patch`: bug fixes, small UX improvements, docs/tests, or operational changes without new end-user capability
   - `minor`: new user-facing features, new API capabilities, or meaningful deployment/runtime additions
   - `major`: breaking behavior, incompatible API changes, required migration steps, or release notes that need an explicit upgrade warning

3. Present the result in this format:

```markdown
## Release Recommendation

- Recommended bump: `patch|minor|major`
- Current version: `X.Y.Z`
- Proposed next version: `X.Y.Z`
- Why: <2-4 bullets tied directly to the changed work>

## Release Notes Draft

### Added
- ...

### Changed
- ...

### Fixed
- ...

### Ops
- ...
```

4. Ask for approval before modifying release metadata.

5. Once approved:
   - update `pubspec.yaml`
   - run:

```bash
python3 -m scripts.release.stack_version prepare-release --owner kounex --write
```

6. Summarize which files were aligned for the release:
   - `pubspec.yaml`
   - `backend/app/main.py`
   - `deploy/helm/ingame-api/Chart.yaml`
   - `deploy/helm/ingame-api/values.yaml`
   - `deploy/helm/ingame-web/Chart.yaml`
   - `deploy/helm/ingame-web/values.yaml`

## Guidance

- Favor `minor` when the release clearly adds new user-visible functionality, even if it also contains fixes.
- Do not hide breaking changes behind `patch` or `minor`; call them out explicitly.
- Release notes should prioritize user-facing changes first, then operational/deployment changes.
- If the snapshot shows mostly internal cleanup, say so directly and keep the release notes short.

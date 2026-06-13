---
name: tag-release
description: Use when the user wants to prepare or execute a new repository release for this repo, asks for semver or release-tag help, or mentions release prep, merging dev to main, or tagging from main.
disable-model-invocation: true
---

# Tag Release

Use this skill when the team is preparing and executing a new release from `dev`.

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

7. Commit the release-prep changes on `dev`.

8. Before pushing anything, run the local `main` CI equivalent against the release candidate commit on `dev`. Mirror `.github/workflows/ci.yml` as closely as possible:

```bash
flutter pub get
# Use lib/ test/ scope to avoid false positives from build-cache package
# sources (e.g. firebase_messaging examples). Info lints ARE fatal in CI,
# so they must be zero here too.
flutter analyze lib/ test/
flutter test
python -m pip install -r backend/requirements.txt
python -m pytest backend/tests
bash scripts/ci/check-spec-freshness.sh
python -m scripts.release.stack_version check-aligned
bash scripts/ci/validate-flutter-models.sh
INGAME_DATABASE_URL=sqlite+aiosqlite:///./ci.db \
INGAME_REDIS_URL=redis://localhost:6379/0 \
python -m uvicorn app.main:app --app-dir backend --host 127.0.0.1 --port 8000
# In another shell, once the backend is up:
python scripts/ci/validate-api-contract.py --api-url http://127.0.0.1:8000/api/v1
```

**Important:** `flutter analyze` exits non-zero on info-level lints. The local check must also treat infos as failures — do not ignore them. Fix all reported issues before proceeding.

If Redis or another local dependency required by the contract checks is not running, start it first or stop and report the blocker. Do not continue to `git push`, `main`, tagging, or GitHub release creation until this local `main` CI pass is green.

9. Push `dev` before touching `main`:

```bash
git push origin dev
```

10. Merge `dev` into `main` and push `main`:

```bash
git switch main
git merge --ff-only dev
git push origin main
```

11. Create the new semver tag from `main`, not from `dev`:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

12. Confirm that `main` and the new tag point to the same commit.

13. Identify the previous GitHub release tag and build the compare link for the new tag:

```bash
PREV_TAG="$(gh release list --exclude-drafts --exclude-pre-releases --limit 1 --json tagName --jq '.[0].tagName')"
COMPARE_URL="https://github.com/Kounex/ingame/compare/${PREV_TAG}...vX.Y.Z"
```

14. Finish by creating a GitHub release from that tag with a changelog since the previous release. The release body must include:
   - a short agent-written summary explaining what changed since the last release
   - a markdown link to the compare view for `${PREV_TAG}...vX.Y.Z`
   - the generated GitHub release notes

```bash
gh release create vX.Y.Z \
  --title "vX.Y.Z" \
  --generate-notes \
  --notes "$(cat <<EOF
## What Changed Since ${PREV_TAG}

- <2-4 bullets written by the agent summarizing the release in plain language>

## Compare

- [Full changelog](${COMPARE_URL})
EOF
)"
```

Use the generated release notes as the baseline changelog since the previous GitHub release, make sure they still match the drafted release notes, and make sure the added summary/compare section accurately describes the release before reporting release success.

## Guardrails

- Do not tag from `dev`.
- Do not push the release tag before `main` has been updated to the same commit.
- Do not create the GitHub release before the tag exists on `origin`.
- Do not publish the GitHub release without both the agent-written summary and the compare link.
- Do not skip the local `main` CI verification step, even if `dev` tests already passed earlier in the session.
- Do not proceed with `git push`, merging to `main`, tagging, or release creation if the local `main` CI equivalent is red or blocked.
- If `main` cannot fast-forward to `dev`, stop and ask before creating the tag.
- If the release version and tag do not match, stop and fix that before pushing.

## Guidance

- Favor `minor` when the release clearly adds new user-visible functionality, even if it also contains fixes.
- Do not hide breaking changes behind `patch` or `minor`; call them out explicitly.
- Release notes should prioritize user-facing changes first, then operational/deployment changes.
- The added summary should explain the release in plain language, not just restate commit subjects.
- If the snapshot shows mostly internal cleanup, say so directly and keep the release notes short.

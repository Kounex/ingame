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

8. Push `dev` before touching `main`:

```bash
git push origin dev
```

9. Merge `dev` into `main` and push `main`:

```bash
git switch main
git merge --ff-only dev
git push origin main
```

10. Create the new semver tag from `main`, not from `dev`:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

11. Confirm that `main` and the new tag point to the same commit.

12. Finish by creating a GitHub release from that tag with a changelog since the previous release:

```bash
gh release create vX.Y.Z \
  --title "vX.Y.Z" \
  --generate-notes
```

Use the generated release notes as the baseline changelog since the previous GitHub release, and make sure they still match the drafted release notes before reporting release success.

## Guardrails

- Do not tag from `dev`.
- Do not push the release tag before `main` has been updated to the same commit.
- Do not create the GitHub release before the tag exists on `origin`.
- If `main` cannot fast-forward to `dev`, stop and ask before creating the tag.
- If the release version and tag do not match, stop and fix that before pushing.

## Guidance

- Favor `minor` when the release clearly adds new user-visible functionality, even if it also contains fixes.
- Do not hide breaking changes behind `patch` or `minor`; call them out explicitly.
- Release notes should prioritize user-facing changes first, then operational/deployment changes.
- If the snapshot shows mostly internal cleanup, say so directly and keep the release notes short.

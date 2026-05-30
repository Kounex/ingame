#!/usr/bin/env bash
#
# Check that spec documents are updated when API/model code changes.
#
# Compares the current branch's diff against the base branch (default: main).
# If files in the "contract zones" are modified but no spec file is updated,
# the check fails.
#
# Usage:
#   ./scripts/ci/check-spec-freshness.sh [base-branch]
#
# Exit codes:
#   0 - pass (no contract changes, or spec was updated)
#   1 - fail (contract changes without spec update)

set -euo pipefail

BASE_BRANCH="${1:-main}"
SPEC_DIR="docs/specs"

CONTRACT_PATHS=(
    "backend/app/api/"
    "backend/app/db/models/"
    "lib/features/*/domain/"
    "lib/features/*/data/"
    "backend/app/ws/"
)

echo "Spec freshness check"
echo "  Base branch: $BASE_BRANCH"
echo ""

if ! git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
    echo "SKIP: Base branch '$BASE_BRANCH' not found (first branch or shallow clone)"
    exit 0
fi

MERGE_BASE=$(git merge-base HEAD "$BASE_BRANCH" 2>/dev/null || echo "")
if [ -z "$MERGE_BASE" ]; then
    echo "SKIP: No merge base found between HEAD and $BASE_BRANCH"
    exit 0
fi

CHANGED_FILES=$(git diff --name-only "$MERGE_BASE"...HEAD 2>/dev/null || git diff --name-only "$BASE_BRANCH" 2>/dev/null || echo "")

if [ -z "$CHANGED_FILES" ]; then
    echo "SKIP: No changed files detected"
    exit 0
fi

CONTRACT_CHANGES=()
for pattern in "${CONTRACT_PATHS[@]}"; do
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            CONTRACT_CHANGES+=("$file")
        fi
    done < <(echo "$CHANGED_FILES" | grep -E "^${pattern}" 2>/dev/null || true)
done

if [ ${#CONTRACT_CHANGES[@]} -eq 0 ]; then
    echo "PASS: No contract-zone files changed"
    exit 0
fi

echo "Contract-zone files changed:"
for f in "${CONTRACT_CHANGES[@]}"; do
    echo "  - $f"
done
echo ""

SPEC_CHANGES=$(echo "$CHANGED_FILES" | grep "^${SPEC_DIR}/" 2>/dev/null || true)

if [ -z "$SPEC_CHANGES" ]; then
    echo "FAIL: Contract-zone files were modified but no spec in $SPEC_DIR/ was updated."
    echo ""
    echo "If this is an intentional change, update the relevant spec document and"
    echo "add an entry to its Change Log table."
    echo ""
    echo "If this is a non-structural change (bug fix, refactor, etc.) that does"
    echo "not affect the API contract, you can skip this check by adding"
    echo "[skip-spec-check] to your commit message."
    exit 1
fi

echo "Spec files updated:"
echo "$SPEC_CHANGES" | while IFS= read -r f; do
    echo "  - $f"
done
echo ""
echo "PASS: Spec updated alongside contract changes"
exit 0

#!/usr/bin/env bash
#
# Validate that Freezed model fields align with the design spec's data model tables.
#
# Parses Freezed model .dart files for field declarations and checks that each
# spec column has a corresponding Freezed field.
#
# Usage:
#   ./scripts/ci/validate-flutter-models.sh [spec-path]
#
# Exit codes:
#   0 - all models aligned
#   1 - mismatches found

set -euo pipefail

SPEC="${1:-docs/specs/2026-05-30-core-platform-design.md}"

if [ ! -f "$SPEC" ]; then
    echo "FAIL: Spec file not found: $SPEC"
    exit 1
fi

ERRORS=""
ERROR_COUNT=0

ignored_columns_for_model() {
    local model_name="$1"
    case "$model_name" in
        User)
            echo "password_hash"
            ;;
        JoinRequest)
            echo "user_id"
            ;;
        *)
            echo ""
            ;;
    esac
}

extract_spec_columns() {
    local model_name="$1"
    local in_model=0

    while IFS= read -r line; do
        if echo "$line" | grep -q "^\*\*${model_name}\*\*"; then
            in_model=1
            continue
        fi

        if [ $in_model -eq 1 ]; then
            if echo "$line" | grep -qE '^\*\*[A-Z]' || echo "$line" | grep -qE '^###' || echo "$line" | grep -qE '^---'; then
                break
            fi

            col=$(echo "$line" | grep -oE '^\|\s*[a-z_]+\s*\|' | sed 's/|//g' | tr -d ' ')
            if [ -n "$col" ] && [ "$col" != "column" ]; then
                echo "$col"
            fi
        fi
    done < "$SPEC"
}

extract_freezed_fields() {
    local dart_file="$1"
    local class_name="$2"
    local in_factory=0

    while IFS= read -r line; do
        if echo "$line" | grep -qE "const factory ${class_name}\("; then
            in_factory=1
            continue
        fi

        if [ $in_factory -eq 1 ]; then
            if echo "$line" | grep -qE '^\s*\)'; then
                break
            fi

            field=$(echo "$line" | grep -oE '[a-zA-Z?]+\s+[a-zA-Z]+,' | tail -1 | sed 's/,//' | awk '{print $NF}')
            if [ -n "$field" ]; then
                echo "$field"
            fi
        fi
    done < "$dart_file"
}

camel_to_snake() {
    echo "$1" | sed -E 's/([A-Z])/_\1/g' | sed 's/^_//' | tr '[:upper:]' '[:lower:]'
}

is_ignored_column() {
    local model_name="$1"
    local col="$2"
    local ignored_columns
    ignored_columns=$(ignored_columns_for_model "$model_name")
    for ignored in $ignored_columns; do
        if [ "$col" = "$ignored" ]; then
            return 0
        fi
    done
    return 1
}

check_model() {
    local dart_file="$1"
    local freezed_class="$2"
    local spec_model="$3"

    if [ ! -f "$dart_file" ]; then
        ERRORS="${ERRORS}\n  - Freezed model file not found: $dart_file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        return
    fi

    echo "Checking $freezed_class ($dart_file) <-> $spec_model (spec)..."

    local spec_cols
    spec_cols=$(extract_spec_columns "$spec_model")

    local freezed_fields
    freezed_fields=$(extract_freezed_fields "$dart_file" "$freezed_class")

    local freezed_snake=""
    while IFS= read -r field; do
        if [ -n "$field" ]; then
            snake=$(camel_to_snake "$field")
            freezed_snake="${freezed_snake} ${snake}"
        fi
    done <<< "$freezed_fields"

    while IFS= read -r col; do
        if [ -z "$col" ]; then continue; fi
        if is_ignored_column "$spec_model" "$col"; then continue; fi

        if ! echo "$freezed_snake" | grep -qw "$col"; then
            ERRORS="${ERRORS}\n  - [$spec_model] Spec column '$col' not found in Freezed class '$freezed_class'"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    done <<< "$spec_cols"
}

echo "Flutter model alignment check"
echo "  Spec: $SPEC"
echo ""

check_model "lib/features/auth/domain/user_model.dart" "User" "User"
check_model "lib/features/groups/domain/group_model.dart" "Group" "Group"
check_model "lib/features/groups/domain/membership_model.dart" "GroupMember" "GroupMembership"
check_model "lib/features/groups/domain/membership_model.dart" "JoinRequest" "JoinRequest"

echo ""

if [ $ERROR_COUNT -gt 0 ]; then
    echo "FAILED with ${ERROR_COUNT} issue(s):"
    echo -e "$ERRORS"
    echo ""
    echo "Update the Freezed models or the spec to resolve mismatches."
    exit 1
fi

echo "ALL CHECKS PASSED"
exit 0

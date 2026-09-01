#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

WPORG_ACTIVE="$ROOT_DIR/manifests/wporg-active.txt"
WPORG_INACTIVE="$ROOT_DIR/manifests/wporg-inactive.txt"
EXTERNAL_ACTIVE="$ROOT_DIR/manifests/external-active.txt"
EXTERNAL_INACTIVE="$ROOT_DIR/manifests/external-inactive.txt"

ERRORS=0

echo "Validating plugin manifests..."
echo

validate_wporg() {

    local file="$1"

    echo "Checking: $file"

    while IFS= read -r plugin; do

        [[ -z "$plugin" ]] && continue
        [[ "$plugin" =~ ^[[:space:]]*# ]] && continue

        if [[ ! "$plugin" =~ ^[a-z0-9][a-z0-9._-]*$ ]]; then
            echo "ERROR: Invalid WordPress.org slug: $plugin"
            ERRORS=$((ERRORS + 1))
        fi

    done < "$file"
}

validate_external() {

    local file="$1"

    echo "Checking: $file"

    while IFS= read -r line; do

        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        if [[ "$line" != *"|"* ]]; then
            echo "ERROR: Invalid external entry: $line"
            echo "Expected: plugin-folder|zip-file"
            ERRORS=$((ERRORS + 1))
        fi

    done < "$file"
}

validate_wporg "$WPORG_ACTIVE"
validate_wporg "$WPORG_INACTIVE"

validate_external "$EXTERNAL_ACTIVE"
validate_external "$EXTERNAL_INACTIVE"

echo

if [[ "$ERRORS" -gt 0 ]]; then
    echo "Validation FAILED with $ERRORS error(s)."
    exit 1
fi

echo "Validation successful."

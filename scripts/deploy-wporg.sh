#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

WP_PATH="${WP_PATH:?WP_PATH is required}"
EXPECTED_SITE_URL="${EXPECTED_SITE_URL:?EXPECTED_SITE_URL is required}"

WPORG_ACTIVE="${ROOT_DIR}/manifests/wporg-active.txt"
WPORG_INACTIVE="${ROOT_DIR}/manifests/wporg-inactive.txt"

WP=(
    wp
    "--path=${WP_PATH}"
    --skip-plugins
    --skip-themes
)


read_manifest() {

    local file="$1"

    sed \
        -e 's/\r$//' \
        -e 's/^[[:space:]]*//' \
        -e 's/[[:space:]]*$//' \
        "$file" |
        grep -vE '^[[:space:]]*(#|$)' || true
}


echo
echo "========================================"
echo "WORDPRESS.ORG PLUGIN DEPLOYMENT"
echo "========================================"


echo
echo "[1/7] Verifying deployment target"

CURRENT_HOME="$("${WP[@]}" option get home)"
CURRENT_SITEURL="$("${WP[@]}" option get siteurl)"

echo "Expected: $EXPECTED_SITE_URL"
echo "Home:     $CURRENT_HOME"
echo "Site URL: $CURRENT_SITEURL"

if [[ "$CURRENT_HOME" != "$EXPECTED_SITE_URL" ]] || \
   [[ "$CURRENT_SITEURL" != "$EXPECTED_SITE_URL" ]]; then
    echo "ERROR: WordPress URL does not match the expected staging URL."
    exit 1
fi

"${WP[@]}" core is-installed
"${WP[@]}" core verify-checksums

echo "OK"


echo
echo "[2/7] Installing and activating configured active plugins"

while IFS= read -r plugin; do
    echo
    echo "Installing: $plugin"
    "${WP[@]}" plugin install "$plugin" --force
    "${WP[@]}" plugin activate "$plugin"
done < <(read_manifest "$WPORG_ACTIVE")


echo
echo "[3/7] Installing configured inactive plugins"

while IFS= read -r plugin; do
    echo
    echo "Installing: $plugin"
    "${WP[@]}" plugin install "$plugin" --force

    if "${WP[@]}" plugin is-active "$plugin" >/dev/null 2>&1; then
        "${WP[@]}" plugin deactivate "$plugin"
    fi
done < <(read_manifest "$WPORG_INACTIVE")


echo
echo "[4/7] Verifying WordPress.org plugin checksums"

while IFS= read -r plugin; do
    "${WP[@]}" plugin verify-checksums "$plugin" --strict
done < <(read_manifest "$WPORG_ACTIVE")

while IFS= read -r plugin; do
    "${WP[@]}" plugin verify-checksums "$plugin" --strict
done < <(read_manifest "$WPORG_INACTIVE")


echo
echo "[5/7] Verifying expected plugin state"

while IFS= read -r plugin; do
    if ! "${WP[@]}" plugin is-installed "$plugin"; then
        echo "ERROR: Expected active plugin is not installed: $plugin"
        exit 1
    fi

    if ! "${WP[@]}" plugin is-active "$plugin"; then
        echo "ERROR: Expected active plugin is inactive: $plugin"
        exit 1
    fi

    echo "[OK] ACTIVE: $plugin"
done < <(read_manifest "$WPORG_ACTIVE")

while IFS= read -r plugin; do
    if ! "${WP[@]}" plugin is-installed "$plugin"; then
        echo "ERROR: Expected inactive plugin is not installed: $plugin"
        exit 1
    fi

    if "${WP[@]}" plugin is-active "$plugin"; then
        echo "ERROR: Expected inactive plugin is active: $plugin"
        exit 1
    fi

    echo "[OK] INACTIVE: $plugin"
done < <(read_manifest "$WPORG_INACTIVE")


echo
echo "[6/7] Flushing WordPress cache"

"${WP[@]}" cache flush


echo
echo "[7/7] Deployment report"

"${WP[@]}" plugin list \
    --fields=name,status,version,update,update_version

echo
echo "========================================"
echo "WORDPRESS.ORG DEPLOYMENT SUCCESSFUL"
echo "========================================"

echo
echo "Configured WordPress.org plugins were installed from WordPress.org."
echo "Checksums and expected active/inactive states were verified."
echo "External and manually managed plugins were not modified."

#!/usr/bin/env bash

set -Eeuo pipefail

WP_PATH="${WP_PATH:?WP_PATH is required}"
EXPECTED_SITE_URL="${EXPECTED_SITE_URL:?EXPECTED_SITE_URL is required}"

WP=(
    wp
    "--path=${WP_PATH}"
    --skip-plugins
    --skip-themes
)

echo
echo "========================================"
echo "WordPress staging preflight"
echo "========================================"

echo
echo "WP_PATH:"
echo "$WP_PATH"

echo
echo "Expected URL:"
echo "$EXPECTED_SITE_URL"


echo
echo "[1/8] Checking WordPress directory"

if [[ ! -d "$WP_PATH" ]]; then
    echo "ERROR: WordPress directory does not exist."
    exit 1
fi

echo "OK"


echo
echo "[2/8] Checking WP-CLI"

if ! command -v wp >/dev/null 2>&1; then
    echo "ERROR: WP-CLI not found."
    exit 1
fi

wp --info

echo "OK"


echo
echo "[3/8] Checking WordPress installation"

"${WP[@]}" core is-installed

echo "OK"


echo
echo "[4/8] Checking target site URL"

CURRENT_HOME="$("${WP[@]}" option get home)"
CURRENT_SITEURL="$("${WP[@]}" option get siteurl)"

echo "home:    $CURRENT_HOME"
echo "siteurl: $CURRENT_SITEURL"

if [[ "$CURRENT_HOME" != "$EXPECTED_SITE_URL" ]]; then
    echo
    echo "ERROR: Target WordPress does not match staging URL."
    echo
    echo "Expected:"
    echo "$EXPECTED_SITE_URL"
    echo
    echo "Received:"
    echo "$CURRENT_HOME"
    exit 1
fi

if [[ "$CURRENT_SITEURL" != "$EXPECTED_SITE_URL" ]]; then
    echo
    echo "ERROR: siteurl does not match staging URL."
    exit 1
fi

echo "OK"


echo
echo "[5/8] Checking plugin directory write access"

PLUGIN_DIR="${WP_PATH}/wp-content/plugins"

if [[ ! -d "$PLUGIN_DIR" ]]; then
    echo "ERROR: Plugin directory does not exist."
    exit 1
fi

TEST_FILE="${PLUGIN_DIR}/.github-actions-write-test"

touch "$TEST_FILE"
rm "$TEST_FILE"

echo "OK"


echo
echo "[6/8] Checking WordPress Core checksums"

"${WP[@]}" core verify-checksums

echo "OK"


echo
echo "[7/8] Checking database"

"${WP[@]}" db check

echo "OK"


echo
echo "[8/8] Current plugin state"

"${WP[@]}" plugin list \
    --fields=name,status,version,update,update_version


echo
echo "========================================"
echo "PREFLIGHT SUCCESSFUL"
echo "========================================"

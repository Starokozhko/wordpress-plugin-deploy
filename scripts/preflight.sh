#!/usr/bin/env bash

set -Eeuo pipefail

WP_PATH="${WP_PATH:?WP_PATH environment variable is required}"

echo "========================================"
echo "WordPress deployment preflight"
echo "========================================"

echo
echo "WordPress path:"
echo "$WP_PATH"

echo
echo "[1/7] Checking WP path..."

if [[ ! -d "$WP_PATH" ]]; then
    echo "ERROR: WordPress directory does not exist:"
    echo "$WP_PATH"
    exit 1
fi

echo "OK"


echo
echo "[2/7] Checking WP-CLI..."

if ! command -v wp >/dev/null 2>&1; then
    echo "ERROR: WP-CLI is not installed or not available in PATH."
    exit 1
fi

wp --info

echo "OK"


echo
echo "[3/7] Checking WordPress installation..."

if ! wp \
    --path="$WP_PATH" \
    --skip-plugins \
    --skip-themes \
    core is-installed; then

    echo "ERROR: WordPress is not installed at:"
    echo "$WP_PATH"
    exit 1
fi

echo "OK"


echo
echo "[4/7] WordPress version..."

wp \
    --path="$WP_PATH" \
    --skip-plugins \
    --skip-themes \
    core version


echo
echo "[5/7] PHP version..."

php -v | head -n 1


echo
echo "[6/7] Current plugin state..."

wp \
    --path="$WP_PATH" \
    --skip-plugins \
    --skip-themes \
    plugin list \
    --fields=name,status,version,update


echo
echo "[7/7] Checking WordPress Core checksums..."

wp \
    --path="$WP_PATH" \
    --skip-plugins \
    --skip-themes \
    core verify-checksums


echo
echo "========================================"
echo "PREFLIGHT SUCCESSFUL"
echo "========================================"

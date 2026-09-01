#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

WP_PATH="${WP_PATH:?WP_PATH is required}"
EXPECTED_SITE_URL="${EXPECTED_SITE_URL:?EXPECTED_SITE_URL is required}"

WPORG_ACTIVE="${ROOT_DIR}/manifests/wporg-active.txt"
WPORG_INACTIVE="${ROOT_DIR}/manifests/wporg-inactive.txt"

EXTERNAL_ACTIVE="${ROOT_DIR}/manifests/external-active.txt"
EXTERNAL_INACTIVE="${ROOT_DIR}/manifests/external-inactive.txt"

WP=(
    wp
    "--path=${WP_PATH}"
    --skip-plugins
    --skip-themes
)

ERRORS=0


read_manifest() {

    local file="$1"

    sed \
        -e 's/\r$//' \
        -e 's/[[:space:]]*$//' \
        "$file" |
        grep -vE '^[[:space:]]*(#|$)' || true
}


echo
echo "========================================"
echo "WORDPRESS PLUGIN DEPLOYMENT DRY RUN"
echo "========================================"


#
# SAFETY CHECK
#

echo
echo "[1/6] Verifying target WordPress"

CURRENT_HOME="$("${WP[@]}" option get home)"
CURRENT_SITEURL="$("${WP[@]}" option get siteurl)"

echo "Expected: $EXPECTED_SITE_URL"
echo "Home:     $CURRENT_HOME"
echo "Site URL: $CURRENT_SITEURL"

if [[ "$CURRENT_HOME" != "$EXPECTED_SITE_URL" ]]; then

    echo
    echo "ERROR: WordPress home URL does not match."
    exit 1

fi

if [[ "$CURRENT_SITEURL" != "$EXPECTED_SITE_URL" ]]; then

    echo
    echo "ERROR: WordPress siteurl does not match."
    exit 1

fi

echo "OK"


#
# DUPLICATES
#

echo
echo "[2/6] Checking active/inactive conflicts"

WPORG_DUPLICATES="$(
    comm -12 \
        <(read_manifest "$WPORG_ACTIVE" | sort -u) \
        <(read_manifest "$WPORG_INACTIVE" | sort -u)
)"

if [[ -n "$WPORG_DUPLICATES" ]]; then

    echo "ERROR: Plugins found in BOTH wporg-active and wporg-inactive:"
    echo
    echo "$WPORG_DUPLICATES"

    exit 1

fi

echo "OK"


#
# WORDPRESS.ORG API CHECK
#

echo
echo "[3/6] Checking WordPress.org plugin slugs"

if ! command -v curl >/dev/null 2>&1; then

    echo "ERROR: curl is required."
    exit 1

fi


check_wporg_plugin() {

    local plugin="$1"
    local desired_state="$2"

    printf "%-45s " "$plugin"

    RESPONSE="$(
        curl \
            --silent \
            --show-error \
            --fail \
            --get \
            'https://api.wordpress.org/plugins/info/1.2/' \
            --data-urlencode 'action=plugin_information' \
            --data-urlencode "request[slug]=${plugin}" \
            2>/dev/null || true
    )"

    if [[ -z "$RESPONSE" ]]; then

        echo "[ERROR] WordPress.org API request failed"

        ERRORS=$((ERRORS + 1))
        return

    fi

    if ! printf '%s' "$RESPONSE" | php -r '
        $json = stream_get_contents(STDIN);
        $data = json_decode($json, true);

        if (
            !is_array($data) ||
            empty($data["slug"]) ||
            !empty($data["error"])
        ) {
            exit(1);
        }
    '; then

        echo "[ERROR] Plugin slug not found"

        ERRORS=$((ERRORS + 1))
        return

    fi

    echo "[OK] $desired_state"
}


echo
echo "ACTIVE:"
echo

while IFS= read -r plugin; do

    check_wporg_plugin "$plugin" "INSTALL + ACTIVATE"

done < <(read_manifest "$WPORG_ACTIVE")


echo
echo "INACTIVE:"
echo

while IFS= read -r plugin; do

    check_wporg_plugin "$plugin" "INSTALL + KEEP INACTIVE"

done < <(read_manifest "$WPORG_INACTIVE")


#
# EXTERNAL PLUGINS
#

echo
echo "[4/6] External plugins"

echo
echo "ACTIVE:"
echo

EXTERNAL_ACTIVE_COUNT=0

while IFS='|' read -r plugin zip_file; do

    [[ -z "$plugin" ]] && continue

    EXTERNAL_ACTIVE_COUNT=$((EXTERNAL_ACTIVE_COUNT + 1))

    echo "$plugin"
    echo "    ZIP: $zip_file"
    echo "    ACTION: INSTALL + ACTIVATE"
    echo

done < <(read_manifest "$EXTERNAL_ACTIVE")

if [[ "$EXTERNAL_ACTIVE_COUNT" -eq 0 ]]; then
    echo "(none configured yet)"
fi


echo
echo "INACTIVE:"
echo

EXTERNAL_INACTIVE_COUNT=0

while IFS='|' read -r plugin zip_file; do

    [[ -z "$plugin" ]] && continue

    EXTERNAL_INACTIVE_COUNT=$((EXTERNAL_INACTIVE_COUNT + 1))

    echo "$plugin"
    echo "    ZIP: $zip_file"
    echo "    ACTION: INSTALL + KEEP INACTIVE"
    echo

done < <(read_manifest "$EXTERNAL_INACTIVE")

if [[ "$EXTERNAL_INACTIVE_COUNT" -eq 0 ]]; then
    echo "(none configured yet)"
fi


#
# CURRENT STATE
#

echo
echo "[5/6] Current staging plugin state"

"${WP[@]}" plugin list \
    --fields=name,status,version,update


#
# RESULT
#

echo
echo "[6/6] Dry-run result"

if [[ "$ERRORS" -gt 0 ]]; then

    echo
    echo "========================================"
    echo "DRY RUN FAILED"
    echo "========================================"

    echo
    echo "$ERRORS WordPress.org plugin(s) could not be validated."
    echo
    echo "NO CHANGES WERE MADE."

    exit 1

fi


echo
echo "========================================"
echo "DRY RUN SUCCESSFUL"
echo "========================================"

echo
echo "All configured WordPress.org slugs were validated."
echo
echo "NO PLUGINS WERE INSTALLED."
echo "NO PLUGINS WERE ACTIVATED."
echo "NO FILES IN WORDPRESS WERE MODIFIED."

#!/bin/bash
# ---------------------------------------------------------------------
# Copyright (C) 2021 DevPanel
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation version 3 of the
# License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# For GNU Affero General Public License see <https://www.gnu.org/licenses/>.
# ----------------------------------------------------------------------

cd $APP_ROOT

# URL-encode function (POSIX safe)
urlencode() {
    local raw="$1"
    local length=${#raw}
    local i char
    for (( i = 0; i < length; i++ )); do
        char="${raw:$i:1}"
        case "$char" in
            [a-zA-Z0-9.~_-]) printf '%s' "$char" ;;
            *) printf '%%%02X' "'$char" ;;
        esac
    done
}
ENCODED_PASS=$(urlencode "$DB_PASSWORD")
echo '> Update .env file'
# Update .env.local file
CONNECT_STRING="${DB_DRIVER}://${DB_USER}:${ENCODED_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

# Check if database exists
if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -e "USE $DB_NAME;" 2>/dev/null; then
    echo "Database '$DB_NAME' exists. Running Shopware install..."

    # Escape special chars for sed
    SAFE_CONNECT_STRING=$(printf '%s' "$CONNECT_STRING" | sed -e 's/[&/\]/\\&/g')

    if grep -q '^DATABASE_URL=' "$APP_ROOT/.env.local"; then
      sed -i "s|^DATABASE_URL=.*|DATABASE_URL=\"${SAFE_CONNECT_STRING}\"|" "$APP_ROOT/.env.local"
    else
      echo "DATABASE_URL=\"${CONNECT_STRING}\"" >> "$APP_ROOT/.env.local"
    fi

    echo "> Import database"
    APP_ENV=prod bin/console framework:demodata && APP_ENV=prod bin/console dal:refresh:index

    bin/console cache:clear
else
    echo "Database '$DB_NAME' does not exist. Skipping install."
fi

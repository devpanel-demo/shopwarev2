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

# Update .env.local file
CONNECT_STRING="${DB_DRIVER}://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
if [ -n "$DP_HOSTNAME" ]; then
    sed -i "s|APP_URL=http://127.0.0.1:8000|APP_URL=https://${DP_HOSTNAME}|" "$APP_ROOT/.env.local"
fi

# Extract DB name from the connect string
DB_NAME=$(echo "$CONNECT_STRING" | cut -d'/' -f4)
# Check if database exists
if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -e "USE $DB_NAME;" 2>/dev/null; then
    echo "Database '$DB_NAME' exists. Running Shopware install..."
    SAFE_CONNECT_STRING=$(printf '%s' "$CONNECT_STRING" | sed -e 's/[&|/$\\]/\\&/g')
    sed -i "s|^DATABASE_URL=.*|DATABASE_URL=\"${SAFE_CONNECT_STRING}\"|" "$APP_ROOT/.env.local"

    echo '> Install shopware package';
    cd $APP_ROOT
    sudo bin/console system:install --basic-setup

    # Allow composer plugin without prompt
    echo '> allow-plugins'
    composer config --no-plugins allow-plugins.php-http/discovery true

    # Install profiler and other dev tools, eg Faker for demo data generation
    echo '> Install dev-tools'
    composer require --dev shopware/dev-tools

    echo "> Import database"
    cd $APP_ROOT
    APP_ENV=prod bin/console framework:demodata && APP_ENV=prod bin/console dal:refresh:index

    bin/console cache:clear
else
    echo "Database '$DB_NAME' does not exist. Skipping install."
fi

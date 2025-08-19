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
sudo mkdir -p vendor var public files
sudo chown -R "$(whoami)":"$(whoami)" vendor/ var/ public/ files/ .env.local composer.json composer.lock
sudo chmod -R 775 vendor/ var/ public/ files/ .env.local composer.json composer.lock

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
if [ -n "$DP_HOSTNAME" ]; then
  if ! grep -q '^APP_URL=' "$APP_ROOT/.env.local"; then
    echo "APP_URL=http://${DP_HOSTNAME}" >> "$APP_ROOT/.env.local"
  fi
fi
echo "> Conect string: ${CONNECT_STRING}"
echo '> DB info'
printenv | grep DB

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

    echo '> Install composer at re-config'
    if [[ -f "$APP_ROOT/composer.json" ]]; then
      # Run Composer
      composer install
      echo '> Composer installed'
    fi

    echo '> Install shopware package';
    sudo bin/console system:install --basic-setup --force

    sudo chown -R www-data:www-data var/ public/
    sudo chmod -R 775 var/ public/
    bin/console cache:clear

    # Allow composer plugin without prompt
    echo '> allow-plugins'
    composer config --no-plugins allow-plugins.php-http/discovery true

    # Install profiler and other dev tools, eg Faker for demo data generation
    echo '> Install dev-tools'
    composer require --dev shopware/dev-tools

    bin/console cache:clear
else
    echo "Database '$DB_NAME' does not exist. Skipping install."
fi

echo "> Host name: ${DP_HOSTNAME}"
echo '> DB info v2'
printenv | grep DB
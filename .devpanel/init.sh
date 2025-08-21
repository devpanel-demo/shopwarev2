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
# sudo chown -R "$(whoami)":"$(whoami)" vendor/ var/ public/ files/ .env.local composer.json composer.lock
# sudo chmod -R 775 vendor/ var/ public/ files/ .env.local composer.json composer.lock
sudo chown -R "$(whoami)":"$(whoami)" vendor/ var/ public/ files/
sudo chmod -R 775 vendor/ var/ public/ files/

# URL-encode function (POSIX safe)
# urlencode() {
#     local raw="$1"
#     local length=${#raw}
#     local i char
#     for (( i = 0; i < length; i++ )); do
#         char="${raw:$i:1}"
#         case "$char" in
#             [a-zA-Z0-9.~_-]) printf '%s' "$char" ;;
#             *) printf '%%%02X' "'$char" ;;
#         esac
#     done
# }
# ENCODED_PASS=$(urlencode "$DB_PASSWORD")
# echo '> Update .env file'
# # Update .env.local file
# CONNECT_STRING="${DB_DRIVER}://${DB_USER}:${ENCODED_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
# if [ -n "$DP_HOSTNAME" ]; then
#   if ! grep -q '^APP_URL=' "$APP_ROOT/.env.local"; then
#     echo "APP_URL=https://${DP_HOSTNAME}" >> "$APP_ROOT/.env.local"
#   fi
# fi

if [[ ! -n "$APACHE_RUN_USER" ]]; then
  export APACHE_RUN_USER=www-data
fi
if [[ ! -n "$APACHE_RUN_GROUP" ]]; then
  export APACHE_RUN_GROUP=www-data
fi

#== If webRoot has not been difined, we will set appRoot to webRoot
if [[ ! -n "$WEB_ROOT" ]]; then
  export WEB_ROOT=$APP_ROOT
fi

cd $APP_ROOT
composer install
mkdir files
sudo chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP public/ files/

echo ">>> Install shopware package";
sudo -E bin/console system:install --basic-setup --force

echo ">>> allow-plugins";
composer config --no-plugins allow-plugins.php-http/discovery true

echo ">>> Install dev-tools";
composer require --dev shopware/dev-tools

echo ">>> Import database";
bin/console framework:demodata
bin/console dal:refresh:index
bin/console cache:clear
echo ">>> Successful, please refresh your web page.";
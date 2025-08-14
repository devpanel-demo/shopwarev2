#!/bin/bash
# ---------------------------------------------------------------------
# Copyright (C) 2023 DevPanel
# You can install any service here to support your project
# Please make sure you run apt update before install any packages
# Example:
# - sudo apt-get update
# - sudo apt-get install nano
#
# ----------------------------------------------------------------------

sudo apt-get update
sudo apt-get install -y nano jq

echo '> Install node 22'
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
\. "$HOME/.nvm/nvm.sh"
nvm install 22
echo "> Installed Node $(node -v), NPM $(npm -v)"

echo '> Install composer';
if [[ ! -n "$APACHE_RUN_USER" ]]; then
  export APACHE_RUN_USER=www-data
fi
if [[ ! -n "$APACHE_RUN_GROUP" ]]; then
  export APACHE_RUN_GROUP=www-data
fi

#== Composer install.
cd $APP_ROOT
sudo usermod -a -G www-data www
# sudo chown -R www:www-data /var/www/html
# sudo chmod -R 775 /var/www/html

# sudo chown -R ${APACHE_RUN_USER}:${APACHE_RUN_GROUP} /var/www/html /home/www/.composer/
# sudo chmod -R 775 /var/www/html /home/www/.composer/
# sudo chmod -R 777 /var/www/html/public /var/www/html/var

# set -e

# # Default to www-data if not set
# : "${APACHE_RUN_USER:=www-data}"
# : "${APACHE_RUN_GROUP:=www-data}"

#sudo chmod -R 775 /var/www/html
# sudo chmod -R 777 /var/www/html/var/ /var/www/html/public/ /home/www/.composer/


if [[ -f "$APP_ROOT/composer.json" ]]; then
  # cd $APP_ROOT && composer install;
  cd $APP_ROOT
  sudo mkdir -p vendor var public
  sudo chown -R "$(whoami)":"$(whoami)" vendor/ var/ public/ .env.local composer.json composer.lock
  sudo chmod -R 775 vendor/ var/ public/ .env.local composer.json composer.lock
  composer install;

fi

# sudo chown -R ${APACHE_RUN_USER}:${APACHE_RUN_GROUP} /var/www/html /home/www/.composer/
# sudo chmod -R 775 /var/www/html /home/www/.composer/
# sudo chmod -R 777 /var/www/html/public /var/www/html/var

# # Function to safe-chown
# safe_chown() {
#   local path="$1"
#   if [ -e "$path" ]; then
#     if id "$APACHE_RUN_USER" &>/dev/null && id -g "$APACHE_RUN_GROUP" &>/dev/null; then
#       sudo chown -R www:${APACHE_RUN_GROUP} "$path"
#       sudo chmod -R 775 "$path"
#       echo "Fixed permissions for $path"
#     else
#       echo "⚠ User/group $APACHE_RUN_USER:$APACHE_RUN_GROUP not found, skipping $path"
#     fi
#   else
#     echo "⚠ Path $path does not exist, skipping"
#   fi
# }

# safe_chown "/var/www/html/var"
# safe_chown "/var/www/html/public"
# safe_chown "/home/www/.composer"
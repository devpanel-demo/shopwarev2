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

sudp chown -R www:www-data /var/www/html /home/www/.composer/
sudo chmod -R 775 /var/www/html /home/www/.composer/

if [[ -f "$APP_ROOT/composer.json" ]]; then
  cd $APP_ROOT && composer install;
fi

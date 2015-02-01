#!/usr/bin/env bash

echo "Setup variables."
export DEBIAN_FRONTEND=noninteractive
echo $timezone > /etc/timezone
. /vagrant/.vagrant_bootstrap/bootstrap.cfg

echo "mysql-server mysql-server/root_password password $mysql_password" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $mysql_password" | debconf-set-selections

echo "Refresh repositories."
sudo apt-key update
sudo apt-get upgrade -y
sudo apt-get update -y

echo "Installing base staff." 
sudo apt-get install -y vim tmux curl wget build-essential python-software-properties git-core unzip curl acl ruby memcached debconf-utils checkinstall zip locate ruby-full libsqlite3-dev

echo "Setup Apache2."
sudo apt-get install -y apache2
echo "ServerName localhost" >> /etc/apache2/apache2.conf
VHOST=$(cat <<EOF
<VirtualHost *:80>
  DocumentRoot "/var/www"
  ServerName localhost
  ErrorLog ${APACHE_LOG_DIR}/error.log
  CustomLog ${APACHE_LOG_DIR}/access.log combined
  <Directory "/var/www">
    AllowOverride All
    Require all granted
  </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-enabled/000-default.conf
usermod -a -G vagrant www-data
sudo a2enmod rewrite
sudo a2enmod expires
sudo a2enmod headers
sudo service apache2 restart

echo "Add repositories."
sudo add-apt-repository -y ppa:ondrej/php5-5.6
sudo add-apt-repository -y ppa:ondrej/apache2
sudo add-apt-repository -y ppa:ondrej/mysql-5.6
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E5267A6C

echo "Update repositories."
sudo apt-get update
sudo apt-get upgrade
echo "Setup GIT."
sudo apt-get install -y git
git config --global color.branch auto
git config --global color.diff auto
git config --global color.status auto

echo "Setup PHP 5."
sudo apt-get install -y php5 php5-gd php5-sqlite php5-common php5-geoip php5-redis php5-memcache php5-memcached  php5-mysql php5-xsl php5-curl php5-mcrypt php5-intl php-pear php5-cli php5-dev libapache2-mod-php5 php-apc php-pear php5-json
sudo mv /etc/php5/apache2/php.ini /etc/php5/apache2/php.ini.bak
sudo cp -s /usr/share/php5/php.ini-development /etc/php5/apache2/php.ini
sed -i 's#;date.timezone\([[:space:]]*\)=\([[:space:]]*\)*#date.timezone\1=\2\"'"$timezone"'\"#g' /etc/php5/apache2/php.ini
sed -i 's#;date.timezone\([[:space:]]*\)=\([[:space:]]*\)*#date.timezone\1=\2\"'"$timezone"'\"#g' /etc/php5/cli/php.ini
sed -i 's#display_errors = Off#display_errors = On#g' /etc/php5/apache2/php.ini
sed -i 's#display_startup_errors = Off#display_startup_errors = On#g' /etc/php5/apache2/php.ini
sed -i 's#error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT#error_reporting = E_ALL#g' /etc/php5/apache2/php.ini
sudo rm -rf /var/www/html/index*
echo "<?php phpinfo(); " > /var/www/html/index.php
sudo a2enmod php5

echo "Configure XDdebug."

cat << EOF | sudo tee -a /etc/php5/mods-available/xdebug.ini
xdebug.scream=0
xdebug.cli_color=1
xdebug.show_local_vars=1
xdebug.remote_enable=On
xdebug.remote_host=localhost
xdebug.remote_port=9002
xdebug.remote_handler=dbgp
xdebug.profiler_append=Off
xdebug.profiler_enable=Off
xdebug.profiler_enable_trigger=Off
xdebug.profiler_output_dir="/tmp/kcachegrind"
xdebug.max_nesting_level = 1000000

EOF

echo "Setup Composer."

if [ ! -f /usr/local/bin/composer ];
  then
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
    chmod a+x /usr/local/bin/composer
  else
    composer self-update
fi

echo "Setup MySql."
# Install MySQL without prompt
sudo apt-get install -y mysql-server-5.6 mysql-client-5.6
# Create main db
mysql -u root -proot -e 'CREATE DATABASE IF NOT EXISTS dev'

echo "Setup Adminer."
if [ ! -f /usr/share/adminer/adminer.php ];
  then
    sudo mkdir /usr/share/adminer
    sudo wget -O /usr/share/adminer/latest.php "http://www.adminer.org/latest.php"
    sudo ln -s /usr/share/adminer/latest.php /usr/share/adminer/adminer.php
    echo "Alias /adminer.php /usr/share/adminer/adminer.php" | sudo tee /etc/apache2/conf-available/adminer.conf
    sudo a2enconf adminer
fi

echo "Setup PEAR."
sudo pear channel-update PEAR
sudo pear upgrade PEAR

echo "Setup Phing."
sudo pear channel-discover pear.phing.info
sudo pear install phing/phing

echo "Setup PHP CodeSniffer."
if [ ! -f /usr/bin/phpcs ];
  then
  sudo pear install PHP_CodeSniffer
fi

echo "Install MailCatcher."
if [ ! -f /usr/local/bin/mailcatcher ];
  then
  sudo gem install mailcatcher --no-ri --no-rdoc
  mailcatcher --http-ip=192.168.56.101
fi

echo "Restart Apache2."
sudo service apache2 restart

sudo apt-get autoremove -y
sudo apt-get autoclean -y
#!/usr/bin/env bash


echo "[BOOTSTRAP] Applying nasty hack for /stdin: is not a tty/ message..."
sudo sed -i 's/^mesg n$/tty -s \&\& mesg n/g' /root/.profile

echo "[BOOTSTRAP] Importing config file..."
. /vagrant/.vagrant_bootstrap/bootstrap.cfg


echo "[BOOTSTRAP] Setting up locales..."
export LANGUAGE=$LOCALE_CODESET
export LANG=$LOCALE_CODESET
export LC_ALL=$LOCALE_CODESET
sudo locale-gen $LOCALE_LANGUAGE $LOCALE_CODESET > /dev/null


echo "[BOOTSTRAP] Changing installer mode to noninteractive..."
export DEBIAN_FRONTEND=noninteractive


echo "[BOOTSTRAP] Refreshing repositories..."
sudo apt-key update
sudo apt-get upgrade -y -qq
sudo apt-get update -y -qq


echo "[BOOTSTRAP] Installing core packages..." 
sudo apt-get install -y -qq vim tmux curl wget build-essential make openssl python-software-properties git-core unzip tree curl acl ruby memcached debconf-utils checkinstall zip locate ruby-full libsqlite3-dev  tzdata


echo "[BOOTSTRAP] Setting up timezone..."
echo $TIMEZONE > /etc/timezone
sudo dpkg-reconfigure --frontend noninteractive tzdata

#######
# GIT #
#######

echo "[BOOTSTRAP] Installing and configuring Git..."
sudo apt-get install -y -qq git
git config --global color.branch auto
git config --global color.diff auto
git config --global color.status auto


###############
# Ondřej Surý #
###############

echo "[BOOTSTRAP] Adding LAMP repositories..."
sudo add-apt-repository -y ppa:ondrej/php5-5.6
sudo add-apt-repository -y ppa:ondrej/apache2
sudo add-apt-repository -y ppa:ondrej/mysql-5.6
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E5267A6C


echo "[BOOTSTRAP] Updating repositories..."
sudo apt-get update -qq
sudo apt-get upgrade -qq


###########
# Apache2 #
###########

echo "[BOOTSTRAP] Installing Apache2..."
sudo apt-get install -y -qq apache2

echo "[BOOTSTRAP] Applying nasty fix to /apache2: Could not reliably determine the server's fully qualified domain name/ error..."
echo "ServerName $SERVER_NAME" >> /etc/apache2/apache2.conf


echo "[BOOTSTRAP] Configuring overrides globally for Apache2..."
sudo rm -rf /var/www/html
VHOST=$(cat <<EOF
<VirtualHost *:80>
  ServerName $SERVER_NAME
  ServerAlias $SERVER_ALIAS
  DocumentRoot /var/www
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

echo "[BOOTSTRAP] Adding vagrant user to www-data group..."
usermod -a -G vagrant www-data


echo "[BOOTSTRAP] Enabling Apache2 modules..."
sudo a2enmod rewrite
sudo a2enmod expires
sudo a2enmod headers
sudo a2enmod actions


echo "[BOOTSTRAP] Restarting Apache2..."
sudo service apache2 restart


########
# PHP5 #
########

echo "Setup PHP 5."
sudo apt-get install -y php5 php5-gd php5-sqlite php5-pgsql php5-ldap php5-common php5-geoip php5-redis php5-memcache php5-memcached  php5-mysql php5-xsl php5-curl php5-mcrypt php5-intl php-pear php5-cli php5-dev libapache2-mod-php5 php-apc php-pear php5-json php5-xdebug
sudo mv /etc/php5/apache2/php.ini /etc/php5/apache2/php.ini.bak
sudo cp -s /usr/share/php5/php.ini-development /etc/php5/apache2/php.ini
sed -i 's#;date.timezone\([[:space:]]*\)=\([[:space:]]*\)*#date.timezone\1=\2\"'"$timezone"'\"#g' /etc/php5/apache2/php.ini
sed -i 's#display_errors = Off#display_errors = On#g' /etc/php5/apache2/php.ini
sed -i 's#display_startup_errors = Off#display_startup_errors = On#g' /etc/php5/apache2/php.ini
sed -i 's#error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT#error_reporting = E_ALL#g' /etc/php5/apache2/php.ini
sed -i 's#;date.timezone\([[:space:]]*\)=\([[:space:]]*\)*#date.timezone\1=\2\"'"$timezone"'\"#g' /etc/php5/cli/php.ini
sed -i 's#display_errors = Off#display_errors = On#g' /etc/php5/cli/php.ini
sed -i 's#display_startup_errors = Off#display_startup_errors = On#g' /etc/php5/cli/php.ini
sed -i 's#error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT#error_reporting = E_ALL#g' /etc/php5/cli/php.ini
sudo a2enmod php5
sudo php5enmod mcrypt # Needs to be activated manually (that's an issue for Ubuntu 14.04)

echo "[BOOTSTRAP] Restarting Apache2..."
sudo service apache2 restart


############
# Composer #
############

echo "[BOOTSTRAP] Checking if Composer has already been installed..."
if [ ! -f /usr/local/bin/composer ];
  then
    echo "[BOOTSTRAP] Composer doesn't exitsts. Installing..."
    curl  -s -L https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
    chmod a+x /usr/local/bin/composer
  else
    echo "[BOOTSTRAP] Composer has already been installed. Self update..."
    composer self-update
fi


#############
#   MySQL   #
#############

echo "[BOOTSTRAP] Setting up selections for MySQL installer..."
echo "mysql-server mysql-server/root_password password $MYSQL_PASSWORD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD" | debconf-set-selections


echo "[BOOTSTRAP] Installing MySQL..."
# Install MySQL without prompt
sudo apt-get install -y mysql-server-5.6 mysql-client-5.6


echo "[BOOTSTRAP] Configuring MySQL server listen to all connection..."
sudo sed -i "s/bind-address.*=.*/bind-address=0.0.0.0/" /etc/mysql/my.cnf
MYSQLGRANT="GRANT ALL ON *.* to root@'%' IDENTIFIED BY '$MYSQL_PASSWORD'; FLUSH PRIVILEGES;"
mysql -u root -p$MYSQL_PASSWORD mysql -e "${MYSQLGRANT}"


echo "[BOOTSTRAP] Creating a main database..."
mysql -u root -p$MYSQL_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $DEFAULT_DATABASE_NAME;"
sudo service mysql restart


###########
# Adminer #
###########

echo "[BOOTSTRAP] Checking if Adminer has already been installed..."
if [ ! -f /usr/share/adminer/adminer.php ];
  then
    echo "[BOOTSTRAP] Adminer doesn't exitsts. Installing..."
    sudo mkdir /usr/share/adminer
    sudo curl -s -L -o /usr/share/adminer/latest.php "http://www.adminer.org/latest.php"
    sudo ln -s /usr/share/adminer/latest.php /usr/share/adminer/adminer.php
    echo "Alias /adminer.php /usr/share/adminer/adminer.php" | sudo tee /etc/apache2/conf-available/adminer.conf
    sudo a2enconf adminer
  else
    echo "[BOOTSTRAP] Adminer has already been installed. Skipping..."
fi


########
# PEAR #
########

echo "[BOOTSTRAP] Installing PEAR..."
sudo pear channel-update PEAR
sudo pear upgrade PEAR


#########
# Phing #
#########

echo "[BOOTSTRAP] Installing Phing..."
sudo pear channel-discover pear.phing.info
sudo pear install phing/phing


###################
# PHP_CodeSniffer #
###################

echo "[BOOTSTRAP] Checking if PHP_CodeSniffer has already been installed..."
if [ ! -f /usr/bin/phpcs ];
  then
    echo "[BOOTSTRAP] PHP_CodeSniffer doesn't exitsts. Installing..."
    sudo pear install PHP_CodeSniffer
  else
    echo "[BOOTSTRAP] PHP_CodeSniffer has already been installed. Skipping..."
fi


###############
# MailCatcher #
###############

echo "[BOOTSTRAP] Checking if MailCatcher has already been installed..."
if [ ! -f /usr/local/bin/mailcatcher ];
  then
    echo "[BOOTSTRAP] MailCatcher doesn't exitsts. Installing..."
    sudo gem install mailcatcher --no-ri --no-rdoc
    mailcatcher --http-ip=$VAGRANT_IP_ADDRESS
  else
    echo "[BOOTSTRAP] MailCatcher has already been installed. Skipping..."
fi


###########
# Postfix #
###########

echo "[BOOTSTRAP] Preconfiguring postfix selections..."
echo postfix postfix/mailname string $SERVER_NAME | debconf-set-selections
echo postfix postfix/main_mailer_type string 'Internet Site' | debconf-set-selections

echo "[BOOTSTRAP] Installing  postfix..."
sudo apt-get install -y postfix
service postfix reload


#############
# Oh My Zsh #
#############

echo "[BOOTSTRAP] Installing zsh shell first..."
sudo apt-get install -y -qq zsh

echo "[BOOTSTRAP] Checking if Oh My Zsh has already been installed..."
if [ ! -f ~/.oh-my-zsh ];
  then
    echo "[BOOTSTRAP] Oh My Zsh doesn't exitsts. Installing..."
	curl -s -L http://install.ohmyz.sh | sh
  else
    echo "[BOOTSTRAP] Oh My Zsh has already been installed. Skipping..."
fi


###############
# n98-magerun #
###############

echo "[BOOTSTRAP] Checking if n98-magerun has already been installed..."
if [ ! -f /usr/local/bin/n98-magerun.phar ];
  then
    echo "[BOOTSTRAP] n98-magerun doesn't exitsts. Installing..."
    curl -s -L -o n98-magerun.phar https://raw.githubusercontent.com/netz98/n98-magerun/master/n98-magerun.phar
    sudo chmod +x ./n98-magerun.phar
    sudo mv ./n98-magerun.phar /usr/local/bin/
  else
    echo "[BOOTSTRAP] modman has already been installed. Self update..."
    n98-magerun.phar self-update
fi


##########
# modgit #
##########

echo "[BOOTSTRAP] Checking if modgit has already been installed..."
if [ ! -f /usr/local/bin/modgit ];
  then
    echo "[BOOTSTRAP] modgit doesn't exitsts. Installing..."
    curl -s -L https://raw.github.com/jreinke/modgit/master/modgit > modgit
    sudo chmod +x modgit
    sudo mv modgit /usr/local/bin
  else
    echo "[BOOTSTRAP] modgit has already been installed. Skipping..."
fi


##########
# modman #
##########


echo "[BOOTSTRAP] Checking if modman has already been installed..."
if [ ! -f /usr/local/bin/modman ];
  then
    echo "[BOOTSTRAP] modman doesn't exitsts. Installing..."
    curl -s -L https://raw.githubusercontent.com/colinmollenhour/modman/master/modman -o modman
    sudo chmod +x modman
    sudo mv modman /usr/local/bin
  else
    echo "[BOOTSTRAP] modman has already been installed. Skipping..."
fi


######################
# Symfony2 Installer #
######################


echo "[BOOTSTRAP] Checking if Symfony2 Installer has already been installed..."
if [ ! -f /usr/local/bin/symfony ];
  then
    echo "[BOOTSTRAP] Symfony2 Installer doesn't exitsts. Installing..."
    curl -LsS http://symfony.com/installer > symfony.phar
    sudo mv symfony.phar /usr/local/bin/symfony
    sudo chmod a+x /usr/local/bin/symfony
  else
    echo "[BOOTSTRAP] Symfony2 Installer has already been installed. Skipping..."
fi


###########
# XDdebug #
###########

echo "[BOOTSTRAP] Configuring XDdebug..."

# xdebug.remote_connect_back=1 Most people don't want it to be set to true. It doesn't allow you to debug CLI scripts remotely (XDdebug doesn't know the clients IP address, so it doesn't know where to send debug data).

sudo cp /dev/null /etc/php5/cli/conf.d/20-xdebug.ini
sudo cp /dev/null /etc/php5/apache2/conf.d/20-xdebug.ini
cat << EOF | sudo tee -a /etc/php5/mods-available/xdebug.ini
zend_extension="$(find /usr/lib/php5 -name xdebug.so)"
xdebug.remote_autostart=1 ;You most likely don't need it. It starts the debugger session every time you run a script. If you're working on DEV only environment with CLI scripts, you can speed up development by enabling it.
xdebug.cli_color=1
xdebug.max_nesting_level = 1000000
xdebug.remote_connect_back=1
xdebug.remote_enable=1
xdebug.remote_handler=dbgp
xdebug.remote_host=$HOST_IP_ADDRESS ; Default IP address for VirtualBox host machine.
xdebug.remote_log="/tmp/log/xdebug.log"
xdebug.remote_port=9000
xdebug.scream=1
xdebug.show_exception_trace=On
xdebug.show_local_vars=1
xdebug.trace_format=1
xdebug.var_display_max_children = 256
xdebug.var_display_max_data = 1024
xdebug.var_display_max_depth = 5
EOF


################
# Post install #
################

echo "[BOOTSTRAP] Setting hostname..."
sudo hostname $SERVER_NAME


echo "[BOOTSTRAP] Restarting Apache2..."
sudo service apache2 restart


echo "[BOOTSTRAP] Cleaning up..."
sudo dpkg --configure -a # when upgrade or install doesnt run well (e.g. loss of connection) this may resolve quite a few issues
sudo apt-get autoremove -y
sudo apt-get autoclean -y
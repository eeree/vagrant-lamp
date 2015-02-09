#!/usr/bin/env bash

echo "[BOOTSTRAP] Importing config file..."
. /vagrant/.vagrant_bootstrap/bootstrap.cfg


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
sudo pear channel-update pear
sudo pear upgrade pear


#########
# Phing #
#########

echo "[BOOTSTRAP] Installing Phing..."
sudo pear channel-discover pear.phing.info
sudo pear install phing/phing


###########################
# PHP Copy/Paste Detector #
###########################

echo "[BOOTSTRAP] Checking if PHP Copy/Paste Detector has already been installed..."
if [ ! -f /usr/bin/phpcpd ];
  then
    echo "[BOOTSTRAP] PHP Copy/Paste Detector doesn't exitsts. Installing..."
    curl -sLo phpcpd.phar https://phar.phpunit.de/phpcpd.phar
    chmod +x phpcpd.phar
    mv phpcpd.phar /usr/local/bin/phpcpd
  else
    echo "[BOOTSTRAP] PHP Copy/Paste Detector has already been installed. Skipping..."
fi


#####################
# PHP Mess Detector #
#####################

echo "[BOOTSTRAP] Installing PHP Mess Detector..."
sudo pear channel-discover pear.phpmd.org
sudo pear channel-discover pear.pdepend.org
sudo pear install --alldeps phpmd/PHP_PMD

# ie.
# phpmd /path/to/source_file.php text codesize,unusedcode,naming

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


#############
# Oh My Zsh #
#############

echo "[BOOTSTRAP] Checking if Oh My Zsh has already been installed..."
if [ ! -f ~/.oh-my-zsh ];
  then
    echo "[BOOTSTRAP] Oh My Zsh doesn't exitsts. Installing..."
        curl -L http://install.ohmyz.sh | sed -n '/chsh/!p' | sed -n '/env zsh/!p' | sed -n '/^\. ~\/\.zshrc/!p' > /tmp/oh-my-zsh-install.sh
        sh /tmp/oh-my-zsh-install.sh
        rm /tmp/oh-my-zsh-install.sh 
        sudo chsh -s $(which zsh) `whoami`
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


##############################
# PHP Coding Standards Fixer #
##############################


echo "[BOOTSTRAP] Checking if PHP Coding Standards Fixer has already been installed..."
if [ ! -f /usr/local/bin/php-cs-fixer ];
  then
    echo "[BOOTSTRAP] PHP Coding Standards Fixer doesn't exitsts. Installing..."
    curl -LsS http://get.sensiolabs.org/php-cs-fixer.phar -o /usr/local/bin/php-cs-fixer
    sudo chmod a+x /usr/local/bin/php-cs-fixer
  else
    echo "[BOOTSTRAP] PHP Coding Standards Fixer has already been installed. Self-update..."
    php-cs-fixer self-update
fi


##############################
# PHP Depend #
##############################


echo "[BOOTSTRAP] Checking if PHP Coding Standards Fixer has already been installed..."
if [ ! -f /usr/local/bin/pdepend ];
  then
    echo "[BOOTSTRAP] PHP Coding Standards Fixer doesn't exitsts. Installing..."
    curl -LsS http://static.pdepend.org/php/latest/pdepend.phar -o /usr/local/bin/pdepend
    sudo chmod a+x /usr/local/bin/pdepend
  else
    echo "[BOOTSTRAP] PHP Coding Standards Fixer has already been installed. Skipping..."
fi



##########
# PHPLOC #
##########


echo "[BOOTSTRAP] Checking if PHPLOC has already been installed..."
if [ ! -f /usr/local/bin/phploc ];
  then
    echo "[BOOTSTRAP] PHPLOC doesn't exitsts. Installing..."
    curl -LsS https://phar.phpunit.de/phploc.phar -o /usr/local/bin/phploc
    sudo chmod a+x /usr/local/bin/phploc
  else
    echo "[BOOTSTRAP] PHPLOC has already been installed. Skipping..."
fi

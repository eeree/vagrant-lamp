# vagrant-lamp
Custom development environment with PHP 5.6, Apache 2.4, MySQL 5.6, XDebug, Composer and some other tools.

# What's that?
It's my custom development box based on [Vagrant](https://www.vagrantup.com/). It uses a standard shell provisioning provider, so there is no need to configure PuPHet nor Chief. 

# What's included?

* Ubuntu Trusty Tahr 14.04 x64
* PHP 5.6
* MySQL 5.6
* Apache 2.4
* Git
* XDebug
* PhpMyAdmin 4.3.x
* Adminer 4.x
* MailCatcher 0.5.x
* PHP_CodeSniffer
* Composer
* PEAR
* Phing

# How to install?

1. Install:
`
[Vagrant](https://www.vagrantup.com/)
`
`
[Oracle VirtualBox](https://www.virtualbox.org/)
`
2. Clone this repository:
`
git clone https://github.com/eeree/vagrant-lamp.git vagrant-lamp
`
3. Navigate to a newly created directory:
`
cd vagrant-lamp
`
4. Run Vagrant
`
vagrant up
`


**That's all!**
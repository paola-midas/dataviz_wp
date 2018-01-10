FROM ubuntu:latest
RUN apt-get update \
	&& apt-get -y upgrade \
	&& apt-get -y autoclean
	&& apt-get -y autoremove

RUN DEBIAN_FRONTEND=noninteractive

# utilities dependencies dependencies
RUN apt-get install -y \
	apt-utils \
	build-essential \
	curl \
	git \
	iptables \
	pwgen \
	software-properties-common \
	vim \
	vim-common

# install language pack required to add PPA
RUN apt-get update \
	&& apt-get install -qy language-pack-en-base \
	&& locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8


# add PPA for PHP 7
RUN apt-get update \
		&& apt-get install -qy \
			php7.2 \
			php7.2-fpm \
			php7.2-dom \
			php7.2-dev \
			php7.2-cli \
			php7.2-common \
			php7.2-intl \
			php7.2-bcmath \
			php7.2-mbstring \
			php7.2-xml \
			php7.2-zip \
			php7.2-json \
			php7.2-gd \
			php7.2-curl \
			php7.2-mcrypt \
			php7.2-mysql \
			php7.2-sqlite \
			php-memcached

# Wordpress installation
ADD ./config/000-default.conf /etc/apache2/sites-available/000-default.conf
RUN rm -rf /var/www/
ADD https://wordpress.org/latest.tar.gz /wordpress.tar.gz
RUN tar xvzf /wordpress.tar.gz
RUN mv /wordpress /var/www/
RUN chown -R www-data:www-data /var/www/

chown www-data:www-data /var/www/wp-config.php

# mysql installation
if [ ! -f /var/www/wp-config.php ]; then
#mysql has to be started this way as it doesn't work to call from /etc/init.d
/usr/bin/mysqld_safe &
sleep 10s
# Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
WORDPRESS_DB="wordpress"
MYSQL_PASSWORD=`pwgen -c -n -1 12`
WORDPRESS_PASSWORD=`pwgen -c -n -1 12`
#This is so the passwords show up in logs.
echo mysql root password: $MYSQL_PASSWORD
echo wordpress password: $WORDPRESS_PASSWORD
echo $MYSQL_PASSWORD > /mysql-root-pw.txt
echo $WORDPRESS_PASSWORD > /wordpress-db-pw.txt
#there used to be a huge ugly line of sed and cat and pipe and stuff below,
#but thanks to @djfiander's thing at https://gist.github.com/djfiander/6141138
#there isn't now.

sed -e "s/database_name_here/$WORDPRESS_DB/
s/username_here/$WORDPRESS_DB/
s/password_here/$WORDPRESS_PASSWORD/
/'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" /var/www/wp-config-sample.php > /var/www/wp-config.php

mysqladmin -u root password $MYSQL_PASSWORD
mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE wordpress; GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost' IDENTIFIED BY '$WORDPRESS_PASSWORD'; FLUSH PRIVILEGES;"
killall mysqld

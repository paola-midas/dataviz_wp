FROM ubuntu:latest
# Set the working directory to /app
WORKDIR /backend

# Copy the current directory contents into the container at /app
ADD . /backend

RUN apt-get update \
	&& apt-get -y upgrade \
	&& apt-get -y autoclean \
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
			php7.0 \
			php7.0-fpm \
			php7.0-dom \
			php7.0-dev \
			php7.0-cli \
			php7.0-common \
			php7.0-intl \
			php7.0-bcmath \
			php7.0-mbstring \
			php7.0-xml \
			php7.0-zip \
			php7.0-json \
			php7.0-gd \
			php7.0-curl \
			php7.0-mcrypt \
			php7.0-mysql \
			php7.0-sqlite \
			php-memcached

# mysql installation
RUN chmod 755 scripts/mysql.sh

# Wordpress installation
ADD ./config/000-default.conf /etc/apache2/sites-available/000-default.conf
RUN rm -rf /var/www/
ADD https://wordpress.org/latest.tar.gz /wordpress.tar.gz
RUN tar xvzf /wordpress.tar.gz
ADD https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar /wp-cli.phar

RUN mv /wordpress /var/www/
RUN chown -R www-data:www-data /var/www/
RUN find /var/www -type d -exec chmod 775 {} \;
RUN find /var/www -type f -exec chmod 664 {} \;


RUN chown www-data:www-data /var/www/wp-config.php



# Define environment variable
ENV NAME backend

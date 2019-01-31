FROM php:7.2-apache

ENV COMPOSER_ALLOW_SUPERUSER=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        wget \
        zlib1g-dev \
        zip \
        unzip \
        bzip2 \
        libmcrypt-dev \
        libicu-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libgd-dev \
        libxslt1.1 \
        libxslt1-dev \
        rsync \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install \
        bcmath \
        intl \
        gd \
        exif \
        xsl \
        mysqli \
        pdo_mysql \
        soap \
        zip

ADD ./php/custom.ini /usr/local/etc/php/conf.d/custom.ini

# create composer cache-directory
RUN mkdir -p /.composer

# install Composer and make it available in the PATH
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# composer parallel install plugin
RUN composer global require "hirak/prestissimo:^0.3"
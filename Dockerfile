FROM php:7.3-apache

ENV COMPOSER_ALLOW_SUPERUSER=1

RUN apt-get --allow-releaseinfo-change update \
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
        gpg \
        dirmngr \
        gpg-agent \
        libzip-dev \
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
        zip \
        sockets

RUN pecl install redis xdebug && docker-php-ext-enable redis xdebug

ADD ./php/custom.ini /usr/local/etc/php/conf.d/custom.ini

# create composer cache-directory
RUN mkdir -p /.composer

# install Composer and make it available in the PATH
RUN curl -sS https://getcomposer.org/download/1.10.17/composer.phar -o /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer

# composer parallel install plugin
RUN composer global require "hirak/prestissimo:^0.3"

RUN echo 'xdebug.profiler_enable_trigger = On' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo 'xdebug.profiler_output_dir = /tmp' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo 'xdebug.profiler_output_name = xdebug.out.%p' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# nodejs

RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

RUN mkdir ~/.gnupg
RUN chmod 0600 ~/.gnupg
RUN echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf

# gpg keys listed at https://github.com/nodejs/node
RUN set -ex \
  && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    74F12602B6F1C4E913FAA37AD3A89613643B6201 \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    108F52B48DB57BB0CC439B2997B01419BD92F80A \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
  ; do \
    gpg --keyserver keys.openpgp.org --recv-keys "$key"; \
  done

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 16.13.0

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

ENV YARN_VERSION 1.22.15



RUN set -ex \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --keyserver keys.openpgp.org --recv-keys "$key"; \
  done \
  && curl -fSL -o yarn.js "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-legacy-$YARN_VERSION.js" \
  && curl -fSL -o yarn.js.asc "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-legacy-$YARN_VERSION.js.asc" \
  && gpg --batch --verify yarn.js.asc yarn.js \
  && rm yarn.js.asc \
  && mv yarn.js /usr/local/bin/yarn \
  && chmod +x /usr/local/bin/yarn

RUN npm install --global gulp-cli
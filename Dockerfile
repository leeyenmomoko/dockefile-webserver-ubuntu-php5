# Dockerfile - Ubuntu Trusty
# https://github.com/openresty/docker-openresty

FROM ubuntu:trusty

MAINTAINER Lee Yen <leeyenwork@gmail.com>

ENV TERM xterm

# Docker Build Arguments
ARG RESTY_VERSION="1.11.2.1"
ARG RESTY_LUAROCKS_VERSION="2.3.0"
ARG RESTY_OPENSSL_VERSION="1.0.2h"
ARG RESTY_PCRE_VERSION="8.39"
ARG RESTY_J="1"
ARG RESTY_CONFIG_OPTIONS="\
    --prefix=/opt/openresty \
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \
    "

# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="--with-openssl=/tmp/openssl-${RESTY_OPENSSL_VERSION} --with-pcre=/tmp/pcre-${RESTY_PCRE_VERSION}"


# 1) Install apt dependencies
# 2) Download and untar OpenSSL, PCRE, and OpenResty
# 3) Build OpenResty
# 4) Cleanup

RUN \
    DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        libgd-dev \
        libgeoip-dev \
        libncurses5-dev \
        libperl-dev \
        libreadline-dev \
        libxslt1-dev \
        make \
        perl \
        unzip \
        zlib1g-dev \
    && cd /tmp \
    && curl -fSL https://www.openssl.org/source/openssl-${RESTY_OPENSSL_VERSION}.tar.gz -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && curl -fSL https://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${RESTY_PCRE_VERSION}.tar.gz -o pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && tar xzf pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
    && cd /tmp/openresty-${RESTY_VERSION} \
    && ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && cd /tmp \
    && rm -rf \
        openssl-${RESTY_OPENSSL_VERSION} \
        openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
        openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} \
        pcre-${RESTY_PCRE_VERSION}.tar.gz pcre-${RESTY_PCRE_VERSION} \
    && curl -fSL http://luarocks.org/releases/luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz -o luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && tar xzf luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && cd luarocks-${RESTY_LUAROCKS_VERSION} \
    && ./configure \
        --prefix=/opt/openresty/luajit \
        --with-lua=/opt/openresty/luajit \
        --lua-suffix=jit-2.1.0-beta2 \
        --with-lua-include=/opt/openresty/luajit/include/luajit-2.1 \
    && make build \
    && make install \
    && cd /tmp \
    && rm -rf luarocks-${RESTY_LUAROCKS_VERSION} luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && DEBIAN_FRONTEND=noninteractive apt-get autoremove -y \
    && ln -sf /dev/stdout /opt/openresty/nginx/logs/access.log \
    && ln -sf /dev/stderr /opt/openresty/nginx/logs/error.log

# PHP
RUN apt-get install -y build-essential curl wget libcurl4-openssl-dev libxml2-dev php-apc \
    php-gettext php-pear php5-imagick php5-curl php5-dev libgpgme11-dev libpcre3-dev \
    php5-fpm php5-gd php5-imap php5-redis \
    php5-mcrypt php5-mysqlnd php5-sybase php5-xdebug \
    php5-intl git \
    && curl -sL https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && pecl install -f solr-2.4.0 \
    && pecl install -f mysqlnd_ms \
    && pecl install -f gnupg \
    && pear clear-cache \
    && pear update-channels \
    && pear upgrade \
    && pecl install mongodb \
    && echo "extension=gnupg.so" >> /etc/php5/mods-available/gnupg.ini \
    && ln -s /etc/php5/mods-available/gnupg.ini /etc/php5/cli/conf.d/20-gnupg.ini \
    && ln -s /etc/php5/mods-available/gnupg.ini /etc/php5/fpm/conf.d/20-gnupg.ini \
    && echo "extension=solr.so" > /etc/php5/mods-available/solr.ini \
    && ln -s /etc/php5/mods-available/solr.ini /etc/php5/cli/conf.d/20-solr.ini \
    && ln -s /etc/php5/mods-available/solr.ini /etc/php5/fpm/conf.d/20-solr.ini \
    && echo "extension=mysqlnd_ms.so" > /etc/php5/mods-available/mysqlnd_ms.ini \
    && ln -s /etc/php5/mods-available/mysqlnd_ms.ini /etc/php5/cli/conf.d/20-mysqlnd_ms.ini \
    && ln -s /etc/php5/mods-available/mysqlnd_ms.ini /etc/php5/fpm/conf.d/20-mysqlnd_ms.ini \
    && echo "extension=mongodb.so" > /etc/php5/mods-available/mongodb.ini \
    && ln -s /etc/php5/mods-available/mongodb.ini /etc/php5/cli/conf.d/20-mongodb.ini \
    && ln -s /etc/php5/mods-available/mongodb.ini /etc/php5/fpm/conf.d/20-mongodb.ini

RUN apt-get remove -y vim-common
RUN apt-get install -y vim nano

RUN echo 'LANG="en_US.UTF-8"' > /etc/default/locale && \
    echo 'LANG="zh_TW.UTF-8"' > /etc/default/locale && \
    echo 'LANG="zh_HK.UTF-8"' > /etc/default/locale && \
    echo 'LANG="zh_CN.UTF-8"' > /etc/default/locale && \
    echo 'LANG="th_TH.UTF-8"' > /etc/default/locale && \
    echo 'LANG="id_ID.UTF-8"' > /etc/default/locale && \
    echo 'LANG="ko_KR.UTF-8"' > /etc/default/locale && \
    echo 'LANG="ja_JP.UTF-8"' > /etc/default/locale && \
    locale-gen en_US.UTF-8 && \
    locale-gen zh_TW.UTF-8 && \
    locale-gen zh_CN.UTF-8 && \
    locale-gen zh_HK.UTF-8 && \
    locale-gen th_TH.UTF-8 && \
    locale-gen id_ID.UTF-8 && \
    locale-gen ko_KR.UTF-8 && \
    locale-gen ja_JP.UTF-8

COPY ./configs/php5/cli/php.ini /etc/php5/cli/php.ini
COPY ./configs/php5/fpm/php.ini /etc/php5/fpm/php.ini
COPY ./configs/php5/fpm/www.conf /etc/php5/fpm/pool.d/www.conf
COPY ./configs/php5/mysqlnd_ms_plugin.ini /etc/eztable/php5/mysqlnd_ms_plugin.ini
COPY ./bin/start.sh /root/start.sh

RUN mkdir /opt/openresty/nginx/conf/conf.d
COPY ./configs/nginx/nginx.conf /opt/openresty/nginx/conf/nginx.conf
COPY ./configs/nginx/conf.d/php.conf /opt/openresty/nginx/conf/conf.d/php.conf
COPY ./configs/nginx/conf.d/servers /opt/openresty/nginx/conf/conf.d/servers

RUN echo "<?php echo 'Ok'; ?>" > /opt/openresty/nginx/html/index.php

EXPOSE 80 9000
#VOLUME ["/www-data"]

#ENTRYPOINT ["/opt/openresty/bin/openresty", "-g", "daemon off;"]
ENTRYPOINT ["bash", "/root/start.sh"]

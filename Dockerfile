FROM alpine
MAINTAINER Alex Neamtu <alexneamtu@gmail.com>

RUN apk update
RUN apk add \
    vim	bash apache2 php7-apache2 curl ca-certificates openssl openssh git \
    php7 php7-phar php7-json php7-iconv php7-openssl tzdata openntpd nano

RUN cp /usr/bin/php7 /usr/bin/php \
    && rm -f /var/cache/apk/*

RUN apk add \
    php-bcmath \
    php-ctype \
    php-curl \
    php-dom \
    php-gd \
    php-intl \
    php-mbstring \
    php-pdo_mysql \
    php-simplexml \
    php-soap \
    php-xsl \
    php-zip \
    php-fileinfo \
    php-sockets \
    php-tokenizer \
    php-xmlwriter \
    php-xml \
    php-sodium \
    php-session

RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

RUN sed -i "s/#LoadModule\ rewrite_module/LoadModule\ rewrite_module/" /etc/apache2/httpd.conf \
    && sed -i "s#^DocumentRoot \".*#DocumentRoot \"/app/pub\"#g" /etc/apache2/httpd.conf \
    && sed -i "s#/var/www/localhost/htdocs#/app/pub#" /etc/apache2/httpd.conf \
    && printf "\n<Directory \"/app/pub\">\n\tAllowOverride All\n</Directory>\n" >> /etc/apache2/httpd.conf

RUN git clone https://github.com/magento/magento2.git /app

# RUN   mkdir /app && mkdir /app/public && chown -R apache:apache /app && chmod -R 755 /app && 
RUN mkdir bootstrap

ADD start.sh /bootstrap/
ADD wait-for-it.sh /
RUN chmod +x /bootstrap/start.sh

RUN echo '{}' > /composer.json
RUN echo 'memory_limit=-1' >> /etc/php7/php.ini 

RUN chown apache:apache /app
RUN chown -R apache:apache /app/var
RUN chown -R apache:apache /app/pub
RUN chown -R apache:apache /app/generated

WORKDIR /app

RUN composer install

EXPOSE 80

ENTRYPOINT ["/bootstrap/start.sh"]

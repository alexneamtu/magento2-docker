#!/bin/sh

# Set the timezone. Base image does not contain the setup-timezone script, so an alternate way is used.
if [ "$CONTAINER_TIMEZONE" ]; then
    cp /usr/share/zoneinfo/${CONTAINER_TIMEZONE} /etc/localtime && \
	echo "${CONTAINER_TIMEZONE}" >  /etc/timezone && \
	echo "Container timezone set to: $CONTAINER_TIMEZONE"
fi

# Apache server name change
if [ ! -z "$APACHE_SERVER_NAME" ]
	then
		sed -i "s/#ServerName www.example.com:80/ServerName $APACHE_SERVER_NAME/" /etc/apache2/httpd.conf
		echo "Changed server name to '$APACHE_SERVER_NAME'..."
	else
		echo "NOTICE: Change 'ServerName' globally and hide server message by setting environment variable >> 'APACHE_SERVER_NAME=your.server.name' in docker command or docker-compose file"
fi

echo "Clearing any old processes..."
rm -f /run/apache2/apache2.pid
rm -f /run/apache2/httpd.pid

./wait-for-it.sh db:3306
./wait-for-it.sh es:9200

cd /app

bin/magento setup:install \
    --db-host db \
    --db-name magento \
    --db-user magento \
    --db-password magento \
    --elasticsearch-host es

bin/magento admin:user:create \
    --admin-user=admin \
    --admin-password=Magento1! \
    --admin-email=magento@email.com \
    --admin-firstname=Magento \
    --admin-lastname=Magento

bin/magento config:set web/unsecure/base_url http://magento2.docker:8080/

chown -R apache:apache /app/var/page_cache
chown -R apache:apache /app/var/cache
chown -R apache:apache /app/var/log
chown -R apache:apache /app/generated


echo "Starting apache..."
httpd -D FOREGROUND
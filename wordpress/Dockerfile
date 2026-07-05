FROM wordpress:6.4-apache

# Install WP-CLI
RUN curl -sL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp \
    && apt-get update && apt-get install -y less mariadb-client curl unzip \
    && rm -rf /var/lib/apt/lists/*

# Allow wordpress to run as www-data
RUN mkdir -p /var/www/.wp-cli && chown -R www-data:www-data /var/www/.wp-cli

# Custom apache config to set ServerName
RUN echo "ServerName cafeipmac.local" >> /etc/apache2/apache2.conf

COPY setup.sh /setup.sh
COPY plugins/ /plugins/

RUN chmod +x /setup.sh

# Override entrypoint to run setup after WP is ready
COPY docker-entrypoint-custom.sh /docker-entrypoint-custom.sh
RUN chmod +x /docker-entrypoint-custom.sh

ENTRYPOINT ["/docker-entrypoint-custom.sh"]
CMD ["apache2-foreground"]

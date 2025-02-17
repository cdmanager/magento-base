# Use PHP 8.1 with Apache as the base image
FROM php:8.1-apache AS base

# Install dependencies and PHP extensions
RUN apt-get update \
    && apt-get install -y git libfreetype6-dev libicu-dev \
    libjpeg62-turbo-dev libpng-dev libxml2-dev libxslt-dev libzip-dev unzip \
    && apt-get clean \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    bcmath \
    gd \
    intl \
    pdo_mysql \
    zip \
    xsl \
    soap \
    sockets \
    && a2enmod rewrite \
    && echo "memory_limit=2G" > /usr/local/etc/php/conf.d/memory-limit.ini


FROM base AS build

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set the working directory to /var/www/html
WORKDIR /var/www/html

# Copy initial files needed for installation into the current working directory
COPY composer.json auth.json Thumbnail.php ./

# Ensure proper ownership and permissions
RUN chown -R www-data:www-data /var/www /var/www/html  \
    && chmod -R 755 /var/www/html

# Switch to www-data user
USER www-data

# Create Composer cache directory and set permissions
#RUN mkdir -p /var/www/html/.composer \
#    && chown -R www-data:www-data /var/www/.composer \

RUN composer install --no-dev --optimize-autoloader --no-interaction \
    && echo "<h1>It works!</h1>" > /var/www/html/index.html

# Switch back to root to change Apache configuration
USER root

# remove auth.json
RUN rm auth.json
# Configure Apache to run as www-data and use port 8080
RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf \
    && sed -i 's/<VirtualHost \*:80>/<VirtualHost *:8080>/' /etc/apache2/sites-available/000-default.conf \
    && echo '<Directory /var/www/html>\n\
        Options Indexes FollowSymLinks\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>' > /etc/apache2/conf-available/html-dir.conf \
    && a2enconf html-dir

# Expose port 8080
EXPOSE 8080

FROM build AS install

# Switch back to www-data for running the application
USER www-data
ARG MAGENTO_CLI=/var/www/html/bin/magento

# Install Magento
RUN $MAGENTO_CLI setup:install \
    --base-url=https://magento.acme.com/ \
    --base-url-secure=https://magento.acme.com/ \
    --db-host=127.0.0.1 \
    --db-name=magento \
    --db-user=db_user \
    --db-password=db_password \
    --admin-firstname=Admin \
    --admin-lastname=User \
    --admin-email=admin@acme.com \
    --admin-user=admin \
    --admin-password=Admin123! \
    --language=en_US \
    --currency=USD \
    --timezone=America/New_York \
    --use-rewrites=1 \
    --search-engine=elasticsearch7 \
    --elasticsearch-host=127.0.0.1 && \
    $MAGENTO_CLI cache:clean && \
    $MAGENTO_CLI cache:flush

# Use a shell command to run the PHP script and then Apache
ENTRYPOINT ["apache2-foreground"]

# Use PHP 8.1 with Apache as the base image
FROM php:8.1-apache

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

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set the working directory to /var/www/html
WORKDIR /var/www/html

# Copy initial files needed for installation into the current working directory
COPY composer.json auth.json Thumbnail.php ./

# Ensure proper ownership and permissions
RUN chown -R www-data:www-data /var/www /var/www/html  \
    && chmod -R 755 /var/www/html

# Ensure proper ownership and permissions
RUN chown -R www-data:www-data /mnt/var-www && chmod -R 755 /mnt/var-www

# Switch to www-data user
USER www-data

# Create Composer cache directory and set permissions
#RUN mkdir -p /var/www/html/.composer \
#    && chown -R www-data:www-data /var/www/.composer \

RUN composer install --no-dev --optimize-autoloader --no-interaction \
    && echo "<h1>It works!</h1>" > /var/www/html/index.html

# Switch back to root to change Apache configuration
USER root

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

COPY install.php /usr/local/bin/
RUN chmod +x /usr/local/bin/install.php

# Switch back to www-data for running the application
USER www-data

# execute installation script
RUN php /usr/local/bin/install.php

# Use a shell command to run the PHP script and then Apache
ENTRYPOINT ["apache2-foreground"]

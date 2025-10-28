# Multi-PHP Version Dockerfile for YADS
# Supports PHP 7.4, 8.0, 8.1, 8.2, 8.3, 8.4

FROM php:8.4-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    oniguruma-dev \
    libzip-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    icu-dev \
    postgresql-dev \
    mysql-client \
    nodejs \
    npm \
    yarn \
    bash \
    vim \
    nano \
    htop \
    supervisor

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    pdo_pgsql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    intl \
    opcache \
    sockets

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Xdebug for development
RUN pecl install xdebug && docker-php-ext-enable xdebug

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Node.js tools
RUN npm install -g \
    @vue/cli \
    @angular/cli \
    create-react-app \
    typescript \
    nodemon \
    pm2 \
    yarn

# Install additional PHP tools
RUN composer global require \
    laravel/installer \
    symfony/cli \
    phpunit/phpunit \
    squizlabs/php_codesniffer \
    friendsofphp/php-cs-fixer \
    psalm/psalm \
    phpstan/phpstan

# Create user for development
RUN adduser -D -s /bin/bash developer && \
    echo 'developer:developer' | chpasswd && \
    adduser developer wheel

# Set working directory
WORKDIR /var/www/html

# Set permissions
RUN chown -R developer:developer /var/www/html

# Switch to developer user
USER developer

# Add Composer and global tools to PATH
ENV PATH="/home/developer/.composer/vendor/bin:${PATH}"

# Create supervisor configuration
USER root
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chown root:root /etc/supervisor/conf.d/supervisord.conf

# Create startup script
COPY scripts/start.sh /start.sh
RUN chmod +x /start.sh

# Expose ports
EXPOSE 9000 3000 8000

# Use supervisor to manage processes
CMD ["/start.sh"]

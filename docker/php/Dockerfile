FROM php:8.2-fpm-alpine

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
    yarn

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
    opcache

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Node.js tools
RUN npm install -g \
    @vue/cli \
    @angular/cli \
    create-react-app \
    typescript \
    nodemon \
    pm2

# Install additional PHP tools
RUN composer global require \
    laravel/installer \
    symfony/cli \
    phpunit/phpunit \
    squizlabs/php_codesniffer \
    friendsofphp/php-cs-fixer

# Set working directory
WORKDIR /var/www/html

# Create user for development
RUN adduser -D -s /bin/sh developer && \
    echo 'developer:developer' | chpasswd && \
    adduser developer wheel

# Set permissions
RUN chown -R developer:developer /var/www/html

# Switch to developer user
USER developer

# Install global Composer packages for developer
RUN composer global require \
    laravel/installer \
    symfony/cli

# Add Composer and global tools to PATH
ENV PATH="/home/developer/.composer/vendor/bin:${PATH}"

# Expose port
EXPOSE 9000

# Start PHP-FPM
CMD ["php-fpm"]

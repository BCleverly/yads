#!/bin/bash

# Domain configuration module for YADS

# Configure domains and SSL
configure_domains() {
    log "${CYAN}Configuring domains and SSL certificates...${NC}"
    
    # Get domain from user
    get_domain_input
    
    # Configure Cloudflare tunnel
    configure_cloudflare_tunnel
    
    # Configure SSL certificates
    configure_ssl
    
    # Update web server configuration
    update_web_server_config
    
    # Save configuration
    save_config
    
    success "Domain configuration completed!"
    info "Your development server is now accessible at: https://*.${DOMAIN}"
}

# Get domain input from user
get_domain_input() {
    if [[ -z "${DOMAIN:-}" ]]; then
        echo
        info "Domain Configuration"
        echo "Enter your domain name (e.g., mydev.com):"
        read -p "Domain: " DOMAIN
        
        if [[ -z "$DOMAIN" ]]; then
            error_exit "Domain is required"
        fi
    fi
    
    # Validate domain format
    if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        error_exit "Invalid domain format. Please enter a valid domain name."
    fi
    
    success "Domain set to: $DOMAIN"
}

# Configure Cloudflare tunnel
configure_cloudflare_tunnel() {
    info "Configuring Cloudflare tunnel..."
    
    # Check if Cloudflare token is provided
    if [[ -z "${CLOUDFLARE_TOKEN:-}" ]]; then
        echo
        info "Cloudflare Configuration"
        echo "To use Cloudflare tunnel, you need a Cloudflare API token."
        echo "Get your token from: https://dash.cloudflare.com/profile/api-tokens"
        echo "Required permissions: Zone:Read, DNS:Edit, Tunnel:Edit"
        echo
        read -p "Enter your Cloudflare API token (or press Enter to skip): " CLOUDFLARE_TOKEN
        
        if [[ -z "$CLOUDFLARE_TOKEN" ]]; then
            warning "Skipping Cloudflare tunnel configuration. You can configure it later."
            return
        fi
    fi
    
    # Authenticate with Cloudflare
    cloudflared tunnel login
    
    # Create tunnel
    TUNNEL_NAME="yads-$(hostname)"
    TUNNEL_ID=$(cloudflared tunnel create "$TUNNEL_NAME" | grep -o 'Created tunnel [a-f0-9-]*' | cut -d' ' -f3)
    
    if [[ -z "$TUNNEL_ID" ]]; then
        error_exit "Failed to create Cloudflare tunnel"
    fi
    
    # Create tunnel configuration
    sudo tee /etc/cloudflared/config.yml > /dev/null << EOF
tunnel: $TUNNEL_ID
credentials-file: /etc/cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: "*.$DOMAIN"
    service: http://localhost:80
  - hostname: "$DOMAIN"
    service: http://localhost:80
  - service: http_status:404
EOF
    
    # Create DNS records
    create_dns_records "$TUNNEL_ID"
    
    # Update systemd service
    sudo systemctl daemon-reload
    sudo systemctl restart cloudflared
    sudo systemctl enable cloudflared
    
    success "Cloudflare tunnel configured"
}

# Create DNS records
create_dns_records() {
    local tunnel_id="$1"
    
    info "Creating DNS records..."
    
    # Create wildcard CNAME record
    cloudflared tunnel route dns "$tunnel_id" "*.$DOMAIN"
    
    # Create root domain CNAME record
    cloudflared tunnel route dns "$tunnel_id" "$DOMAIN"
    
    success "DNS records created"
}

# Configure SSL certificates
configure_ssl() {
    info "Configuring SSL certificates..."
    
    # Install certbot if not already installed
    install_certbot
    
    # Configure SSL for wildcard domain
    configure_wildcard_ssl
    
    success "SSL certificates configured"
}

# Install certbot
install_certbot() {
    if command -v certbot &> /dev/null; then
        info "Certbot is already installed"
        return
    fi
    
    info "Installing certbot..."
    
    case "$OS" in
        "ubuntu"|"debian")
            sudo apt-get install -y certbot python3-certbot-nginx
            ;;
        "centos"|"rhel"|"fedora")
            sudo dnf install -y certbot python3-certbot-nginx
            ;;
        "arch")
            sudo pacman -S --noconfirm certbot certbot-nginx
            ;;
    esac
}

# Configure wildcard SSL
configure_wildcard_ssl() {
    info "Configuring wildcard SSL certificate..."
    
    # Get email for Let's Encrypt
    read -p "Enter your email for Let's Encrypt notifications: " EMAIL
    
    if [[ -z "$EMAIL" ]]; then
        error_exit "Email is required for SSL certificate"
    fi
    
    # Configure DNS challenge for wildcard certificate
    info "You'll need to add a TXT record to your DNS for domain validation."
    echo "Please add the following TXT record to your DNS:"
    echo "_acme-challenge.$DOMAIN"
    echo
    read -p "Press Enter after adding the TXT record..."
    
    # Request wildcard certificate
    sudo certbot certonly \
        --manual \
        --preferred-challenges dns \
        --server https://acme-v02.api.letsencrypt.org/directory \
        --agree-tos \
        --email "$EMAIL" \
        -d "$DOMAIN" \
        -d "*.$DOMAIN"
    
    if [[ $? -eq 0 ]]; then
        success "Wildcard SSL certificate obtained"
        
        # Set up auto-renewal
        setup_ssl_renewal
    else
        warning "Failed to obtain SSL certificate. You can try again later with 'yads domains'"
    fi
}

# Set up SSL certificate renewal
setup_ssl_renewal() {
    info "Setting up SSL certificate auto-renewal..."
    
    # Create renewal script
    sudo tee /usr/local/bin/yads-ssl-renewal.sh > /dev/null << 'EOF'
#!/bin/bash
# YADS SSL Certificate Renewal Script

certbot renew --quiet --nginx
if [[ $? -eq 0 ]]; then
    systemctl reload nginx
    echo "$(date): SSL certificates renewed successfully" >> /var/log/yads-ssl-renewal.log
fi
EOF
    
    sudo chmod +x /usr/local/bin/yads-ssl-renewal.sh
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/yads-ssl-renewal.sh") | crontab -
    
    success "SSL certificate auto-renewal configured"
}

# Update web server configuration for SSL
update_web_server_config() {
    info "Updating web server configuration for SSL..."
    
    if [[ "$WEB_SERVER" == "nginx" ]]; then
        update_nginx_ssl_config
    elif [[ "$WEB_SERVER" == "frankenphp" ]]; then
        update_frankenphp_ssl_config
    fi
}

# Update NGINX SSL configuration
update_nginx_ssl_config() {
    info "Updating NGINX configuration for SSL..."
    
    # Create SSL configuration
    sudo tee /etc/nginx/sites-available/ssl-default > /dev/null << EOF
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name $DOMAIN *.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS configuration
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    server_name $DOMAIN *.$DOMAIN;
    
    root /var/www/html;
    index index.php index.html index.htm;
    
    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/$DOMAIN/chain.pem;
    
    # SSL security settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Rate limiting
    limit_req zone=api burst=20 nodelay;
    
    # Main location block
    location / {
        try_files \$uri \$uri/ @fallback;
    }
    
    # Fallback for PHP applications
    location @fallback {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param HTTPS on;
        fastcgi_param HTTP_SCHEME https;
    }
    
    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Security - deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF
    
    # Enable SSL site
    sudo ln -sf /etc/nginx/sites-available/ssl-default /etc/nginx/sites-enabled/
    
    # Remove default HTTP site
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test configuration
    sudo nginx -t
    
    if [[ $? -eq 0 ]]; then
        sudo systemctl reload nginx
        success "NGINX SSL configuration updated"
    else
        error_exit "NGINX configuration test failed"
    fi
}

# Update FrankenPHP SSL configuration
update_frankenphp_ssl_config() {
    info "Updating FrankenPHP configuration for SSL..."
    
    # Update Caddyfile for SSL
    sudo tee /etc/frankenphp/Caddyfile > /dev/null << EOF
{
    auto_https off
    servers {
        protocols h1 h2 h3
    }
}

# HTTP redirect
:80 {
    redir https://{host}{uri} permanent
}

# HTTPS configuration
:443 {
    tls /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/letsencrypt/live/$DOMAIN/privkey.pem
    
    root * /var/www/html
    php_fastcgi unix//var/run/php/php8.4-fpm.sock
    file_server
    
    # Security headers
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Frame-Options DENY
        X-Content-Type-Options nosniff
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
    }
    
    # Static files caching
    @static {
        path *.jpg *.jpeg *.png *.gif *.ico *.css *.js *.woff *.woff2 *.ttf *.svg
    }
    header @static Cache-Control "public, max-age=31536000"
}
EOF
    
    # Restart FrankenPHP
    sudo systemctl restart frankenphp
    
    success "FrankenPHP SSL configuration updated"
}

# Create project-specific domain configuration
create_project_domain_config() {
    local project_name="$1"
    local project_domain="${project_name}.${DOMAIN}"
    local project_path="/var/www/html/${project_name}"
    
    info "Creating domain configuration for $project_name..."
    
    if [[ "$WEB_SERVER" == "nginx" ]]; then
        create_nginx_project_config "$project_name" "$project_domain" "$project_path"
    elif [[ "$WEB_SERVER" == "frankenphp" ]]; then
        create_frankenphp_project_config "$project_name" "$project_domain" "$project_path"
    fi
}

# Create NGINX project configuration
create_nginx_project_config() {
    local project_name="$1"
    local project_domain="$2"
    local project_path="$3"
    
    sudo tee "/etc/nginx/sites-available/${project_name}" > /dev/null << EOF
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    server_name $project_domain;
    
    root $project_path/public;
    index index.php index.html index.htm;
    
    # SSL configuration (inherited from main config)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Main location block
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param HTTPS on;
        fastcgi_param HTTP_SCHEME https;
    }
    
    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Security - deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF
    
    # Enable site
    sudo ln -sf "/etc/nginx/sites-available/${project_name}" "/etc/nginx/sites-enabled/"
    
    # Test and reload
    sudo nginx -t && sudo systemctl reload nginx
    
    success "NGINX configuration created for $project_name"
}

# Create FrankenPHP project configuration
create_frankenphp_project_config() {
    local project_name="$1"
    local project_domain="$2"
    local project_path="$3"
    
    # Add project configuration to main Caddyfile
    sudo tee -a /etc/frankenphp/Caddyfile > /dev/null << EOF

# Project: $project_name
$project_domain {
    tls /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/letsencrypt/live/$DOMAIN/privkey.pem
    
    root * $project_path/public
    php_fastcgi unix//var/run/php/php8.4-fpm.sock
    file_server
    
    # Security headers
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Frame-Options DENY
        X-Content-Type-Options nosniff
        X-XSS-Protection "1; mode=block"
    }
}
EOF
    
    # Restart FrankenPHP
    sudo systemctl restart frankenphp
    
    success "FrankenPHP configuration updated for $project_name"
}


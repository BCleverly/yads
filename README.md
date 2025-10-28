# YADS - Yet Another Development Server

🐳 **A modern, containerized remote development environment** with automatic SSL, subdomain routing, and Cloudflare tunnel integration.

## ✨ What is YADS?

YADS transforms any server into a powerful, containerized development environment with:

- 🐳 **Docker-based Architecture** - Everything runs in containers
- 🌐 **Automatic SSL** - Traefik handles SSL certificates via Cloudflare
- 🔗 **Subdomain Routing** - Each service gets its own subdomain
- ☁️ **Cloudflare Tunnels** - Secure internet access without port forwarding
- 💻 **VS Code Server** - Full IDE in your browser
- 🗄️ **Multiple Databases** - MySQL, PostgreSQL, Redis
- 🛠️ **Development Tools** - phpMyAdmin, pgAdmin, Portainer
- 📁 **Project Management** - Easy project creation and management

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Cloudflare account (for tunnels and SSL)
- Domain name (optional, can use localhost)

### 📦 Installation

#### Option 1: One-Liner Setup (Recommended)
```bash
git clone https://github.com/BCleverly/yads.git && cd yads && chmod +x setup-docker.sh && ./setup-docker.sh
```

#### Option 2: Step-by-Step Setup
```bash
# 1. Clone the repository
git clone https://github.com/BCleverly/yads.git
cd yads

# 2. Setup Docker environment
chmod +x setup-docker.sh
./setup-docker.sh

# 3. Configure environment
# Edit .env file with your settings
nano .env

# 4. Start services
./yads start
```

### 🔧 First-Time Setup

After installation, configure your development environment:

```bash
# 1. Check service status
yads status

# 2. Create your first project
yads project myapp laravel

# 3. Create database for your project
yads db create myapp mysql

# 4. Setup project dependencies (optional)
yads setup myapp
```

## 📋 Commands Reference

### 🎯 Core Commands
```bash
yads start           # Start all services
yads stop            # Stop all services
yads restart         # Restart all services
yads status          # Show service status
yads logs [service]  # Show logs for service
yads update          # Update containers
yads help            # Show help
yads version         # Show version
```

### 📁 Project Management
```bash
yads project myapp laravel    # Create Laravel project
yads project myapp symfony    # Create Symfony project
yads project myapp wordpress   # Create WordPress project
yads project myapp node        # Create Node.js project
yads setup myapp              # Setup project dependencies
yads stop-project myapp       # Stop project
yads list-projects            # List all projects
```

### 🗄️ Database Management
```bash
yads db create mydb mysql     # Create MySQL database
yads db create mydb postgres  # Create PostgreSQL database
yads db list                  # List all databases
```

### 🐳 Container Management
```bash
yads restart traefik         # Restart specific service
yads backup                  # Backup all data
```

## 🏗️ Architecture

### Core Services
- **Traefik** - Reverse proxy and load balancer with automatic SSL
- **Cloudflared** - Secure tunnel to Cloudflare network
- **VS Code Server** - Browser-based IDE
- **MySQL** - Database server with phpMyAdmin
- **PostgreSQL** - Database server with pgAdmin
- **Redis** - Caching and session storage
- **Nginx** - Web server with PHP-FPM
- **Portainer** - Docker management interface

### Service URLs
After starting YADS, access your services at:
- **Traefik Dashboard**: `https://traefik.yourdomain.com`
- **VS Code Server**: `https://code.yourdomain.com`
- **phpMyAdmin**: `https://phpmyadmin.yourdomain.com`
- **pgAdmin**: `https://pgadmin.yourdomain.com`
- **Portainer**: `https://portainer.yourdomain.com`
- **Your Projects**: `https://project-name.yourdomain.com`

## ⚙️ Configuration

### Environment Variables

Create a `.env` file with your configuration:

```bash
# Domain Configuration
DOMAIN=yourdomain.com
ACME_EMAIL=admin@yourdomain.com

# Cloudflare Configuration
CLOUDFLARE_API_TOKEN=your_cloudflare_api_token
CLOUDFLARE_TUNNEL_TOKEN=your_cloudflare_tunnel_token

# VS Code Server
VSCODE_PASSWORD=your_secure_password
VSCODE_SUDO_PASSWORD=your_sudo_password

# Database Configuration
MYSQL_ROOT_PASSWORD=your_mysql_root_password
MYSQL_PASSWORD=your_mysql_password
POSTGRES_PASSWORD=your_postgres_password
REDIS_PASSWORD=your_redis_password
```

### Cloudflare Setup

1. **Get API Token:**
   - Go to Cloudflare Dashboard → My Profile → API Tokens
   - Create token with Zone:Edit permissions

2. **Create Tunnel:**
   - Go to Cloudflare Dashboard → Zero Trust → Tunnels
   - Create new tunnel
   - Copy the tunnel token

3. **Configure DNS:**
   - Add CNAME records for your subdomains
   - Point to your tunnel domain

## 🐳 Adding Custom Containers

### Method 1: Edit docker-compose.custom.yml

```yaml
version: '3.8'

services:
  my-custom-app:
    image: nginx:alpine
    container_name: yads-my-custom-app
    restart: unless-stopped
    volumes:
      - ./projects/my-custom-app:/usr/share/nginx/html
    networks:
      - yads-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.my-custom-app.rule=Host(`my-custom-app.${DOMAIN:-localhost}`)"
      - "traefik.http.routers.my-custom-app.entrypoints=websecure"
      - "traefik.http.routers.my-custom-app.tls.certresolver=cloudflare"
      - "traefik.http.services.my-custom-app.loadbalancer.server.port=80"
```

### Method 2: Create separate docker-compose file

```bash
# Create your own docker-compose file
cat > docker-compose.my-app.yml << 'EOF'
version: '3.8'

services:
  my-app:
    build: ./projects/my-app
    container_name: yads-my-app
    restart: unless-stopped
    networks:
      - yads-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.my-app.rule=Host(`my-app.${DOMAIN:-localhost}`)"
      - "traefik.http.routers.my-app.entrypoints=websecure"
      - "traefik.http.routers.my-app.tls.certresolver=cloudflare"
      - "traefik.http.services.my-app.loadbalancer.server.port=3000"
EOF

# Start with your custom services
docker-compose -f docker-compose.yml -f docker-compose.my-app.yml up -d
```

## 🔧 Development Workflow

### 1. Create a New Project
```bash
# Create Laravel project
yads project myapp laravel

# Access at: https://myapp.yourdomain.com
```

### 2. Develop with VS Code Server
```bash
# Access VS Code Server
# URL: https://code.yourdomain.com
# Password: (from .env file)
```

### 3. Database Management
```bash
# MySQL: https://phpmyadmin.yourdomain.com
# PostgreSQL: https://pgadmin.yourdomain.com
```

### 4. Docker Management
```bash
# Portainer: https://portainer.yourdomain.com
# Or use: docker-compose ps
```

## 📁 Directory Structure

```
yads/
├── docker-compose.yml          # Core services
├── docker-compose.custom.yml  # Custom services
├── yads                       # Main CLI script
├── setup-docker.sh             # Setup script
├── .env                        # Environment configuration
├── data/                       # Persistent data
│   ├── traefik/               # Traefik data
│   ├── mysql/                 # MySQL data
│   ├── postgres/              # PostgreSQL data
│   ├── redis/                 # Redis data
│   ├── vscode/                # VS Code Server data
│   └── portainer/             # Portainer data
├── projects/                   # Your projects
│   └── sample/                 # Sample project
├── config/                     # Configuration files
│   ├── traefik/               # Traefik config
│   ├── nginx/                  # Nginx config
│   └── php/                    # PHP config
├── scripts/                    # Management scripts
│   ├── database-manager.sh     # Database operations
│   ├── container-orchestrator.sh # Container orchestration
│   └── project-manager.sh      # Project management
└── templates/                  # Project templates
    ├── php/                    # PHP template
    ├── laravel/                # Laravel template
    └── node/                   # Node.js template
```

## 🔒 Security Features

### SSL/TLS
- Automatic SSL certificates via Cloudflare
- HTTPS redirect for all services
- Modern TLS configuration

### Authentication
- VS Code Server password protection
- Basic auth for admin interfaces
- Secure database passwords

### Network Security
- Docker network isolation
- Cloudflare tunnel encryption
- Rate limiting and security headers

## 🚨 Troubleshooting

### Common Issues

#### Services not starting
```bash
# Check logs
yads logs

# Check specific service
yads logs traefik
```

#### SSL certificate issues
```bash
# Check Traefik logs
yads logs traefik

# Verify Cloudflare configuration
# Check .env file for correct tokens
```

#### Database connection issues
```bash
# Check database logs
yads logs mysql
yads logs postgres

# Verify database is running
yads status
```

### Debug Commands
```bash
# Check all containers
docker-compose ps

# Check logs for specific service
docker-compose logs -f traefik

# Restart specific service
docker-compose restart traefik

# Rebuild and restart
docker-compose up -d --build
```

## 🔄 Updates

### Update YADS
```bash
# Update all services
yads update

# Or manually
docker-compose pull
docker-compose up -d
```

### Update specific service
```bash
# Update Traefik
docker-compose pull traefik
docker-compose up -d traefik
```

## 📚 Examples

### Laravel Project
```bash
# Create Laravel project
yads project myapp laravel

# Access at: https://myapp.yourdomain.com
# Database: MySQL (via phpMyAdmin)
# IDE: VS Code Server
```

### Node.js Project
```bash
# Create Node.js project
yads project myapp node

# Access at: https://myapp.yourdomain.com
# Database: PostgreSQL (via pgAdmin)
# IDE: VS Code Server
```

### WordPress Site
```bash
# Create WordPress project
yads project myapp wordpress

# Access at: https://myapp.yourdomain.com
# Database: MySQL (via phpMyAdmin)
# IDE: VS Code Server
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with Docker setup
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/BCleverly/yads/issues)
- **Documentation**: [Wiki](https://github.com/BCleverly/yads/wiki)
- **Docker**: [Docker Hub](https://hub.docker.com/)

## 🎉 Features

- ✅ **Docker-based** - Everything in containers
- ✅ **Automatic SSL** - Traefik + Cloudflare
- ✅ **Subdomain routing** - Each service gets its own domain
- ✅ **VS Code Server** - Full IDE in browser
- ✅ **Multiple databases** - MySQL, PostgreSQL, Redis
- ✅ **Development tools** - phpMyAdmin, pgAdmin, Portainer
- ✅ **Project management** - Easy project creation
- ✅ **Custom containers** - Add your own services
- ✅ **Cloudflare tunnels** - Secure internet access
- ✅ **Modern stack** - Latest versions of all tools
# YADS - Yet Another Development Server

A comprehensive bash script for setting up a PHP development server with remote access capabilities using Cloudflare tunnels and VS Code Server.

## Features

- **PHP 8.4** with easy version management
- **Database Support**: MySQL and PostgreSQL
- **Web Server Choice**: NGINX or FrankenPHP
- **SSL Certificates**: Automatic Let's Encrypt wildcard certificates
- **Remote Access**: Cloudflare tunnel integration
- **Development Tools**: GitHub CLI, Cursor AI CLI, Composer, Laravel
- **Project Management**: Easy project creation and management
- **User Permissions**: Proper group/permission setup for development
- **Wildcard Domains**: Support for multiple projects on subdomains

## Quick Start

1. **Download and install YADS:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/your-repo/yads/main/install.sh | bash
   ```

2. **Install the development server:**
   ```bash
   yads install
   ```

3. **Configure your domain:**
   ```bash
   yads domains
   ```

4. **Create your first project:**
   ```bash
   yads create my-laravel-app
   ```

## Commands

### `yads install`
Installs all required software and configures the development server.

**What gets installed:**
- PHP 8.4 with extensions (MySQL, PostgreSQL, Redis, Memcached, Xdebug)
- MySQL and PostgreSQL databases
- Composer and Laravel installer
- GitHub CLI and Cursor AI CLI
- Cloudflare tunnel
- Your choice of web server (NGINX or FrankenPHP)

### `yads domains`
Configures domain settings and SSL certificates.

**Features:**
- Wildcard domain setup (e.g., `*.yourdomain.com`)
- Automatic SSL certificate generation with Let's Encrypt
- Cloudflare tunnel configuration
- DNS record management

### `yads create <project-name>`
Creates a new PHP project with proper configuration.

**Supported project types:**
- Laravel (recommended)
- Symfony
- CodeIgniter
- Custom PHP
- WordPress

**What gets created:**
- Project directory with proper permissions
- Database setup (MySQL and PostgreSQL)
- Domain configuration
- Git repository initialization
- Development scripts

### `yads status`
Shows the current installation status of all components.

### `yads update`
Updates all installed software to the latest versions.

### `yads uninstall`
Removes all YADS components and configurations.

## Configuration

YADS stores its configuration in `~/.yads/config`. You can edit this file to modify settings:

```bash
WEB_SERVER="nginx"           # or "frankenphp"
PHP_VERSION="8.4"
DOMAIN="yourdomain.com"
CLOUDFLARE_TOKEN="your-token"
GITHUB_TOKEN="your-token"
```

## Project Structure

After creating a project, you'll have:

```
/var/www/html/your-project/
├── public/                 # Web root
├── src/                   # Source code
├── config/                # Configuration files
├── tests/                 # Test files
├── .yads/                 # YADS configuration
├── dev.sh                 # Development scripts
└── .gitignore            # Git ignore rules
```

## Development Workflow

1. **Create a project:**
   ```bash
   yads create my-app
   ```

2. **Access your project:**
   - Local: `https://my-app.yourdomain.com`
   - Remote: Access via Cloudflare tunnel

3. **Development commands:**
   ```bash
   cd /var/www/html/my-app
   ./dev.sh start    # Start development server
   ./dev.sh build    # Build frontend assets
   ./dev.sh test     # Run tests
   ./dev.sh migrate  # Run database migrations
   ```

## Remote Development

YADS is designed for remote development with VS Code Server:

1. **Install VS Code Server:**
   ```bash
   curl -fsSL https://code-server.dev/install.sh | sh
   ```

2. **Start VS Code Server:**
   ```bash
   code-server --bind-addr 0.0.0.0:8080
   ```

3. **Access via Cloudflare tunnel:**
   - Your VS Code Server will be accessible at `https://vscode.yourdomain.com`

## SSL Certificates

YADS automatically handles SSL certificates:

- **Wildcard certificates** for all subdomains
- **Automatic renewal** via cron job
- **Security headers** configured
- **HTTP to HTTPS redirect**

## Database Management

Each project gets its own databases:

- **MySQL database**: `projectname_dev`
- **PostgreSQL database**: `projectname_dev_pg`
- **User**: `yads`
- **Automatic password generation**

## Troubleshooting

### Check installation status:
```bash
yads status
```

### View logs:
```bash
tail -f ~/.yads/yads.log
```

### Restart services:
```bash
sudo systemctl restart nginx    # or frankenphp
sudo systemctl restart mysql
sudo systemctl restart postgresql
sudo systemctl restart cloudflared
```

### Reset permissions:
```bash
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

## Requirements

- **Operating System**: Ubuntu 20.04+, Debian 11+, CentOS 8+, RHEL 8+, Fedora 35+, Arch Linux
- **Memory**: Minimum 2GB RAM (4GB recommended)
- **Storage**: Minimum 10GB free space
- **Network**: Internet connection for package downloads
- **Domain**: A domain name for SSL certificates and remote access

## Security Features

- **User isolation**: Proper user/group permissions
- **SSL/TLS encryption**: Automatic HTTPS
- **Security headers**: HSTS, XSS protection, etc.
- **Rate limiting**: API and login protection
- **Firewall ready**: Configured for common ports

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

- **Issues**: GitHub Issues
- **Documentation**: This README
- **Community**: GitHub Discussions

---

**YADS** - Making PHP development server setup as easy as possible! 🚀


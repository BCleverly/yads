# YADS - Yet Another Development Server

A remote PHP web development server with Cloudflared tunnels for internet accessibility.

## Features

- **Remote Development**: VS Code Server accessible via authentication
- **Cloudflared Tunnels**: Secure internet access without port forwarding
- **Multiple PHP Versions**: Support for PHP 5.6 through 8.5 (defaults to PHP 8.4)
- **Web Server Choice**: Apache, Nginx, or FrankenPHP
- **Database Support**: MySQL, PostgreSQL, and Redis
- **Project Management**: Easy project creation and management
- **Wildcard Domains**: `project.remote.domain.tld` routing
- **Composer & Laravel**: Pre-installed and configured

## Quick Start

### Installation

```bash
# Download and install YADS
curl -fsSL https://raw.githubusercontent.com/BCleverly/yads/main/install.sh | bash

# Or clone and install manually
git clone https://github.com/BCleverly/yads.git && cd yads && chmod +x install.sh && sudo ./install.sh

# Or use the setup script (recommended)
git clone https://github.com/BCleverly/yads.git && cd yads && chmod +x setup.sh && ./setup.sh && sudo ./install.sh

# Or make yads available locally first (for development)
git clone https://github.com/BCleverly/yads.git && cd yads && chmod +x local-setup.sh && ./local-setup.sh

# If you get "cannot execute: required file not found" error, fix line endings first:
git clone https://github.com/BCleverly/yads.git && cd yads && chmod +x fix-line-endings.sh && ./fix-line-endings.sh && ./local-setup.sh

# If you get "sudo: yads: command not found" error, use the direct script:
git clone https://github.com/BCleverly/yads.git && cd yads && chmod +x install.sh && sudo ./install.sh
```

### Basic Usage

```bash
# Check status
yads status

# Configure Cloudflared tunnel
yads tunnel setup

# Create a new project
yads project myapp laravel

# Install specific PHP version
yads php 8.2

# Switch web server
yads server nginx
```

## Commands

### Core Commands

- `yads install` - Install YADS development server
- `yads uninstall` - Uninstall YADS (preserves SSH keys)
- `yads status` - Show service status
- `yads start` - Start all services
- `yads stop` - Stop all services
- `yads restart` - Restart all services

### PHP Management

- `yads php <version>` - Install specific PHP version (5.6-8.5)
- `yads php composer` - Install Composer and Laravel installer
- `yads php list` - List available PHP versions

### Web Servers

- `yads server apache` - Switch to Apache
- `yads server nginx` - Switch to Nginx
- `yads server frankenphp` - Switch to FrankenPHP
- `yads server status` - Show web server status

### Databases

- `yads database mysql` - Install MySQL
- `yads database postgresql` - Install PostgreSQL
- `yads database redis` - Install Redis
- `yads database create <project> <mysql|postgresql>` - Create project database

### Cloudflared Tunnels

- `yads tunnel setup` - Configure Cloudflared tunnel
- `yads tunnel start` - Start tunnel
- `yads tunnel stop` - Stop tunnel
- `yads tunnel restart` - Restart tunnel
- `yads tunnel status` - Show tunnel status

### VS Code Server

- `yads vscode setup` - Configure VS Code Server
- `yads vscode start` - Start VS Code Server
- `yads vscode stop` - Stop VS Code Server
- `yads vscode password` - Change password
- `yads vscode install <extension>` - Install extension

### Project Management

- `yads project <name>` - Create new PHP project
- `yads project <name> laravel` - Create Laravel project
- `yads project <name> symfony` - Create Symfony project
- `yads project <name> wordpress` - Create WordPress project
- `yads project list` - List all projects
- `yads project delete <name>` - Delete project

## Architecture

### Directory Structure

```
/opt/yads/                 # YADS installation directory
├── modules/               # YADS modules
├── config/               # Configuration files
└── logs/                 # Log files

/var/www/projects/         # Project directory
├── project1/             # Individual projects
├── project2/
└── ...

/opt/vscode-server/        # VS Code Server
├── .config/
└── .password
```

### Service Architecture

- **VS Code Server**: Port 8080 (authenticated access)
- **Web Server**: Port 80 (Apache/Nginx/FrankenPHP)
- **Cloudflared**: Secure tunnel to internet
- **Databases**: MySQL, PostgreSQL, Redis

### Domain Routing

- `code.remote.domain.tld` → VS Code Server
- `*.remote.domain.tld` → Project routing
- `project1.remote.domain.tld` → `/var/www/projects/project1`
- `project2.remote.domain.tld` → `/var/www/projects/project2`

## Configuration

### VS Code Server

Access: `http://localhost:8080` or `https://code.remote.domain.tld`

Default password is generated during installation and stored in `/opt/vscode-server/.password`

### Cloudflared Tunnel

1. Run `yads tunnel setup`
2. Login to your Cloudflare account
3. Configure your domain DNS
4. Access your server via `https://code.remote.domain.tld`

### Project Access

Projects are accessible via:
- `https://projectname.remote.domain.tld`
- Local: `http://localhost/projectname`

## Prerequisites

- Ubuntu/Debian/CentOS/RHEL/Fedora/Arch Linux
- Root or sudo access
- Internet connection
- Cloudflare account (for tunnels)

## Uninstallation

### Normal Uninstall

```bash
yads uninstall
```

### Manual Uninstall

If normal uninstall fails:

```bash
sudo ./manual-uninstall.sh
```

**Note**: SSH keys and user data are preserved during uninstallation.

## Troubleshooting

### "sudo: yads: command not found" Error

This happens because `sudo` doesn't have access to your user's PATH. Use one of these solutions:

```bash
# Solution 1: Use the direct script (recommended)
sudo ./install.sh

# Solution 2: Use full path to yads
sudo ~/.local/bin/yads install

# Solution 3: Preserve PATH with sudo
sudo -E yads install
```

### Services Not Starting

```bash
# Check service status
yads status

# Restart services
yads restart

# Check logs
journalctl -u vscode-server
journalctl -u cloudflared
```

### VS Code Server Issues

```bash
# Change password
yads vscode password

# Restart VS Code Server
yads vscode restart

# Check configuration
cat /opt/vscode-server/.config/code-server/config.yaml
```

### Tunnel Issues

```bash
# Check tunnel status
yads tunnel status

# Restart tunnel
yads tunnel restart

# Check tunnel logs
journalctl -u cloudflared
```

## Development

### Project Structure

- `yads` - Main CLI script
- `install.sh` - Installation script
- `modules/` - Individual modules
- `manual-uninstall.sh` - Manual uninstall script

### Adding New Modules

1. Create new module in `modules/`
2. Add command handling in main `yads` script
3. Update help documentation

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/BCleverly/yads/issues)
- Documentation: [Wiki](https://github.com/BCleverly/yads/wiki)

## Changelog

### v1.0.0
- Initial release
- VS Code Server with authentication
- Cloudflared tunnel support
- Multiple PHP version support
- Web server choice (Apache/Nginx/FrankenPHP)
- Database support (MySQL/PostgreSQL/Redis)
- Project management
- Wildcard domain routing

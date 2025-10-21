# YADS - Yet Another Development Server

🚀 **A complete remote PHP web development server** with secure internet access via Cloudflared tunnels.

## ✨ What is YADS?

YADS transforms any Linux server into a powerful remote development environment with:

- 🌐 **Secure Internet Access** - No port forwarding needed
- 💻 **VS Code Server** - Full IDE in your browser
- 🐘 **Multiple PHP Versions** - PHP 5.6 to 8.5 (default: 8.4)
- 🗄️ **Modern Databases** - MySQL, PostgreSQL, Redis
- 🚀 **AI-Powered CLI** - Cursor CLI for intelligent assistance
- 📁 **Project Management** - Easy Laravel, Symfony, WordPress setup
- 🔧 **Multiple Web Servers** - Apache, Nginx, or FrankenPHP

## 🚀 Quick Start

### 📦 Installation (Choose One)

#### Option 1: One-Liner Installation (Recommended)
```bash
git clone https://github.com/BCleverly/yads.git && cd yads && chmod +x *.sh && sudo ./install.sh
```

#### Option 2: Step-by-Step Installation
```bash
# 1. Clone the repository
git clone https://github.com/BCleverly/yads.git
cd yads

# 2. Make scripts executable
chmod +x *.sh

# 3. Install YADS
sudo ./install.sh
```

#### Option 3: Development Setup
```bash
# For local development (makes yads available locally)
git clone https://github.com/BCleverly/yads.git && cd yads && chmod +x local-setup.sh && ./local-setup.sh
```

### 🔧 First-Time Setup

After installation, configure your development environment:

```bash
# 1. Check installation status
yads status

# 2. Configure VS Code Server
yads vscode setup

# 3. Set up Cloudflared tunnel (for internet access)
yads tunnel setup

# 4. Create your first project
yads project myapp laravel
```

## 📋 Commands Reference

### 🎯 Core Commands
```bash
yads status          # Show service status
yads start           # Start all services
yads stop            # Stop all services
yads restart         # Restart all services
yads help            # Show help
yads version         # Show version
```

### 🐘 PHP Management
```bash
yads php 8.4         # Install PHP 8.4 (default)
yads php 8.2         # Install PHP 8.2
yads php 7.4         # Install PHP 7.4
yads php list        # List available versions
```

### 🌐 Web Servers
```bash
yads server apache     # Switch to Apache
yads server nginx      # Switch to Nginx  
yads server frankenphp # Switch to FrankenPHP
yads server status     # Show current server
```

### 🗄️ Databases
```bash
yads database mysql      # Install MySQL
yads database postgresql # Install PostgreSQL
yads database redis      # Install Redis
```

### 🔗 Cloudflared Tunnels
```bash
yads tunnel setup    # Configure tunnel (first time)
yads tunnel start    # Start tunnel
yads tunnel stop     # Stop tunnel
yads tunnel status   # Show tunnel status
```

### 🌐 NGINX Proxy Manager
```bash
yads proxy install                    # Install NGINX Proxy Manager
yads proxy status                     # Show NPM status
yads proxy vscode domain.tld         # Setup VS Code Server proxy
yads proxy project name port domain  # Add project proxy
yads proxy add domain target port    # Add custom proxy host
yads proxy ssl domain                # Enable SSL for domain
```

### 💻 VS Code Server
```bash
yads vscode setup    # Configure VS Code Server
yads vscode start    # Start VS Code Server
yads vscode stop     # Stop VS Code Server
yads vscode password # Change password
```

### 📁 Project Management
```bash
yads project myapp              # Create basic PHP project
yads project myapp laravel       # Create Laravel project
yads project myapp symfony       # Create Symfony project
yads project myapp wordpress     # Create WordPress project
yads project myapp laravel --proxy  # Create with proxy setup
yads project list               # List all projects
```

## 🏗️ Architecture

### 📁 Directory Structure
```
/opt/yads/                 # YADS installation
├── modules/               # YADS modules
├── config/                # Configuration files
└── logs/                  # Log files

/var/www/projects/         # Your projects
├── myapp/                 # Laravel project
├── blog/                  # WordPress project
└── api/                   # Symfony project

/opt/vscode-server/        # VS Code Server
├── .config/               # VS Code configuration
└── .password              # Generated password
```

### 🌐 Service Architecture
- **NGINX Proxy Manager**: `localhost:81` (proxy management)
- **VS Code Server**: `localhost:8080` (authenticated)
- **Web Server**: `localhost:80` (Apache/Nginx/FrankenPHP)
- **Cloudflared**: Secure tunnel to internet
- **Databases**: MySQL, PostgreSQL, Redis

### 🔗 Domain Routing with NPM
- `code-server.yourdomain.com` → VS Code Server
- `proxy-manager.code-server.yourdomain.com` → NPM Admin
- `phpmyadmin.code-server.yourdomain.com` → phpMyAdmin
- `projects.code-server.yourdomain.com` → Projects List
- `myapp.projects.code-server.yourdomain.com` → Laravel Project
- `blog.projects.code-server.yourdomain.com` → WordPress Project

## ⚙️ Configuration

### 💻 VS Code Server Setup
1. **Access**: `http://localhost:8080` or `https://code-server.yourdomain.com`
2. **Password**: Generated during installation (stored in `/opt/vscode-server/.password`)
3. **Change Password**: `yads vscode password`

### 🔗 Cloudflared Tunnel Setup with NGINX Proxy Manager
1. **Configure**: `yads tunnel setup`
2. **Login**: Browser opens to Cloudflare dashboard
3. **DNS**: Configure your domain DNS records
4. **Access**: `https://code-server.yourdomain.com`

#### 🌐 Domain Structure
- **VS Code Server**: `https://code-server.yourdomain.com`
- **NGINX Proxy Manager**: `https://proxy-manager.code-server.yourdomain.com`
- **phpMyAdmin**: `https://phpmyadmin.code-server.yourdomain.com`
- **Projects**: `https://project1.projects.code-server.yourdomain.com`
- **Projects List**: `https://projects.code-server.yourdomain.com` (password protected)

### 📁 Project Access
- **Local**: `http://localhost/myapp`
- **Internet**: `https://project1.projects.code-server.yourdomain.com`

## 🌐 NGINX Proxy Manager Integration

### 🚀 Quick Setup
```bash
# Install YADS (automatically installs NPM and configures proxies)
sudo ./install.sh

# Configure tunnel for NPM (auto-configures all standard routes)
yads tunnel setup yourdomain.com

# Create project with proxy
yads project myapp laravel --proxy
```

#### 🎯 **Automatic Configuration**
When you run `yads tunnel setup`, it automatically configures:
- **VS Code Server**: `code-server.yourdomain.com` → `localhost:8080`
- **NPM Admin**: `proxy-manager.code-server.yourdomain.com` → `localhost:81`
- **phpMyAdmin**: `phpmyadmin.code-server.yourdomain.com` → `localhost:8080/phpmyadmin`
- **Projects List**: `projects.code-server.yourdomain.com` → `localhost:8080/projects`

#### 🔧 **What Happens Automatically:**
1. **NPM Installation**: Installs NGINX Proxy Manager during YADS installation
2. **Tunnel Configuration**: Sets up Cloudflare tunnel to point to `localhost:81`
3. **Proxy Routes**: Automatically creates all standard proxy routes
4. **SSL Setup**: Configures Let's Encrypt certificates for all domains
5. **Service Integration**: Links all YADS services to their respective domains

### 🔧 Domain Configuration

#### **Main Services**
- **VS Code Server**: `https://code-server.yourdomain.com`
  - Routes to: `localhost:8080`
  - SSL: Automatic Let's Encrypt
  - WebSocket: Enabled for VS Code

#### **Management Tools**
- **NGINX Proxy Manager**: `https://proxy-manager.code-server.yourdomain.com`
  - Routes to: `localhost:81`
  - Admin interface for proxy management
  - SSL certificate management

- **phpMyAdmin**: `https://phpmyadmin.code-server.yourdomain.com`
  - Routes to: `localhost:8080/phpmyadmin`
  - Database management interface

#### **Project Structure**
- **Projects List**: `https://projects.code-server.yourdomain.com`
  - Password protected project directory
  - Simple PHP script listing all projects
  - Authentication: Basic HTTP Auth

- **Individual Projects**:
  - `https://project1.projects.code-server.yourdomain.com`
  - `https://project2.projects.code-server.yourdomain.com`
  - `https://laravel-app.projects.code-server.yourdomain.com`

### 🔐 Security Features
- **SSL Termination**: Automatic Let's Encrypt certificates
- **Access Control**: Basic HTTP authentication for sensitive areas
- **Rate Limiting**: Built-in protection against abuse
- **WebSocket Support**: Full VS Code Server functionality
- **Custom Headers**: Security headers and CORS configuration

### 📊 Monitoring & Management
- **Real-time Logs**: Access logs for all services
- **SSL Certificate Monitoring**: Automatic renewal tracking
- **Performance Metrics**: Request/response statistics
- **Health Checks**: Service availability monitoring

## 🚀 Complete Setup Example

### **Step 1: Install YADS (Auto-configures NPM)**
```bash
# Install YADS (automatically installs and configures NPM)
sudo ./install.sh
```

### **Step 2: Configure Tunnel (Auto-configures all proxies)**
```bash
# Configure tunnel - automatically sets up all standard routes
yads tunnel setup yourdomain.com
```

### **Step 3: Create Projects**
```bash
# Create Laravel project with proxy
yads project myapp laravel --proxy
# Results in: https://myapp.projects.code-server.yourdomain.com

# Create WordPress project with proxy
yads project blog wordpress --proxy
# Results in: https://blog.projects.code-server.yourdomain.com
```

### **Step 4: Access Your Services (All Auto-configured)**
- **VS Code Server**: `https://code-server.yourdomain.com` ✅ Auto-configured
- **Proxy Manager**: `https://proxy-manager.code-server.yourdomain.com` ✅ Auto-configured
- **phpMyAdmin**: `https://phpmyadmin.code-server.yourdomain.com` ✅ Auto-configured
- **Projects List**: `https://projects.code-server.yourdomain.com` ✅ Auto-configured
- **Your Projects**: `https://myapp.projects.code-server.yourdomain.com` ✅ Auto-configured

## 📋 Prerequisites

- ✅ **Linux**: Ubuntu/Debian/CentOS/RHEL/Fedora/Arch
- ✅ **Permissions**: Root or sudo access
- ✅ **Internet**: Stable connection required
- ✅ **Cloudflare**: Account for tunnel setup

## 🔄 Updating YADS

### 🚀 Automatic Update (Recommended)
```bash
cd ~/yads
./update-yads.sh
```

**What it does:**
- ✅ Pulls latest changes from GitHub
- ✅ Fixes line endings automatically  
- ✅ Makes all scripts executable
- ✅ Updates CLI symlink
- ✅ Updates shell configuration

### 🔧 Manual Update
```bash
git pull origin master
./fix-line-endings.sh
./setup.sh
./local-setup.sh
```

## 🗑️ Uninstallation

### Normal Uninstall
```bash
yads uninstall
```

### Manual Uninstall
```bash
sudo ./manual-uninstall.sh
```

> **Note**: SSH keys and user data are preserved during uninstallation.

## 🔧 Troubleshooting

### ❌ "sudo: yads: command not found" Error
**Problem**: `sudo` doesn't have access to your user's PATH.

**Solutions:**
```bash
# Solution 1: Use direct script (recommended)
sudo ./install.sh

# Solution 2: Use full path
sudo ~/.local/bin/yads install

# Solution 3: Preserve PATH
sudo -E yads install
```

### 🚫 Services Not Starting
```bash
# Check status
yads status

# Restart all services
yads restart

# Check specific logs
journalctl -u vscode-server
journalctl -u cloudflared
```

### 💻 VS Code Server Issues
```bash
# Change password
yads vscode password

# Restart VS Code Server
yads vscode restart

# Check configuration
cat /opt/vscode-server/.config/code-server/config.yaml
```

### 🔗 Tunnel Issues
```bash
# Check tunnel status
yads tunnel status

# Restart tunnel
yads tunnel restart

# Check tunnel logs
journalctl -u cloudflared
```

### 🐛 Common Issues

#### "cannot execute: required file not found"
```bash
# Fix line endings
./fix-line-endings.sh
```

#### Commands not available after installation
```bash
# Update shell configuration
source ~/.bashrc
# or restart your terminal
```

## 🛠️ Development

### 📁 Project Structure
```
yads/                    # Main CLI script
install.sh              # Installation script
modules/                # Individual modules
├── install.sh          # Installation module
├── tunnel.sh           # Cloudflared module
├── vscode.sh           # VS Code Server module
└── ...
```

### ➕ Adding New Modules
1. Create new module in `modules/`
2. Add command handling in main `yads` script
3. Update help documentation

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/BCleverly/yads/issues)
- **Documentation**: [Wiki](https://github.com/BCleverly/yads/wiki)

## 📝 Changelog

### v1.0.0
- ✅ Initial release
- ✅ VS Code Server with authentication
- ✅ Cloudflared tunnel support
- ✅ Multiple PHP version support (5.6-8.5)
- ✅ Web server choice (Apache/Nginx/FrankenPHP)
- ✅ Database support (MySQL/PostgreSQL/Redis)
- ✅ Project management
- ✅ Wildcard domain routing
- ✅ NVM and Node.js LTS support
- ✅ Cursor CLI integration

# YADS Docker Testing

This directory contains Docker configuration for testing YADS in a containerized environment using Ubuntu 24.04 LTS.

## 🐳 **Quick Start**

### **Build and Run with Docker Compose (Recommended)**
```bash
# Build and start the container
docker-compose up --build

# Run in detached mode
docker-compose up -d --build

# View logs
docker-compose logs -f
```

### **Build and Run with Docker**
```bash
# Build the image
docker build -t yads-test .

# Run the container
docker run -it --privileged --name yads-test-container yads-test

# Run in detached mode
docker run -d --privileged --name yads-test-container yads-test
```

## 🧪 **Testing YADS**

### **Run Tests Inside Container**
```bash
# Enter the container
docker exec -it yads-test-container bash

# Run the test suite
./test-docker.sh

# Run YADS tests
./test-yads.sh
```

### **Test Installation**
```bash
# Enter the container
docker exec -it yads-test-container bash

# Run full installation
sudo ./install.sh

# Check status
yads status
```

## 📋 **Available Commands**

### **Container Management**
```bash
# Start container
docker-compose up -d

# Stop container
docker-compose down

# Rebuild container
docker-compose up --build

# View logs
docker-compose logs -f

# Enter container shell
docker exec -it yads-test-container bash
```

### **YADS Testing**
```bash
# Test basic functionality
yads --version
yads help
yads status

# Test update functionality
yads update

# Test specific modules
yads php 8.4
yads server nginx
yads database mysql
```

## 🔧 **Container Configuration**

### **Ports Exposed**
- **8080** - VS Code Server
- **80** - Web server (HTTP)
- **443** - Web server (HTTPS)
- **3306** - MySQL
- **5432** - PostgreSQL
- **6379** - Redis

### **Volumes**
- `/sys/fs/cgroup` - Systemd support
- `/tmp/yads-test` - Test data

### **Environment**
- **OS**: Ubuntu 24.04 LTS
- **User**: yadsuser (non-root)
- **Privileged**: Yes (for systemd support)
- **Systemd**: Enabled for service testing

## 🚀 **Testing Scenarios**

### **1. Basic Functionality Test**
```bash
docker exec -it yads-test-container ./test-docker.sh
```

### **2. Full Installation Test**
```bash
docker exec -it yads-test-container bash
sudo ./install.sh
yads status
```

### **3. Service Testing**
```bash
docker exec -it yads-test-container bash
yads start
yads status
yads stop
```

### **4. Module Testing**
```bash
docker exec -it yads-test-container bash
yads php 8.4
yads server nginx
yads database mysql
```

## 🐛 **Troubleshooting**

### **Container Won't Start**
```bash
# Check if ports are in use
netstat -tulpn | grep -E ":(80|443|8080|3306|5432|6379)"

# Check Docker logs
docker logs yads-test-container
```

### **Services Not Starting**
```bash
# Check systemd status
docker exec -it yads-test-container systemctl status

# Check service logs
docker exec -it yads-test-container journalctl -u yads*
```

### **Permission Issues**
```bash
# Check file permissions
docker exec -it yads-test-container ls -la

# Fix permissions
docker exec -it yads-test-container chmod +x *.sh
```

## 📊 **Test Results**

The test suite checks:
- ✅ **Basic YADS functionality** (version, help, status)
- ✅ **Update functionality** (yads update)
- ✅ **Module loading** (all modules present)
- ✅ **Script permissions** (all scripts executable)
- ✅ **Installation readiness** (install.sh ready)
- ✅ **Docker functionality** (systemd, sudo available)

## 🔄 **Continuous Testing**

### **Automated Testing**
```bash
# Run tests on every build
docker-compose up --build
docker exec -it yads-test-container ./test-docker.sh
docker-compose down
```

### **Integration Testing**
```bash
# Full installation test
docker-compose up -d
docker exec -it yads-test-container sudo ./install.sh
docker exec -it yads-test-container yads status
docker-compose down
```

## 📝 **Notes**

- **Privileged mode required** for systemd support
- **Ubuntu 24.04 LTS** base image
- **Non-root user** (yadsuser) for security
- **All ports exposed** for testing
- **Systemd enabled** for service management
- **YADS pre-configured** for testing

This Docker setup provides a complete testing environment for YADS development and validation! 🎉

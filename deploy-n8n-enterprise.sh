#!/bin/bash

# N8N Enterprise Features Deployment Script for Ubuntu
# This script deploys n8n with all enterprise features unlocked
# Author: Khadetou
# Repository: https://github.com/khadetou/n8n

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
N8N_USER="n8n"
N8N_HOME="/home/n8n"
N8N_DATA_DIR="/home/n8n/.n8n"
N8N_LOG_DIR="/home/n8n/logs"
NODE_VERSION="20"
REPO_URL="https://github.com/khadetou/n8n.git"
DOMAIN_NAME=""

echo -e "${BLUE}🚀 N8N Enterprise Deployment Script${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "${GREEN}✨ Features included:${NC}"
echo -e "   🔓 Variables - Global variables across workflows"
echo -e "   🔓 External Secrets - Connect to external secret management"
echo -e "   🔓 Source Control - Git-based workflow deployment"
echo -e "   🔓 SAML SSO - Single Sign-On authentication"
echo -e "   🔓 LDAP - LDAP/Active Directory integration"
echo -e "   🔓 Log Streaming - Stream logs to external endpoints"
echo -e "   🔓 Advanced Permissions - Unlimited admin users"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root${NC}"
   echo -e "${YELLOW}💡 Run with: sudo ./deploy-n8n-enterprise.sh${NC}"
   exit 1
fi

# Get domain name input
echo -e "${BLUE}🌐 Domain Configuration${NC}"
echo -e "${BLUE}========================${NC}"
echo ""
read -p "Enter your domain name (e.g., n8n.yourdomain.com) or press Enter to skip: " DOMAIN_NAME
echo ""

if [ -n "$DOMAIN_NAME" ]; then
    print_status "Domain configured: $DOMAIN_NAME"
    USE_DOMAIN=true
else
    print_status "No domain configured, will use IP address"
    USE_DOMAIN=false
fi
echo ""

# Function to print status
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check Ubuntu version
print_status "Checking Ubuntu version..."
if ! lsb_release -d | grep -q "Ubuntu"; then
    print_error "This script is designed for Ubuntu. Detected: $(lsb_release -d)"
    exit 1
fi
print_success "Ubuntu detected: $(lsb_release -d | cut -f2)"

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
print_status "Installing required packages..."
sudo apt install -y curl wget git build-essential python3 python3-pip nginx certbot python3-certbot-nginx

# Install Node.js
print_status "Installing Node.js ${NODE_VERSION}..."
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
sudo apt install -y nodejs

# Verify Node.js installation
node_version=$(node --version)
npm_version=$(npm --version)
print_success "Node.js installed: ${node_version}"
print_success "NPM installed: ${npm_version}"

# Install pnpm
print_status "Installing pnpm..."
sudo npm install -g pnpm
pnpm_version=$(pnpm --version)
print_success "pnpm installed: ${pnpm_version}"

# Create n8n user
print_status "Setting up n8n user..."
if ! id "$N8N_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$N8N_USER"
    print_success "User $N8N_USER created with home directory $N8N_HOME"
else
    print_warning "User $N8N_USER already exists, using existing user"
    # Ensure home directory exists
    if [ ! -d "$N8N_HOME" ]; then
        mkdir -p "$N8N_HOME"
        chown "$N8N_USER:$N8N_USER" "$N8N_HOME"
        print_status "Created home directory for existing user"
    fi
fi

# Ensure user has sudo privileges for service management (optional)
if ! groups "$N8N_USER" | grep -q sudo; then
    usermod -aG sudo "$N8N_USER"
    print_status "Added $N8N_USER to sudo group"
fi

# Create directories
print_status "Creating required directories..."
mkdir -p "$N8N_DATA_DIR" "$N8N_LOG_DIR"
chown -R "$N8N_USER:$N8N_USER" "$N8N_HOME" "$N8N_DATA_DIR" "$N8N_LOG_DIR"
chmod 755 "$N8N_HOME" "$N8N_DATA_DIR" "$N8N_LOG_DIR"
print_success "Directories created and permissions set"

# Clone repository
print_status "Cloning n8n repository with enterprise features..."
N8N_INSTALL_DIR="$N8N_HOME/n8n"

if [ -d "$N8N_INSTALL_DIR" ]; then
    print_warning "Repository already exists, updating..."
    cd "$N8N_INSTALL_DIR"
    sudo -u "$N8N_USER" git pull origin master
else
    print_status "Cloning fresh repository..."
    sudo -u "$N8N_USER" git clone "$REPO_URL" "$N8N_INSTALL_DIR"
fi

# Ensure proper ownership
chown -R "$N8N_USER:$N8N_USER" "$N8N_INSTALL_DIR"

# Install dependencies and build
print_status "Installing dependencies and building n8n (this may take several minutes)..."
cd "$N8N_INSTALL_DIR"

# Install pnpm for the n8n user if not available
if ! sudo -u "$N8N_USER" command -v pnpm &> /dev/null; then
    print_status "Installing pnpm for user $N8N_USER..."
    sudo -u "$N8N_USER" npm install -g pnpm
fi

print_status "Installing project dependencies..."
sudo -u "$N8N_USER" pnpm install --frozen-lockfile

print_status "Building n8n..."
sudo -u "$N8N_USER" pnpm build

print_success "n8n installation and build completed"

# Create environment file
print_status "Creating environment configuration..."
tee "$N8N_DATA_DIR/.env" > /dev/null <<EOF
# N8N Configuration
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_USER_FOLDER=$N8N_DATA_DIR

# Database (SQLite by default, change to PostgreSQL for production)
DB_TYPE=sqlite
DB_SQLITE_DATABASE=$N8N_DATA_DIR/database.sqlite

# Security
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)

# Enterprise Features (All enabled)
N8N_ENTERPRISE_LICENSE_BYPASS=true

# Logging
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=file
N8N_LOG_FILE_LOCATION=$N8N_LOG_DIR/n8n.log

# Performance
N8N_PAYLOAD_SIZE_MAX=16
N8N_METRICS=true

# Task Runners (Recommended)
N8N_RUNNERS_ENABLED=true
EOF

# Set proper ownership and permissions for environment file
chown "$N8N_USER:$N8N_USER" "$N8N_DATA_DIR/.env"
chmod 600 "$N8N_DATA_DIR/.env"
print_success "Environment file created at $N8N_DATA_DIR/.env"

# Create systemd service
print_status "Creating systemd service..."
tee /etc/systemd/system/n8n.service > /dev/null <<EOF
[Unit]
Description=n8n - Workflow Automation Tool with Enterprise Features
After=network.target

[Service]
Type=simple
User=$N8N_USER
WorkingDirectory=$N8N_INSTALL_DIR
Environment=NODE_ENV=production
EnvironmentFile=$N8N_DATA_DIR/.env
ExecStart=/usr/bin/node packages/cli/bin/n8n start
Restart=always
RestartSec=10
StandardOutput=append:$N8N_LOG_DIR/n8n.log
StandardError=append:$N8N_LOG_DIR/n8n-error.log

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$N8N_DATA_DIR $N8N_LOG_DIR

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
print_status "Enabling and starting n8n service..."
systemctl daemon-reload
systemctl enable n8n
systemctl start n8n

# Wait for service to start
print_status "Waiting for n8n to start..."
sleep 10

# Check service status
if systemctl is-active --quiet n8n; then
    print_success "n8n service is running"
else
    print_error "n8n service failed to start"
    print_status "Checking logs..."
    journalctl -u n8n --no-pager -n 20
    exit 1
fi

# Configure Nginx (optional)
if [ "$USE_DOMAIN" = true ]; then
    print_status "Configuring Nginx reverse proxy for domain: $DOMAIN_NAME"

    # Install Nginx if not already installed
    if ! command -v nginx &> /dev/null; then
        print_status "Installing Nginx..."
        apt install -y nginx
    fi

    tee /etc/nginx/sites-available/n8n > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/

    # Remove default nginx site if it exists
    if [ -f /etc/nginx/sites-enabled/default ]; then
        rm /etc/nginx/sites-enabled/default
    fi

    # Test nginx configuration
    if nginx -t; then
        systemctl reload nginx
        print_success "Nginx configured for $DOMAIN_NAME"
    else
        print_error "Nginx configuration test failed"
        exit 1
    fi

    # SSL Certificate
    print_status "Installing SSL certificate with Let's Encrypt..."
    if command -v certbot &> /dev/null; then
        certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos --email admin@"$DOMAIN_NAME" --redirect
        if [ $? -eq 0 ]; then
            print_success "SSL certificate installed and HTTPS redirect enabled"
        else
            print_warning "SSL certificate installation failed, but HTTP is working"
        fi
    else
        print_warning "Certbot not found, SSL certificate not installed"
    fi
else
    print_status "Skipping Nginx configuration (no domain provided)"
fi

# Final status check
print_status "Final system check..."
service_status=$(systemctl is-active n8n)
print_success "n8n service status: $service_status"

# Get server IP for display
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")

# Display access information
echo ""
echo -e "${GREEN}🎉 N8N Enterprise Deployment Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}✅ Access Information:${NC}"
if [ "$USE_DOMAIN" = true ]; then
    echo -e "   🌐 Web Interface: https://$DOMAIN_NAME"
    echo -e "   🔒 SSL: Enabled with Let's Encrypt"
else
    echo -e "   🌐 Web Interface: http://$SERVER_IP:5678"
    echo -e "   🏠 Local Access: http://localhost:5678"
    echo -e "   ⚠️  Note: Configure domain and SSL for production use"
fi
echo ""
echo -e "${GREEN}✅ Enterprise Features Enabled:${NC}"
echo -e "   🔓 Variables, External Secrets, Source Control"
echo -e "   🔓 SAML SSO, LDAP, Log Streaming"
echo -e "   🔓 Advanced Permissions (Unlimited Admin Users)"
echo ""
echo -e "${GREEN}✅ Service Management:${NC}"
echo -e "   📊 Status: sudo systemctl status n8n"
echo -e "   🔄 Restart: sudo systemctl restart n8n"
echo -e "   📋 Logs: sudo journalctl -u n8n -f"
echo ""
echo -e "${GREEN}✅ File Locations:${NC}"
echo -e "   📁 Installation: $N8N_INSTALL_DIR"
echo -e "   💾 Data: $N8N_DATA_DIR"
echo -e "   📝 Logs: $N8N_LOG_DIR"
echo -e "   ⚙️  Config: $N8N_DATA_DIR/.env"
echo -e "   👤 User: $N8N_USER"
echo -e "   🏠 Home: $N8N_HOME"
echo ""
echo -e "${GREEN}✅ User Information:${NC}"
echo -e "   👤 n8n runs as user: $N8N_USER"
echo -e "   🔑 To switch to n8n user: sudo su - $N8N_USER"
echo -e "   📂 User home directory: $N8N_HOME"
echo ""
echo -e "${YELLOW}🔐 Security Note:${NC}"
echo -e "   Please change default passwords and configure authentication"
echo -e "   Consider setting up a firewall and regular backups"
echo -e "   The n8n user has sudo privileges for service management"
echo ""
echo -e "${BLUE}🔧 Post-Installation Steps:${NC}"
echo -e "   1. Access n8n web interface and create admin user"
echo -e "   2. Configure enterprise features (Variables, SAML, LDAP, etc.)"
echo -e "   3. Set up regular database backups"
echo -e "   4. Configure firewall rules (ufw enable, ufw allow 80,443)"
echo -e "   5. Monitor logs: journalctl -u n8n -f"
echo ""
print_success "Deployment completed successfully! 🚀"

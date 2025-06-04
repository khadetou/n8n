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
N8N_HOME="/opt/n8n"
N8N_DATA_DIR="/var/lib/n8n"
N8N_LOG_DIR="/var/log/n8n"
NODE_VERSION="20"
REPO_URL="https://github.com/khadetou/n8n.git"

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
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}❌ This script should not be run as root${NC}"
   echo -e "${YELLOW}💡 Run with: sudo ./deploy-n8n-enterprise.sh${NC}"
   exit 1
fi

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
print_status "Creating n8n user..."
if ! id "$N8N_USER" &>/dev/null; then
    sudo useradd -r -s /bin/bash -d "$N8N_HOME" -m "$N8N_USER"
    print_success "User $N8N_USER created"
else
    print_warning "User $N8N_USER already exists"
fi

# Create directories
print_status "Creating directories..."
sudo mkdir -p "$N8N_HOME" "$N8N_DATA_DIR" "$N8N_LOG_DIR"
sudo chown -R "$N8N_USER:$N8N_USER" "$N8N_HOME" "$N8N_DATA_DIR" "$N8N_LOG_DIR"

# Clone repository
print_status "Cloning n8n repository with enterprise features..."
if [ -d "$N8N_HOME/n8n" ]; then
    print_warning "Repository already exists, updating..."
    sudo -u "$N8N_USER" git -C "$N8N_HOME/n8n" pull
else
    sudo -u "$N8N_USER" git clone "$REPO_URL" "$N8N_HOME/n8n"
fi

# Install dependencies and build
print_status "Installing dependencies and building n8n..."
cd "$N8N_HOME/n8n"
sudo -u "$N8N_USER" pnpm install --frozen-lockfile
sudo -u "$N8N_USER" pnpm build

# Create environment file
print_status "Creating environment configuration..."
sudo -u "$N8N_USER" tee "$N8N_DATA_DIR/.env" > /dev/null <<EOF
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

print_success "Environment file created at $N8N_DATA_DIR/.env"

# Create systemd service
print_status "Creating systemd service..."
sudo tee /etc/systemd/system/n8n.service > /dev/null <<EOF
[Unit]
Description=n8n - Workflow Automation Tool with Enterprise Features
After=network.target

[Service]
Type=simple
User=$N8N_USER
WorkingDirectory=$N8N_HOME/n8n
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
sudo systemctl daemon-reload
sudo systemctl enable n8n
sudo systemctl start n8n

# Wait for service to start
print_status "Waiting for n8n to start..."
sleep 10

# Check service status
if sudo systemctl is-active --quiet n8n; then
    print_success "n8n service is running"
else
    print_error "n8n service failed to start"
    print_status "Checking logs..."
    sudo journalctl -u n8n --no-pager -n 20
    exit 1
fi

# Configure Nginx (optional)
read -p "Do you want to configure Nginx reverse proxy? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter your domain name (e.g., n8n.yourdomain.com): " domain_name
    
    print_status "Configuring Nginx for domain: $domain_name"
    
    sudo tee /etc/nginx/sites-available/n8n > /dev/null <<EOF
server {
    listen 80;
    server_name $domain_name;

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

    sudo ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl reload nginx
    
    print_success "Nginx configured for $domain_name"
    
    # SSL Certificate
    read -p "Do you want to install SSL certificate with Let's Encrypt? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installing SSL certificate..."
        sudo certbot --nginx -d "$domain_name" --non-interactive --agree-tos --email admin@"$domain_name"
        print_success "SSL certificate installed"
    fi
fi

# Final status check
print_status "Final system check..."
service_status=$(sudo systemctl is-active n8n)
print_success "n8n service status: $service_status"

# Display access information
echo ""
echo -e "${GREEN}🎉 N8N Enterprise Deployment Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}✅ Access Information:${NC}"
if [ -n "$domain_name" ]; then
    echo -e "   🌐 Web Interface: https://$domain_name"
else
    echo -e "   🌐 Web Interface: http://$(curl -s ifconfig.me):5678"
    echo -e "   🏠 Local Access: http://localhost:5678"
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
echo -e "   📁 Installation: $N8N_HOME/n8n"
echo -e "   💾 Data: $N8N_DATA_DIR"
echo -e "   📝 Logs: $N8N_LOG_DIR"
echo -e "   ⚙️  Config: $N8N_DATA_DIR/.env"
echo ""
echo -e "${YELLOW}🔐 Security Note:${NC}"
echo -e "   Please change default passwords and configure authentication"
echo -e "   Consider setting up a firewall and regular backups"
echo ""
print_success "Deployment completed successfully! 🚀"

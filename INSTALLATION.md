# N8N Enterprise Installation Guide 🚀

This guide will help you install n8n with all enterprise features unlocked on Ubuntu/Debian systems.

## 🎯 Quick Installation

### One-Command Installation

```bash
wget https://raw.githubusercontent.com/khadetou/n8n/master/deploy-n8n-enterprise.sh && chmod +x deploy-n8n-enterprise.sh && sudo ./deploy-n8n-enterprise.sh
```

### Step-by-Step Installation

1. **Download the installation script:**
```bash
wget https://raw.githubusercontent.com/khadetou/n8n/master/deploy-n8n-enterprise.sh
```

2. **Make it executable:**
```bash
chmod +x deploy-n8n-enterprise.sh
```

3. **Run the installation (as root):**
```bash
sudo ./deploy-n8n-enterprise.sh
```

4. **Follow the prompts:**
   - Enter your domain name (optional but recommended)
   - The script will automatically configure SSL if domain is provided

## 📋 What the Script Does

### System Setup
- ✅ Updates Ubuntu/Debian packages
- ✅ Installs Node.js 20+, npm, pnpm
- ✅ Installs build tools and dependencies
- ✅ Installs Nginx and Certbot (for SSL)

### User Management
- ✅ Creates `n8n` user (or uses existing one)
- ✅ Sets up home directory at `/home/n8n`
- ✅ Adds user to sudo group for service management

### N8N Installation
- ✅ Clones the enterprise-enabled repository
- ✅ Installs dependencies with pnpm
- ✅ Builds the application
- ✅ Creates systemd service for auto-start

### Configuration
- ✅ Creates environment file with enterprise features enabled
- ✅ Sets up proper file permissions and ownership
- ✅ Configures logging and data directories

### Web Server (Optional)
- ✅ Configures Nginx reverse proxy
- ✅ Installs SSL certificate with Let's Encrypt
- ✅ Enables HTTPS redirect

## 🗂 File Structure After Installation

```
/home/n8n/                     # n8n user home directory
├── n8n/                       # n8n application code
├── .n8n/                      # n8n data directory
│   ├── .env                   # environment configuration
│   └── database.sqlite        # SQLite database (default)
└── logs/                      # application logs
    ├── n8n.log               # main application log
    └── n8n-error.log         # error log

/etc/systemd/system/n8n.service # systemd service file
/etc/nginx/sites-available/n8n  # nginx configuration (if domain provided)
```

## 🔧 Service Management

### Check Status
```bash
sudo systemctl status n8n
```

### Start/Stop/Restart
```bash
sudo systemctl start n8n
sudo systemctl stop n8n
sudo systemctl restart n8n
```

### View Logs
```bash
# Real-time logs
sudo journalctl -u n8n -f

# Recent logs
sudo journalctl -u n8n -n 50

# Application logs
tail -f /home/n8n/logs/n8n.log
```

## 🌐 Access Your Installation

### With Domain (Recommended)
- **URL**: `https://your-domain.com`
- **SSL**: Automatically configured
- **Security**: HTTPS enforced

### Without Domain
- **URL**: `http://your-server-ip:5678`
- **Note**: Configure domain and SSL for production

## ⚙️ Configuration

### Environment Variables
Edit `/home/n8n/.n8n/.env` to customize:

```bash
# Basic settings
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http

# Database (upgrade to PostgreSQL for production)
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=localhost
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=your_password

# Security
N8N_ENCRYPTION_KEY=your_32_character_encryption_key

# Enterprise features (all enabled)
N8N_ENTERPRISE_LICENSE_BYPASS=true
```

### Database Upgrade (Recommended for Production)

1. **Install PostgreSQL:**
```bash
sudo apt install postgresql postgresql-contrib
```

2. **Create database and user:**
```bash
sudo -u postgres psql
CREATE DATABASE n8n;
CREATE USER n8n WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;
\q
```

3. **Update environment file:**
```bash
sudo nano /home/n8n/.n8n/.env
# Update DB_TYPE and connection settings
```

4. **Restart n8n:**
```bash
sudo systemctl restart n8n
```

## 🔒 Security Hardening

### Firewall Setup
```bash
# Enable firewall
sudo ufw enable

# Allow SSH (if using)
sudo ufw allow ssh

# Allow HTTP and HTTPS
sudo ufw allow 80
sudo ufw allow 443

# Check status
sudo ufw status
```

### SSL Certificate Renewal
```bash
# Test renewal
sudo certbot renew --dry-run

# Certificates auto-renew via cron
```

### Regular Backups
```bash
# Create backup script
sudo nano /home/n8n/backup.sh
```

```bash
#!/bin/bash
# N8N Backup Script
BACKUP_DIR="/home/n8n/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
if [ "$DB_TYPE" = "sqlite" ]; then
    cp /home/n8n/.n8n/database.sqlite $BACKUP_DIR/database_$DATE.sqlite
else
    pg_dump -h localhost -U n8n n8n > $BACKUP_DIR/database_$DATE.sql
fi

# Backup workflows and settings
tar -czf $BACKUP_DIR/n8n_data_$DATE.tar.gz /home/n8n/.n8n/

# Keep only last 7 days
find $BACKUP_DIR -name "*.sqlite" -mtime +7 -delete
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
```

## 🛠 Troubleshooting

### Service Won't Start
```bash
# Check service status
sudo systemctl status n8n

# Check logs for errors
sudo journalctl -u n8n -n 50

# Check file permissions
ls -la /home/n8n/.n8n/
```

### Port Already in Use
```bash
# Check what's using port 5678
sudo netstat -tulpn | grep 5678

# Kill process if needed
sudo kill -9 <PID>
```

### Permission Issues
```bash
# Fix ownership
sudo chown -R n8n:n8n /home/n8n/

# Fix permissions
sudo chmod 755 /home/n8n/
sudo chmod 600 /home/n8n/.n8n/.env
```

### Database Connection Issues
```bash
# Test PostgreSQL connection
sudo -u n8n psql -h localhost -U n8n -d n8n

# Check PostgreSQL service
sudo systemctl status postgresql
```

## 🔄 Updates

### Update N8N
```bash
# Switch to n8n user
sudo su - n8n

# Navigate to installation
cd /home/n8n/n8n

# Pull latest changes
git pull origin master

# Install dependencies
pnpm install

# Build application
pnpm build

# Exit n8n user
exit

# Restart service
sudo systemctl restart n8n
```

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/khadetou/n8n/issues)
- **Documentation**: [Original N8N Docs](https://docs.n8n.io/)
- **Community**: [N8N Community](https://community.n8n.io/)

## ⚠️ Important Notes

1. **First Access**: Create admin user immediately after installation
2. **Security**: Change default passwords and configure authentication
3. **Backups**: Set up regular database and workflow backups
4. **Monitoring**: Monitor logs and system resources
5. **Updates**: Keep system and n8n updated regularly

---

**Happy Automating! 🎉**

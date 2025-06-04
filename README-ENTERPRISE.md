# N8N with Enterprise Features Unlocked 🚀

This is a fork of [n8n](https://github.com/n8n-io/n8n) with all enterprise features enabled without license restrictions.

## 🔓 Enterprise Features Unlocked

All the following enterprise features are **fully functional** without any license requirements:

### ✅ **Variables**
- Create and manage global variables across all workflows
- Use `$vars.variableName` syntax in any node
- Perfect for API keys, configuration values, and environment-specific settings

### ✅ **External Secrets**
- Connect to external secret management systems (HashiCorp Vault, AWS Secrets Manager, etc.)
- Centralized credential management across environments
- Enhanced security for sensitive data

### ✅ **Source Control (Environments)**
- Git-based workflow deployment and version control
- Multiple environment support (dev, staging, production)
- Collaborative workflow development

### ✅ **SAML SSO**
- Single Sign-On with SAML 2.0 identity providers
- Enterprise authentication integration
- Seamless user management

### ✅ **LDAP Integration**
- LDAP/Active Directory authentication
- Enterprise user directory integration
- Automated user provisioning

### ✅ **Log Streaming**
- Stream logs to external endpoints and services
- Real-time monitoring and alerting
- Integration with logging platforms (Elasticsearch, Splunk, etc.)

### ✅ **Advanced Permissions**
- Create unlimited admin users
- No quota restrictions on user creation
- Full permission management capabilities

## 🚀 Quick Deployment

### Ubuntu/Debian Production Deployment

1. **Download and run the deployment script:**
```bash
wget https://raw.githubusercontent.com/khadetou/n8n/master/deploy-n8n-enterprise.sh
chmod +x deploy-n8n-enterprise.sh
sudo ./deploy-n8n-enterprise.sh
```

2. **Follow the interactive prompts** for domain configuration and SSL setup

3. **Access your n8n instance** at the configured domain or IP address

### Manual Installation

1. **Clone the repository:**
```bash
git clone https://github.com/khadetou/n8n.git
cd n8n
```

2. **Install dependencies:**
```bash
pnpm install
```

3. **Build the project:**
```bash
pnpm build
```

4. **Start n8n:**
```bash
pnpm start
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file with the following configuration:

```bash
# Basic Configuration
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http

# Database (PostgreSQL recommended for production)
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=localhost
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=your_password

# Security
N8N_ENCRYPTION_KEY=your_encryption_key_here

# Enterprise Features (All enabled by default)
N8N_ENTERPRISE_LICENSE_BYPASS=true

# Performance
N8N_PAYLOAD_SIZE_MAX=16
N8N_METRICS=true
N8N_RUNNERS_ENABLED=true
```

### Database Setup

For production, use PostgreSQL:

```sql
CREATE DATABASE n8n;
CREATE USER n8n WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;
```

## 📚 Using Enterprise Features

### Variables
1. Go to **Settings** → **Variables**
2. Create variables with key-value pairs
3. Use in workflows: `$vars.myVariable`

### External Secrets
1. Go to **Settings** → **External Secrets**
2. Configure your secret provider (Vault, AWS, etc.)
3. Connect and sync secrets

### Source Control
1. Go to **Settings** → **Source Control**
2. Connect your Git repository
3. Push/pull workflows to/from Git

### SAML SSO
1. Go to **Settings** → **SSO**
2. Configure your SAML identity provider
3. Enable SSO authentication

### LDAP
1. Go to **Settings** → **LDAP**
2. Configure LDAP server settings
3. Enable LDAP authentication

### Log Streaming
1. Go to **Settings** → **Log Streaming**
2. Add destinations (webhooks, files, etc.)
3. Configure event filtering

## 🔒 Security Considerations

- **Change default passwords** immediately after installation
- **Use HTTPS** in production (included in deployment script)
- **Configure firewall** to restrict access
- **Regular backups** of database and workflows
- **Monitor logs** for suspicious activity

## 🛠 Development

### Local Development

```bash
# Backend development
pnpm dev:be

# Frontend development  
pnpm dev:fe

# Full development (both)
pnpm dev
```

### Building for Production

```bash
pnpm build
```

## 📋 System Requirements

### Minimum Requirements
- **OS**: Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- **Node.js**: 20.x or higher
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 10GB minimum
- **Database**: PostgreSQL 12+ (recommended) or SQLite

### Recommended Production Setup
- **RAM**: 8GB+
- **CPU**: 4+ cores
- **Storage**: 50GB+ SSD
- **Database**: PostgreSQL with dedicated server
- **Reverse Proxy**: Nginx with SSL

## 🔄 Updates

To update your installation:

```bash
cd /path/to/n8n
git pull origin master
pnpm install
pnpm build
sudo systemctl restart n8n
```

## 🐛 Troubleshooting

### Service Issues
```bash
# Check service status
sudo systemctl status n8n

# View logs
sudo journalctl -u n8n -f

# Restart service
sudo systemctl restart n8n
```

### Common Issues
- **Port conflicts**: Change N8N_PORT in environment
- **Database connection**: Verify database credentials
- **Permission errors**: Check file ownership and permissions

## 📄 License

This fork maintains the same license as the original n8n project. The enterprise features are unlocked for self-hosted deployments.

## 🤝 Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## ⚠️ Disclaimer

This fork is intended for self-hosted deployments and educational purposes. The enterprise features are unlocked by modifying license checks. Please respect n8n's commercial licensing if you're using this in a commercial environment where a license would normally be required.

## 📞 Support

- **Issues**: Open an issue on this repository
- **Discussions**: Use GitHub Discussions
- **Original n8n**: [Official Documentation](https://docs.n8n.io/)

---

**Made with ❤️ for the open-source community**

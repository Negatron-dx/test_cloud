# 🚀 Complete Dojo-Task Application Deployment Guide

This guide provides everything you need to deploy your full-stack application with monitoring to Azure using Infrastructure as Code.

## 📋 Quick Start Checklist

- [ ] Azure CLI installed and logged in
- [ ] Terraform installed
- [ ] Ansible installed with sshpass
- [ ] GitHub repository ready
- [ ] Domain name configured (optional)
- [ ] All files from this setup in your working directory

## 🎯 **What You'll Get After Deployment:**

```
Your Domain (https://your-domain.com)
├── 🌐 Main Application (Frontend + Backend)
├── 📊 Grafana Dashboard (/grafana)
├── 📈 Prometheus Metrics (/prometheus) 
├── 🗄️ Database Admin (/adminer - db.your-domain.com)
├── 🐳 Container Metrics (/cadvisor)
└── 🔒 Automatic SSL Certificates
```

## 📁 Required Files Structure

Create a new directory and ensure you have all these files:

```
dojo-task-deployment/
├── main.tf                    # ✅ Terraform infrastructure
├── variables.tf               # ✅ Terraform variables
├── outputs.tf                 # ✅ Terraform outputs
├── inventory.tpl              # ✅ Ansible inventory template
├── playbook.yml              # ✅ Ansible configuration
├── deploy.sh                 # ✅ Automated deployment script
├── maintenance.sh            # ✅ Server maintenance script
├── terraform.tfvars          # ⚠️ Create from template below
└── README.md                 # ✅ Documentation
```

## ⚡ **One-Command Deployment:**

```bash
# 1. Make script executable
chmod +x deploy.sh

# 2. Run deployment (interactive mode)
./deploy.sh

# 3. Follow prompts for:
#    - GitHub repository URL
#    - Domain name
#    - Email for SSL certificates
#    - Azure region
```

## 🔧 **Manual Configuration (Alternative):**

### 1. Create Configuration File

```bash
# Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

**terraform.tfvars content:**
```hcl
# Infrastructure Settings
resource_group_name = "rg-dojo-task-prod"
location           = "East US"
vm_size           = "Standard_B4ms"
admin_username    = "azureuser"

# Application Settings  
github_repo = "https://github.com/YOUR_USERNAME/dojo-task.git"
domain_name = "your-domain.com"
email      = "admin@your-domain.com"
```

### 2. Deploy with Terraform

```bash
# Initialize Terraform
terraform init

# Plan deployment  
terraform plan

# Apply (creates VM + runs Ansible automatically)
terraform apply -auto-approve
```

## 🌐 **DNS Configuration Required:**

After deployment, configure your DNS provider to point these domains to your VM's public IP:

```bash
# Get your VM's public IP
terraform output public_ip_address

# Configure these DNS records (A records):
your-domain.com        -> YOUR_VM_IP
www.your-domain.com    -> YOUR_VM_IP  
db.your-domain.com     -> YOUR_VM_IP
```

## 📊 **Post-Deployment Access:**

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| **Main App** | `https://your-domain.com` | - |
| **Grafana** | `https://your-domain.com/grafana` | admin / admin123 |
| **Prometheus** | `https://your-domain.com/prometheus` | - |
| **Adminer** | `https://db.your-domain.com` | Use DB credentials |
| **cAdvisor** | `https://your-domain.com/cadvisor` | - |

## 🔐 **Server Access:**

```bash
# Get SSH credentials
terraform output ssh_connection

# Copy and run the SSH command
sshpass -p 'PASSWORD' ssh azureuser@YOUR_VM_IP

# Or save credentials to file
terraform output -raw vm_password > vm_password.txt
```

## 🛠️ **Server Management:**

Once SSH'd to the server, use the maintenance script:

```bash
# Make maintenance script executable
chmod +x ~/dojo-task/maintenance.sh

# Run interactive maintenance menu
cd ~/dojo-task && ./maintenance.sh

# Or run specific commands:
./maintenance.sh health    # Quick health check
./maintenance.sh update    # Update system
./maintenance.sh backup    # Backup data
./maintenance.sh cleanup   # Clean system
./maintenance.sh security  # Security audit
./maintenance.sh report    # Full health report
```

## 🔄 **Common Management Tasks:**

### Application Updates:
```bash
cd ~/dojo-task
git pull origin main
docker-compose up -d --build
```

### View Logs:
```bash
# All application logs
docker-compose logs -f

# Specific service logs
docker-compose logs -f backend
docker logs traefik
```

### Restart Services:
```bash
# Restart specific service
docker-compose restart backend

# Restart all services
docker-compose down && docker-compose up -d
```

### Check Container Status:
```bash
docker ps
docker-compose ps
docker-compose -f docker-compose.monitoring.yml ps
```

### Monitor System Resources:
```bash
# Real-time system monitoring
htop

# Disk usage
df -h

# Docker resource usage
docker system df
```

## 🚨 **Troubleshooting Guide:**

### SSL Certificate Issues:
```bash
# Check DNS propagation
dig your-domain.com

# View Traefik logs for SSL issues
docker logs traefik

# Force SSL certificate renewal
docker-compose restart traefik
```

### Application Not Accessible:
```bash
# Check if containers are running
docker ps

# Check Traefik routing
docker logs traefik | grep "your-domain"

# Test local connectivity
curl -I http://localhost:80
```

### Database Connection Issues:
```bash
# Check database container
docker-compose logs db

# Test database connection
docker-compose exec db psql -U app -d app -c "\dt"
```

### Monitoring Stack Issues:
```bash
# Restart monitoring stack
docker-compose -f docker-compose.monitoring.yml restart

# Check Grafana
curl -I http://localhost:3000

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets
```

### High Resource Usage:
```bash
# Clean up Docker resources
docker system prune -a -f

# Remove unused volumes
docker volume prune -f

# Check largest files
du -h /home /var | sort -hr | head -20
```

## 📈 **Scaling Options:**

### Vertical Scaling (More Resources):
```bash
# Update VM size in terraform.tfvars
vm_size = "Standard_D8s_v3"  # 8 vCPUs, 32GB RAM

# Apply changes
terraform apply
```

### Horizontal Scaling (Multiple VMs):
```bash
# Deploy additional VMs
terraform workspace new production-2
terraform apply

# Use Azure Load Balancer
# Configure in Azure Portal
```

## 💰 **Cost Management:**

### Development Environment:
```hcl
# terraform.tfvars for dev
vm_size = "Standard_B2ms"  # ~$60-80/month
```

### Production Environment:
```hcl
# terraform.tfvars for prod
vm_size = "Standard_B4ms"  # ~$120-150/month
```

### Cost Optimization Tips:
- Use Azure Reserved Instances for long-term deployments
- Schedule VM shutdown during off-hours
- Monitor costs with Azure Cost Management
- Clean up unused resources regularly

## 🔒 **Security Best Practices:**

### Implemented Security Features:
- ✅ Network Security Groups with minimal required ports
- ✅ Automatic SSL certificates via Let's Encrypt  
- ✅ UFW firewall configuration
- ✅ Container network isolation
- ✅ Password-based authentication with strong passwords

### Additional Security Recommendations:
```bash
# Enable automatic security updates
sudo dpkg-reconfigure -plow unattended-upgrades

# Set up fail2ban for SSH protection
sudo apt install fail2ban

# Monitor logs for suspicious activity
sudo tail -f /var/log/auth.log
```

## 🔄 **CI/CD Integration:**

### GitHub Actions Setup:

1. **Add the GitHub Actions workflow file** to your repository at `.github/workflows/deploy.yml`

2. **Configure GitHub Secrets:**
   - Go to your GitHub repository → Settings → Secrets and variables → Actions
   - Add these secrets:
     ```
     SERVER_HOST: [Your VM Public IP]
     SERVER_USERNAME: azureuser  
     SERVER_PASSWORD: [From terraform output]
     ```

3. **Enable Automatic Deployment:**
   - Push to main branch triggers deployment
   - Includes security scanning and health checks
   - Automatic rollback on failure

## 🧹 **Cleanup and Destruction:**

### Temporary Cleanup (Keep Infrastructure):
```bash
# Stop services
docker-compose down
docker-compose -f docker-compose.monitoring.yml down

# Clean Docker resources
docker system prune -a -f
```

### Complete Cleanup (Destroy Infrastructure):
```bash
# Destroy all Azure resources
terraform destroy -auto-approve

# Clean local files  
rm -f vm_credentials.txt inventory.ini terraform.tfstate*
```

## 📊 **Monitoring and Alerting:**

### Pre-configured Dashboards:
- **System Overview**: CPU, memory, disk usage
- **Container Metrics**: Docker performance
- **Application Metrics**: API response times
- **Infrastructure Health**: Network and storage

### Setting Up Alerts:
1. Access Grafana at `https://your-domain.com/grafana`
2. Login with `admin / admin123`
3. Go to Alerting → Alert Rules
4. Configure alerts for:
   - High CPU usage (>80%)
   - Low disk space (<20%)
   - Container down
   - High response times

### Log Analysis:
- All container logs are centralized in Loki
- Access via Grafana → Explore
- Query examples:
  ```
  {container_name="backend"}
  {container_name="traefik"} |= "error"
  {service="frontend"} |= "404"
  ```

## 🆘 **Getting Help:**

### Diagnostic Commands:
```bash
# Run full health check
./maintenance.sh report

# Check system resources
free -h && df -h

# View recent errors
sudo journalctl --since "1 hour ago" --priority=err

# Check network connectivity  
curl -I https://your-domain.com
```

### Common Issues and Solutions:

| Problem | Diagnostic | Solution |
|---------|------------|----------|
| **Website not loading** | `curl localhost:80` | Check Traefik logs, restart containers |
| **SSL certificate error** | `dig your-domain.com` | Verify DNS, restart Traefik |
| **High memory usage** | `free -h` | Restart services, clean Docker |
| **Disk space low** | `df -h` | Clean logs, prune Docker resources |
| **Database connection failed** | `docker-compose logs db` | Check DB container, restart if needed |

## 🎯 **Next Steps After Deployment:**

1. **✅ Verify DNS Configuration**
   - Test all domain endpoints
   - Confirm SSL certificates are issued

2. **✅ Set Up Monitoring Alerts**
   - Configure Grafana notifications
   - Set up email/Slack alerts

3. **✅ Configure Backups**
   - Schedule automatic backups
   - Test backup restoration

4. **✅ Security Hardening**
   - Review firewall rules
   - Set up log monitoring

5. **✅ Performance Optimization**
   - Monitor resource usage
   - Optimize container resources

## 🏆 **Success Indicators:**

Your deployment is successful when:

- ✅ All containers show "healthy" status
- ✅ Main application loads at your domain
- ✅ Grafana shows system metrics
- ✅ SSL certificates are valid
- ✅ Database is accessible via Adminer
- ✅ Logs are flowing to Loki
- ✅ No critical alerts in monitoring

## 📞 **Support:**

If you encounter issues:

1. **Check the troubleshooting section** above
2. **Run health diagnostics**: `./maintenance.sh health`
3. **Generate full report**: `./maintenance.sh report`
4. **Review container logs**: `docker-compose logs`
5. **Check system resources**: `htop` and `df -h`

---

## 🎉 **Congratulations!**

You now have a production-ready full-stack application with:
- **Automated SSL certificates**
- **Comprehensive monitoring**
- **Centralized logging**
- **Container orchestration**
- **CI/CD pipeline ready**
- **Scalable infrastructure**

**Your application is ready for production! 🚀**
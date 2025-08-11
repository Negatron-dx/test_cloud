# Dojo-Task Application Deployment with Azure, Terraform, and Ansible

This project demonstrates a complete Infrastructure as Code (IaC) solution that deploys a full-stack application with monitoring to Azure using Terraform and Ansible. The setup includes Traefik as a reverse proxy with automatic SSL certificates, comprehensive monitoring with Grafana/Prometheus/Loki stack, and database management with Adminer.

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────────────────┐    ┌─────────────────┐
│   Terraform     │───▶│        Azure VM              │───▶│    Ansible      │
│                 │    │   (Ubuntu 20.04 - 4vCPU)     │    │                 │
│ • Resource Group│    │ • Public IP + DNS            │    │ • Clone GitHub  │
│ • Virtual Network│   │ • Security Groups            │    │ • Install Docker│
│ • VM + Storage  │    │ • Password Auth Enabled      │    │ • Deploy Stack  │
│ • Auto Inventory│    │ • Premium SSD Storage        │    │ • Configure SSL │
└─────────────────┘    └──────────────────────────────┘    └─────────────────┘

Application Stack (Docker Compose):
┌─────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐
│   Traefik   │  │   Frontend   │  │   Backend    │  │ PostgreSQL  │
│ (SSL/Proxy) │  │   (React)    │  │  (FastAPI)   │  │ (Database)  │
└─────────────┘  └──────────────┘  └──────────────┘  └─────────────┘

Monitoring Stack:
┌─────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐
│  Grafana    │  │ Prometheus   │  │     Loki     │  │  cAdvisor   │
│ (Dashboards)│  │ (Metrics)    │  │  (Logs)      │  │ (Container) │
└─────────────┘  └──────────────┘  └──────────────┘  └─────────────┘
```

## 🎯 **What This Setup Does:**

1. **Infrastructure Provisioning (Terraform)**:
   - Creates Azure VM with Ubuntu 20.04 LTS
   - Configures networking, security groups, and storage
   - Generates secure password authentication
   - Creates dynamic Ansible inventory

2. **Server Configuration (Ansible)**:
   - Installs Docker, Docker Compose, and dependencies
   - Clones your GitHub repository
   - Configures monitoring stack (Prometheus, Grafana, Loki)
   - Deploys application with Traefik reverse proxy
   - Sets up automatic SSL certificates

3. **Application Deployment**:
   - Traefik handles routing and SSL termination
   - Frontend, backend, and database containers
   - Comprehensive monitoring and logging
   - Database administration interface

## 📋 Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed and configured:
   ```bash
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   az login
   ```

2. **Terraform** installed:
   ```bash
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install terraform
   ```

3. **Ansible** installed:
   ```bash
   sudo apt update && sudo apt install ansible sshpass
   ```

4. **GitHub Repository** with your dojo-task application

5. **Domain Name** (optional) for SSL certificates

## 📁 Project Structure

```
terraform-ansible-dojo-task/
├── main.tf                          # Main Terraform configuration
├── variables.tf                     # Terraform variables
├── outputs.tf                      # Terraform outputs
├── terraform.tfvars               # Configuration values (create from template)
├── inventory.tpl                   # Ansible inventory template
├── playbook.yml                    # Ansible playbook
├── vault.yml                       # Encrypted secrets (optional)
├── deploy.sh                       # Automated deployment script
└── README.md                       # This file
```

## 🚀 Quick Deployment

### Option 1: Interactive Deployment (Recommended)

1. **Clone this repository** and navigate to the directory

2. **Make the deployment script executable:**
   ```bash
   chmod +x deploy.sh
   ```

3. **Run the interactive deployment:**
   ```bash
   ./deploy.sh
   ```

The script will prompt you for:
- GitHub repository URL
- Domain name
- Email for SSL certificates
- Azure region

### Option 2: Configuration File Deployment

1. **Create configuration file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit configuration:**
   ```bash
   nano terraform.tfvars
   ```

3. **Deploy with configuration:**
   ```bash
   terraform init
   terraform apply -auto-approve
   ```

## 🔧 Configuration Options

### Terraform Variables (terraform.tfvars)

```hcl
# Infrastructure
resource_group_name = "rg-dojo-task-prod"
location           = "East US"
vm_size           = "Standard_B4ms"    # 4 vCPUs, 16GB RAM

# Application
github_repo = "https://github.com/yourusername/dojo-task.git"
domain_name = "your-domain.com"
email      = "admin@your-domain.com"
```

### VM Size Options

| Size | vCPUs | RAM | Use Case |
|------|-------|-----|----------|
| Standard_B2ms | 2 | 8GB | Development/Testing |
| Standard_B4ms | 4 | 16GB | Production (Recommended) |
| Standard_D4s_v3 | 4 | 16GB | High Performance |
| Standard_D8s_v3 | 8 | 32GB | High Load |

## 🌐 Application URLs

After deployment, access your application at:

- **Main Application**: `https://your-domain.com`
- **Grafana Dashboard**: `https://your-domain.com/grafana`
- **Prometheus**: `https://your-domain.com/prometheus`
- **Database Admin**: `https://db.your-domain.com`
- **Container Metrics**: `https://your-domain.com/cadvisor`

## 🔐 Security Features

- **Password-based SSH** (automatically generated)
- **Network Security Groups** with minimal required ports
- **Automatic SSL certificates** via Let's Encrypt
- **Firewall configuration** with UFW
- **Container isolation** with Docker networks
- **Encrypted secrets** support with Ansible Vault

## 📊 Monitoring Stack

### Pre-configured Dashboards
- **System Overview**: CPU, Memory, Disk usage
- **Container Metrics**: Docker containers performance
- **Application Metrics**: API response times, error rates
- **Infrastructure**: Network, storage, and system health

### Log Aggregation
- **Centralized Logging**: All container logs in Loki
- **Log Retention**: Configurable retention policies
- **Search & Filter**: Advanced log querying in Grafana

## 🔧 Management Commands

### Deployment Management
```bash
# Test SSH connectivity
./deploy.sh test

# Perform health checks
./deploy.sh health

# Destroy infrastructure
./deploy.sh destroy
```

### Server Management (SSH to server)
```bash
# View all containers
docker ps

# Check application logs
cd ~/dojo-task && docker-compose logs -f

# Restart specific service
docker-compose restart backend

# Update application
git pull && docker-compose up -d --build

# Monitor resources
htop
df -h
```

### Monitoring Commands
```bash
# View Grafana logs
docker logs grafana

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Test Loki
curl http://localhost:3100/ready
```

## 🚨 Troubleshooting

### Common Issues

1. **SSL Certificate Issues**:
   ```bash
   # Check DNS propagation
   dig your-domain.com
   
   # View Traefik logs
   docker logs traefik
   
   # Restart Traefik
   docker-compose restart traefik
   ```

2. **Container Issues**:
   ```bash
   # Check container status
   docker-compose ps
   
   # View specific logs
   docker-compose logs backend
   
   # Restart all services
   docker-compose down && docker-compose up -d
   ```

3. **Database Connection Issues**:
   ```bash
   # Check database logs
   docker-compose logs db
   
   # Test database connection
   docker-compose exec db psql -U app -d app
   ```

4. **Monitoring Stack Issues**:
   ```bash
   # Restart monitoring stack
   docker-compose -f docker-compose.monitoring.yml restart
   
   # Check Grafana configuration
   docker logs grafana
   ```

### Resource Monitoring

```bash
# Check disk usage
df -h

# Monitor memory
free -h

# Check Docker resource usage
docker system df

# Clean up Docker resources
docker system prune -f
```

## 🔄 CI/CD Integration

The setup includes GitHub Actions workflow for automated deployment:

1. **Copy the workflow file** to `.github/workflows/deploy.yml`
2. **Configure GitHub Secrets**:
   - `SERVER_HOST`: Your VM's public IP
   - `SERVER_USERNAME`: VM username (azureuser)
   - `SERVER_PASSWORD`: VM password (from Terraform output)

3. **Workflow Features**:
   - Automatic deployment on push to main
   - Security scanning with Trivy
   - Health checks and rollback capability
   - Slack notifications (optional)

## 💰 Cost Optimization

### For Development/Testing:
- Use `Standard_B2ms` VM size
- Schedule VM shutdown during non-work hours
- Use Azure Dev/Test pricing if eligible

### For Production:
- Consider Reserved Instances for 1-3 year commitments
- Monitor resource usage with Azure Cost Management
- Set up budget alerts

### Estimated Monthly Costs (East US):
- **Standard_B2ms**: ~$60-80/month
- **Standard_B4ms**: ~$120-150/month
- **Storage & Network**: ~$10-20/month

## 📈 Scaling Options

### Vertical Scaling:
```bash
# Update VM size in terraform.tfvars
vm_size = "Standard_D8s_v3"

# Apply changes
terraform apply
```

### Horizontal Scaling:
- Set up Azure Load Balancer
- Deploy multiple VMs
- Use Azure Container Instances for services
- Consider AKS for Kubernetes orchestration

## 🧹 Cleanup

### Temporary Cleanup:
```bash
# Stop services
cd ~/dojo-task
docker-compose down
docker-compose -f docker-compose.monitoring.yml down

# Clean Docker resources
docker system prune -a -f
```

### Complete Cleanup:
```bash
# Destroy all Azure resources
terraform destroy -auto-approve

# Clean local files
rm -f vm_credentials.txt inventory.ini terraform.tfstate*
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## 📜 License

This project is licensed under the MIT License. See LICENSE file for details.

## 🆘 Support

For issues and questions:

1. **Check troubleshooting section** above
2. **Review logs** on the deployed server
3. **Create GitHub issue** with detailed error information
4. **Include relevant logs** and configuration details

---

## 📚 Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Grafana Documentation](https://grafana.com/docs/)

---

**Happy Deploying! 🚀**
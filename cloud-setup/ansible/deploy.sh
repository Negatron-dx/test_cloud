#!/bin/bash
# deploy.sh - Complete deployment script for Dojo-Task Application

set -e

echo "🚀 Starting Dojo-Task Application deployment with Terraform and Ansible..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
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

print_section() {
    echo -e "${PURPLE}[SECTION]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_section "Checking prerequisites..."
    
    # Check if Azure CLI is installed and logged in
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        echo "Install with: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
        exit 1
    fi
    
    # Check if logged into Azure
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure. Please run 'az login' first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        print_error "Ansible is not installed. Please install it first."
        echo "Install with: sudo apt update && sudo apt install ansible"
        exit 1
    fi
    
    # Check if sshpass is installed
    if ! command -v sshpass &> /dev/null; then
        print_warning "sshpass not found. Installing..."
        sudo apt update && sudo apt install sshpass -y
    fi
    
    print_success "All prerequisites are met!"
}

# Get user configuration
get_configuration() {
    print_section "Configuration Setup"
    
    echo "Please provide the following configuration:"
    echo ""
    
    # GitHub repository
    read -p "Enter your GitHub repository URL (https://github.com/username/repo.git): " GITHUB_REPO
    if [[ -z "$GITHUB_REPO" ]]; then
        print_error "GitHub repository URL is required!"
        exit 1
    fi
    
    # Domain name
    read -p "Enter your domain name (e.g., dojo-task.com): " DOMAIN_NAME
    if [[ -z "$DOMAIN_NAME" ]]; then
        print_error "Domain name is required!"
        exit 1
    fi
    
    # Email for SSL certificates
    read -p "Enter email for SSL certificates (e.g., admin@$DOMAIN_NAME): " EMAIL
    if [[ -z "$EMAIL" ]]; then
        EMAIL="admin@$DOMAIN_NAME"
    fi
    
    # Azure region
    read -p "Enter Azure region [East US]: " AZURE_REGION
    if [[ -z "$AZURE_REGION" ]]; then
        AZURE_REGION="East US"
    fi
    
    echo ""
    print_status "Configuration Summary:"
    echo "  GitHub Repository: $GITHUB_REPO"
    echo "  Domain Name: $DOMAIN_NAME"
    echo "  Email: $EMAIL"
    echo "  Azure Region: $AZURE_REGION"
    echo ""
}

# Initialize Terraform
init_terraform() {
    print_section "Initializing Terraform..."
    terraform init
    print_success "Terraform initialized successfully!"
}

# Plan Terraform deployment
plan_terraform() {
    print_section "Planning Terraform deployment..."
    terraform plan \
        -var="github_repo=$GITHUB_REPO" \
        -var="domain_name=$DOMAIN_NAME" \
        -var="email=$EMAIL" \
        -var="location=$AZURE_REGION" \
        -out=tfplan
    print_success "Terraform plan created successfully!"
}

# Apply Terraform deployment
apply_terraform() {
    print_section "Applying Terraform deployment..."
    terraform apply tfplan
    print_success "Terraform deployment completed successfully!"
}

# Show deployment results
show_results() {
    print_section "Deployment Results"
    echo ""
    
    # Get outputs
    VM_IP=$(terraform output -raw public_ip_address)
    VM_USER=$(terraform output -raw vm_username)
    
    echo "🎉 Your Dojo-Task application has been deployed successfully!"
    echo ""
    echo "📋 Server Information:"
    echo "  Public IP: $VM_IP"
    echo "  Username: $VM_USER"
    echo "  SSH Command: $(terraform output -raw ssh_connection)"
    echo ""
    echo "🌐 Application URLs (after DNS configuration):"
    echo "  Main App: https://$DOMAIN_NAME"
    echo "  Grafana: https://$DOMAIN_NAME/grafana"
    echo "  Prometheus: https://$DOMAIN_NAME/prometheus"
    echo "  Adminer: https://db.$DOMAIN_NAME"
    echo "  cAdvisor: https://$DOMAIN_NAME/cadvisor"
    echo ""
    echo "🔐 Default Credentials:"
    echo "  Grafana: admin / admin123"
    echo ""
    echo "⚠️  DNS Configuration Required:"
    echo "  Configure your DNS provider to point these domains to $VM_IP:"
    echo "  - $DOMAIN_NAME"
    echo "  - www.$DOMAIN_NAME"
    echo "  - db.$DOMAIN_NAME"
    echo ""
    echo "📁 Useful Commands:"
    echo "  - Check container status: ssh to server and run 'docker ps'"
    echo "  - View application logs: 'cd ~/dojo-task && docker-compose logs -f'"
    echo "  - Restart services: 'cd ~/dojo-task && docker-compose restart'"
    echo "  - Update application: 'cd ~/dojo-task && git pull && docker-compose up -d --build'"
    echo ""
    echo "🔧 Monitoring:"
    echo "  - Grafana dashboards are pre-configured for container monitoring"
    echo "  - Prometheus is collecting metrics from all services"
    echo "  - Loki is aggregating logs from all containers"
    echo "  - Traefik is handling SSL certificates automatically"
    echo ""
}

# Main deployment function
main() {
    echo "======================================================"
    echo "🌩️  Dojo-Task Application Deployment"
    echo "     Azure + Terraform + Ansible + Docker + Traefik"
    echo "======================================================"
    echo ""
    
    check_prerequisites
    echo ""
    
    get_configuration
    echo ""
    
    # Ask for confirmation before proceeding
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled by user."
        exit 0
    fi
    echo ""
    
    init_terraform
    echo ""
    
    plan_terraform
    echo ""
    
    # Final confirmation before applying
    print_warning "This will create Azure resources that will incur costs."
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled by user."
        exit 0
    fi
    echo ""
    
    apply_terraform
    echo ""
    
    show_results
    echo ""
    
    print_success "🎉 Deployment completed successfully!"
    echo ""
    echo "📝 Next Steps:"
    echo "1. Configure DNS records as shown above"
    echo "2. Wait for SSL certificates to be generated (may take a few minutes)"
    echo "3. Access your application at https://$DOMAIN_NAME"
    echo ""
    echo "💡 Troubleshooting:"
    echo "- If SSL fails, check DNS propagation with: dig $DOMAIN_NAME"
    echo "- View Traefik logs: ssh to server and run 'docker logs traefik'"
    echo "- Check all services: 'docker ps' and 'docker-compose ps'"
    echo ""
    echo "🗑️  To destroy the infrastructure when done:"
    echo "terraform destroy"
}

# Cleanup function
cleanup() {
    print_status "Cleaning up temporary files..."
    rm -f tfplan
    print_success "Cleanup completed!"
}

# Test connectivity function
test_connectivity() {
    if [[ -f "vm_credentials.txt" ]]; then
        source vm_credentials.txt
        print_status "Testing SSH connectivity to $VM_IP..."
        if sshpass -p "$VM_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$VM_USERNAME@$VM_IP" "echo 'SSH connection successful'"; then
            print_success "SSH connectivity confirmed!"
        else
            print_error "SSH connectivity test failed!"
        fi
    fi
}

# Health check function
health_check() {
    if [[ -f "vm_credentials.txt" ]]; then
        source vm_credentials.txt
        print_section "Performing health checks..."
        
        sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no "$VM_USERNAME@$VM_IP" << 'EOF'
echo "=== Docker Status ==="
sudo systemctl status docker --no-pager -l

echo ""
echo "=== Running Containers ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=== Container Health ==="
cd ~/dojo-task
docker-compose ps

echo ""
echo "=== Disk Usage ==="
df -h

echo ""
echo "=== Memory Usage ==="
free -h

echo ""
echo "=== Network Ports ==="
sudo netstat -tulpn | grep LISTEN | head -10
EOF
    fi
}

# Trap to cleanup on exit
trap cleanup EXIT

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main "$@"
        ;;
    "test")
        test_connectivity
        ;;
    "health")
        health_check
        ;;
    "destroy")
        print_warning "This will destroy all Azure resources!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            terraform destroy -auto-approve
            print_success "Resources destroyed successfully!"
        fi
        ;;
    *)
        echo "Usage: $0 [deploy|test|health|destroy]"
        echo "  deploy  - Deploy the full application (default)"
        echo "  test    - Test SSH connectivity to deployed VM"
        echo "  health  - Perform health checks on deployed services"
        echo "  destroy - Destroy all Azure resources"
        exit 1
        ;;
esac
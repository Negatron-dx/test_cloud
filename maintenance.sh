#!/bin/bash
# maintenance.sh - Server maintenance and monitoring script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

DEPLOY_DIR="/home/$USER/dojo-task"

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

# Check system health
check_system_health() {
    print_section "System Health Check"
    
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime -p)"
    echo "Load Average: $(uptime | awk -F'load average:' '{ print $2 }')"
    echo "Kernel: $(uname -r)"
    echo ""
    
    echo "=== Memory Usage ==="
    free -h
    echo ""
    
    echo "=== Disk Usage ==="
    df -h | grep -E '^/dev/'
    echo ""
    
    echo "=== Network Connections ==="
    ss -tuln | head -10
    echo ""
    
    # Check critical services
    echo "=== Critical Services Status ==="
    for service in docker ufw ssh; do
        if systemctl is-active --quiet $service; then
            print_success "$service is running"
        else
            print_error "$service is not running"
        fi
    done
    echo ""
}

# Check Docker health
check_docker_health() {
    print_section "Docker Health Check"
    
    echo "=== Docker Version ==="
    docker --version
    docker-compose --version
    echo ""
    
    echo "=== Docker System Information ==="
    docker system df
    echo ""
    
    echo "=== Running Containers ==="
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.RunningFor}}"
    echo ""
    
    echo "=== Container Health Status ==="
    for container in $(docker ps --format "{{.Names}}"); do
        health=$(docker inspect --format='{{.State.Health.Status}}' $container 2>/dev/null || echo "no-healthcheck")
        if [ "$health" = "healthy" ]; then
            print_success "$container: $health"
        elif [ "$health" = "no-healthcheck" ]; then
            echo "$container: no health check configured"
        else
            print_warning "$container: $health"
        fi
    done
    echo ""
    
    echo "=== Docker Networks ==="
    docker network ls
    echo ""
}

# Check application health
check_application_health() {
    print_section "Application Health Check"
    
    cd $DEPLOY_DIR || { print_error "Deploy directory not found"; return 1; }
    
    echo "=== Application Containers ==="
    docker-compose ps
    echo ""
    
    echo "=== Monitoring Containers ==="
    docker-compose -f docker-compose.monitoring.yml ps
    echo ""
    
    echo "=== Endpoint Health Checks ==="
    endpoints=(
        "http://localhost:80:Main Application"
        "http://localhost:3000:Grafana"
        "http://localhost:9090:Prometheus"
        "http://localhost:3100/ready:Loki"
        "http://localhost:8080/healthz:cAdvisor"
    )
    
    for endpoint in "${endpoints[@]}"; do
        IFS=':' read -r url name <<< "$endpoint"
        if curl -f -s -m 5 "$url" > /dev/null 2>&1; then
            print_success "$name is responding"
        else
            print_error "$name is not responding"
        fi
    done
    echo ""
}

# Update system and containers
update_system() {
    print_section "System Update"
    
    # Update system packages
    print_status "Updating system packages..."
    sudo apt update
    sudo apt upgrade -y
    sudo apt autoremove -y
    sudo apt autoclean
    
    # Update Docker images
    print_status "Updating Docker images..."
    cd $DEPLOY_DIR
    docker-compose pull
    docker-compose -f docker-compose.monitoring.yml pull
    
    print_success "System update completed"
}

# Backup data
backup_data() {
    print_section "Data Backup"
    
    BACKUP_DIR="/home/$USER/backups"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p $BACKUP_DIR
    
    # Backup application data
    print_status "Backing up application data..."
    tar -czf "$BACKUP_DIR/dojo-task-backup-$TIMESTAMP.tar.gz" -C /home/$USER dojo-task
    
    # Backup Docker volumes
    print_status "Backing up Docker volumes..."
    docker run --rm \
        -v dojo-task_db_data:/source:ro \
        -v $BACKUP_DIR:/backup \
        alpine tar -czf /backup/db-data-$TIMESTAMP.tar.gz -C /source .
    
    # Backup monitoring data
    docker run --rm \
        -v dojo-task_grafana-data:/source:ro \
        -v $BACKUP_DIR:/backup \
        alpine tar -czf /backup/grafana-data-$TIMESTAMP.tar.gz -C /source .
    
    print_success "Backup completed: $BACKUP_DIR"
    
    # Clean old backups (keep last 7 days)
    find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
}

# Clean up system
cleanup_system() {
    print_section "System Cleanup"
    
    # Clean Docker resources
    print_status "Cleaning Docker resources..."
    docker system prune -f
    docker volume prune -f
    docker image prune -a -f
    
    # Clean system logs
    print_status "Cleaning system logs..."
    sudo journalctl --vacuum-time=7d
    
    # Clean package cache
    print_status "Cleaning package cache..."
    sudo apt clean
    sudo apt autoremove -y
    
    print_success "System cleanup completed"
}

# Monitor logs
monitor_logs() {
    print_section "Log Monitoring"
    
    cd $DEPLOY_DIR
    
    echo "Select log source to monitor:"
    echo "1. All application logs"
    echo "2. Traefik logs"
    echo "3. Backend logs"
    echo "4. Frontend logs"
    echo "5. Database logs"
    echo "6. Grafana logs"
    echo "7. Prometheus logs"
    echo "8. System logs"
    
    read -p "Enter choice (1-8): " choice
    
    case $choice in
        1) docker-compose logs -f ;;
        2) docker logs -f traefik ;;
        3) docker-compose logs -f backend ;;
        4) docker-compose logs -f frontend ;;
        5) docker-compose logs -f db ;;
        6) docker logs -f grafana ;;
        7) docker logs -f prometheus ;;
        8) sudo journalctl -f ;;
        *) print_error "Invalid choice" ;;
    esac
}

# Restart services
restart_services() {
    print_section "Service Restart"
    
    cd $DEPLOY_DIR
    
    echo "Select service to restart:"
    echo "1. All application services"
    echo "2. All monitoring services"
    echo "3. Traefik only"
    echo "4. Backend only"
    echo "5. Frontend only"
    echo "6. Database only"
    echo "7. Grafana only"
    echo "8. Prometheus only"
    
    read -p "Enter choice (1-8): " choice
    
    case $choice in
        1) 
            print_status "Restarting all application services..."
            docker-compose restart
            ;;
        2) 
            print_status "Restarting all monitoring services..."
            docker-compose -f docker-compose.monitoring.yml restart
            ;;
        3) docker-compose restart traefik ;;
        4) docker-compose restart backend ;;
        5) docker-compose restart frontend ;;
        6) docker-compose restart db ;;
        7) docker restart grafana ;;
        8) docker restart prometheus ;;
        *) print_error "Invalid choice" ;;
    esac
    
    print_success "Service restart completed"
}

# Security check
security_check() {
    print_section "Security Check"
    
    echo "=== SSH Configuration ==="
    print_status "Checking SSH security..."
    grep -E "^(PermitRootLogin|PasswordAuthentication|Port)" /etc/ssh/sshd_config || true
    echo ""
    
    echo "=== Firewall Status ==="
    sudo ufw status verbose
    echo ""
    
    echo "=== Failed Login Attempts ==="
    sudo grep "Failed password" /var/log/auth.log | tail -5 || print_status "No recent failed login attempts"
    echo ""
    
    echo "=== Open Ports ==="
    sudo netstat -tulpn | grep LISTEN | head -10
    echo ""
    
    echo "=== SSL Certificate Status ==="
    cd $DEPLOY_DIR
    if [ -d "traefik-certificates" ]; then
        print_status "SSL certificates directory exists"
        docker exec traefik ls -la /letsencrypt/ || print_warning "Cannot check SSL certificates"
    else
        print_warning "SSL certificates directory not found"
    fi
    echo ""
}

# Performance metrics
performance_metrics() {
    print_section "Performance Metrics"
    
    echo "=== CPU Usage (top 10 processes) ==="
    ps aux --sort=-%cpu | head -11
    echo ""
    
    echo "=== Memory Usage (top 10 processes) ==="
    ps aux --sort=-%mem | head -11
    echo ""
    
    echo "=== IO Statistics ==="
    iostat -x 1 1 2>/dev/null || print_warning "iostat not available (install with: sudo apt install sysstat)"
    echo ""
    
    echo "=== Network Statistics ==="
    ss -i | grep -E "(ESTAB|LISTEN)" | wc -l
    echo "Active connections: $(ss -i | grep ESTAB | wc -l)"
    echo "Listening ports: $(ss -i | grep LISTEN | wc -l)"
    echo ""
}

# Interactive menu
show_menu() {
    clear
    echo "======================================================"
    echo "🔧  Dojo-Task Server Maintenance Menu"
    echo "======================================================"
    echo "1.  System Health Check"
    echo "2.  Docker Health Check"
    echo "3.  Application Health Check"
    echo "4.  Monitor Logs"
    echo "5.  Restart Services"
    echo "6.  Update System & Containers"
    echo "7.  Backup Data"
    echo "8.  Cleanup System"
    echo "9.  Security Check"
    echo "10. Performance Metrics"
    echo "11. Full Health Report"
    echo "0.  Exit"
    echo "======================================================"
}

# Full health report
full_health_report() {
    print_section "Generating Full Health Report"
    
    REPORT_FILE="/tmp/health-report-$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "Dojo-Task Server Health Report"
        echo "Generated: $(date)"
        echo "========================================"
        echo ""
        
        check_system_health
        check_docker_health
        check_application_health
        security_check
        performance_metrics
        
    } | tee $REPORT_FILE
    
    print_success "Full health report saved to: $REPORT_FILE"
}

# Main menu loop
main() {
    while true; do
        show_menu
        read -p "Enter your choice (0-11): " choice
        
        case $choice in
            1) check_system_health ;;
            2) check_docker_health ;;
            3) check_application_health ;;
            4) monitor_logs ;;
            5) restart_services ;;
            6) update_system ;;
            7) backup_data ;;
            8) cleanup_system ;;
            9) security_check ;;
            10) performance_metrics ;;
            11) full_health_report ;;
            0) 
                print_success "Goodbye!"
                exit 0
                ;;
            *) 
                print_error "Invalid choice. Please try again."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "This script should not be run as root for most operations"
    print_warning "Some operations may fail or behave differently"
fi

# Handle script arguments
case "${1:-menu}" in
    "menu") main ;;
    "health") check_system_health && check_docker_health && check_application_health ;;
    "update") update_system ;;
    "backup") backup_data ;;
    "cleanup") cleanup_system ;;
    "security") security_check ;;
    "report") full_health_report ;;
    *)
        echo "Usage: $0 [menu|health|update|backup|cleanup|security|report]"
        echo "  menu     - Interactive menu (default)"
        echo "  health   - Quick health check"
        echo "  update   - Update system and containers"
        echo "  backup   - Backup data"
        echo "  cleanup  - Clean up system"
        echo "  security - Security check"
        echo "  report   - Generate full health report"
        exit 1
        ;;
esac
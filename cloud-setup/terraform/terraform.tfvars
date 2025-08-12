# Resource configuration
resource_group_name = "rg-dojo-task-prod"
location           = "West US 2"
prefix             = "dojo-task-prod"
vm_size           = "Standard_B4ms"  # 4 vCPUs, 16GB RAM
admin_username    = "azureuser"

# Application configuration
github_repo = "https://github.com/mroluwasesan/full-stack-FastAPI-backend-and-React-Frontend.git"
domain_name = "dojo-task.com"
email      = "admin@dojo-task.com"
#github_repo = "https://github.com/yourusername/dojo-task.git https://github.com/mroluwasesan/full-stack-FastAPI-backend-and-React-Frontend.git"
#domain_name = "your-domain.com"
#email      = "admin@your-domain.com"


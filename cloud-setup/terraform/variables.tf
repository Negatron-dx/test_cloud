variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-dojo-task"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "dojo-task"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B4ms"  # 4 vCPUs, 16GB RAM - suitable for Docker containers
}

variable "admin_username" {
  description = "Administrator username for the VM"
  type        = string
  default     = "azureuser"
}

variable "github_repo" {
  description = "GitHub repository URL"
  type        = string
  default     = "https://github.com/yourusername/dojo-task.git"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "dojo-task.com"
}

variable "email" {
  description = "Email for Let's Encrypt SSL certificates"
  type        = string
  default     = "admin@dojo-task.com"
}
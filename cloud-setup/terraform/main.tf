terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1"
    }
  }
}

provider "azurerm" {
  features {}
}

# Generate random password
resource "random_password" "vm_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Public IP
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-publicip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Grafana"
    priority                   = 106
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Prometheus"
    priority                   = 108
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9090"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# Associate Network Security Group to the Network Interface
resource "azurerm_network_interface_security_group_association" "main" {
  depends_on           = [azurerm_network_security_group.main]
  network_interface_id = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.prefix}-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username

  # Enable password authentication
  disable_password_authentication = false
  admin_password                  = random_password.vm_password.result

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  # Wait for VM to be ready
  provisioner "remote-exec" {
    inline = ["echo 'VM is ready'"]
    
    connection {
      type     = "ssh"
      host     = azurerm_public_ip.main.ip_address
      user     = var.admin_username
      password = random_password.vm_password.result
    }
  }
}

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  depends_on = [azurerm_linux_virtual_machine.main]
  content = templatefile("${path.module}/../ansible/inventory.tpl", {
    vm_ip = azurerm_public_ip.main.ip_address
    admin_username = var.admin_username
    admin_password = random_password.vm_password.result
  })
  filename = "${path.module}/../ansible/inventory.ini"
}

# Save VM credentials
resource "local_file" "vm_credentials" {
  depends_on = [azurerm_linux_virtual_machine.main]
  content = <<-EOT
VM_IP=${azurerm_public_ip.main.ip_address}
VM_USERNAME=${var.admin_username}
VM_PASSWORD=${random_password.vm_password.result}
SSH_COMMAND=sshpass -p '${random_password.vm_password.result}' ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}
EOT
  filename = "${path.module}/vm_credentials.txt"
  file_permission = "0600"
}

# Run Ansible playbook
resource "null_resource" "run_ansible" {
  depends_on = [
    azurerm_linux_virtual_machine.main,
    local_file.ansible_inventory,
    local_file.vm_credentials
  ]

  triggers = {
    vm_id = azurerm_linux_virtual_machine.main.id
  }

  provisioner "local-exec" {
  command = "ansible-playbook -i ${path.module}/../ansible/inventory.ini ${path.module}/../ansible/playbook.yml"
  }
}
output "public_ip_address" {
  description = "The public IP address of the virtual machine"
  value       = azurerm_public_ip.main.ip_address
}

output "vm_username" {
  description = "VM username"
  value       = var.admin_username
}

output "vm_password" {
  description = "VM password"
  value       = random_password.vm_password.result
  sensitive   = true
}

output "ssh_connection" {
  description = "SSH connection command"
  value       = "sshpass -p '${random_password.vm_password.result}' ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
  sensitive   = true
}

output "application_urls" {
  description = "Application URLs"
  value = {
    main_app    = "https://${var.domain_name}"
    grafana     = "https://${var.domain_name}/grafana"
    prometheus  = "https://${var.domain_name}/prometheus"
    adminer     = "https://db.${var.domain_name}"
    cadvisor    = "https://${var.domain_name}/cadvisor"
  }
}

output "dns_configuration" {
  description = "DNS configuration required"
  value = {
    message = "Please configure your DNS to point the following domains to ${azurerm_public_ip.main.ip_address}:"
    domains = [
      var.domain_name,
      "www.${var.domain_name}",
      "db.${var.domain_name}"
    ]
  }
}
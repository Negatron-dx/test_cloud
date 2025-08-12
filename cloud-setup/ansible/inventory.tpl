[webservers]
${vm_ip} ansible_user=${admin_username} ansible_password=${admin_password} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
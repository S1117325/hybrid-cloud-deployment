[azure]
${azure_vm_name} ansible_host=${azure_vm_ip}

[azure:vars]
ansible_user=${ssh_user}
ansible_ssh_private_key_file=~/.ssh/azure
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

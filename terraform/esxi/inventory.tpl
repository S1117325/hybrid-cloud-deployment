[esxi]
databaseserver ansible_host=${esxi_vm_ip}

[esxi:vars]
ansible_user=${ssh_user}
ansible_ssh_private_key_file=~/.ssh/skylab
ansible_ssh_common_args='-o StrictHostKeyChecking=no'


# Force Python 3 for Ansible
ansible_python_interpreter=/usr/bin/python3

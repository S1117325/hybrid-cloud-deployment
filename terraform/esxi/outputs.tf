output "databaseserver_ip" {
  value = esxi_guest.databaseserver.guest_name
}

output "ansible_inventory" {
  value = "Inventory file generated at: ${path.module}/inventory.ini"
}

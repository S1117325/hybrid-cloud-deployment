output "esxi_vm_ip" {
  description = "Het IP-adres van de ESXi databaseserver VM"
  value       = esxi_guest.databaseserver.ip_address
}

output "esxi_vm_name" {
  description = "De naam van de ESXi VM"
  value       = esxi_guest.databaseserver.guest_name
}
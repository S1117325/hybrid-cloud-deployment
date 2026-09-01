resource "esxi_guest" "databaseserver" {
  guest_name  = "databaseserver"
  disk_store  = "datastore1"
  memsize     = "2048"
  numvcpus    = "1"
  power       = "on"

  ovf_source = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.ova"

  network_interfaces {
    virtual_network = "VM Network"
  }

  guest_startup_timeout  = 45
  guest_shutdown_timeout = 30

guestinfo = {
  "metadata"          = base64encode(templatefile("${path.module}/metadata.yaml", { hostname = "databaseserver" }))
  "metadata.encoding" = "base64"
  "userdata" = base64encode(templatefile("${path.module}/userdata.yaml", {
    ssh_public_key            = file(var.ssh_public_key_path),
    ssh_private_key_azure_b64 = base64encode(file(var.ssh_private_key_path))
}))
  "userdata.encoding" = "base64"
}

}

resource "local_file" "esxi_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    esxi_vm_ip   = esxi_guest.databaseserver.ip_address,
    ssh_user     = "test_user"
  })

  filename = "${path.module}/../../ansible/esxi_inventory.ini"
}
resource "null_resource" "ansible_provisioner_esxi" {
  depends_on = [esxi_guest.databaseserver]

    # Draai Ansible opnieuw zodra de VM verandert (bv. bij -replace of nieuw IP)
  triggers = {
    vm_id = esxi_guest.databaseserver.id
    vm_ip = esxi_guest.databaseserver.ip_address
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/../../ansible/esxi_inventory.ini ${path.module}/../../ansible/playbook.yml"
  }
}


output "azure_public_ip" {
  value = esxi_guest.databaseserver.ip_address
}


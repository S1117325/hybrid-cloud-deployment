variable "prefix" {
  description = "Prefix voor alle resources en de resource group"
  default     = "S1117325"
}

variable "location" {
  description = "De Azure regio waarin de resources worden aangemaakt"
  default     = "West Europe"
}

variable "vm_count" {
  description = "Aantal VM's dat zal worden aangemaakt"
  default     = 1
}

variable "vm_size" {
  description = "De VM grootte"
  default     = "Standard_B2ats_v2"
}

variable "admin_username" {
  description = "De gebruikersnaam voor de VM"
  default     = "test_user"
}

variable "ssh_public_key_path" {
  description = "Het pad naar de SSH public key (de key die al geüpload is)"
  default     = "~/.ssh/azure.pub"
}

variable "cloudinit_file" {
  description = "Pad naar het CloudInit bestand"
  default     = "cloud-init.yml"
}

variable "subscription_id" {
  description = "Jouw eigen Azure subscription ID. Zet via TF_VAR_subscription_id of secret.auto.tfvars (gitignored), NIET hardcoden."
  type        = string
}

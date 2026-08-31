variable "esxi_hostname" {
  description = "Hostname of the ESXi server"
  type        = string
}

variable "esxi_hostport" {
  description = "SSH Port for ESXi"
  type        = string
  default     = "22"
}

variable "esxi_hostssl" {
  description = "SSL Port for ESXi"
  type        = string
  default     = "443"
}

variable "esxi_username" {
  description = "Username for ESXi"
  type        = string
}

variable "esxi_password" {
  description = "Password for ESXi"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to the public key used to log into ESXi VM"
  type        = string
  default     = "~/.ssh/skylab.pub"
}

variable "ssh_private_key_path" {
  description = "Path to the private key used to connect from ESXi to Azure"
  type        = string
  default     = "~/.ssh/azure"
}


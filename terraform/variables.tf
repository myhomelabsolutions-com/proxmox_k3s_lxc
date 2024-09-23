variable "proxmox_api_url" {
  description = "Proxmox API URL"
  default     = "https://10.0.0.99:8006/api2/json"
}

variable "proxmox_user" {
  description = "Proxmox user"
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox password"
  default     = "password"
}

variable "proxmox_node" {
  description = "Proxmox node name"
  default     = "pve"
}

variable "lxc_template" {
  description = "LXC template for k3s nodes"
  default     = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
}

variable "lxc_password" {
  description = "Password for LXC containers"
  type        = string
}

variable "lxc_cores" {
  description = "Number of CPU cores for LXC containers"
  type        = number
  default     = 2
}

variable "lxc_memory" {
  description = "Amount of memory for LXC containers (in MB)"
  type        = number
  default     = 2048
}

variable "lxc_swap" {
  description = "Amount of swap for LXC containers (in MB)"
  type        = number
  default     = 512
}

variable "lxc_network_bridge" {
  description = "Network bridge for LXC containers"
  type        = string
  default     = "vmbr0"
}

variable "lxc_storage" {
  description = "Storage for LXC containers"
  type        = string
  default     = "local-lvm"
}

variable "lxc_disk_size" {
  description = "Disk size for LXC containers"
  type        = string
  default     = "8G"
}

variable "ssh_public_key_file" {
  description = "Path to SSH public key file"
  default     = "~/.ssh/id_rsa.pub"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}

variable "domain" {
  description = "Domain name for k3s nodes"
  type        = string
}

variable "node_count" {
  description = "Number of k3s nodes to create"
  type        = number
  default     = 3
}

variable "lxc_username" {
    description = "Username for LXC containers"
    type        = string
    default     = "root"
}



variable "proxmox_host" {   
    description = "Proxmox host"
    type        = string
    default     = "10.0.0.99"
}
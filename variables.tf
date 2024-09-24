# Variable declarations

variable "proxmox_host" {
  type        = string
  description = "Proxmox host IP address"
}

variable "proxmox_user" {
  type        = string
  description = "Proxmox user"
}

variable "proxmox_password" {
  type        = string
  description = "Proxmox password"
}

variable "container_user" {
  type        = string
  description = "LXC container user"
}

variable "container_password" {
  type        = string
  description = "LXC container password"
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token"
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID"
}

variable "domain_name" {
  type        = string
  description = "Domain name for the cluster"
}

variable "email_address" {
  type        = string
  description = "Email address for Let's Encrypt SSL certificate"
}
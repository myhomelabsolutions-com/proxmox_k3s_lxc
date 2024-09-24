# Main Terraform configuration file

terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://${var.proxmox_host}:8006/api2/json"
  pm_user         = "${var.proxmox_user}@pam"
  pm_password     = var.proxmox_password
  pm_tls_insecure = true
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Include other configuration files
# Note: These are not modules, just additional .tf files in the same directory
# Cloudflare DNS configuration

resource "cloudflare_record" "k3s_master" {
  zone_id = var.cloudflare_zone_id
  name    = "k3s-master"
  content = var.external_ip_address
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "k3s_workers" {
  count   = 2
  zone_id = var.cloudflare_zone_id
  name    = "k3s-worker-${count.index + 1}"
  content = var.external_ip_address
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "argocd" {
  zone_id = var.cloudflare_zone_id
  name    = "argocd"
  content = var.external_ip_address
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = "*"
  content = var.external_ip_address
  type    = "A"
  proxied = true
}
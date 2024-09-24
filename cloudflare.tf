# Cloudflare DNS configuration

resource "cloudflare_record" "k3s_master" {
  zone_id = var.cloudflare_zone_id
  name    = "k3s-master"
  content = "24.126.172.118"
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "k3s_workers" {
  count   = 2
  zone_id = var.cloudflare_zone_id
  name    = "k3s-worker-${count.index + 1}"
  content = "24.126.172.118"
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "argocd" {
  zone_id = var.cloudflare_zone_id
  name    = "argocd"
  content = "24.126.172.118"
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = "*"
  content = "24.126.172.118"
  type    = "A"
  proxied = true
}
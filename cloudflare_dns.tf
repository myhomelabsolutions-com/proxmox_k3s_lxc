# Cloudflare DNS configuration

resource "cloudflare_record" "k3s_master" {
  count   = var.deploy_cloudflare_dns ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "k3s-master"
  content = var.external_ip_address
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "k3s_workers" {
  count   = var.deploy_cloudflare_dns ? 2 : 0
  zone_id = var.cloudflare_zone_id
  name    = "k3s-worker-${count.index + 1}"
  content = var.external_ip_address
  type    = "A"
  proxied = false
}